import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../data/sesion_repository.dart';
import 'config.dart';

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
  Future<TranscripcionResult> transcribir({
    required Uint8List audio,
    required String filename,
    List<String> terminos = const [],
    String? idioma,
  }) async {
    final request = http.MultipartRequest('POST', _uri('/v1/transcripciones'))
      ..fields['diarizar'] = 'true'
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
}
