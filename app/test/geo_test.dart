import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:sirius_agro/core/geo.dart';

/// Barranca de Upia, que es donde se va a usar esto.
const _lat = 4.5697;
const _lon = -72.9631;

/// Cuantos grados son [metros], sobre la MISMA esfera que usa `geo.dart`.
///
/// Se convierte con `radioTierraM` y no con las constantes de sobremesa
/// (110574 m por grado de latitud) a proposito: si el test usara otro modelo
/// de Tierra, estaria midiendo la diferencia entre los dos modelos y no la
/// formula. Esa diferencia existe y esta medida abajo, en su propio test.
double _gradosLat(double metros) =>
    metros * 180 / (math.pi * radioTierraM);
double _gradosLon(double metros, double lat) =>
    _gradosLat(metros) / math.cos(lat * math.pi / 180);

void main() {
  group('distancia', () {
    test('el mismo punto mide cero', () {
      expect(
        distanciaMetros(const PuntoGeo(_lat, _lon), const PuntoGeo(_lat, _lon)),
        0,
      );
    });

    test('100 m al norte miden 100 m', () {
      final d = distanciaMetros(
        const PuntoGeo(_lat, _lon),
        PuntoGeo(_lat + _gradosLat(100), _lon),
      );
      expect(d, closeTo(100, 1));
    });

    test('100 m al este miden 100 m', () {
      final d = distanciaMetros(
        const PuntoGeo(_lat, _lon),
        PuntoGeo(_lat, _lon + _gradosLon(100, _lat)),
      );
      expect(d, closeTo(100, 1));
    });
  });

  group('area', () {
    /// Un cuadrado de 100 m tiene una hectarea. Es la prueba que importa: es
    /// el numero que el visitador le va a decir al productor.
    List<PuntoGeo> cuadrado(double metros) {
      final dLat = _gradosLat(metros);
      final dLon = _gradosLon(metros, _lat);
      return [
        const PuntoGeo(_lat, _lon),
        PuntoGeo(_lat, _lon + dLon),
        PuntoGeo(_lat + dLat, _lon + dLon),
        PuntoGeo(_lat + dLat, _lon),
      ];
    }

    test('un cuadrado de 100 m es una hectarea', () {
      expect(areaHectareas(cuadrado(100)), closeTo(1.0, 0.001));
    });

    test('un cuadrado de 400 m son 16 hectareas', () {
      expect(areaHectareas(cuadrado(400)), closeTo(16.0, 0.01));
    });

    test('recorrer al reves da la misma area, no una negativa', () {
      final derecho = areaM2(cuadrado(100));
      final alReves = areaM2(cuadrado(100).reversed.toList());
      expect(alReves, closeTo(derecho, 0.01));
      expect(alReves, greaterThan(0));
    });

    test('repetir el primer punto al final no cambia el area', () {
      final base = cuadrado(100);
      expect(areaM2([...base, base.first]), closeTo(areaM2(base), 0.01));
    });

    test('el sesgo contra el elipsoide se queda por debajo del 1%', () {
      // La formula trabaja sobre una esfera de radio ecuatorial, igual que
      // Google Earth. Contra el elipsoide WGS84 eso da areas ~0,7% mas
      // grandes en esta latitud. Es una decision, no un descuido: el numero de
      // la app coincide con el que ve quien abra el KML exportado, y esa
      // coincidencia vale mas que el 0,7%.
      //
      // Se mide con un cuadrado armado con la longitud real del grado de
      // latitud (110574 m en el ecuador).
      const lado = 400.0;
      final dLat = lado / 110574.0;
      final dLon = lado / (111320.0 * math.cos(_lat * math.pi / 180));
      final real = [
        const PuntoGeo(_lat, _lon),
        PuntoGeo(_lat, _lon + dLon),
        PuntoGeo(_lat + dLat, _lon + dLon),
        PuntoGeo(_lat + dLat, _lon),
      ];
      final esperado = lado * lado / 10000;
      final medido = areaHectareas(real);
      expect((medido - esperado).abs() / esperado, lessThan(0.01));
    });

    test('con menos de tres puntos no hay area', () {
      // No devuelve un numero pequeño: devuelve cero. Inventarle superficie a
      // un lote de dos puntos es peor que no medirlo.
      expect(areaM2(cuadrado(100).take(2).toList()), 0);
      expect(areaM2(const []), 0);
    });
  });

  group('perimetro', () {
    test('el cuadrado de 100 m tiene 400 m de perimetro', () {
      final dLat = _gradosLat(100);
      final dLon = _gradosLon(100, _lat);
      final puntos = [
        const PuntoGeo(_lat, _lon),
        PuntoGeo(_lat, _lon + dLon),
        PuntoGeo(_lat + dLat, _lon + dLon),
        PuntoGeo(_lat + dLat, _lon),
      ];
      expect(longitudMetros(puntos, cerrado: true), closeTo(400, 2));
    });

    test('abierto es un lado menos', () {
      final dLon = _gradosLon(100, _lat);
      final puntos = [
        const PuntoGeo(_lat, _lon),
        PuntoGeo(_lat, _lon + dLon),
      ];
      expect(longitudMetros(puntos), closeTo(100, 1));
      expect(longitudMetros(puntos, cerrado: true), closeTo(200, 2));
    });
  });

  group('croquis', () {
    test('un cuadrado se proyecta como cuadrado, no como rectangulo', () {
      final dLat = _gradosLat(200);
      final dLon = _gradosLon(200, _lat);
      final puntos = [
        const PuntoGeo(_lat, _lon),
        PuntoGeo(_lat, _lon + dLon),
        PuntoGeo(_lat + dLat, _lon + dLon),
        PuntoGeo(_lat + dLat, _lon),
      ];

      final e = Encuadre.de(puntos)!;
      final esquinas = [for (final p in puntos) e.proyectar(p)];

      final ancho = (esquinas[1].x - esquinas[0].x).abs();
      final alto = (esquinas[3].y - esquinas[0].y).abs();
      // Sin la correccion por el achatamiento del grado de longitud, esto
      // fallaria y el lote se veria deformado en pantalla.
      expect(ancho, closeTo(alto, 0.01));
    });

    test('todo queda dentro del cuadro 0..1', () {
      final puntos = [
        const PuntoGeo(_lat, _lon),
        PuntoGeo(_lat + _gradosLat(500), _lon),
        PuntoGeo(_lat, _lon + _gradosLon(80, _lat)),
      ];
      final e = Encuadre.de(puntos)!;
      for (final p in puntos) {
        final plano = e.proyectar(p);
        expect(plano.x, inInclusiveRange(0, 1));
        expect(plano.y, inInclusiveRange(0, 1));
      }
    });

    test('un solo punto no divide por cero', () {
      final e = Encuadre.de(const [PuntoGeo(_lat, _lon)])!;
      final plano = e.proyectar(const PuntoGeo(_lat, _lon));
      expect(plano.x, closeTo(0.5, 0.001));
      expect(plano.y, closeTo(0.5, 0.001));
      expect(e.ladoM, greaterThan(0));
    });
  });

  group('formato', () {
    test('debajo de media hectarea se habla en metros cuadrados', () {
      // Un almacigo de 300 m² leido como «0,03 ha» no le dice nada a nadie.
      expect(formatearArea(300), '300 m²');
      expect(formatearArea(12000), '1,20 ha');
      expect(formatearArea(0), '—');
    });

    test('las distancias pasan a km despues del kilometro', () {
      expect(formatearDistancia(430), '430 m');
      expect(formatearDistancia(2500), '2,50 km');
    });
  });
}
