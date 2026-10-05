import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'fuentes_pdf.dart';
import 'informe_pdf.dart' show PaletaInforme;

/// Una persona en la lista. Se arma desde la fila de `Asistencias` y la
/// vereda ya resuelta: el PDF no sabe nada de la base del telefono.
class FilaListaAsistencia {
  const FilaListaAsistencia({
    required this.registradoEn,
    required this.firmaPath,
    this.procesado = false,
    this.nombre,
    this.cedula,
    this.telefono,
    this.vereda,
    this.cultivos = const [],
    this.areaSembradaHa,
    this.quiereVisita = false,
  });

  final DateTime registradoEn;
  final String firmaPath;

  /// Si el backend ya saco los datos de la nota. Sin procesar, la fila sale
  /// igual —la persona firmo y estuvo— pero con los datos marcados como
  /// pendientes en vez de en blanco, que se leeria como un dato que no dio.
  final bool procesado;
  final String? nombre;
  final String? cedula;
  final String? telefono;
  final String? vereda;
  final List<String> cultivos;
  final double? areaSembradaHa;
  final bool quiereVisita;
}

/// Lo que se imprime: las filas y de donde salieron.
class DatosListaAsistencia {
  const DatosListaAsistencia({
    required this.filas,
    required this.generadoEn,
    this.responsable,
  });

  final List<FilaListaAsistencia> filas;
  final DateTime generadoEn;

  /// Quien tomo la asistencia, de la sesion del telefono.
  final String? responsable;
}

/// Las filas en el orden en que se imprimen: por dia y, dentro del dia, por
/// hora de registro. Es el orden de la fila del taller, que es como se
/// recuerda quien llego, y el que permite cotejar la hoja con las firmas.
List<({DateTime dia, List<FilaListaAsistencia> filas})> agruparPorDia(
  List<FilaListaAsistencia> filas,
) {
  final ordenadas = [...filas]
    ..sort((a, b) => a.registradoEn.compareTo(b.registradoEn));
  final grupos = <DateTime, List<FilaListaAsistencia>>{};
  for (final f in ordenadas) {
    final l = f.registradoEn.toLocal();
    grupos.putIfAbsent(DateTime(l.year, l.month, l.day), () => []).add(f);
  }
  return [for (final e in grupos.entries) (dia: e.key, filas: e.value)];
}

const _margenVertical = 40.0;
const _margenLateral = 36.0;

final _fechaLarga = DateFormat("EEEE d 'de' MMMM 'de' y", 'es');
final _fechaCorta = DateFormat("d 'de' MMMM 'de' y", 'es');
final _hora = DateFormat('h:mm a', 'es');

String _numero(double v) =>
    v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2).replaceAll('.', ',');

String _capital(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

/// Arma la lista de asistencia. Horizontal: son diez columnas y la firma
/// necesita ancho para que se reconozca.
Future<Uint8List> construirListaAsistenciaPdf(DatosListaAsistencia datos) async {
  final doc = pw.Document(
    title: 'Lista de asistencia',
    author: 'Sirius Regenerative',
    subject: 'Lista de asistencia',
  );

  final logo = await rootBundle.loadString('assets/marca/sirius.svg');
  final fuentes = await FuentesInforme.cargar();
  final tema = await fuentes.tema();

  // Una firma que ya no esta en disco no tumba la lista: la fila sale con la
  // casilla marcada como faltante, que tambien es informacion.
  final firmas = <String, pw.MemoryImage>{};
  for (final f in datos.filas) {
    final archivo = File(f.firmaPath);
    if (await archivo.exists()) {
      firmas[f.firmaPath] = pw.MemoryImage(await archivo.readAsBytes());
    }
  }

  final grupos = agruparPorDia(datos.filas);

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.symmetric(
        horizontal: _margenLateral,
        vertical: _margenVertical,
      ),
      theme: tema,
      header: (ctx) =>
          ctx.pageNumber == 1 ? pw.SizedBox() : _encabezado(logo, grupos),
      footer: (ctx) => _pie(ctx, datos),
      build: (ctx) => [
        _membrete(logo, datos, grupos),
        pw.SizedBox(height: 12),
        _resumen(datos.filas),
        for (final g in grupos) ...[
          pw.SizedBox(height: 16),
          if (grupos.length > 1) ...[
            pw.Text(
              '${_capital(_fechaLarga.format(g.dia))}  ·  '
              '${g.filas.length} ${g.filas.length == 1 ? 'persona' : 'personas'}',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PaletaInforme.seccion,
              ),
            ),
            pw.SizedBox(height: 6),
          ],
          _tabla(g.filas, firmas),
        ],
      ],
    ),
  );

  return doc.save();
}

String _rango(List<({DateTime dia, List<FilaListaAsistencia> filas})> grupos) {
  if (grupos.isEmpty) return 'Sin registros';
  final primero = grupos.first.dia;
  final ultimo = grupos.last.dia;
  if (primero == ultimo) return _capital(_fechaLarga.format(primero));
  return 'Del ${_fechaCorta.format(primero)} al ${_fechaCorta.format(ultimo)}';
}

pw.Widget _membrete(
  String logo,
  DatosListaAsistencia datos,
  List<({DateTime dia, List<FilaListaAsistencia> filas})> grupos,
) {
  return pw.Column(
    children: [
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 10, right: 4),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.SvgImage(svg: logo, height: 30),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                if (datos.responsable != null)
                  pw.Text(
                    'Tomada por ${datos.responsable}',
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PaletaInforme.tinta,
                    ),
                  ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Generada el ${_fechaCorta.format(datos.generadoEn)}, '
                  '${_hora.format(datos.generadoEn)}',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PaletaInforme.seccion,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(vertical: 9),
        decoration: const pw.BoxDecoration(color: PaletaInforme.membrete),
        child: pw.Column(
          children: [
            pw.Text(
              'LISTA DE ASISTENCIA',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PaletaInforme.sobreMembrete,
                letterSpacing: 1.6,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              _rango(grupos),
              style: const pw.TextStyle(
                fontSize: 9,
                color: PaletaInforme.franja,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

pw.Widget _resumen(List<FilaListaAsistencia> filas) {
  final visita = filas.where((f) => f.quiereVisita).length;
  final pendientes = filas.where((f) => !f.procesado).length;

  pw.Widget dato(String valor, String etiqueta) => pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 10),
      decoration: const pw.BoxDecoration(color: PaletaInforme.suave),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            valor,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PaletaInforme.tinta,
            ),
          ),
          pw.Text(
            etiqueta,
            style: const pw.TextStyle(fontSize: 8, color: PaletaInforme.seccion),
          ),
        ],
      ),
    ),
  );

  return pw.Row(
    children: [
      dato('${filas.length}', 'Personas registradas'),
      pw.SizedBox(width: 8),
      dato('$visita', 'Piden visita técnica'),
      pw.SizedBox(width: 8),
      dato('$pendientes', 'Datos por procesar'),
    ],
  );
}

const _encabezados = [
  'N.º',
  'Hora',
  'Nombre completo',
  'Cédula',
  'Teléfono',
  'Vereda',
  'Cultivos',
  'Área (ha)',
  'Visita',
  'Firma',
];
const _anchos = [3, 6, 17, 9, 9, 13, 15, 5, 5, 13];

pw.Widget _tabla(
  List<FilaListaAsistencia> filas,
  Map<String, pw.MemoryImage> firmas,
) {
  final total = _anchos.fold(0, (a, b) => a + b);
  const pendiente = pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600);
  const cuerpo = pw.TextStyle(fontSize: 8, color: PaletaInforme.cuerpo);

  pw.Widget celda(pw.Widget hijo) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
    child: hijo,
  );
  // Sin procesar, el aviso va una sola vez, en el nombre: repetido en cada
  // columna angosta se parte en dos lineas y la fila se lee como un error.
  pw.Widget texto(String? v) =>
      celda(pw.Text(v ?? '—', style: v == null ? pendiente : cuerpo));

  return pw.Table(
    border: pw.TableBorder.all(color: PaletaInforme.borde, width: 0.6),
    defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
    columnWidths: {
      for (var i = 0; i < _anchos.length; i++)
        i: pw.FractionColumnWidth(_anchos[i] / total),
    },
    children: [
      // Se repite en cada hoja: una lista de cuarenta personas pasa de una
      // pagina, y la segunda sin encabezado es una cuadricula de numeros.
      pw.TableRow(
        repeat: true,
        decoration: const pw.BoxDecoration(color: PaletaInforme.tinta),
        children: [
          for (final e in _encabezados)
            celda(
              pw.Text(
                e,
                style: pw.TextStyle(
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
        ],
      ),
      // Sin filas alternas: la firma es un PNG con fondo blanco y sobre una
      // banda de color se ve como un recorte pegado.
      for (final (i, f) in filas.indexed)
        pw.TableRow(
          children: [
            texto('${i + 1}'),
            texto(_hora.format(f.registradoEn.toLocal())),
            celda(
              pw.Text(
                f.nombre ??
                    (f.procesado ? '—' : 'Por procesar'),
                style: f.nombre == null
                    ? pendiente
                    : cuerpo.copyWith(fontWeight: pw.FontWeight.bold),
              ),
            ),
            texto(f.cedula),
            texto(f.telefono),
            texto(f.vereda),
            texto(f.cultivos.isEmpty ? null : f.cultivos.join(', ')),
            texto(
              f.areaSembradaHa == null ? null : _numero(f.areaSembradaHa!),
            ),
            texto(f.procesado ? (f.quiereVisita ? 'Sí' : 'No') : null),
            celda(
              firmas[f.firmaPath] == null
                  ? pw.Text('Sin firma en el teléfono', style: pendiente)
                  : pw.Container(
                      height: 34,
                      alignment: pw.Alignment.center,
                      child: pw.Image(
                        firmas[f.firmaPath]!,
                        fit: pw.BoxFit.contain,
                      ),
                    ),
            ),
          ],
        ),
    ],
  );
}

pw.Widget _encabezado(
  String logo,
  List<({DateTime dia, List<FilaListaAsistencia> filas})> grupos,
) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 10),
    padding: const pw.EdgeInsets.only(bottom: 5),
    decoration: const pw.BoxDecoration(
      border: pw.Border(
        bottom: pw.BorderSide(color: PaletaInforme.borde, width: 0.8),
      ),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.SvgImage(svg: logo, height: 14),
        pw.Text(
          'Lista de asistencia  ·  ${_rango(grupos)}',
          style: const pw.TextStyle(fontSize: 8, color: PaletaInforme.seccion),
        ),
      ],
    ),
  );
}

pw.Widget _pie(pw.Context ctx, DatosListaAsistencia datos) {
  const estilo = pw.TextStyle(fontSize: 7.5, color: PaletaInforme.seccion);
  return pw.Container(
    margin: const pw.EdgeInsets.only(top: 8),
    padding: const pw.EdgeInsets.only(top: 5),
    decoration: const pw.BoxDecoration(
      border: pw.Border(
        top: pw.BorderSide(color: PaletaInforme.borde, width: 0.6),
      ),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Las personas aceptaron la política de tratamiento de datos de '
          'Sirius Regenerative (Ley 1581 de 2012) al registrarse.',
          style: estilo,
        ),
        pw.Text('Página ${ctx.pageNumber} de ${ctx.pagesCount}', style: estilo),
      ],
    ),
  );
}
