import 'geo.dart';

/// Armador de KML 2.2, el formato que abre Google Earth, QGIS y casi
/// cualquier cosa que dibuje mapas.
///
/// Se escribe a mano y no con una libreria a proposito: KML es XML plano y lo
/// que la app necesita son tres geometrias. Una dependencia mas en el APK para
/// concatenar texto no se paga.
///
/// Regla del formato que cuesta una tarde si se olvida: las coordenadas van
/// **longitud,latitud,altitud** — al reves de como se dicen y de como las
/// guarda la base. Un KML con los ejes invertidos abre sin error y pone el
/// lote en Somalia.

enum GeometriaKml { poligono, ruta, punto }

/// Un punto tal como sale al KML, con lo que se sabe de como se capturo.
class PuntoKml {
  const PuntoKml({
    required this.latitud,
    required this.longitud,
    this.altitud,
    this.precisionM,
    this.momento,
    this.nota,
    this.automatico = false,
    this.nombre,
  });

  final double latitud;
  final double longitud;
  final double? altitud;
  final double? precisionM;
  final DateTime? momento;
  final String? nota;
  final bool automatico;

  /// Solo para los puntos que van como marca propia (vertices, fotos).
  final String? nombre;

  PuntoGeo get geo => PuntoGeo(latitud, longitud);

  /// `lon,lat,alt`. Siete decimales son ~1 cm en el ecuador: mas que la
  /// precision del dato, pero redondear coordenadas de un lindero es la clase
  /// de perdida que no se puede reconstruir despues.
  String get coordenada {
    final alt = (altitud ?? 0).toStringAsFixed(1);
    return '${longitud.toStringAsFixed(7)},${latitud.toStringAsFixed(7)},$alt';
  }
}

/// Una figura del KML: el lote, el recorrido o el punto suelto.
class TrazadoKml {
  const TrazadoKml({
    required this.nombre,
    required this.geometria,
    required this.puntos,
    this.cerrado = true,
    this.etiqueta,
    this.notas,
    this.datos = const {},
  });

  final String nombre;
  final GeometriaKml geometria;
  final List<PuntoKml> puntos;

  /// Solo aplica al poligono. Un poligono sin cerrar no es un poligono, asi
  /// que cuando esto es false el trazado sale como linea: es mejor entregar el
  /// recorrido real que un lote cerrado que el visitador no cerro.
  final bool cerrado;

  final String? etiqueta;
  final String? notas;

  /// Pares que van al `<ExtendedData>`: se ven en la ficha de Google Earth y
  /// sobreviven a una importacion a QGIS como columnas de la tabla.
  final Map<String, String> datos;

  List<PuntoGeo> get geos => [for (final p in puntos) p.geo];

  /// La geometria efectiva. Un poligono con menos de tres puntos no se puede
  /// escribir como tal: KML lo acepta y Google Earth lo dibuja como nada.
  GeometriaKml get efectiva {
    if (puntos.length < 2) return GeometriaKml.punto;
    if (geometria == GeometriaKml.poligono && (!cerrado || puntos.length < 3)) {
      return GeometriaKml.ruta;
    }
    return geometria;
  }
}

class DocumentoKml {
  const DocumentoKml({
    required this.nombre,
    this.descripcion,
    this.trazados = const [],
    this.referencias = const [],
    this.incluirVertices = false,
  });

  final String nombre;
  final String? descripcion;
  final List<TrazadoKml> trazados;

  /// Puntos que no son trazados: donde arranco la visita, donde se tomo cada
  /// foto. Van en su propia carpeta para poder apagarlos en Google Earth sin
  /// perder los lotes.
  final List<PuntoKml> referencias;

  /// Cada vertice como marca propia, con su hora y su precision. Apagado por
  /// defecto: en un recorrido automatico de 40 minutos son cientos de marcas y
  /// tapan el lote. Se prende cuando lo que se quiere revisar es la captura
  /// misma.
  final bool incluirVertices;

  bool get vacio =>
      trazados.every((t) => t.puntos.isEmpty) && referencias.isEmpty;
}

/// Devuelve el KML completo, listo para escribir a disco.
String construirKml(DocumentoKml doc) {
  final b = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..writeln('<kml xmlns="http://www.opengis.net/kml/2.2">')
    ..writeln('  <Document>')
    ..writeln('    <name>${_xml(doc.nombre)}</name>');

  if (doc.descripcion != null && doc.descripcion!.trim().isNotEmpty) {
    b.writeln('    <description>${_xml(doc.descripcion!)}</description>');
  }

  b.write(_estilos);

  for (final t in doc.trazados) {
    if (t.puntos.isEmpty) continue;
    b.write(_carpetaTrazado(t, doc.incluirVertices));
  }

  if (doc.referencias.isNotEmpty) {
    b
      ..writeln('    <Folder>')
      ..writeln('      <name>Referencias</name>')
      ..writeln('      <open>0</open>');
    for (final p in doc.referencias) {
      b.write(_marcaPunto(p, p.nombre ?? 'Punto', '#sirius-referencia', 6));
    }
    b.writeln('    </Folder>');
  }

  b
    ..writeln('  </Document>')
    ..writeln('</kml>');
  return b.toString();
}

/// Una carpeta por trazado: la geometria y, si se pidio, sus vertices. Asi
/// cada lote se prende y apaga entero en el arbol de Google Earth.
String _carpetaTrazado(TrazadoKml t, bool incluirVertices) {
  final b = StringBuffer()
    ..writeln('    <Folder>')
    ..writeln('      <name>${_xml(t.nombre)}</name>')
    ..writeln('      <open>0</open>')
    ..writeln('      <Placemark>')
    ..writeln('        <name>${_xml(t.nombre)}</name>');

  final descripcion = _descripcion(t);
  if (descripcion.isNotEmpty) {
    b.writeln('        <description>${_xml(descripcion)}</description>');
  }

  final geometria = t.efectiva;
  b
    ..writeln('        <styleUrl>${_estiloDe(geometria)}</styleUrl>')
    ..write(_datosExtendidos(t))
    ..write(switch (geometria) {
      GeometriaKml.poligono => _poligono(t.puntos),
      GeometriaKml.ruta => _linea(t.puntos),
      GeometriaKml.punto => _punto(t.puntos.first),
    })
    ..writeln('      </Placemark>');

  if (incluirVertices && t.puntos.length > 1) {
    b
      ..writeln('      <Folder>')
      ..writeln('        <name>Puntos capturados</name>')
      ..writeln('        <open>0</open>');
    for (var i = 0; i < t.puntos.length; i++) {
      b.write(_marcaPunto(t.puntos[i], '${i + 1}', '#sirius-vertice', 8));
    }
    b.writeln('      </Folder>');
  }

  b.writeln('    </Folder>');
  return b.toString();
}

String _poligono(List<PuntoKml> puntos) {
  // El anillo se cierra repitiendo el primer punto: sin eso el poligono no es
  // valido y Google Earth lo descarta en silencio.
  final anillo = [...puntos];
  if (anillo.first.latitud != anillo.last.latitud ||
      anillo.first.longitud != anillo.last.longitud) {
    anillo.add(anillo.first);
  }

  return '        <Polygon>\n'
      // El lote se dibuja pegado al suelo, no flotando: la altitud del GPS de
      // un telefono se equivoca por decenas de metros y un poligono a 40 m de
      // altura se ve suspendido sobre la finca.
      '          <tessellate>1</tessellate>\n'
      '          <altitudeMode>clampToGround</altitudeMode>\n'
      '          <outerBoundaryIs>\n'
      '            <LinearRing>\n'
      '              <coordinates>\n'
      '${_coordenadas(anillo, 16)}'
      '              </coordinates>\n'
      '            </LinearRing>\n'
      '          </outerBoundaryIs>\n'
      '        </Polygon>\n';
}

String _linea(List<PuntoKml> puntos) => '        <LineString>\n'
    '          <tessellate>1</tessellate>\n'
    '          <altitudeMode>clampToGround</altitudeMode>\n'
    '          <coordinates>\n'
    '${_coordenadas(puntos, 12)}'
    '          </coordinates>\n'
    '        </LineString>\n';

String _punto(PuntoKml p) => '        <Point>\n'
    '          <coordinates>${p.coordenada}</coordinates>\n'
    '        </Point>\n';

String _marcaPunto(PuntoKml p, String nombre, String estilo, int sangria) {
  final e = ' ' * sangria;
  final b = StringBuffer()
    ..writeln('$e<Placemark>')
    ..writeln('$e  <name>${_xml(nombre)}</name>');

  final detalle = [
    if (p.momento != null) 'Capturado: ${_hora(p.momento!)}',
    if (p.precisionM != null)
      'Precision GPS: ${p.precisionM!.toStringAsFixed(0)} m',
    p.automatico ? 'Modo: automatico' : 'Modo: marcado a mano',
    if (p.nota != null && p.nota!.trim().isNotEmpty) 'Nota: ${p.nota}',
  ].join('\n');
  b.writeln('$e  <description>${_xml(detalle)}</description>');

  if (p.momento != null) {
    b
      ..writeln('$e  <TimeStamp>')
      ..writeln('$e    <when>${p.momento!.toUtc().toIso8601String()}</when>')
      ..writeln('$e  </TimeStamp>');
  }

  b
    ..writeln('$e  <styleUrl>$estilo</styleUrl>')
    ..writeln('$e  <Point><coordinates>${p.coordenada}</coordinates></Point>')
    ..writeln('$e</Placemark>');
  return b.toString();
}

/// La ficha que se abre al tocar el lote en Google Earth. Lleva el area
/// calculada por la app: Google Earth recalcula la suya y tener las dos
/// permite ver si coinciden.
String _descripcion(TrazadoKml t) {
  final geos = t.geos;
  final notas = t.notas?.trim() ?? '';
  return <String>[
    if (t.etiqueta != null && t.etiqueta!.trim().isNotEmpty)
      'Cultivo: ${t.etiqueta!.trim()}',
    'Puntos capturados: ${t.puntos.length}',
    if (t.efectiva == GeometriaKml.poligono) ...[
      'Area: ${formatearArea(areaM2(geos))}',
      'Perimetro: ${formatearDistancia(longitudMetros(geos, cerrado: true))}',
    ],
    if (t.efectiva == GeometriaKml.ruta)
      'Recorrido: ${formatearDistancia(longitudMetros(geos))}',
    if (notas.isNotEmpty) '',
    if (notas.isNotEmpty) notas,
  ].join('\n');
}

String _datosExtendidos(TrazadoKml t) {
  if (t.datos.isEmpty) return '';
  final b = StringBuffer()..writeln('        <ExtendedData>');
  for (final e in t.datos.entries) {
    b
      ..writeln('          <Data name="${_xml(e.key)}">')
      ..writeln('            <value>${_xml(e.value)}</value>')
      ..writeln('          </Data>');
  }
  b.writeln('        </ExtendedData>');
  return b.toString();
}

String _coordenadas(List<PuntoKml> puntos, int sangria) {
  final e = ' ' * sangria;
  return puntos.map((p) => '$e${p.coordenada}\n').join();
}

String _estiloDe(GeometriaKml g) => switch (g) {
      GeometriaKml.poligono => '#sirius-lote',
      GeometriaKml.ruta => '#sirius-ruta',
      GeometriaKml.punto => '#sirius-punto',
    };

/// Los colores de la marca. KML los pide en **aabbggrr** — alfa primero y los
/// canales al reves del hexadecimal de siempre. El verde 6EB100 sale
/// `ff00b16e`.
const _estilos = '''
    <Style id="sirius-lote">
      <LineStyle><color>ff00b16e</color><width>3</width></LineStyle>
      <PolyStyle><color>4d00b16e</color><fill>1</fill><outline>1</outline></PolyStyle>
    </Style>
    <Style id="sirius-ruta">
      <LineStyle><color>ffff9d00</color><width>4</width></LineStyle>
    </Style>
    <Style id="sirius-punto">
      <IconStyle>
        <color>ff9d4e00</color>
        <scale>1.1</scale>
        <Icon><href>http://maps.google.com/mapfiles/kml/paddle/wht-blank.png</href></Icon>
      </IconStyle>
    </Style>
    <Style id="sirius-vertice">
      <IconStyle>
        <color>ff00b16e</color>
        <scale>0.6</scale>
        <Icon><href>http://maps.google.com/mapfiles/kml/shapes/placemark_circle.png</href></Icon>
      </IconStyle>
      <LabelStyle><scale>0.7</scale></LabelStyle>
    </Style>
    <Style id="sirius-referencia">
      <IconStyle>
        <color>ffff4e00</color>
        <scale>0.9</scale>
        <Icon><href>http://maps.google.com/mapfiles/kml/shapes/camera.png</href></Icon>
      </IconStyle>
    </Style>
''';

String _hora(DateTime d) {
  final l = d.toLocal();
  String dd(int n) => n.toString().padLeft(2, '0');
  return '${l.year}-${dd(l.month)}-${dd(l.day)} '
      '${dd(l.hour)}:${dd(l.minute)}:${dd(l.second)}';
}

/// Escape de XML. Sin esto, una finca que se llame «Mata de Guadua & Anexos»
/// produce un KML que ningun visor abre.
String _xml(String texto) => texto
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');
