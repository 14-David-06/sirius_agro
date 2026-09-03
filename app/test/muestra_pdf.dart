import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sirius_agro/core/informe_pdf.dart';

/// No es una prueba: genera la muestra que se revisa a ojo.
/// Se corre a mano:
///   `MUESTRA_DIR=<carpeta> flutter test test/muestra_pdf.dart`
/// Sin esa variable no hace nada, para no romper la suite.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('muestra', () async {
    await initializeDateFormatting('es');
    // Solo corre cuando se pide a mano; en la suite normal no hace nada.
    final base = Platform.environment['MUESTRA_DIR'];
    if (base == null) return;

    final bytes = await construirInformePdf(
      DatosInforme(
        titulo: 'Informe La Soledad - 2026-09-03',
        contenido: await File('$base/informe.md').readAsString(),
        generadoEn: DateTime(2026, 9, 3, 10, 50),
        productor: 'Señor Rumi',
        finca: 'La Soledad',
        vereda: 'Barranca',
        municipio: 'Barranca de Upía',
        visitador: 'Persona De Prueba',
        fechaVisita: DateTime(2026, 9, 2, 17, 12),
      ),
    );
    await File('$base/muestra.pdf').writeAsBytes(bytes);
  });
}
