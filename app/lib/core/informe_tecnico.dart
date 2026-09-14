import 'package:intl/intl.dart';

import 'geo.dart' as geo;

/// El informe tecnico de la visita: el documento de la EMPRESA.
///
/// Es el hermano del informe del productor y no su reemplazo. Aquel lo escribe
/// el modelo y se le lee al agricultor en la casa; este no pasa por el modelo
/// en absoluto — se arma con lo que hay en la base del telefono y nada mas.
///
/// Esa es la decision de fondo: un documento institucional que muestra
/// coordenadas no puede depender de un modelo de lenguaje. Un lindero mal
/// escrito por una alucinacion es un lindero equivocado en un papel con el
/// membrete de Sirius, y nadie que lo lea seis meses despues va a poder
/// distinguirlo de una medida real. Aca los numeros salen de `PuntosTrazado`,
/// `Visitas.latitud` y `Evidencias`, y por eso se pueden auditar.
///
/// La otra consecuencia: se arma SIN SENAL. El visitador lo puede entregar en
/// la finca igual que el del productor.
///
/// El PDF vive en `informe_tecnico_pdf.dart`; aca estan los datos y el
/// markdown que se guarda en `Informes.Contenido` — el mismo contenido en
/// texto, para que en Airtable se pueda leer sin abrir el adjunto y para
/// poder regenerar el documento sin volver a recorrer la base.

/// Coincide con una opcion de `Informes.Tipo`. La sincronizacion escribe con
/// `typecast`, asi que Airtable crea la opcion la primera vez.
const tipoInformeTecnico = 'Informe tecnico de visita';

/// Codigo de formato del documento. El del productor es FT-AGRO-001.
const codigoFormatoTecnico = 'FT-AGRO-002';

class ProductorTecnico {
  const ProductorTecnico({
    required this.nombre,
    this.documento,
    this.tipoDocumento,
    this.telefono,
    this.organizacion,
    this.codigoProductor,
    this.consentimientoDatos = false,
    this.fechaConsentimiento,
  });

  final String nombre;
  final String? documento;
  final String? tipoDocumento;
  final String? telefono;
  final String? organizacion;

  /// Consecutivo BU-0001 que asigna el backend. Nulo mientras la visita no
  /// haya sincronizado: es el numero con el que el productor existe para la
  /// empresa, y decirlo cuando todavia no existe seria inventarlo.
  final String? codigoProductor;

  final bool consentimientoDatos;
  final DateTime? fechaConsentimiento;
}

class FincaTecnica {
  const FincaTecnica({
    required this.nombre,
    this.latitud,
    this.longitud,
    this.areaDeclaradaHa,
  });

  final String nombre;
  final double? latitud;
  final double? longitud;

  /// Lo que el productor dijo que mide. Se llama «declarada» a proposito: no
  /// es lo mismo que el area caminada de los trazados, y el informe muestra
  /// las dos sin mezclarlas.
  final double? areaDeclaradaHa;
}

class PuntoTecnico {
  const PuntoTecnico({
    required this.orden,
    required this.latitud,
    required this.longitud,
    required this.capturadoEn,
    this.altitud,
    this.precisionM,
    this.automatico = false,
    this.nota,
  });

  final int orden;
  final double latitud;
  final double longitud;
  final DateTime capturadoEn;
  final double? altitud;
  final double? precisionM;
  final bool automatico;
  final String? nota;

  geo.PuntoGeo get punto => geo.PuntoGeo(latitud, longitud);
}

class TrazadoTecnico {
  const TrazadoTecnico({
    required this.nombre,
    required this.tipo,
    required this.modoCaptura,
    required this.cerrado,
    required this.puntos,
    this.etiqueta,
    this.notas,
    this.areaM2,
    this.perimetroM,
  });

  final String nombre;

  /// `Poligono` | `Ruta` | `Punto`, tal como se guardan.
  final String tipo;
  final String modoCaptura;
  final bool cerrado;
  final List<PuntoTecnico> puntos;
  final String? etiqueta;
  final String? notas;
  final double? areaM2;
  final double? perimetroM;

  bool get esPoligono => tipo == 'Poligono';

  List<geo.PuntoGeo> get geometria => [for (final p in puntos) p.punto];

  /// Se recalcula y no se confia en la columna: la fila guarda el area para
  /// que la lista no recorra los puntos, pero el documento que se archiva
  /// tiene que poder rehacerse desde la geometria. Si los dos numeros no
  /// coinciden, manda la geometria — es lo unico que se camino.
  double get areaCalculadaM2 => esPoligono && cerrado ? geo.areaM2(geometria) : 0;

  double get perimetroCalculadoM =>
      geo.longitudMetros(geometria, cerrado: esPoligono && cerrado);

  geo.PuntoGeo? get centroide => geo.centro(geometria);

  /// Promedio del radio de error que reporto el GPS en cada vertice. Es lo que
  /// permite decidir, tres meses despues, si un lindero raro fue un error del
  /// visitador o un salto del GPS bajo los arboles.
  double? get precisionPromedioM {
    final valores = [
      for (final p in puntos)
        if (p.precisionM != null) p.precisionM!,
    ];
    if (valores.isEmpty) return null;
    return valores.reduce((a, b) => a + b) / valores.length;
  }

  double? get precisionPeorM {
    final valores = [
      for (final p in puntos)
        if (p.precisionM != null) p.precisionM!,
    ];
    if (valores.isEmpty) return null;
    return valores.reduce((a, b) => a > b ? a : b);
  }
}

class HallazgoTecnico {
  const HallazgoTecnico({
    required this.modulo,
    required this.campo,
    required this.claveTecnica,
    required this.valor,
    required this.certeza,
    required this.fuente,
    required this.estado,
    this.unidad,
    this.confianza,
    this.segundoAudio,
    this.citaTextual,
    this.razonamiento,
    this.valorCorregido,
    this.entidad,
  });

  final String modulo;
  final String campo;
  final String claveTecnica;
  final String valor;
  final String certeza;
  final String fuente;
  final String estado;
  final String? unidad;

  /// 0..1 como la reporto el modelo.
  final double? confianza;
  final int? segundoAudio;
  final String? citaTextual;
  final String? razonamiento;

  /// Lo que el visitador dejo como verdad final. El original nunca se borra:
  /// sin los dos no se puede medir la precision del modelo en el piloto.
  final String? valorCorregido;

  /// `Cultivo 2`, `Lote 1`. Distingue a cual de los tres cultivos se refiere.
  final String? entidad;

  /// Lo que se muestra como dato: la correccion del visitador manda sobre lo
  /// que extrajo el modelo.
  String get valorVigente =>
      (valorCorregido?.isNotEmpty ?? false) ? valorCorregido! : valor;

  String get valorConUnidad =>
      unidad == null || unidad!.isEmpty ? valorVigente : '$valorVigente $unidad';
}

class EvidenciaTecnica {
  const EvidenciaTecnica({
    required this.archivoPath,
    required this.tomadaEn,
    this.tipo,
    this.latitud,
    this.longitud,
    this.segundoAudio,
    this.descripcion,
    this.textoOcr,
    this.estadoValidacion,
  });

  final String archivoPath;
  final DateTime tomadaEn;
  final String? tipo;
  final double? latitud;
  final double? longitud;

  /// Segundo de la grabacion en curso cuando se tomo la foto. Es lo que
  /// permite volver a lo que se estaba hablando mientras se fotografiaba.
  final int? segundoAudio;
  final String? descripcion;
  final String? textoOcr;
  final String? estadoValidacion;

  bool get tieneGps => latitud != null && longitud != null;
}

class GrabacionTecnica {
  const GrabacionTecnica({
    required this.orden,
    required this.inicio,
    required this.duracionSeg,
    required this.tamanoBytes,
    this.motor,
    this.estado,
    this.transcrita = false,
  });

  final int orden;
  final DateTime inicio;
  final int duracionSeg;
  final int tamanoBytes;
  final String? motor;
  final String? estado;
  final bool transcrita;
}

/// El registro de consentimiento (Ley 1581/2012).
///
/// Va en el informe tecnico y no en el del productor porque es lo que la
/// empresa tiene que poder mostrar si alguien pregunta con que permiso se
/// grabo. [segundoConsentimiento] es la prueba auditable: el segundo exacto
/// del audio donde el productor lo dice con su voz.
class ConsentimientoTecnico {
  const ConsentimientoTecnico({
    this.audio = false,
    this.fotos = false,
    this.usoDatos = false,
    this.segundoConsentimiento,
    this.marcadaParaEliminacion = false,
  });

  final bool audio;
  final bool fotos;
  final bool usoDatos;
  final int? segundoConsentimiento;

  /// El productor revoco. Al sincronizar, el backend borra audio, fotos y
  /// hallazgos. Si esta marcada, el informe lo dice arriba y en grande: un
  /// documento con datos de una visita revocada no se puede usar.
  final bool marcadaParaEliminacion;
}

class DatosInformeTecnico {
  const DatosInformeTecnico({
    required this.codigoVisita,
    required this.inicio,
    required this.generadoEn,
    required this.version,
    this.fin,
    this.estado,
    this.tipoVisita,
    this.completitudPct = 0,
    this.visitador,
    this.productor,
    this.finca,
    this.vereda,
    this.municipio,
    this.latitud,
    this.longitud,
    this.precisionGps,
    this.objetivo,
    this.observaciones,
    this.temasPendientes,
    this.trazados = const [],
    this.hallazgos = const [],
    this.evidencias = const [],
    this.grabaciones = const [],
    this.consentimiento = const ConsentimientoTecnico(),
    this.sincronizada = false,
    this.modeloIa,
  });

  /// UUID de la visita. Es tambien `Visitas.Codigo de visita` en Airtable, y
  /// la llave con la que se encuentra todo lo demas: el prefijo del bucket, la
  /// carpeta del telefono, el registro de la visita.
  final String codigoVisita;

  final DateTime inicio;
  final DateTime? fin;
  final DateTime generadoEn;

  /// Version del informe dentro de su tipo. Las anteriores no se borran.
  final int version;

  final String? estado;
  final String? tipoVisita;
  final int completitudPct;
  final String? visitador;
  final ProductorTecnico? productor;
  final FincaTecnica? finca;
  final String? vereda;
  final String? municipio;

  /// Donde se abrio la visita, con el radio de error que reporto el telefono.
  final double? latitud;
  final double? longitud;
  final double? precisionGps;

  final String? objetivo;
  final String? observaciones;
  final String? temasPendientes;

  final List<TrazadoTecnico> trazados;
  final List<HallazgoTecnico> hallazgos;
  final List<EvidenciaTecnica> evidencias;
  final List<GrabacionTecnica> grabaciones;
  final ConsentimientoTecnico consentimiento;
  final bool sincronizada;

  /// Modelo de IA registrado en la visita: el que transcribio y extrajo los
  /// hallazgos. No escribio este documento — se nombra para que quede claro
  /// de donde vienen los datos de la seccion 5.
  final String? modeloIa;

  Duration? get duracion => fin?.difference(inicio);

  String get lugar => [vereda, municipio]
      .whereType<String>()
      .where((x) => x.isNotEmpty)
      .join(' / ');

  bool get tieneGps => latitud != null && longitud != null;

  /// Los hallazgos agrupados por modulo, con los modulos en orden alfabetico y
  /// los campos en el orden del catalogo dentro de cada uno.
  ///
  /// Los `Pendiente` NO se filtran, al contrario del informe del productor:
  /// alla un pendiente presentado como dato seria una mentira al agricultor,
  /// aca es informacion de gestion — dice que falta y que hay que volver a
  /// preguntar.
  Map<String, List<HallazgoTecnico>> get porModulo {
    final mapa = <String, List<HallazgoTecnico>>{};
    for (final h in hallazgos) {
      mapa.putIfAbsent(h.modulo, () => []).add(h);
    }
    final claves = mapa.keys.toList()..sort();
    return {for (final k in claves) k: mapa[k]!};
  }

  /// Cuantos hallazgos hay de cada certeza. Es el indicador de calidad del
  /// dato: una visita con 40 hallazgos de los cuales 30 son Inferido no vale
  /// lo mismo que una con 20 confirmados.
  Map<String, int> get conteoPorCerteza {
    final conteo = <String, int>{};
    for (final h in hallazgos) {
      conteo[h.certeza] = (conteo[h.certeza] ?? 0) + 1;
    }
    return conteo;
  }

  /// Suma de las areas de los poligonos cerrados, en metros cuadrados. Los
  /// recorridos no entran: una ruta no tiene area.
  double get areaMedidaM2 => trazados.fold(
        0.0,
        (suma, t) => suma + t.areaCalculadaM2,
      );

  int get puntosGpsTotales =>
      trazados.fold(0, (suma, t) => suma + t.puntos.length);

  Duration get audioTotal => Duration(
        seconds: grabaciones.fold(0, (suma, g) => suma + g.duracionSeg),
      );
}

// --- Formato ---

/// «4,573210° N  ·  72,819044° W». El grado decimal con seis cifras es el
/// formato con el que se pega una coordenada en Google Earth o en QGIS, y seis
/// decimales son ~11 cm: mas alla de eso se estaria escribiendo ruido, porque
/// el GPS de un telefono anda entre 3 y 10 m.
String coordenadaDecimal(double lat, double lon) {
  final ns = lat >= 0 ? 'N' : 'S';
  final eo = lon >= 0 ? 'E' : 'W';
  final la = lat.abs().toStringAsFixed(6).replaceAll('.', ',');
  final lo = lon.abs().toStringAsFixed(6).replaceAll('.', ',');
  return '$la° $ns  ·  $lo° $eo';
}

/// «4° 34' 23,6" N  ·  72° 49' 8,6" W». Va junto al decimal porque es el
/// formato de los linderos en las escrituras y en los planos del IGAC: quien
/// compare este informe con un plano lo hace en sexagesimal.
String coordenadaSexagesimal(double lat, double lon) =>
    '${_dms(lat, 'N', 'S')}  ·  ${_dms(lon, 'E', 'W')}';

String _dms(double valor, String positivo, String negativo) {
  final hemisferio = valor >= 0 ? positivo : negativo;
  final abs = valor.abs();
  final grados = abs.floor();
  final minutosDecimal = (abs - grados) * 60;
  final minutos = minutosDecimal.floor();
  final segundos = (minutosDecimal - minutos) * 60;
  final seg = segundos.toStringAsFixed(1).replaceAll('.', ',');
  return '$grados° $minutos\' $seg" $hemisferio';
}

/// «± 6 m» / «sin dato». La precision se escribe siempre, incluso cuando
/// falta: una coordenada sin su radio de error invita a creerle mas de lo que
/// merece.
String precision(double? metros) =>
    metros == null ? 'sin dato' : '± ${metros.round()} m';

String duracionLegible(Duration? d) {
  if (d == null) return '—';
  final horas = d.inHours;
  final minutos = d.inMinutes.remainder(60);
  if (horas == 0) return '$minutos min';
  return '$horas h $minutos min';
}

String pesoLegible(int bytes) {
  if (bytes <= 0) return '—';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} MB';
}

/// «12:04» a partir del segundo del audio. Mas util que «724 s»: es lo que se
/// escribe en la barra del reproductor para llegar al momento exacto.
String marcaAudio(int? segundos) {
  if (segundos == null) return '—';
  final m = segundos ~/ 60;
  final s = segundos.remainder(60).toString().padLeft(2, '0');
  return '$m:$s';
}

String si(bool valor) => valor ? 'Si' : 'No';

/// El nombre del archivo, sin la ruta. En el informe no va la ruta completa:
/// `/data/user/0/com.sirius.agro/...` no le dice nada a nadie y ocupa media
/// linea. El archivo se encuentra por su nombre dentro del prefijo de la
/// visita en el bucket, que es donde alguien lo va a buscar.
String soloNombre(String ruta) =>
    ruta.split(RegExp(r'[\\/]')).where((x) => x.isNotEmpty).last;

/// Las fechas del informe van en español, como en el resto de la app.
class FormatoInforme {
  FormatoInforme();

  final _fechaLarga = DateFormat("d 'de' MMMM 'de' y", 'es');
  final _hora = DateFormat('h:mm a', 'es');
  final _fechaHora = DateFormat("d 'de' MMM, h:mm a", 'es');

  String fechaLarga(DateTime d) => _fechaLarga.format(d);
  String hora(DateTime d) => _hora.format(d);
  String fechaHora(DateTime d) => _fechaHora.format(d);

  /// Coma decimal y sin decimales cuando el numero es entero: «3 ha», no
  /// «3,00 ha».
  String numero(double v) =>
      v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2).replaceAll('.', ',');
}

// --- Markdown ---

/// El mismo informe en texto, para `Informes.Contenido`.
///
/// Existe por dos razones y ninguna es cosmetica. La primera: en Airtable
/// alguien tiene que poder leer el informe sin descargar el PDF — filtrar por
/// vereda y abrir veinte adjuntos no lo hace nadie. La segunda: el PDF que se
/// archiva es un binario, y si el renderizador cambia, este texto es de donde
/// se puede volver a armar el documento.
///
/// No lo escribe un modelo: es la misma data de las tablas, puesta en lineas.
String markdownInformeTecnico(DatosInformeTecnico d) {
  final f = FormatoInforme();
  final l = <String>[];
  final p = d.productor;

  l.add('# Informe tecnico de visita de campo');
  l.add('');
  l.add('Documento interno de Sirius Regenerative · $codigoFormatoTecnico · '
      'version ${d.version}');

  if (d.consentimiento.marcadaParaEliminacion) {
    l.add('');
    l.add('> VISITA MARCADA PARA ELIMINACION. El productor revoco su '
        'autorizacion: los datos de este informe no se pueden usar y se '
        'borran del servidor al sincronizar.');
  }

  l.add('');
  l.add('## 1. Identificacion de la visita');
  l.add('');
  l.addAll(_pares([
    ['Codigo de visita', d.codigoVisita],
    ['Fecha', f.fechaLarga(d.inicio)],
    ['Hora de inicio', f.hora(d.inicio)],
    ['Hora de cierre', d.fin == null ? 'Sin cerrar' : f.hora(d.fin!)],
    ['Duracion', duracionLegible(d.duracion)],
    ['Estado', d.estado ?? '—'],
    ['Tipo de visita', d.tipoVisita ?? '—'],
    ['Visitador', d.visitador ?? 'Sin registrar'],
    ['Cobertura del cuestionario', '${d.completitudPct}%'],
    ['Sincronizada', si(d.sincronizada)],
  ]));

  l.add('');
  l.add('## 2. Productor y predio');
  l.add('');
  l.addAll(_pares([
    ['Productor', p?.nombre ?? 'Sin registrar'],
    ['Documento', _documento(p)],
    ['Telefono', p?.telefono ?? 'Sin registrar'],
    ['Codigo de productor', p?.codigoProductor ?? 'Pendiente de sincronizar'],
    ['Organizacion', p?.organizacion ?? 'Ninguna'],
    ['Finca', d.finca?.nombre ?? 'Sin registrar'],
    ['Vereda / Municipio', d.lugar.isEmpty ? 'Sin registrar' : d.lugar],
    ['Area declarada', _areaDeclarada(d, f)],
  ]));

  l.add('');
  l.add('## 3. Georreferenciacion');
  l.add('');
  if (d.tieneGps) {
    l.addAll(_pares([
      ['Punto de la visita', coordenadaDecimal(d.latitud!, d.longitud!)],
      ['En sexagesimal', coordenadaSexagesimal(d.latitud!, d.longitud!)],
      ['Precision reportada', precision(d.precisionGps)],
    ]));
  } else {
    l.add('- Sin coordenada de la visita: el telefono no tenia posicion '
        'cuando se abrio.');
  }
  final fincaLat = d.finca?.latitud;
  final fincaLon = d.finca?.longitud;
  if (fincaLat != null && fincaLon != null) {
    l.addAll(_pares([
      ['Punto de la finca', coordenadaDecimal(fincaLat, fincaLon)],
    ]));
  }
  l.add('- Sistema de referencia: WGS84 (EPSG:4326).');

  l.add('');
  l.add('## 4. Lotes y recorridos medidos');
  l.add('');
  if (d.trazados.isEmpty) {
    l.add('No se camino ningun lote en esta visita. El area de la seccion 2 '
        'es la que declaro el productor, no una medida.');
  } else {
    l.add('| Nombre | Que hay | Figura | Area | Perimetro | Vertices | '
        'Captura | Precision media |');
    l.add('| --- | --- | --- | --- | --- | --- | --- | --- |');
    for (final t in d.trazados) {
      l.add(_fila([
        t.nombre,
        t.etiqueta ?? '—',
        t.esPoligono && !t.cerrado ? '${t.tipo} (sin cerrar)' : t.tipo,
        t.esPoligono && t.cerrado
            ? geo.formatearArea(t.areaCalculadaM2)
            : '—',
        geo.formatearDistancia(t.perimetroCalculadoM),
        '${t.puntos.length}',
        t.modoCaptura,
        precision(t.precisionPromedioM),
      ]));
    }
    l.add('');
    l.add('- Area total medida, solo poligonos cerrados: '
        '${geo.formatearArea(d.areaMedidaM2)}');
    l.add('- Vertices capturados: ${d.puntosGpsTotales}');
    l.add('- Las areas se calculan por excedente esferico sobre WGS84, la '
        'misma formula de Google Earth: el numero coincide con el del KML.');
  }

  l.add('');
  l.add('## 5. Datos registrados');
  l.add('');
  if (d.hallazgos.isEmpty) {
    l.add('No hay datos extraidos para esta visita.');
  } else {
    final conteo = d.conteoPorCerteza;
    l.add('${d.hallazgos.length} dato(s). Por certeza: '
        '${conteo.entries.map((e) => '${e.key} ${e.value}').join(' · ')}.');
    for (final entrada in d.porModulo.entries) {
      l.add('');
      l.add('### ${entrada.key}');
      l.add('');
      l.add('| Campo | Valor | Certeza | Fuente | Estado | Audio |');
      l.add('| --- | --- | --- | --- | --- | --- |');
      for (final h in entrada.value) {
        l.add(_fila([
          h.entidad == null ? h.campo : '${h.campo} (${h.entidad})',
          h.valorConUnidad.isEmpty ? '—' : h.valorConUnidad,
          h.certeza,
          h.fuente,
          h.estado,
          marcaAudio(h.segundoAudio),
        ]));
      }
    }
    l.add('');
    l.add('- Confirmado: lo dijo el agricultor textualmente. Estimado: dio un '
        'aproximado. Inferido: se dedujo y exige razonamiento. Pendiente: no '
        'salio en la conversacion, y no es un dato.');
  }

  final pendientes = d.temasPendientes;
  if (pendientes != null && pendientes.trim().isNotEmpty) {
    l.add('');
    l.add('## 6. Temas pendientes');
    l.add('');
    for (final linea in pendientes.split('\n')) {
      if (linea.trim().isNotEmpty) l.add('- ${linea.trim()}');
    }
  }

  l.add('');
  l.add('## 7. Evidencias');
  l.add('');
  if (d.evidencias.isEmpty) {
    l.add('No se tomaron fotos en esta visita.');
  } else {
    l.add('| # | Archivo | Tomada | Coordenada | Audio | Descripcion |');
    l.add('| --- | --- | --- | --- | --- | --- |');
    for (var i = 0; i < d.evidencias.length; i++) {
      final e = d.evidencias[i];
      l.add(_fila([
        (i + 1).toString().padLeft(2, '0'),
        soloNombre(e.archivoPath),
        f.fechaHora(e.tomadaEn),
        e.tieneGps
            ? coordenadaDecimal(e.latitud!, e.longitud!)
            : 'sin GPS',
        marcaAudio(e.segundoAudio),
        e.descripcion ?? '—',
      ]));
    }
  }

  l.add('');
  l.add('## 8. Audio de la visita');
  l.add('');
  if (d.grabaciones.isEmpty) {
    l.add('No se grabo audio en esta visita.');
  } else {
    l.add('| Tramo | Inicio | Duracion | Peso | Motor | Transcrito |');
    l.add('| --- | --- | --- | --- | --- | --- |');
    for (final g in d.grabaciones) {
      l.add(_fila([
        g.orden.toString().padLeft(2, '0'),
        f.hora(g.inicio),
        duracionLegible(Duration(seconds: g.duracionSeg)),
        pesoLegible(g.tamanoBytes),
        g.motor ?? '—',
        si(g.transcrita),
      ]));
    }
    l.add('');
    l.add('- Audio total: ${duracionLegible(d.audioTotal)}');
  }

  l.add('');
  l.add('## 9. Consentimiento (Ley 1581 de 2012)');
  l.add('');
  final c = d.consentimiento;
  l.addAll(_pares([
    ['Autoriza grabar el audio', si(c.audio)],
    ['Autoriza tomar fotos', si(c.fotos)],
    ['Autoriza el uso de los datos', si(c.usoDatos)],
    ['Consta en el audio, minuto', marcaAudio(c.segundoConsentimiento)],
    ['Autorizacion de tratamiento del productor', _autorizacion(p, f)],
    ['Marcada para eliminacion', si(c.marcadaParaEliminacion)],
  ]));

  l.add('');
  l.add('## 10. Trazabilidad');
  l.add('');
  l.addAll(_pares([
    ['Generado el', '${f.fechaLarga(d.generadoEn)}, ${f.hora(d.generadoEn)}'],
    ['Formato', codigoFormatoTecnico],
    ['Version del informe', '${d.version}'],
    ['Origen de los datos', 'Base local de la app, sin intervencion de IA'],
    ['Modelo de IA registrado', d.modeloIa ?? 'No registrado'],
  ]));
  l.add('');
  l.add('Las coordenadas, areas y perimetros de este documento se calculan '
      'sobre los puntos que capturo el GPS del telefono. Ningun numero de '
      'este informe lo escribio un modelo de lenguaje.');

  return l.join('\n');
}

String _documento(ProductorTecnico? p) {
  final documento = p?.documento;
  if (documento == null || documento.isEmpty) return 'Sin registrar';
  return '${p!.tipoDocumento ?? 'CC'} $documento';
}

String _areaDeclarada(DatosInformeTecnico d, FormatoInforme f) {
  final area = d.finca?.areaDeclaradaHa;
  return area == null ? 'Sin registrar' : '${f.numero(area)} ha';
}

String _autorizacion(ProductorTecnico? p, FormatoInforme f) {
  if (p == null) return 'Sin registrar';
  final fecha = p.fechaConsentimiento;
  if (fecha == null) return si(p.consentimientoDatos);
  return '${si(p.consentimientoDatos)} (${f.fechaLarga(fecha)})';
}

/// Una fila de tabla markdown. Los pipes de los extremos van pegados al
/// borde: un espacio antes del primero hace que varios lectores dejen de
/// reconocer la tabla y muestren la fila como texto suelto.
String _fila(List<String> celdas) => '| ${celdas.join(' | ')} |';

List<String> _pares(List<List<String>> filas) =>
    [for (final fila in filas) '- ${fila[0]}: ${fila[1]}'];
