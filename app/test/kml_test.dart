import 'package:flutter_test/flutter_test.dart';
import 'package:sirius_agro/core/kml.dart';

PuntoKml _p(double lat, double lon) => PuntoKml(
      latitud: lat,
      longitud: lon,
      momento: DateTime.utc(2026, 9, 7, 15, 30),
      precisionM: 4.2,
    );

final _cuadrado = [
  _p(4.5697, -72.9631),
  _p(4.5697, -72.9622),
  _p(4.5706, -72.9622),
  _p(4.5706, -72.9631),
];

void main() {
  group('coordenadas', () {
    test('van longitud primero, que es al reves de como se dicen', () {
      // Este es EL error del formato: un KML con los ejes cambiados abre sin
      // quejarse y pone el lote en otro continente.
      expect(_p(4.5697, -72.9631).coordenada, startsWith('-72.9631'));
      expect(_p(4.5697, -72.9631).coordenada, contains(',4.5697'));
    });
  });

  group('poligono', () {
    final kml = construirKml(
      DocumentoKml(
        nombre: 'Finca La Esperanza',
        trazados: [
          TrazadoKml(
            nombre: 'Lote de arriba',
            geometria: GeometriaKml.poligono,
            puntos: _cuadrado,
            etiqueta: 'Platano',
          ),
        ],
      ),
    );

    test('sale como Polygon con anillo exterior', () {
      expect(kml, contains('<Polygon>'));
      expect(kml, contains('<outerBoundaryIs>'));
      expect(kml, contains('<LinearRing>'));
    });

    test('el anillo se cierra repitiendo el primer punto', () {
      // Sin esto Google Earth descarta el poligono en silencio: no da error,
      // simplemente no dibuja nada.
      final coords = kml
          .split('<coordinates>')[1]
          .split('</coordinates>')[0]
          .trim()
          .split(RegExp(r'\s+'));
      expect(coords.length, _cuadrado.length + 1);
      expect(coords.first, coords.last);
    });

    test('lleva el area calculada en la ficha', () {
      expect(kml, contains('Area:'));
      expect(kml, contains('Cultivo: Platano'));
    });

    test('va pegado al suelo', () {
      // La altitud del GPS de un telefono se equivoca por decenas de metros:
      // sin esto el lote se ve flotando sobre la finca.
      expect(kml, contains('<altitudeMode>clampToGround</altitudeMode>'));
    });
  });

  group('un poligono que el visitador no cerro', () {
    final kml = construirKml(
      DocumentoKml(
        nombre: 'x',
        trazados: [
          TrazadoKml(
            nombre: 'A medio caminar',
            geometria: GeometriaKml.poligono,
            puntos: _cuadrado,
            cerrado: false,
          ),
        ],
      ),
    );

    test('sale como linea, no como lote', () {
      // Cerrar un anillo que nadie cerro seria inventar un lindero.
      expect(kml, contains('<LineString>'));
      expect(kml, isNot(contains('<Polygon>')));
    });
  });

  group('degradaciones', () {
    test('dos puntos no alcanzan para un poligono', () {
      final kml = construirKml(
        DocumentoKml(
          nombre: 'x',
          trazados: [
            TrazadoKml(
              nombre: 'Dos',
              geometria: GeometriaKml.poligono,
              puntos: _cuadrado.take(2).toList(),
            ),
          ],
        ),
      );
      expect(kml, contains('<LineString>'));
      expect(kml, isNot(contains('<Polygon>')));
    });

    test('un solo punto sale como marca', () {
      final kml = construirKml(
        DocumentoKml(
          nombre: 'x',
          trazados: [
            TrazadoKml(
              nombre: 'Bocatoma',
              geometria: GeometriaKml.ruta,
              puntos: [_p(4.57, -72.96)],
            ),
          ],
        ),
      );
      expect(kml, contains('<Point>'));
      expect(kml, isNot(contains('<LineString>')));
    });

    test('un trazado sin puntos no genera Placemark vacio', () {
      final doc = DocumentoKml(
        nombre: 'x',
        trazados: const [
          TrazadoKml(
            nombre: 'Vacio',
            geometria: GeometriaKml.poligono,
            puntos: [],
          ),
        ],
      );
      expect(doc.vacio, isTrue);
      expect(construirKml(doc), isNot(contains('<Placemark>')));
    });
  });

  group('vertices', () {
    TrazadoKml unLote() => TrazadoKml(
          nombre: 'Lote',
          geometria: GeometriaKml.poligono,
          puntos: _cuadrado,
        );

    test('apagados por defecto: en un recorrido largo taparian el lote', () {
      final kml = construirKml(
        DocumentoKml(nombre: 'x', trazados: [unLote()]),
      );
      expect(kml, isNot(contains('Puntos capturados</name>')));
    });

    test('prendidos, cada punto lleva su hora y su precision', () {
      final kml = construirKml(
        DocumentoKml(
          nombre: 'x',
          trazados: [unLote()],
          incluirVertices: true,
        ),
      );
      expect(kml, contains('Puntos capturados'));
      expect(kml, contains('Precision GPS: 4 m'));
      expect(kml, contains('<TimeStamp>'));
      expect(kml, contains('Modo: marcado a mano'));
    });
  });

  test('las referencias van en su propia carpeta, para poder apagarlas', () {
    final kml = construirKml(
      DocumentoKml(
        nombre: 'x',
        trazados: [
          TrazadoKml(
            nombre: 'Lote',
            geometria: GeometriaKml.poligono,
            puntos: _cuadrado,
          ),
        ],
        referencias: [
          PuntoKml(nombre: 'Foto 01', latitud: 4.57, longitud: -72.96),
        ],
      ),
    );
    expect(kml, contains('<name>Referencias</name>'));
    expect(kml, contains('<name>Foto 01</name>'));
  });

  test('un nombre con & no rompe el archivo', () {
    // «Mata de Guadua & Anexos» produciria un XML invalido que ningun visor
    // abre.
    final kml = construirKml(
      DocumentoKml(
        nombre: 'Mata de Guadua & Anexos',
        trazados: [
          TrazadoKml(
            nombre: '<Lote "A">',
            geometria: GeometriaKml.poligono,
            puntos: _cuadrado,
          ),
        ],
      ),
    );
    expect(kml, contains('Mata de Guadua &amp; Anexos'));
    expect(kml, contains('&lt;Lote &quot;A&quot;&gt;'));
    expect(kml, isNot(contains('& Anexos')));
  });

  test('el documento arranca con el encabezado XML y el namespace', () {
    final kml = construirKml(const DocumentoKml(nombre: 'Vacia'));
    expect(kml, startsWith('<?xml version="1.0" encoding="UTF-8"?>'));
    expect(kml, contains('xmlns="http://www.opengis.net/kml/2.2"'));
    expect(kml.trim(), endsWith('</kml>'));
  });
}
