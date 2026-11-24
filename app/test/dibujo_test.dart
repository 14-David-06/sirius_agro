import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:sirius_agro/core/dibujo.dart';
import 'package:sirius_agro/core/geo.dart';

/// Dibujar el lote con el dedo: que el trazo se guarde con la forma que se
/// dibujo, sin el temblor del dedo y sin cientos de vertices encimados.
void main() {
  /// Un circulo de [n] posiciones del dedo, con temblor de ±[temblor] px.
  List<Offset> circulo(int n, {double radio = 100, double temblor = 0}) {
    final azar = math.Random(7);
    return [
      for (var i = 0; i < n; i++)
        Offset(
          200 +
              radio * math.cos(2 * math.pi * i / n) +
              (azar.nextDouble() * 2 - 1) * temblor,
          200 +
              radio * math.sin(2 * math.pi * i / n) +
              (azar.nextDouble() * 2 - 1) * temblor,
        ),
    ];
  }

  group('simplificar el trazo del pincel', () {
    test('una linea recta tembloroso queda en sus dos extremos', () {
      final recta = [
        for (var i = 0; i <= 100; i++) Offset(i * 3.0, i.isEven ? 0.0 : 1.0),
      ];

      final s = simplificarTrazo(recta);

      expect(s, [recta.first, recta.last]);
    });

    test('las esquinas de un cuadrado se conservan', () {
      final cuadrado = <Offset>[
        for (var i = 0; i <= 50; i++) Offset(i * 4.0, 0),
        for (var i = 1; i <= 50; i++) Offset(200, i * 4.0),
        for (var i = 1; i <= 50; i++) Offset(200 - i * 4.0, 200),
        for (var i = 1; i < 50; i++) Offset(0, 200 - i * 4.0),
      ];

      final s = simplificarTrazo(cuadrado);

      expect(s, containsAll(const [Offset(200, 0), Offset(200, 200)]));
      expect(s.length, lessThanOrEqualTo(5));
    });

    test('menos de tres posiciones no se tocan', () {
      const dos = [Offset(0, 0), Offset(10, 10)];
      expect(simplificarTrazo(dos), dos);
    });
  });

  group('preparar el trazo para guardarlo', () {
    test('un contorno largo queda bajo el tope de vertices', () {
      final s = prepararTrazo(
        circulo(2000, radio: 400, temblor: 2),
        cerrado: true,
      );

      expect(s.length, lessThanOrEqualTo(maximoVerticesTrazo));
      // Sigue siendo un circulo: no se aplano en un triangulo.
      expect(s.length, greaterThan(12));
    });

    test('el poligono no repite el primer vertice al final', () {
      final crudo = [...circulo(200), circulo(200).first];

      final s = prepararTrazo(crudo, cerrado: true);

      expect((s.last - s.first).distance, greaterThan(12));
    });

    test('una ruta conserva donde termino aunque vuelva cerca del inicio', () {
      final crudo = [...circulo(200), circulo(200).first];

      final s = prepararTrazo(crudo, cerrado: false);

      expect(s.last, crudo.last);
    });

    test('las posiciones repetidas del dedo quieto se descartan', () {
      final crudo = [
        const Offset(0, 0),
        const Offset(0, 0),
        const Offset(0, 0.2),
        const Offset(50, 0),
        const Offset(50, 50),
      ];

      final s = prepararTrazo(crudo, cerrado: false);

      expect(s.first, const Offset(0, 0));
      expect(s.where((p) => p == const Offset(0, 0)).length, 1);
    });
  });

  group('un contorno que se cruza', () {
    const cuadrado = [
      PuntoGeo(4.50, -72.90),
      PuntoGeo(4.50, -72.89),
      PuntoGeo(4.51, -72.89),
      PuntoGeo(4.51, -72.90),
    ];

    test('un cuadrado no se cruza', () {
      expect(seCruza(cuadrado, cerrado: true), isFalse);
    });

    test('un ocho si', () {
      // Las dos esquinas de arriba intercambiadas: el lote se vuelve un moño.
      final ocho = [cuadrado[0], cuadrado[1], cuadrado[3], cuadrado[2]];
      expect(seCruza(ocho, cerrado: true), isTrue);
    });

    test('una ruta abierta en zigzag no se cruza', () {
      const zigzag = [
        PuntoGeo(4.50, -72.90),
        PuntoGeo(4.51, -72.89),
        PuntoGeo(4.50, -72.88),
        PuntoGeo(4.51, -72.87),
      ];
      expect(seCruza(zigzag, cerrado: false), isFalse);
    });

    test('una ruta que vuelve sobre si misma si', () {
      const lazo = [
        PuntoGeo(4.50, -72.90),
        PuntoGeo(4.50, -72.88),
        PuntoGeo(4.51, -72.89),
        PuntoGeo(4.49, -72.89),
      ];
      expect(seCruza(lazo, cerrado: false), isTrue);
    });

    test('con menos de cuatro puntos no hay como cruzarse', () {
      expect(seCruza(cuadrado.sublist(0, 3), cerrado: true), isFalse);
    });
  });

  group('tocar dentro de un lote', () {
    const cuadrado = [
      PuntoGeo(4.50, -72.90),
      PuntoGeo(4.50, -72.89),
      PuntoGeo(4.51, -72.89),
      PuntoGeo(4.51, -72.90),
    ];

    test('el centro esta dentro y lo de al lado no', () {
      expect(contienePunto(cuadrado, const PuntoGeo(4.505, -72.895)), isTrue);
      expect(contienePunto(cuadrado, const PuntoGeo(4.505, -72.885)), isFalse);
      expect(contienePunto(cuadrado, const PuntoGeo(4.515, -72.895)), isFalse);
    });

    test('en una L, el hueco de la esquina no es del lote', () {
      const ele = [
        PuntoGeo(4.50, -72.90),
        PuntoGeo(4.50, -72.88),
        PuntoGeo(4.51, -72.88),
        PuntoGeo(4.51, -72.89),
        PuntoGeo(4.52, -72.89),
        PuntoGeo(4.52, -72.90),
      ];
      expect(contienePunto(ele, const PuntoGeo(4.515, -72.895)), isTrue);
      expect(contienePunto(ele, const PuntoGeo(4.505, -72.885)), isTrue);
      expect(contienePunto(ele, const PuntoGeo(4.515, -72.885)), isFalse);
    });

    test('dos puntos no encierran nada', () {
      expect(
        contienePunto(cuadrado.sublist(0, 2), const PuntoGeo(4.50, -72.895)),
        isFalse,
      );
    });
  });
}
