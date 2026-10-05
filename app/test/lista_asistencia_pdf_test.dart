import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sirius_agro/core/lista_asistencia_pdf.dart';

/// La lista de asistencia en PDF.
///
/// Lo que se protege: el orden —por dia y por hora, que es como se coteja la
/// hoja con la fila del taller—, y que se arme aunque falten datos o firmas:
/// un registro sin procesar o una firma borrada no pueden impedir entregar la
/// lista.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting('es'));

  FilaListaAsistencia fila(DateTime en, {String? nombre}) => FilaListaAsistencia(
    registradoEn: en,
    firmaPath: 'no-existe/firma.png',
    procesado: nombre != null,
    nombre: nombre,
  );

  test('agrupa por dia y ordena por hora dentro del dia', () {
    final grupos = agruparPorDia([
      fila(DateTime(2026, 10, 5, 9, 10), nombre: 'C'),
      fila(DateTime(2026, 10, 2, 15, 0), nombre: 'B'),
      fila(DateTime(2026, 10, 5, 8, 30), nombre: 'A'),
      fila(DateTime(2026, 10, 2, 9, 0), nombre: 'Z'),
    ]);

    expect(grupos.map((g) => g.dia), [
      DateTime(2026, 10, 2),
      DateTime(2026, 10, 5),
    ]);
    expect(grupos[0].filas.map((f) => f.nombre), ['Z', 'B']);
    expect(grupos[1].filas.map((f) => f.nombre), ['A', 'C']);
  });

  test('se arma con registros sin procesar y firmas que no estan', () async {
    final bytes = await construirListaAsistenciaPdf(
      DatosListaAsistencia(
        generadoEn: DateTime(2026, 10, 5, 12),
        responsable: 'Ana',
        filas: [
          fila(DateTime(2026, 10, 5, 7, 44)),
          FilaListaAsistencia(
            registradoEn: DateTime(2026, 10, 5, 7, 5),
            firmaPath: 'no-existe/firma.png',
            procesado: true,
            nombre: 'Juan David',
            cedula: '111111',
            telefono: '3223140309',
            vereda: 'Guaicaramo · Barranca de Upia',
            correo: 'juan.david@gmail.com',
            quiereVisita: true,
          ),
        ],
      ),
    );

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(String.fromCharCodes(bytes).contains('MuseoSlab'), isTrue);
  });

  test('una lista larga pasa de pagina sin romperse', () async {
    final firma = File('test/fixtures/firma.png');
    final filas = [
      for (var i = 0; i < 45; i++)
        FilaListaAsistencia(
          registradoEn: DateTime(2026, 10, 5, 8).add(Duration(minutes: i * 3)),
          firmaPath: firma.existsSync() ? firma.path : 'no-existe.png',
          procesado: true,
          nombre: 'Persona numero $i',
          cedula: '${1000000 + i}',
        ),
    ];
    final bytes = await construirListaAsistenciaPdf(
      DatosListaAsistencia(generadoEn: DateTime(2026, 10, 5), filas: filas),
    );

    final salida = Platform.environment['LISTA_PDF_SALIDA'];
    if (salida != null) await File(salida).writeAsBytes(bytes);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
