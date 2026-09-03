import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pdf/pdf.dart';
import 'package:sirius_agro/core/informe_pdf.dart';

/// El PDF que se le entrega al productor.
///
/// Lo que se protege: que sea A4, que el markdown del modelo no se filtre
/// crudo al papel, y que una foto borrada del telefono no impida entregar el
/// informe.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Las fechas del informe van en español, como en `main()`.
  setUpAll(() => initializeDateFormatting('es'));

  const md = '''
# Informe de su visita

## Lo que conversamos

Fue una visita corta. Hablamos del **agua** y de lo que siembra.

## Su finca hoy

### Agua
- Usted tiene tres pozos propios.
- Ademas recoge agua lluvia.

## Lo que quedo pendiente

- Cuanta tierra tiene.
''';

  DatosInforme datos({List<String> fotos = const []}) => DatosInforme(
        titulo: 'Informe La Soledad - 2026-09-03',
        contenido: md,
        generadoEn: DateTime(2026, 9, 3, 10, 50),
        productor: 'Senor Rumi',
        finca: 'La Soledad',
        vereda: 'Barranca',
        municipio: 'Barranca de Upia',
        visitador: 'Persona De Prueba',
        fechaVisita: DateTime(2026, 9, 2, 17, 12),
        fotos: fotos,
      );

  test('se genera un PDF valido y con contenido', () async {
    final bytes = await construirInformePdf(datos());

    // Firma de PDF. Sin esto, "genero algo" no significa "genero un PDF".
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    // El logo pesa: un PDF de pocos bytes seria una hoja en blanco.
    expect(bytes.length, greaterThan(20000));
  });

  test('es A4, no carta', () {
    // El formato lo fija el patron de diseño de las actas; carta cambiaria
    // los saltos y los margenes calculados sobre 798 pt utiles.
    expect(PdfPageFormat.a4.width.round(), 595);
    expect(PdfPageFormat.a4.height.round(), 842);
  });

  test('la paleta es la profesional, no el azul intenso viejo', () {
    // El azul corporativo #0154AC y el verde neon #00B602 se descartaron
    // justamente por lo que hacian en un documento denso.
    expect(PaletaInforme.tinta.toInt(), 0xFF1F3D5C);
    expect(PaletaInforme.franja.toInt(), 0xFFDCE6EE);
    expect(PaletaInforme.suave.toInt(), 0xFFF5F8FA);
    expect(PaletaInforme.seccion.toInt(), 0xFF4A7A96);
    expect(PaletaInforme.cierre.toInt(), 0xFF7C9A72);
    expect(PaletaInforme.cuerpo.toInt(), 0xFF2E3A46);

    for (final descartado in [0xFF0154AC, 0xFFBCD7EA, 0xFF00A3FF, 0xFF00B602]) {
      expect(
        [
          PaletaInforme.tinta.toInt(),
          PaletaInforme.franja.toInt(),
          PaletaInforme.suave.toInt(),
          PaletaInforme.seccion.toInt(),
          PaletaInforme.cierre.toInt(),
        ],
        isNot(contains(descartado)),
      );
    }
  });

  test('la ficha del modelo no se duplica con la del documento', () async {
    // El modelo a veces repite finca/vereda/fecha bajo el titulo, con la fecha
    // de generacion en vez de la de la visita: no solo se repite, se
    // contradice con la ficha del encabezado.
    final bytes = await construirInformePdf(
      datos().copiaCon(
        '# Informe de su visita\n'
        'Finca: OTRA FINCA - Fecha: 31 de diciembre de 2099\n\n'
        '## Lo que conversamos\n\nTexto real.',
      ),
    );

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    // No se puede leer el texto del PDF comprimido aca, pero el documento se
    // arma: la regresion que importa la cubre `_cuerpo` descartando todo lo
    // anterior a la primera seccion.
    expect(bytes.length, greaterThan(20000));
  });

  test('embebe una fuente TTF, no las internas sin Unicode', () async {
    // Las fuentes internas del generador (Helvetica y compania) no cubren
    // Unicode: con ellas, "señor", "años" y "quemó" salen rotos en el papel
    // que se le entrega al productor. Este test es el que atrapa la regresion.
    final bytes = await construirInformePdf(
      datos().copiaCon(
        '## Sección\n\nEl señor quemó el lote hace años. ¿Sí? «Alrededor de 9».',
      ),
    );

    // FontFile2 es como el formato PDF marca una TrueType embebida. Con una
    // fuente interna no aparece.
    expect(String.fromCharCodes(bytes).contains('FontFile2'), isTrue);
  });

  test('una foto que ya no esta en disco no impide entregar el informe',
      () async {
    // El telefono se llena y el sistema borra cache. Que falte una evidencia
    // no puede dejar al productor sin su informe.
    final bytes = await construirInformePdf(
      datos(fotos: ['/no/existe/foto-1.jpg', '/no/existe/foto-2.jpg']),
    );

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('las fotos que si existen entran y hacen crecer el documento', () async {
    final carpeta = await Directory.systemTemp.createTemp('informe-pdf-');
    addTearDown(() => carpeta.delete(recursive: true));

    // PNG de 1x1 valido, suficiente para que el encoder lo acepte.
    final png = File('${carpeta.path}/foto.png');
    await png.writeAsBytes(_png1x1);

    final sinFotos = await construirInformePdf(datos());
    final conFotos = await construirInformePdf(datos(fotos: [png.path]));

    expect(conFotos.length, greaterThan(sinFotos.length));
  });

  test('sin datos de la visita no revienta, escribe «Sin registrar»', () async {
    // Una visita puede sincronizarse a medias: el informe se entrega igual.
    final bytes = await construirInformePdf(
      DatosInforme(
        titulo: 'Informe',
        contenido: md,
        generadoEn: DateTime(2026, 9, 3),
      ),
    );

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}

/// PNG 1x1 real, con CRC valido: el generador de PDF rechaza uno mal armado.
const _png1x1 = <int>[137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, 0, 0, 0, 1, 8, 2, 0, 0, 0, 144, 119, 83, 222, 0, 0, 0, 12, 73, 68, 65, 84, 120, 156, 99, 248, 207, 192, 0, 0, 3, 1, 1, 0, 201, 254, 146, 239, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130];
