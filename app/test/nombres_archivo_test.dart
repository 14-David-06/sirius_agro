import 'package:flutter_test/flutter_test.dart';
import 'package:sirius_agro/data/nombres_archivo.dart';

/// El nombre del PDF es lo unico que ve el productor en su bandeja de WhatsApp
/// y lo unico que ve el visitador en su carpeta de descargas. Por eso se
/// prueba: un cambio que lo devuelva al codigo de la visita no rompe ninguna
/// pantalla, y nadie se daria cuenta hasta que alguien no encuentre un informe.
void main() {
  group('nombre del PDF que se descarga', () {
    test('lleva el nombre del agricultor y la fecha, no el serial', () {
      expect(
        nombreArchivoInforme(
          productor: 'Señor Rumi',
          finca: 'La Soledad',
          fecha: DateTime(2026, 9, 2, 17, 12),
        ),
        'visita-senor-rumi-2026-09-02.pdf',
      );
    });

    test('sin productor cae en la finca, no en un UUID', () {
      expect(
        nombreArchivoInforme(
          finca: 'La Soledad',
          fecha: DateTime(2026, 9, 2),
        ),
        'visita-la-soledad-2026-09-02.pdf',
      );
    });

    test('sin nombre de nadie sigue siendo un nombre legible', () {
      expect(
        nombreArchivoInforme(fecha: DateTime(2026, 9, 2)),
        'visita-sin-nombre-2026-09-02.pdf',
      );
    });

    test('el tecnico se distingue del de la misma visita y el mismo dia', () {
      final agricultor = nombreArchivoInforme(
        productor: 'Señora De Prueba',
        fecha: DateTime(2026, 9, 14),
      );
      final tecnico = nombreArchivoInforme(
        productor: 'Señora De Prueba',
        fecha: DateTime(2026, 9, 14),
        sufijo: '-tecnico-v1',
      );
      expect(tecnico, 'visita-senora-de-prueba-2026-09-14-tecnico-v1.pdf');
      expect(agricultor, isNot(tecnico));
    });

    test('la fecha es la del dia local de la visita', () {
      expect(selloDia(DateTime(2026, 1, 7, 23, 59)), '2026-01-07');
    });
  });
}
