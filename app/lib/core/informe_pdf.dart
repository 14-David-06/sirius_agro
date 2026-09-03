import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// El PDF del informe, con el mismo patron de diseño de las actas de dotacion.
///
/// La paleta viene de ahi tal cual: se descarto el azul intenso corporativo
/// (#0154AC) porque en un documento denso cansa la vista y compite con el
/// contenido. El azul pizarra sostiene el membrete sin gritar.
class PaletaInforme {
  /// Membrete y encabezados de tabla.
  static const tinta = PdfColor.fromInt(0xFF1F3D5C);

  /// Franja del titulo, bajo el membrete.
  static const franja = PdfColor.fromInt(0xFFDCE6EE);

  /// Bandas suaves: filas alternas y bloques de datos.
  static const suave = PdfColor.fromInt(0xFFF5F8FA);

  /// Encabezado de seccion dentro del cuerpo.
  static const seccion = PdfColor.fromInt(0xFF4A7A96);

  /// Linea de cierre. Verde salvia, no el verde neon.
  static const cierre = PdfColor.fromInt(0xFF7C9A72);

  /// Texto de cuerpo. Gris grafito, no negro puro: en papel el negro pleno
  /// sobre blanco vibra y cansa.
  static const cuerpo = PdfColor.fromInt(0xFF2E3A46);

  static const borde = PdfColor.fromInt(0xFFD5DFEB);
}

/// Codigo de formato, abajo a la derecha en cada pagina.
const _codigoFormato = 'FT-AGRO-001';

class DatosInforme {
  const DatosInforme({
    required this.titulo,
    required this.contenido,
    required this.generadoEn,
    this.productor,
    this.finca,
    this.vereda,
    this.municipio,
    this.visitador,
    this.fechaVisita,
    this.fotos = const [],
  });

  final String titulo;

  /// Markdown que devolvio el modelo.
  final String contenido;
  final DateTime generadoEn;

  final String? productor;
  final String? finca;
  final String? vereda;
  final String? municipio;
  final String? visitador;
  final DateTime? fechaVisita;

  /// Rutas locales de las evidencias. Se ignoran las que ya no existan: una
  /// foto borrada del telefono no puede impedir que se entregue el informe.
  final List<String> fotos;

  DatosInforme copiaCon(String otroContenido) => DatosInforme(
        titulo: titulo,
        contenido: otroContenido,
        generadoEn: generadoEn,
        productor: productor,
        finca: finca,
        vereda: vereda,
        municipio: municipio,
        visitador: visitador,
        fechaVisita: fechaVisita,
        fotos: fotos,
      );
}

/// Arma el PDF. Devuelve los bytes listos para compartir o imprimir.
Future<Uint8List> construirInformePdf(DatosInforme datos) async {
  final doc = pw.Document(
    title: datos.titulo,
    author: 'Sirius Regenerative',
    subject: 'Informe de visita de campo',
  );

  final logo = pw.MemoryImage(
    (await rootBundle.load('assets/marca/sirius.png')).buffer.asUint8List(),
  );

  // Roboto empaquetada, no las fuentes internas del generador: esas no cubren
  // Unicode, y el informe esta lleno de "señor", "años" y "quemó". Que salgan
  // rotos en el papel que se le entrega al productor no es un detalle.
  final fuente = pw.Font.ttf(await rootBundle.load('assets/fuentes/Roboto-Regular.ttf'));
  final fuenteBold = pw.Font.ttf(await rootBundle.load('assets/fuentes/Roboto-Bold.ttf'));

  final fotos = <pw.MemoryImage>[];
  for (final ruta in datos.fotos) {
    final archivo = File(ruta);
    if (await archivo.exists()) {
      fotos.add(pw.MemoryImage(await archivo.readAsBytes()));
    }
  }

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      // Los mismos margenes de las actas: 20 arriba, 24 abajo para el pie,
      // 18 a los lados.
      margin: const pw.EdgeInsets.fromLTRB(18, 20, 18, 24),
      theme: pw.ThemeData.withFont(base: fuente, bold: fuenteBold),
      header: (ctx) => ctx.pageNumber == 1
          ? pw.SizedBox()
          : _membreteContinuacion(logo, datos),
      footer: _pie,
      build: (ctx) => [
        _membrete(logo),
        _franjaTitulo(),
        pw.SizedBox(height: 14),
        _bloqueDatos(datos),
        pw.SizedBox(height: 18),
        ..._cuerpo(datos.contenido),
        if (fotos.isNotEmpty) ...[
          pw.SizedBox(height: 18),
          _bandaSeccion('EVIDENCIAS FOTOGRÁFICAS'),
          pw.SizedBox(height: 10),
          _galeria(fotos),
        ],
        pw.SizedBox(height: 22),
        _lineaCierre(datos),
      ],
    ),
  );

  return doc.save();
}

/// El logo va centrado en su propio bloque, no arrinconado: es lo primero que
/// mira el productor y lo que le dice de quien es el documento.
pw.Widget _membrete(pw.MemoryImage logo) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(vertical: 16),
    decoration: const pw.BoxDecoration(color: PaletaInforme.tinta),
    child: pw.Center(child: pw.Image(logo, height: 52)),
  );
}

/// En las paginas siguientes el membrete se reduce: repetir el bloque entero
/// gastaria un tercio de cada hoja en algo que ya se dijo.
pw.Widget _membreteContinuacion(pw.MemoryImage logo, DatosInforme datos) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 14),
    padding: const pw.EdgeInsets.only(bottom: 6),
    decoration: const pw.BoxDecoration(
      border: pw.Border(
        bottom: pw.BorderSide(color: PaletaInforme.borde, width: 0.8),
      ),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Image(logo, height: 20),
        pw.Text(
          datos.finca ?? datos.productor ?? 'Informe de visita',
          style: const pw.TextStyle(
            fontSize: 8.5,
            color: PaletaInforme.seccion,
          ),
        ),
      ],
    ),
  );
}

pw.Widget _franjaTitulo() {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(vertical: 9),
    decoration: const pw.BoxDecoration(color: PaletaInforme.franja),
    child: pw.Center(
      child: pw.Text(
        'INFORME DE VISITA DE CAMPO',
        style: pw.TextStyle(
          fontSize: 11.5,
          fontWeight: pw.FontWeight.bold,
          color: PaletaInforme.tinta,
          letterSpacing: 1.8,
        ),
      ),
    ),
  );
}

/// Los datos de la visita en dos columnas, con bandas alternas. Es lo que el
/// productor mira primero para confirmar que el papel es sobre su finca.
pw.Widget _bloqueDatos(DatosInforme datos) {
  final lugar = [datos.vereda, datos.municipio]
      .where((x) => x != null && x.isNotEmpty)
      .join(' / ');
  final fecha = datos.fechaVisita ?? datos.generadoEn;

  final filas = <List<String>>[
    ['Productor', datos.productor ?? 'Sin registrar'],
    ['Finca', datos.finca ?? 'Sin registrar'],
    ['Vereda / Municipio', lugar.isEmpty ? 'Sin registrar' : lugar],
    ['Fecha de la visita', DateFormat("d 'de' MMMM 'de' y", 'es').format(fecha)],
    ['Visitó', datos.visitador ?? 'Sin registrar'],
  ];

  return pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PaletaInforme.borde, width: 0.8),
    ),
    child: pw.Column(
      children: [
        for (var i = 0; i < filas.length; i++)
          pw.Container(
            decoration: pw.BoxDecoration(
              color: i.isEven ? PaletaInforme.suave : PdfColors.white,
            ),
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: pw.Row(
              children: [
                pw.SizedBox(
                  width: 130,
                  child: pw.Text(
                    filas[i][0],
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PaletaInforme.tinta,
                    ),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    filas[i][1],
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PaletaInforme.cuerpo,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

pw.Widget _bandaSeccion(String texto) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: const pw.BoxDecoration(color: PaletaInforme.seccion),
    child: pw.Text(
      texto.toUpperCase(),
      style: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        letterSpacing: 1.1,
      ),
    ),
  );
}

/// Renderiza el markdown del modelo: `#`, `##`, `###`, vinetas y parrafos.
///
/// El `#` de nivel 1 se descarta a proposito: el titulo ya esta en la franja
/// del membrete y repetirlo dentro del cuerpo se ve como un error de armado.
List<pw.Widget> _cuerpo(String md) {
  final widgets = <pw.Widget>[];

  // Todo lo anterior a la primera seccion se descarta: ahi el modelo suele
  // repetir finca, vereda y fecha, que este documento ya muestra en su ficha —
  // y con la fecha de generacion en vez de la de la visita, que es peor que
  // repetir: se contradicen en la misma hoja.
  var empezo = false;

  for (final crudo in md.split('\n')) {
    final linea = crudo.trim();
    if (linea.isEmpty) {
      widgets.add(pw.SizedBox(height: 7));
      continue;
    }

    if (linea.startsWith('# ')) {
      continue;
    }
    if (!empezo && !linea.startsWith('## ')) {
      continue;
    }

    if (linea.startsWith('## ')) {
      empezo = true;
      widgets
        ..add(pw.SizedBox(height: 10))
        ..add(_bandaSeccion(_limpiar(linea.substring(3))))
        ..add(pw.SizedBox(height: 9));
    } else if (linea.startsWith('### ')) {
      widgets
        ..add(pw.SizedBox(height: 8))
        ..add(pw.Text(
          _limpiar(linea.substring(4)),
          style: pw.TextStyle(
            fontSize: 10.5,
            fontWeight: pw.FontWeight.bold,
            color: PaletaInforme.tinta,
          ),
        ))
        ..add(pw.SizedBox(height: 5));
    } else if (linea.startsWith('- ') || linea.startsWith('* ')) {
      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 5, left: 6),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 3,
                height: 3,
                margin: const pw.EdgeInsets.only(top: 4.5, right: 8),
                decoration: const pw.BoxDecoration(
                  color: PaletaInforme.seccion,
                  shape: pw.BoxShape.circle,
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  _limpiar(linea.substring(2)),
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PaletaInforme.cuerpo,
                    lineSpacing: 2.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 5),
          child: pw.Text(
            _limpiar(linea),
            textAlign: pw.TextAlign.justify,
            style: const pw.TextStyle(
              fontSize: 10,
              color: PaletaInforme.cuerpo,
              lineSpacing: 2.6,
            ),
          ),
        ),
      );
    }
  }

  return widgets;
}

/// Las fotos, repartidas con espacios iguales y a buen tamaño: son la prueba
/// de lo que se conversó y en un informe chiquitas no sirven de nada.
pw.Widget _galeria(List<pw.MemoryImage> fotos) {
  const porFila = 2;
  final filas = <pw.Widget>[];

  for (var i = 0; i < fotos.length; i += porFila) {
    final grupo = fotos.skip(i).take(porFila).toList();
    filas.add(
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            for (var j = 0; j < porFila; j++) ...[
              pw.Expanded(
                child: j < grupo.length
                    ? pw.Container(
                        height: 170,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PaletaInforme.borde,
                            width: 0.8,
                          ),
                        ),
                        child: pw.ClipRect(
                          child: pw.Image(grupo[j], fit: pw.BoxFit.cover),
                        ),
                      )
                    // Hueco para que una fila impar no estire la ultima foto
                    // al doble de ancho que las demas.
                    : pw.SizedBox(height: 170),
              ),
              if (j < porFila - 1) pw.SizedBox(width: 10),
            ],
          ],
        ),
      ),
    );
  }

  return pw.Column(children: filas);
}

pw.Widget _lineaCierre(DatosInforme datos) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Container(height: 3, width: double.infinity, color: PaletaInforme.cierre),
      pw.SizedBox(height: 7),
      pw.Text(
        'Documento generado por Sirius Agro a partir de la conversación de la '
        'visita. Si algún dato no coincide con lo que usted dijo, infórmelo '
        'para corregirlo.',
        style: const pw.TextStyle(fontSize: 7.5, color: PaletaInforme.seccion),
      ),
      pw.SizedBox(height: 3),
      pw.Text(
        'Generado el '
        '${DateFormat("d 'de' MMMM 'de' y, h:mm a", 'es').format(datos.generadoEn)}',
        style: const pw.TextStyle(fontSize: 7.5, color: PaletaInforme.seccion),
      ),
    ],
  );
}

pw.Widget _pie(pw.Context ctx) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(top: 8),
    child: pw.Row(
      children: [
        pw.Expanded(child: pw.SizedBox()),
        pw.Text(
          'Página ${ctx.pageNumber} de ${ctx.pagesCount}',
          style: const pw.TextStyle(fontSize: 7.5, color: PaletaInforme.seccion),
        ),
        pw.Expanded(
          child: pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              _codigoFormato,
              style: const pw.TextStyle(
                fontSize: 7.5,
                color: PaletaInforme.seccion,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Quita el enfasis de markdown: los asteriscos sueltos en un PDF impreso se
/// leen como un error de armado.
String _limpiar(String texto) =>
    texto.replaceAll(RegExp(r'\*{1,2}'), '').replaceAll('__', '').trim();
