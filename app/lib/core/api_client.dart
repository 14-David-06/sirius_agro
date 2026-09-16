import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../data/sesion_repository.dart';
import 'config.dart';

class InformeGenerado {
  const InformeGenerado({
    required this.titulo,
    required this.tipo,
    required this.contenido,
    this.modelo,
  });

  final String titulo;
  final String tipo;
  final String contenido;
  final String? modelo;
}

/// Un turno del chat de campo. `rol` es "user" o "assistant" tal cual lo
/// espera el backend.
class MensajeChat {
  const MensajeChat({required this.rol, required this.contenido});

  final String rol;
  final String contenido;

  bool get esDelVisitador => rol == 'user';

  Map<String, dynamic> toJson() => {'rol': rol, 'contenido': contenido};
}

/// Lo que devuelve el chat de una visita: la respuesta y lo que quedo escrito.
///
/// Los dos van juntos a proposito. La pantalla tiene que poder decir «guarde
/// esto» en el mismo turno en que lo guardo: el dato entra directo al registro,
/// y el unico momento en que alguien puede notar que el modelo entendio mal es
/// ese.
class ComplementoResult {
  const ComplementoResult({
    required this.respuesta,
    this.hallazgos = const [],
    this.temasPendientes = const [],
  });

  final String respuesta;

  /// En el formato de la extraccion del audio, para que la app los guarde por
  /// el camino que ya aplica las reglas duras.
  final List<Map<String, dynamic>> hallazgos;

  final List<String> temasPendientes;
}

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class Turno {
  const Turno({
    required this.hablante,
    required this.inicio,
    required this.fin,
    required this.texto,
  });

  final int hablante;
  final double inicio;
  final double fin;
  final String texto;

  factory Turno.fromJson(Map<String, dynamic> j) => Turno(
        hablante: (j['hablante'] as num).toInt(),
        inicio: (j['inicio'] as num).toDouble(),
        fin: (j['fin'] as num).toDouble(),
        texto: j['texto'] as String,
      );
}

class TranscripcionResult {
  const TranscripcionResult({
    required this.texto,
    this.textoConMarcas,
    this.duracionSegundos,
    this.motor,
    this.turnos = const [],
    this.hablanteVisitadorSugerido,
    this.razonSugerencia = '',
  });

  final String texto;

  /// Turnos con segundo de inicio y hablante. Sin esto no hay citas, y sin
  /// citas los hallazgos no pueden pasar de Pendiente.
  final String? textoConMarcas;
  final double? duracionSegundos;
  final String? motor;
  final List<Turno> turnos;

  /// Cual de las voces PARECE ser el visitador. Es una sugerencia del backend,
  /// no un dato: lo confirma el visitador de un toque en la validacion.
  ///
  /// Importa porque de esto depende la regla de que lo dicho por el visitador
  /// nunca queda Confirmado. Si el mapeo se invierte, se degrada el dato del
  /// agricultor y se avala el del visitador — al reves de lo que busca.
  final int? hablanteVisitadorSugerido;
  final String razonSugerencia;

  factory TranscripcionResult.fromJson(Map<String, dynamic> j) =>
      TranscripcionResult(
        texto: j['text'] as String,
        textoConMarcas: j['text_with_timestamps'] as String?,
        duracionSegundos: (j['duration_seconds'] as num?)?.toDouble(),
        motor: j['motor'] as String?,
        turnos: ((j['turnos'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(Turno.fromJson)
            .toList(),
        hablanteVisitadorSugerido:
            (j['hablante_visitador_sugerido'] as num?)?.toInt(),
        razonSugerencia: (j['razon_sugerencia'] as String?) ?? '',
      );
}

class ExtraccionResult {
  const ExtraccionResult({
    required this.hallazgos,
    this.resumen,
    this.temasPendientes = const [],
  });

  /// Cada mapa es un `HallazgoExtraido` sin decodificar todavia. Se decodifica
  /// en el repositorio, que es donde se aplican las reglas duras.
  final List<Map<String, dynamic>> hallazgos;
  final String? resumen;
  final List<String> temasPendientes;
}

class VisitaSyncResult {
  const VisitaSyncResult({
    required this.codigoVisita,
    required this.recordId,
    required this.url,
    this.grabaciones = 0,
    this.evidencias = 0,
    this.hallazgos = 0,
    this.clavesDesconocidas = const [],
    this.degradados = const [],
  });

  final String codigoVisita;
  final String recordId;
  final String url;

  final int grabaciones;
  final int evidencias;
  final int hallazgos;

  /// Claves que el modelo devolvio y no estan en el catalogo. El backend las
  /// descarta en vez de inventar el campo, y las reporta para que alguien
  /// decida si merecen entrar al catalogo.
  final List<String> clavesDesconocidas;

  /// Hallazgos que bajaron de certeza al aplicar las reglas duras, con el
  /// motivo en una linea.
  final List<String> degradados;

  factory VisitaSyncResult.fromJson(Map<String, dynamic> j) => VisitaSyncResult(
        codigoVisita: j['codigo_visita'] as String,
        recordId: j['record_id'] as String,
        url: j['url'] as String,
        grabaciones: (j['grabaciones'] as num?)?.toInt() ?? 0,
        evidencias: (j['evidencias'] as num?)?.toInt() ?? 0,
        hallazgos: (j['hallazgos'] as num?)?.toInt() ?? 0,
        clavesDesconocidas:
            ((j['claves_desconocidas'] as List?) ?? const []).cast<String>(),
        degradados: ((j['degradados'] as List?) ?? const []).cast<String>(),
      );
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Map<String, String> get _headers => {
        ..._authHeaders,
        'Content-Type': 'application/json',
      };

  /// El backend exige `X-API-Key` en todas las rutas de `/v1`. Sin esto la
  /// respuesta es 401 aunque el token del visitador sea valido.
  Map<String, String> get _authHeaders => {
        if (AppConfig.apiKey.isNotEmpty) 'X-API-Key': AppConfig.apiKey,
      };

  Uri _uri(String path) => Uri.parse('${AppConfig.baseUrl}$path');

  Never _fail(http.Response response) {
    String detail = response.body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['detail'] != null) {
        detail = decoded['detail'].toString();
      }
    } catch (_) {
      // El backend no siempre responde JSON (proxies, 502 de infraestructura).
    }
    throw ApiException('HTTP ${response.statusCode}: $detail');
  }

  /// Verifica la contrasena contra `Sirius Nomina Core`.
  ///
  /// La app no habla con Airtable: el PAT que lee `Personal` tambien lee
  /// salarios y cuentas bancarias, y una llave dentro de un APK es publica.
  ///
  /// La respuesta trae el hash bcrypt de la persona para poder validar sin
  /// senal despues. Solo llega aca porque la contrasena ya se verifico del
  /// otro lado: no hay ningun endpoint que reparta hashes sin esa prueba.
  Future<CredencialRemota> login({
    required String cedula,
    required String password,
  }) async {
    final response = await _client.post(
      _uri('/v1/auth/login'),
      headers: _headers,
      body: jsonEncode({'cedula': cedula, 'password': password}),
    );
    if (response.statusCode >= 400) _fail(response);

    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return CredencialRemota(
      idEmpleado: json['id_empleado'] as String? ?? '',
      cedula: json['cedula'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      email: json['email'] as String? ?? '',
      rolApp: json['rol_app'] as String? ?? 'Visitador',
      nivelAcceso: json['nivel_acceso'] as String? ?? '',
      ordenNivel: (json['orden_nivel'] as num?)?.toInt() ?? 99,
      hashBcrypt: json['hash_offline'] as String? ?? '',
      diasMaxOffline: (json['dias_max_offline'] as num?)?.toInt() ?? 30,
    );
  }

  /// Arma el informe que el visitador le entrega al agricultor.
  ///
  /// Necesita señal: lo escribe Claude a partir de la conversacion y los
  /// hallazgos. No hay modo degradado — un informe generado sin el modelo
  /// seria una plantilla con el nombre de la finca encima.
  Future<InformeGenerado> generarInforme(Map<String, dynamic> contexto) async {
    final response = await _client.post(
      _uri('/v1/informes'),
      headers: _headers,
      body: jsonEncode(contexto),
    );
    if (response.statusCode >= 400) _fail(response);

    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return InformeGenerado(
      titulo: json['titulo'] as String,
      tipo: json['tipo'] as String? ?? 'Resumen para el agricultor',
      contenido: json['contenido'] as String,
      modelo: json['modelo'] as String?,
    );
  }

  /// Responde una pregunta del visitador en campo.
  ///
  /// El hilo viaja completo en cada peticion: el backend no guarda la
  /// conversacion. Necesita señal — es una consulta al modelo, no hay como
  /// responderla desde el telefono.
  Future<String> chat({
    required List<MensajeChat> mensajes,
    String? visitador,
    String? contexto,
  }) async {
    final response = await _client.post(
      _uri('/v1/chat'),
      headers: _headers,
      body: jsonEncode({
        'mensajes': [for (final m in mensajes) m.toJson()],
        'visitador': ?visitador,
        if (contexto != null && contexto.isNotEmpty) 'contexto': contexto,
      }),
    );
    if (response.statusCode >= 400) _fail(response);

    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return json['respuesta'] as String;
  }

  /// El chat de UNA visita: responde sobre ella y captura lo que falto.
  ///
  /// Distinto del chat de campo en lo que importa: aquel solo responde, este
  /// devuelve tambien `hallazgos` — datos que el visitador aporto tecleando y
  /// que entran al registro de la visita.
  ///
  /// Vienen en el mismo formato que la extraccion del audio, asi que la app
  /// los guarda por el camino que ya existe: el que aplica las reglas duras y
  /// recalcula la completitud. Lo que los distingue es la procedencia, que
  /// marca el backend: `fuente = Manual`, `hablante = visitador`.
  Future<ComplementoResult> complementar({
    required String codigoVisita,
    required List<MensajeChat> mensajes,
    required List<Map<String, dynamic>> campos,
    String? contexto,
    String? visitador,
  }) async {
    final response = await _client.post(
      _uri('/v1/complemento'),
      headers: _headers,
      body: jsonEncode({
        'codigo_visita': codigoVisita,
        'mensajes': [for (final m in mensajes) m.toJson()],
        'campos': campos,
        'visitador': ?visitador,
        if (contexto != null && contexto.isNotEmpty) 'contexto': contexto,
      }),
    );
    if (response.statusCode >= 400) _fail(response);

    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return ComplementoResult(
      respuesta: json['respuesta'] as String,
      hallazgos: (json['hallazgos'] as List).cast<Map<String, dynamic>>(),
      temasPendientes:
          ((json['temas_pendientes'] as List?) ?? const []).cast<String>(),
    );
  }

  /// Trae el catalogo vigente para refrescar el espejo local. Airtable es la
  /// fuente de verdad; la semilla del APK solo cubre el primer arranque.
  Future<List<Map<String, dynamic>>> catalogo() async {
    final response = await _client.get(_uri('/v1/catalogo'), headers: _headers);
    if (response.statusCode >= 400) _fail(response);

    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return (json['campos'] as List).cast<Map<String, dynamic>>();
  }

  /// `terminos` es lo especifico de esta visita: el nombre del productor, su
  /// vereda, los insumos que ya se le registraron. Es lo que de verdad mejora
  /// la transcripcion — un termino generico ayuda poco, el apellido de la
  /// persona que esta hablando ayuda mucho.
  ///
  /// `diarizar` separa las voces, que es lo que da las citas de la
  /// conversacion. Una nota de voz del visitador lo apaga: ahi habla uno solo
  /// y las marcas de hablante solo estorban.
  Future<TranscripcionResult> transcribir({
    required Uint8List audio,
    required String filename,
    List<String> terminos = const [],
    String? idioma,
    bool diarizar = true,
  }) async {
    final request = http.MultipartRequest('POST', _uri('/v1/transcripciones'))
      ..fields['diarizar'] = '$diarizar'
      ..fields['terminos'] = terminos.join(',')
      ..files
          .add(http.MultipartFile.fromBytes('file', audio, filename: filename));
    if (idioma != null) request.fields['idioma'] = idioma;
    request.headers.addAll(_authHeaders);

    final response = await http.Response.fromStream(await _client.send(request));
    if (response.statusCode >= 400) _fail(response);

    return TranscripcionResult.fromJson(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
    );
  }

  /// Estructura la conversacion contra el esquema derivado del catalogo.
  ///
  /// El catalogo va en la peticion, no lo lee el backend de Airtable: son los
  /// mismos campos contra los que la app calcula la completitud, asi que el
  /// esquema de extraccion y el conteo no pueden desalinearse. Un telefono con
  /// la semilla vieja pide el esquema que de verdad esta usando.
  Future<ExtraccionResult> extraer({
    required String visitaId,
    required String transcripcion,
    required List<Map<String, dynamic>> campos,
    int? hablanteVisitador,
  }) async {
    final response = await _client.post(
      _uri('/v1/extracciones'),
      headers: _headers,
      body: jsonEncode({
        'codigo_visita': visitaId,
        'transcripcion': transcripcion,
        'campos': campos,
        'hablante_visitador': hablanteVisitador,
      }),
    );
    if (response.statusCode >= 400) _fail(response);

    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return ExtraccionResult(
      hallazgos: (json['hallazgos'] as List).cast<Map<String, dynamic>>(),
      resumen: json['resumen'] as String?,
      temasPendientes:
          ((json['temas_pendientes'] as List?) ?? const []).cast<String>(),
    );
  }

  /// Sube un tramo de audio o una foto al bucket y devuelve su URL publica.
  ///
  /// Va contra el backend y no contra S3 directo a proposito: una llave de
  /// bucket dentro de un APK que anda en el bolsillo de alguien es una llave
  /// publica. El backend tiene las credenciales; la app solo tiene la suya.
  Future<String> subirArchivo({
    required Uint8List contenido,
    required String filename,
    required String codigoVisita,
    required String categoria,
    int? orden,
  }) async {
    final request = http.MultipartRequest('POST', _uri('/v1/archivos'))
      ..fields['codigo_visita'] = codigoVisita
      ..fields['categoria'] = categoria;
    if (orden != null) request.fields['orden'] = '$orden';
    request.files.add(
      http.MultipartFile.fromBytes('file', contenido, filename: filename),
    );
    request.headers.addAll(_authHeaders);

    final response = await http.Response.fromStream(await _client.send(request));
    if (response.statusCode >= 400) _fail(response);

    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return json['url'] as String;
  }

  /// Sube el PDF del informe al bucket con una URL prefirmada.
  ///
  /// No pasa por `/v1/archivos` como el audio y las fotos porque no cabe: el
  /// informe lleva las fotos embebidas y el cuerpo maximo del host son 4,5 MB,
  /// que es un limite de infraestructura y no se configura.
  ///
  /// Sigue sin haber una llave de bucket en el APK. El backend firma un PUT
  /// contra UNA ruta que el mismo arma, y la firma vence: es un permiso
  /// temporal para un archivo, no una credencial.
  ///
  /// Devuelve la URL publica, que es la que se guarda. La firmada lleva la
  /// autorizacion en la query y manana no sirve.
  ///
  /// [categoria] separa el informe del productor (`informes`) del tecnico de
  /// la empresa (`informes_tecnicos`). Van a carpetas distintas del bucket
  /// porque el backend renombra por categoria y por orden: en la misma
  /// carpeta, el tecnico 01 pisaria el del productor 01.
  Future<String> subirInformePdf({
    required Uint8List contenido,
    required String filename,
    required String codigoVisita,
    String categoria = 'informes',
    int? orden,
  }) async {
    final firma = await _client.post(
      _uri('/v1/archivos/firma'),
      headers: _authHeaders,
      body: {
        'codigo_visita': codigoVisita,
        'nombre': filename,
        'categoria': categoria,
        if (orden != null) 'orden': '$orden',
      },
    );
    if (firma.statusCode >= 400) _fail(firma);

    final json =
        jsonDecode(utf8.decode(firma.bodyBytes)) as Map<String, dynamic>;

    // El Content-Type va DENTRO de la firma: si el PUT manda otro, S3 rechaza
    // la subida. Se usa el que dijo el backend, no uno propio.
    final puesto = await _client.put(
      Uri.parse(json['url_firmada'] as String),
      headers: {'Content-Type': json['content_type'] as String},
      body: contenido,
    );
    if (puesto.statusCode >= 400) {
      // S3 responde XML, no el JSON con `detail` que espera `_fail`.
      throw ApiException(
        'El bucket rechazo el PDF (HTTP ${puesto.statusCode}).',
      );
    }

    return json['url_publica'] as String;
  }

  /// Sube la visita. Idempotente por `codigo_visita`, que es el UUID que
  /// genero el dispositivo: reintentar nunca duplica.
  ///
  /// Devuelve lo que el backend decidio: cuantos hijos escribio, que claves
  /// quedaron fuera del catalogo y que hallazgos bajaron de certeza al
  /// aplicar las reglas duras. Eso ultimo importa mostrarlo — el visitador
  /// creyo haber capturado un dato Confirmado y quedo Pendiente.
  Future<VisitaSyncResult> sincronizarVisita(
    Map<String, dynamic> payload,
  ) async {
    final response = await _client.post(
      _uri('/v1/visitas'),
      headers: _headers,
      body: jsonEncode(payload),
    );
    if (response.statusCode >= 400) _fail(response);

    return VisitaSyncResult.fromJson(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
    );
  }

  /// Los agricultores ya registrados en Airtable, para no volver a crearlos.
  ///
  /// Es una ayuda y se trata como tal: quien la llama tiene que dejar seguir
  /// el registro si esto falla. Sin senal en la vereda —que es la mitad del
  /// tiempo— la app busca en su espejo local y, si el agricultor no esta en
  /// ninguna parte, se teclea el nombre y la visita arranca igual.
  ///
  /// [timeout] es corto a proposito: el visitador esta parado frente al
  /// agricultor esperando para escribir un nombre. Pasado ese punto la
  /// respuesta ya no ayuda, aunque llegue.
  Future<List<Map<String, dynamic>>> productoresRegistrados({
    String? buscar,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final texto = (buscar ?? '').trim();
    final response = await _client
        .get(
          _uri('/v1/productores').replace(
            queryParameters: texto.isEmpty ? null : {'buscar': texto},
          ),
          headers: _headers,
        )
        .timeout(timeout);
    if (response.statusCode >= 400) _fail(response);

    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return (json['productores'] as List).cast<Map<String, dynamic>>();
  }

  /// Las visitas ya registradas de un agricultor.
  ///
  /// Es lo unico que baja de Airtable aparte del directorio, y baja para
  /// CONSULTARSE: la app las guarda como espejo de solo lectura. El timeout es
  /// mas largo que el del directorio porque el backend recorre varias tablas,
  /// y esto se pide a proposito —el visitador toca un boton y espera—, no en
  /// medio de una pantalla que tiene que responder.
  Future<Map<String, dynamic>> historialDeProductor(
    String productorId, {
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final response = await _client
        .get(_uri('/v1/productores/$productorId/visitas'), headers: _headers)
        .timeout(timeout);
    if (response.statusCode >= 400) _fail(response);

    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  /// El indice de visitas de Airtable: solo las fichas, sin hijos.
  ///
  /// Es lo que la app refresca sola para que las visitas del equipo aparezcan
  /// en la lista sin que nadie toque un boton. Liviano a proposito — por eso
  /// puede ser automatico.
  ///
  /// Timeout corto y del lado de la comodidad: esto corre en segundo plano
  /// mientras el visitador mira su lista, y si tarda mas de esto ya no es un
  /// refresco, es una espera.
  Future<List<Map<String, dynamic>>> indiceDeVisitas({
    Duration timeout = const Duration(seconds: 25),
  }) async {
    final response = await _client
        .get(_uri('/v1/visitas'), headers: _headers)
        .timeout(timeout);
    if (response.statusCode >= 400) _fail(response);

    return (jsonDecode(utf8.decode(response.bodyBytes)) as List)
        .cast<Map<String, dynamic>>();
  }

  /// Una visita con todo lo suyo, para cuando alguien la abre.
  Future<Map<String, dynamic>> detalleDeVisita(
    String codigoVisita, {
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final response = await _client
        .get(_uri('/v1/visitas/$codigoVisita'), headers: _headers)
        .timeout(timeout);
    if (response.statusCode >= 400) _fail(response);

    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  /// Baja un archivo del historial: la foto de un adjunto de Airtable o el
  /// audio del bucket.
  ///
  /// Va POR EL BACKEND y no directo al dominio del archivo. El telefono no
  /// siempre llega a Airtable ni a S3 —en la finca depende de la red que haya,
  /// y conectado por USB no tiene mas salida que el backend—, y el resultado
  /// de intentarlo directo era una foto rota en la galeria: el archivo no
  /// bajaba pero la fila se escribia igual.
  ///
  /// Por el mismo canal que el resto de la API significa una sola red que
  /// tiene que funcionar y una sola autenticacion. La llave viaja a nuestro
  /// backend, que es de donde salio, y nunca a un tercero.
  ///
  /// Devuelve null si falla: un archivo que no se pudo bajar deja un hueco en
  /// el historial, no cancela la descarga entera.
  Future<List<int>?> descargarArchivo(
    String url, {
    Duration timeout = const Duration(seconds: 60),
  }) async {
    try {
      final response = await _client
          .get(
            _uri('/v1/archivos/contenido')
                .replace(queryParameters: {'url': url}),
            headers: _authHeaders,
          )
          .timeout(timeout);
      if (response.statusCode >= 400) return null;
      return response.bodyBytes;
    } catch (_) {
      return null;
    }
  }
}
