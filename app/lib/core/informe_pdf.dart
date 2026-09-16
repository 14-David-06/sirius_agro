import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'fuentes_pdf.dart';

/// El PDF del informe, con el mismo patron de diseño de las actas de dotacion.
///
/// Los colores salen del manual de marca de Sirius (2023, seccion 03 Color,
/// «Paleta de colores primarios»). No son aproximaciones: son los hex que
/// declara el manual, y por eso llevan el nombre que les puso el manual.
class ColoresSirius {
  /// Azul Barranca. El color caracteristico de la marca.
  static const azulBarranca = PdfColor.fromInt(0xFF0154AC);

  /// Verde Alegria.
  static const verdeAlegria = PdfColor.fromInt(0xFF00B602);

  /// Azul Cielo.
  static const azulCielo = PdfColor.fromInt(0xFF00A3FF);

  /// Imperial. El azul casi negro de la paleta.
  static const imperial = PdfColor.fromInt(0xFF1A1A33);

  /// Sutileza, y su gradiente claro.
  static const sutileza = PdfColor.fromInt(0xFFBCD7EA);
  static const sutilezaClara = PdfColor.fromInt(0xFFECF1F4);

  /// Cotiledon, y su gradiente claro.
  static const cotiledon = PdfColor.fromInt(0xFFBCD983);
  static const cotiledonClaro = PdfColor.fromInt(0xFFF2FFDD);
}

/// Los colores de marca repartidos en los papeles que cumplen en el documento.
///
/// Las combinaciones son las que el manual aprueba en «Combinaciones de
/// colores»: blanco sobre azul en las bandas de seccion, azul sobre sutileza
/// en la franja del titulo y la marca a color sobre cotiledon en el membrete.
class PaletaInforme {
  /// Encabezados de tabla, etiquetas y titulos.
  static const tinta = ColoresSirius.imperial;

  /// El membrete: la banda donde va el logo, arriba de todo.
  ///
  /// Azul Barranca, el mismo de las bandas de seccion. El logo se apoya
  /// directamente encima, con sus colores y sin nada detras.
  static const membrete = ColoresSirius.azulBarranca;

  /// Lo que se escribe encima del membrete.
  static const sobreMembrete = PdfColors.white;

  /// Franja del titulo, bajo el membrete.
  static const franja = ColoresSirius.sutileza;

  /// Bandas suaves: filas alternas y bloques de datos.
  static const suave = ColoresSirius.sutilezaClara;

  /// Encabezado de seccion dentro del cuerpo, y los textos de apoyo.
  static const seccion = ColoresSirius.azulBarranca;

  /// Linea de cierre.
  static const cierre = ColoresSirius.verdeAlegria;

  /// Texto de cuerpo.
  static const cuerpo = ColoresSirius.imperial;

  static const borde = ColoresSirius.sutileza;
}

/// El margen del documento, en puntos: 2,54 cm arriba y abajo, 1,91 cm a los
/// lados. Es la caja de la papeleria de Sirius — la pulgada completa arriba
/// para el membrete, y los lados un poco mas angostos para que las tablas no
/// se aprieten.
const _margenVertical = 72.0; // 2,54 cm
const _margenLateral = 54.0; // 1,91 cm

class DatosInforme {
  const DatosInforme({
    required this.titulo,
    required this.contenido,
    required this.generadoEn,
    this.version = 1,
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

  /// La version del informe. Va al pie de cada pagina: dos informes de la
  /// misma visita se distinguen por ahi y por la fecha, no por un codigo.
  final int version;

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
        version: version,
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

  // El logo va como vector y no como PNG: es el activo mas importante de la
  // marca y el manual no perdona que se vea pixelado. Dibujado desde su
  // contorno se imprime nitido a cualquier tamaño y en cualquier impresora.
  //
  // Uno solo, y es el de color: el membrete lo apoya sobre una placa blanca en
  // vez de repintarlo, asi que no hace falta una version mono.
  final logoColor = await rootBundle.loadString('assets/marca/sirius.svg');

  // Museo Slab, la corporativa de Sirius, y no las fuentes internas del
  // generador: esas no cubren Unicode y el informe esta lleno de "señor",
  // "años" y "quemó". Que salgan rotos en el papel que se le entrega al
  // productor no es un detalle.
  final fuentes = await FuentesInforme.cargar();
  final tema = await fuentes.tema();

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
      // Mas aire del que pedia el diseño de las actas, y a proposito — este
      // papel se archiva, se anilla y se fotocopia, y en todas esas el margen
      // es lo que salva el texto del borde.
      margin: const pw.EdgeInsets.symmetric(
        horizontal: _margenLateral,
        vertical: _margenVertical,
      ),
      theme: tema,
      header: (ctx) => ctx.pageNumber == 1
          ? pw.SizedBox()
          : _membreteContinuacion(logoColor, datos),
      footer: (ctx) => _pie(ctx, datos),
      build: (ctx) => [
        _membrete(logoColor),
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
pw.Widget _membrete(String logo) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.only(top: 4, bottom: 18),
    child: pw.Center(child: pw.SvgImage(svg: logo, height: 46)),
  );
}

/// En las paginas siguientes el membrete se reduce: repetir el bloque entero
/// gastaria un tercio de cada hoja en algo que ya se dijo.
pw.Widget _membreteContinuacion(String logo, DatosInforme datos) {
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
        pw.SvgImage(svg: logo, height: 18),
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
    padding: const pw.EdgeInsets.symmetric(vertical: 11),
    decoration: const pw.BoxDecoration(color: PaletaInforme.membrete),
    child: pw.Center(
      child: pw.Text(
        'INFORME DE VISITA DE CAMPO',
        style: pw.TextStyle(
          fontSize: 11.5,
          fontWeight: pw.FontWeight.bold,
          color: PaletaInforme.sobreMembrete,
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

pw.Widget _pie(pw.Context ctx, DatosInforme datos) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(top: 8),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        // Version y fecha de creacion: es lo que permite saber cual de dos
        // papeles del mismo productor es el ultimo, que es la unica pregunta
        // que se le hace a un pie de pagina.
        pw.Text(
          'Versión ${datos.version}',
          style: const pw.TextStyle(fontSize: 7.5, color: PaletaInforme.seccion),
        ),
        pw.Text(
          'Página ${ctx.pageNumber} de ${ctx.pagesCount}',
          style: const pw.TextStyle(fontSize: 7.5, color: PaletaInforme.seccion),
        ),
        pw.Text(
          DateFormat("d 'de' MMMM 'de' y", 'es').format(datos.generadoEn),
          style: const pw.TextStyle(fontSize: 7.5, color: PaletaInforme.seccion),
        ),
      ],
    ),
  );
}

/// Quita el enfasis de markdown: los asteriscos sueltos en un PDF impreso se
/// leen como un error de armado.
String _limpiar(String texto) =>
    texto.replaceAll(RegExp(r'\*{1,2}'), '').replaceAll('__', '').trim();
