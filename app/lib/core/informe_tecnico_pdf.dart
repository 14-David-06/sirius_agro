import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'fuentes_pdf.dart';
import 'geo.dart' as geo;
import 'iconos_modulo.dart';
import 'informe_pdf.dart' show PaletaInforme;
import 'informe_tecnico.dart';

/// El PDF del informe tecnico: el documento que se archiva en la empresa.
///
/// Comparte la paleta con el informe del productor —son documentos de la misma
/// casa— y NADA MAS. Aquel es una carta: parrafos, tipografia grande, para
/// leerse en voz alta en el patio de la finca. Este es un formato: tablas
/// numeradas, coordenadas, precision del GPS, el registro de consentimiento y
/// un anexo con cada vertice caminado.
///
/// Por eso son dos renderizadores y no uno con una bandera. Un documento que
/// intenta las dos cosas termina siendo un informe tecnico que el productor no
/// entiende y una carta que no sirve de respaldo.
///
/// Se arma en el telefono y sin senal, igual que el otro.
class PaletaTecnica {
  /// Confirmado. Verde salvia, el mismo del cierre del otro informe.
  static const confirmado = PdfColor.fromInt(0xFF7C9A72);

  /// Estimado. Ocre: no es una alarma, es una advertencia de lectura.
  static const estimado = PdfColor.fromInt(0xFFB98A3C);

  /// Inferido. Azul pizarra claro: lo dedujo la app, no lo dijo nadie.
  static const inferido = PdfColor.fromInt(0xFF5C7C9A);

  /// Pendiente y No legible. Gris: un hueco, no un error.
  static const pendiente = PdfColor.fromInt(0xFF8B949E);

  /// El aviso de visita revocada. Es el unico rojo del documento, y por eso
  /// funciona.
  static const alerta = PdfColor.fromInt(0xFF9A4B3C);
  static const alertaFondo = PdfColor.fromInt(0xFFF7EAE7);
}

/// El margen del documento, en puntos: 2,54 cm arriba y abajo, 1,91 cm a los
/// lados. Es la caja de la papeleria de Sirius — la pulgada completa arriba
/// para el membrete, y los lados un poco mas angostos para que las tablas no
/// se aprieten.
const _margenVertical = 72.0; // 2,54 cm
const _margenLateral = 54.0; // 1,91 cm

PdfColor _colorCerteza(String certeza) => switch (certeza) {
      'Confirmado' => PaletaTecnica.confirmado,
      'Estimado' => PaletaTecnica.estimado,
      'Inferido' => PaletaTecnica.inferido,
      _ => PaletaTecnica.pendiente,
    };

/// Arma el PDF tecnico. Devuelve los bytes listos para archivar o imprimir.
Future<Uint8List> construirInformeTecnicoPdf(DatosInformeTecnico datos) async {
  final f = FormatoInforme();

  final doc = pw.Document(
    title: 'Informe tecnico ${datos.codigoVisita}',
    author: 'Sirius Regenerative',
    subject: 'Informe tecnico de visita de campo',
    keywords: datos.codigoVisita,
  );

  // Vectorial, igual que el informe del productor: este documento se imprime
  // para archivarlo y se fotocopia, y el logo tiene que aguantar las dos.
  // Uno solo, y es el de color: el membrete lo apoya sobre una placa blanca en
  // vez de repintarlo.
  final logoColor = await rootBundle.loadString('assets/marca/sirius.svg');

  // Museo Slab, la corporativa de Sirius, y no las fuentes internas del
  // generador: esas no cubren Unicode y este documento esta lleno de grados,
  // comillas de minuto y «±». Un informe que muestra coordenadas con los
  // simbolos rotos no sirve para compararlo con un plano.
  final fuentes = await FuentesInforme.cargar();
  final tema = await fuentes.tema();

  // Las fotos que ya no estan en el telefono se omiten sin ruido, igual que en
  // el informe del productor: una foto borrada no puede impedir que se archive
  // el documento. Pero la FILA de la tabla de evidencias se conserva — que la
  // foto no este es tambien informacion, y borrarla del listado seria tapar un
  // hueco de la evidencia.
  final imagenes = <int, pw.MemoryImage>{};
  for (var i = 0; i < datos.evidencias.length; i++) {
    final archivo = File(datos.evidencias[i].archivoPath);
    if (await archivo.exists()) {
      imagenes[i] = pw.MemoryImage(await archivo.readAsBytes());
    }
  }

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      // La misma caja del informe del productor: los dos documentos de la
      // misma visita se archivan juntos y tienen que verse de la misma casa.
      margin: const pw.EdgeInsets.symmetric(
        horizontal: _margenLateral,
        vertical: _margenVertical,
      ),
      theme: tema,
      header: (ctx) =>
          ctx.pageNumber == 1 ? pw.SizedBox() : _encabezado(logoColor, datos),
      footer: (ctx) => _pie(ctx, datos),
      build: (ctx) => [
        _membrete(logoColor, datos, f),
        if (datos.consentimiento.marcadaParaEliminacion) ...[
          pw.SizedBox(height: 12),
          _avisoRevocada(),
        ],
        pw.SizedBox(height: 14),
        ..._seccionIdentificacion(datos, f),
        ..._seccionPredio(datos, f),
        ..._seccionGeorreferenciacion(datos),
        ..._seccionTrazados(datos),
        ..._seccionDatos(datos),
        ..._seccionPendientes(datos),
        ..._seccionEvidencias(datos, imagenes, f),
        ..._seccionAudio(datos, f),
        ..._seccionConsentimiento(datos, f),
        ..._seccionTrazabilidad(datos, f),
        ..._anexoVertices(datos, f),
        // Las firmas cierran el documento, despues del anexo. Una hoja
        // firmada en la mitad deja sin respaldar todo lo que viene detras:
        // quien firma responde por el documento entero, no por la parte que
        // le quedaba encima.
        pw.SizedBox(height: 20),
        _firmas(datos),
      ],
    ),
  );

  return doc.save();
}

// --- Membrete, encabezado y pie ---

pw.Widget _membrete(
  String logo,
  DatosInformeTecnico datos,
  FormatoInforme f,
) {
  return pw.Column(
    children: [
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.only(top: 2, bottom: 14, right: 4),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.SvgImage(svg: logo, height: 36),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'DOCUMENTO INTERNO',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PaletaInforme.tinta,
                    letterSpacing: 1.4,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Versión ${datos.version}  ·  ${f.fechaLarga(datos.generadoEn)}',
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
        padding: const pw.EdgeInsets.symmetric(vertical: 10),
        decoration: const pw.BoxDecoration(color: PaletaInforme.membrete),
        child: pw.Column(
          children: [
            pw.Text(
              'INFORME TÉCNICO DE VISITA DE CAMPO',
              style: pw.TextStyle(
                fontSize: 11.5,
                fontWeight: pw.FontWeight.bold,
                color: PaletaInforme.sobreMembrete,
                letterSpacing: 1.6,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              '${datos.finca?.nombre ?? datos.productor?.nombre ?? 'Sin registrar'}'
              '  ·  ${f.fechaLarga(datos.inicio)}',
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

/// En las paginas siguientes se repite lo minimo para identificar la hoja si
/// alguien la saca de la carpeta: de quien es el documento, de que finca y de
/// que visita. El codigo de visita es lo que permite volver al audio, a las
/// fotos y al registro de Airtable.
pw.Widget _encabezado(String logo, DatosInformeTecnico datos) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 12),
    padding: const pw.EdgeInsets.only(bottom: 5),
    decoration: const pw.BoxDecoration(
      border: pw.Border(
        bottom: pw.BorderSide(color: PaletaInforme.borde, width: 0.8),
      ),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.SvgImage(svg: logo, height: 16),
        pw.Text(
          'Informe técnico  ·  '
          '${datos.finca?.nombre ?? datos.productor?.nombre ?? 'Sin registrar'}'
          '  ·  ${datos.codigoVisita.substring(0, 8)}',
          style: const pw.TextStyle(
            fontSize: 8,
            color: PaletaInforme.seccion,
          ),
        ),
      ],
    ),
  );
}

pw.Widget _pie(pw.Context ctx, DatosInformeTecnico datos) {
  final f = FormatoInforme();
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
          'Visita ${datos.codigoVisita}',
          style: const pw.TextStyle(fontSize: 7, color: PaletaInforme.seccion),
        ),
        pw.Text(
          'Página ${ctx.pageNumber} de ${ctx.pagesCount}',
          style: const pw.TextStyle(fontSize: 7.5, color: PaletaInforme.seccion),
        ),
        pw.Text(
          'Versión ${datos.version}  ·  ${f.fechaLarga(datos.generadoEn)}',
          style: const pw.TextStyle(fontSize: 7.5, color: PaletaInforme.seccion),
        ),
      ],
    ),
  );
}

/// Una visita revocada no se borra del telefono hasta que sincroniza, asi que
/// el informe se puede generar igual. Lo que no puede pasar es que alguien lo
/// lea sin saberlo: el aviso va primero, antes de cualquier dato.
pw.Widget _avisoRevocada() {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      color: PaletaTecnica.alertaFondo,
      border: pw.Border.all(color: PaletaTecnica.alerta, width: 1),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'VISITA MARCADA PARA ELIMINACIÓN',
          style: pw.TextStyle(
            fontSize: 9.5,
            fontWeight: pw.FontWeight.bold,
            color: PaletaTecnica.alerta,
            letterSpacing: 0.8,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          'El productor revocó su autorización. Los datos de este informe no '
          'se pueden usar y se borran del servidor al sincronizar.',
          style: const pw.TextStyle(fontSize: 8.5, color: PaletaTecnica.alerta),
        ),
      ],
    ),
  );
}

// --- Piezas reutilizables ---

pw.Widget _banda(String numero, String titulo) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: const pw.BoxDecoration(color: PaletaInforme.seccion),
    child: pw.Row(
      children: [
        pw.Container(
          width: 16,
          child: pw.Text(
            numero,
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ),
        pw.Text(
          titulo.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 9.5,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
            letterSpacing: 1,
          ),
        ),
      ],
    ),
  );
}

/// La ficha de datos: dos pares etiqueta/valor por fila.
///
/// Dos columnas y no una: con una, las veinte lineas de identificacion y
/// predio se comen dos paginas antes de llegar a un solo dato de la finca.
pw.Widget _ficha(List<List<String>> filas) {
  final grupos = <List<List<String>>>[];
  for (var i = 0; i < filas.length; i += 2) {
    grupos.add(filas.skip(i).take(2).toList());
  }

  return pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PaletaInforme.borde, width: 0.8),
    ),
    child: pw.Column(
      children: [
        for (var i = 0; i < grupos.length; i++)
          pw.Container(
            decoration: pw.BoxDecoration(
              color: i.isEven ? PaletaInforme.suave : PdfColors.white,
            ),
            child: pw.Row(
              children: [
                pw.Expanded(child: _celdaFicha(grupos[i][0])),
                pw.Expanded(
                  child: grupos[i].length > 1
                      ? _celdaFicha(grupos[i][1], separador: true)
                      // El hueco de una lista impar. Sin esto la ultima
                      // etiqueta se estira al doble de ancho que las demas y
                      // la columna deja de leerse como columna.
                      : pw.SizedBox(),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

pw.Widget _celdaFicha(List<String> par, {bool separador = false}) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 5.5),
    decoration: separador
        // La linea que separa las dos columnas. Va como borde de la celda y no
        // como un Container entre las dos: un divisor suelto en la fila
        // necesita altura propia, y una fila sin altura resuelta no se puede
        // paginar.
        ? const pw.BoxDecoration(
            border: pw.Border(
              left: pw.BorderSide(color: PaletaInforme.borde, width: 0.8),
            ),
          )
        : null,
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 108,
          child: pw.Text(
            par[0],
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PaletaInforme.tinta,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            par[1],
            style: const pw.TextStyle(
              fontSize: 8.5,
              color: PaletaInforme.cuerpo,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Tabla con encabezado oscuro y filas alternas.
///
/// [anchos] son pesos relativos, no puntos: el documento tiene que sobrevivir
/// a un nombre de lote largo sin que se le desarme la cuadricula.
///
/// [colores] pinta una columna con el color de la certeza. Es el unico uso de
/// color por dato en el documento: un informe donde todo esta coloreado no
/// destaca nada.
pw.Widget _tabla({
  required List<String> encabezados,
  required List<List<String>> filas,
  required List<int> anchos,
  int? columnaColoreada,
  List<PdfColor?>? colores,
}) {
  final total = anchos.fold(0, (a, b) => a + b);
  return pw.Table(
    border: pw.TableBorder.all(color: PaletaInforme.borde, width: 0.6),
    columnWidths: {
      for (var i = 0; i < anchos.length; i++)
        i: pw.FractionColumnWidth(anchos[i] / total),
    },
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PaletaInforme.tinta),
        children: [
          for (final e in encabezados)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 4.5,
              ),
              child: pw.Text(
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
      for (var i = 0; i < filas.length; i++)
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: i.isEven ? PdfColors.white : PaletaInforme.suave,
          ),
          children: [
            for (var j = 0; j < filas[i].length; j++)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 4,
                ),
                child: pw.Text(
                  filas[i][j],
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: j == columnaColoreada
                        ? (colores?[i] ?? PaletaInforme.cuerpo)
                        : PaletaInforme.cuerpo,
                    fontWeight: j == columnaColoreada
                        ? pw.FontWeight.bold
                        : pw.FontWeight.normal,
                  ),
                ),
              ),
          ],
        ),
    ],
  );
}

/// La nota al pie de una seccion: de donde salio el numero, o que significa.
pw.Widget _nota(String texto) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(top: 5),
    child: pw.Text(
      texto,
      style: const pw.TextStyle(fontSize: 7.5, color: PaletaInforme.seccion),
    ),
  );
}

pw.Widget _vacio(String texto) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(9),
    decoration: pw.BoxDecoration(
      color: PaletaInforme.suave,
      border: pw.Border.all(color: PaletaInforme.borde, width: 0.8),
    ),
    child: pw.Text(
      texto,
      style: const pw.TextStyle(fontSize: 8.5, color: PaletaInforme.seccion),
    ),
  );
}

// --- Secciones ---

List<pw.Widget> _seccionIdentificacion(
  DatosInformeTecnico d,
  FormatoInforme f,
) {
  return [
    _banda('1.', 'Identificación de la visita'),
    pw.SizedBox(height: 8),
    _ficha([
      ['Código de visita', d.codigoVisita],
      ['Estado', d.estado ?? '—'],
      ['Fecha', f.fechaLarga(d.inicio)],
      ['Tipo de visita', d.tipoVisita ?? '—'],
      ['Hora de inicio', f.hora(d.inicio)],
      ['Hora de cierre', d.fin == null ? 'Sin cerrar' : f.hora(d.fin!)],
      ['Duración', duracionLegible(d.duracion)],
      ['Cobertura', '${d.completitudPct}% del cuestionario'],
      ['Visitador', d.visitador ?? 'Sin registrar'],
      ['Sincronizada', si(d.sincronizada)],
    ]),
    pw.SizedBox(height: 14),
  ];
}

List<pw.Widget> _seccionPredio(DatosInformeTecnico d, FormatoInforme f) {
  final p = d.productor;
  final area = d.finca?.areaDeclaradaHa;

  return [
    _banda('2.', 'Productor y predio'),
    pw.SizedBox(height: 8),
    _ficha([
      ['Productor', p?.nombre ?? 'Sin registrar'],
      [
        'Documento',
        p?.documento == null || p!.documento!.isEmpty
            ? 'Sin registrar'
            : '${p.tipoDocumento ?? 'CC'} ${p.documento}',
      ],
      ['Código', p?.codigoProductor ?? 'Pendiente de sincronizar'],
      ['Teléfono', p?.telefono ?? 'Sin registrar'],
      ['Finca', d.finca?.nombre ?? 'Sin registrar'],
      ['Organización', p?.organizacion ?? 'Ninguna'],
      ['Vereda / Municipio', d.lugar.isEmpty ? 'Sin registrar' : d.lugar],
      [
        'Área declarada',
        area == null ? 'Sin registrar' : '${f.numero(area)} ha',
      ],
    ]),
    // El area declarada y el area medida son dos cosas distintas y el
    // documento no las suma nunca: una salio de la conversacion, la otra de
    // caminar el lindero.
    if (area != null && d.areaMedidaM2 > 0)
      _nota(
        'El área declarada es la que dijo el productor. El área medida, en la '
        'sección 4, es la que se caminó con el GPS: '
        '${geo.formatearArea(d.areaMedidaM2)}. No son el mismo dato y no se '
        'suman.',
      ),
    pw.SizedBox(height: 14),
  ];
}

List<pw.Widget> _seccionGeorreferenciacion(DatosInformeTecnico d) {
  final fincaLat = d.finca?.latitud;
  final fincaLon = d.finca?.longitud;

  return [
    _banda('3.', 'Georreferenciación'),
    pw.SizedBox(height: 8),
    if (!d.tieneGps && fincaLat == null)
      _vacio(
        'Esta visita no tiene coordenada: el teléfono no tenía posición '
        'cuando se abrió. No se puede ubicar el predio con este documento.',
      )
    else
      _ficha([
        if (d.tieneGps) ...[
          ['Punto de la visita', coordenadaDecimal(d.latitud!, d.longitud!)],
          ['Precisión', precision(d.precisionGps)],
          [
            'En sexagesimal',
            coordenadaSexagesimal(d.latitud!, d.longitud!),
          ],
          ['Sistema', 'WGS84 (EPSG:4326)'],
        ],
        if (fincaLat != null && fincaLon != null) ...[
          ['Punto de la finca', coordenadaDecimal(fincaLat, fincaLon)],
          ['En sexagesimal', coordenadaSexagesimal(fincaLat, fincaLon)],
        ],
      ]),
    if (d.tieneGps)
      _nota(
        'El punto de la visita es donde se abrió la visita en el teléfono: '
        'por lo general la casa, no el centro del predio. Los linderos están '
        'en la sección 4.',
      ),
    pw.SizedBox(height: 14),
  ];
}

List<pw.Widget> _seccionTrazados(DatosInformeTecnico d) {
  if (d.trazados.isEmpty) {
    return [
      _banda('4.', 'Lotes y recorridos medidos'),
      pw.SizedBox(height: 8),
      _vacio(
        'No se caminó ningún lote en esta visita. El área de la sección 2 es '
        'la que declaró el productor, no una medida.',
      ),
      pw.SizedBox(height: 14),
    ];
  }

  return [
    _banda('4.', 'Lotes y recorridos medidos'),
    pw.SizedBox(height: 8),
    _tabla(
      encabezados: [
        'Nombre',
        'Qué hay',
        'Figura',
        'Área',
        'Perímetro',
        'Vért.',
        'Captura',
        'Precisión',
      ],
      anchos: [19, 15, 11, 11, 11, 6, 15, 12],
      filas: [
        for (final t in d.trazados)
          [
            t.nombre,
            t.etiqueta ?? '—',
            t.esPoligono && !t.cerrado ? '${t.tipo} (abierto)' : t.tipo,
            t.esPoligono && t.cerrado
                ? geo.formatearArea(t.areaCalculadaM2)
                : '—',
            geo.formatearDistancia(t.perimetroCalculadoM),
            '${t.puntos.length}',
            t.modoCaptura,
            precision(t.precisionPromedioM),
          ],
      ],
    ),
    _nota(
      'Área total medida (solo polígonos cerrados): '
      '${geo.formatearArea(d.areaMedidaM2)}  ·  '
      'Vértices capturados: ${d.puntosGpsTotales}. Las áreas se calculan por '
      'excedente esférico sobre WGS84, la misma fórmula de Google Earth: el '
      'número coincide con el del KML de la visita.',
    ),
    // Un poligono sin cerrar no es un lote: es un recorrido a medias, y su
    // area no existe. Se dice aca y no en una nota al final, porque quien lee
    // la tabla tiene que verlo junto al «—» de la columna de area.
    if (d.trazados.any((t) => t.esPoligono && !t.cerrado))
      _nota(
        'Los polígonos marcados «abierto» no cerraron el anillo: no tienen '
        'área y salen al KML como línea. Hay que volver a caminarlos.',
      ),
    pw.SizedBox(height: 12),
    ..._croquis(d),
    pw.SizedBox(height: 14),
  ];
}

/// Los croquis de los trazados, dos por fila.
///
/// Es un dibujo vectorial y no una captura del mapa a proposito: el informe se
/// arma en la finca, sin red, y un mapa necesita descargar teselas. Lo que el
/// croquis tiene que responder es lo mismo que en la pantalla — que la figura
/// cerro donde debia y que ningun vertice quedo disparado por un salto del
/// GPS — y para eso alcanza la forma real con su escala y su norte.
List<pw.Widget> _croquis(DatosInformeTecnico d) {
  final conForma = [for (final t in d.trazados) if (t.puntos.length >= 2) t];
  if (conForma.isEmpty) return [];

  final filas = <pw.Widget>[];
  for (var i = 0; i < conForma.length; i += 2) {
    final grupo = conForma.skip(i).take(2).toList();
    filas.add(
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: _croquisDe(grupo[0])),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: grupo.length > 1 ? _croquisDe(grupo[1]) : pw.SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
  return filas;
}

pw.Widget _croquisDe(TrazadoTecnico t) {
  final encuadre = geo.Encuadre.de(t.geometria)!;
  final cierra = t.esPoligono && t.cerrado;

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Container(
        height: 150,
        decoration: pw.BoxDecoration(
          color: PaletaInforme.suave,
          border: pw.Border.all(color: PaletaInforme.borde, width: 0.8),
        ),
        child: pw.Stack(
          children: [
            // El lienzo se declara con un tamano finito: `double.infinity`
            // deja la caja sin resolver y el paginador entra en un bucle
            // creando hojas para algo que nunca cabe. 265 x 150 es la mitad
            // del ancho util de la A4 con sus margenes, que es el espacio que
            // ocupa un croquis de a dos por fila.
            pw.CustomPaint(
              size: const PdfPoint(265, 150),
              painter: (canvas, size) => _pintarTrazado(
                canvas,
                size,
                t.geometria,
                encuadre,
                cierra,
              ),
            ),
            // El norte y la escala van como texto encima del lienzo: escribir
            // dentro del canvas obliga a cargar la fuente a mano y a calcular
            // el ancho del texto.
            //
            // La FLECHA si va dibujada, y no como el caracter «↑»: Roboto no
            // trae ese glifo y el generador lo deja en blanco. Un croquis con
            // una letra N y ninguna flecha no dice para donde es el norte.
            pw.Positioned(
              top: 4,
              right: 6,
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'N',
                    style: pw.TextStyle(
                      fontSize: 7.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PaletaInforme.seccion,
                    ),
                  ),
                  pw.SizedBox(width: 2),
                  pw.CustomPaint(
                    size: const PdfPoint(7, 11),
                    painter: _pintarNorte,
                  ),
                ],
              ),
            ),
            pw.Positioned(
              bottom: 5,
              left: 6,
              child: pw.Text(
                'lado ≈ ${geo.formatearDistancia(encuadre.ladoM)}',
                style: const pw.TextStyle(
                  fontSize: 7,
                  color: PaletaInforme.seccion,
                ),
              ),
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        t.nombre,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: pw.FontWeight.bold,
          color: PaletaInforme.tinta,
        ),
      ),
      pw.Text(
        [
          if (t.etiqueta != null) t.etiqueta!,
          if (cierra) geo.formatearArea(t.areaCalculadaM2),
          '${t.puntos.length} vértices',
        ].join('  ·  '),
        style: const pw.TextStyle(fontSize: 7.5, color: PaletaInforme.seccion),
      ),
    ],
  );
}

/// La flecha del norte: un asta con la punta hacia arriba.
void _pintarNorte(PdfGraphics canvas, PdfPoint size) {
  final medio = size.x / 2;
  canvas
    ..setStrokeColor(PaletaInforme.seccion)
    ..setLineWidth(0.8)
    ..moveTo(medio, 1)
    ..lineTo(medio, size.y - 2)
    ..strokePath()
    ..setFillColor(PaletaInforme.seccion)
    ..moveTo(medio, size.y)
    ..lineTo(medio - 2.4, size.y - 3.4)
    ..lineTo(medio + 2.4, size.y - 3.4)
    ..fillPath();
}

/// Dibuja la figura en el lienzo del PDF.
///
/// El origen del canvas de un PDF esta abajo a la izquierda, al contrario de
/// la pantalla. La proyeccion de `geo.Encuadre` devuelve `y` creciendo hacia
/// abajo, como en la pantalla, asi que se invierte aca: sin eso el lote sale
/// reflejado y el norte apunta al sur.
void _pintarTrazado(
  PdfGraphics canvas,
  PdfPoint size,
  List<geo.PuntoGeo> puntos,
  geo.Encuadre encuadre,
  bool cerrado,
) {
  const margen = 14.0;
  final lado = (size.x < size.y ? size.x : size.y) - margen * 2;
  final desplazX = (size.x - lado) / 2;
  final desplazY = (size.y - lado) / 2;

  PdfPoint aLienzo(geo.PuntoGeo p) {
    final plano = encuadre.proyectar(p);
    return PdfPoint(
      desplazX + plano.x * lado,
      // 1 - y: el canvas crece hacia arriba.
      desplazY + (1 - plano.y) * lado,
    );
  }

  final vertices = [for (final p in puntos) aLienzo(p)];

  canvas
    ..setLineWidth(1.2)
    ..setStrokeColor(PaletaInforme.tinta)
    ..setLineJoin(PdfLineJoin.round)
    ..moveTo(vertices.first.x, vertices.first.y);
  for (final v in vertices.skip(1)) {
    canvas.lineTo(v.x, v.y);
  }

  if (cerrado) {
    // El relleno va primero y con la figura cerrada, para que el contorno
    // quede encima y no lo tape el area.
    canvas
      ..closePath()
      ..setFillColor(PaletaInforme.franja)
      ..fillPath();
    canvas
      ..moveTo(vertices.first.x, vertices.first.y)
      ..setStrokeColor(PaletaInforme.tinta);
    for (final v in vertices.skip(1)) {
      canvas.lineTo(v.x, v.y);
    }
    canvas.strokePath(close: true);
  } else {
    canvas.strokePath();
  }

  // Los vertices, uno por uno. Es lo que permite ver que un lado recto tiene
  // dos puntos y una curva veinte, y cazar el punto disparado.
  canvas.setFillColor(PaletaInforme.seccion);
  for (final v in vertices) {
    canvas
      ..drawEllipse(v.x, v.y, 1.5, 1.5)
      ..fillPath();
  }

  // El primero, mas grande y en verde: por donde arranco el recorrido.
  canvas
    ..setFillColor(PaletaInforme.cierre)
    ..drawEllipse(vertices.first.x, vertices.first.y, 2.6, 2.6)
    ..fillPath();
}

List<pw.Widget> _seccionDatos(DatosInformeTecnico d) {
  if (d.hallazgos.isEmpty) {
    return [
      _banda('5.', 'Datos registrados'),
      pw.SizedBox(height: 8),
      _vacio(
        'No hay datos extraídos para esta visita. Si la conversación se grabó, '
        'falta procesarla.',
      ),
      pw.SizedBox(height: 14),
    ];
  }

  final widgets = <pw.Widget>[
    _banda('5.', 'Datos registrados'),
    pw.SizedBox(height: 10),
  ];

  for (final entrada in d.porModulo.entries) {
    widgets
      ..add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 5),
          // El mismo icono que la app dibuja en pantalla para ese modulo. No
          // es adorno: quien lee el informe con el telefono al lado tiene que
          // ver el mismo simbolo en los dos sitios para «Suelos».
          child: pw.Row(
            children: [
              pw.Icon(
                pw.IconData(iconoModuloPdf(entrada.key)),
                size: 10,
                color: PaletaInforme.tinta,
              ),
              pw.SizedBox(width: 4),
              pw.Text(
                entrada.key,
                style: pw.TextStyle(
                  fontSize: 9.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PaletaInforme.tinta,
                ),
              ),
            ],
          ),
        ),
      )
      ..add(
        _tabla(
          encabezados: ['Campo', 'Valor', 'Certeza', 'Fuente', 'Estado', 'Min'],
          anchos: [25, 29, 12, 11, 14, 9],
          columnaColoreada: 2,
          colores: [for (final h in entrada.value) _colorCerteza(h.certeza)],
          filas: [
            for (final h in entrada.value)
              [
                h.entidad == null ? h.campo : '${h.campo} (${h.entidad})',
                h.valorConUnidad.isEmpty ? '—' : h.valorConUnidad,
                h.certeza,
                h.fuente,
                h.estado,
                marcaAudio(h.segundoAudio),
              ],
          ],
        ),
      )
      ..add(pw.SizedBox(height: 10));
  }

  widgets
    ..add(
      _nota(
        'Certeza: «Confirmado» lo dijo el agricultor textualmente; '
        '«Estimado» dio un aproximado; «Inferido» se dedujo de lo que contó; '
        '«Pendiente» no salió en la conversación y no es un dato. «Min» es el '
        'minuto del audio donde consta.',
      ),
    )
    ..add(pw.SizedBox(height: 14));

  return widgets;
}


List<pw.Widget> _seccionPendientes(DatosInformeTecnico d) {
  final pendientes = d.temasPendientes;
  if (pendientes == null || pendientes.trim().isEmpty) return [];

  final lineas = [
    for (final l in pendientes.split('\n'))
      if (l.trim().isNotEmpty) l.trim(),
  ];

  return [
    _banda('6.', 'Temas pendientes'),
    pw.SizedBox(height: 8),
    pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(9),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PaletaInforme.borde, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          for (final l in lineas)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3.5),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 3,
                    height: 3,
                    margin: const pw.EdgeInsets.only(top: 4, right: 7),
                    decoration: const pw.BoxDecoration(
                      color: PaletaInforme.seccion,
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      l,
                      style: const pw.TextStyle(
                        fontSize: 8.5,
                        color: PaletaInforme.cuerpo,
                        lineSpacing: 1.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
    pw.SizedBox(height: 14),
  ];
}

List<pw.Widget> _seccionEvidencias(
  DatosInformeTecnico d,
  Map<int, pw.MemoryImage> imagenes,
  FormatoInforme f,
) {
  if (d.evidencias.isEmpty) {
    return [
      _banda('7.', 'Evidencias fotográficas'),
      pw.SizedBox(height: 8),
      _vacio('No se tomaron fotos en esta visita.'),
      pw.SizedBox(height: 14),
    ];
  }

  final faltantes = d.evidencias.length - imagenes.length;

  return [
    _banda('7.', 'Evidencias fotográficas'),
    pw.SizedBox(height: 8),
    _tabla(
      encabezados: ['#', 'Archivo', 'Tomada', 'Coordenada', 'Min', 'Qué es'],
      anchos: [5, 17, 14, 25, 9, 30],
      filas: [
        for (var i = 0; i < d.evidencias.length; i++)
          [
            (i + 1).toString().padLeft(2, '0'),
            soloNombre(d.evidencias[i].archivoPath),
            f.fechaHora(d.evidencias[i].tomadaEn),
            d.evidencias[i].tieneGps
                ? coordenadaDecimal(
                    d.evidencias[i].latitud!,
                    d.evidencias[i].longitud!,
                  )
                : 'sin GPS',
            marcaAudio(d.evidencias[i].segundoAudio),
            d.evidencias[i].descripcion ?? '—',
          ],
      ],
    ),
    if (faltantes > 0)
      _nota(
        '$faltantes foto(s) de la lista ya no están en el teléfono y no se '
        'pudieron incluir. La fila se conserva: que falte el archivo también '
        'es información.',
      ),
    pw.SizedBox(height: 10),
    ..._laminas(d, imagenes),
    pw.SizedBox(height: 14),
  ];
}

/// Las fotos con su numero de evidencia debajo.
///
/// Tres por fila y no dos como en el informe del productor: alla la foto es lo
/// que el agricultor mira, aca es el respaldo de una fila de la tabla. Lo que
/// importa es poder ir del numero de la tabla a la imagen, y para eso el pie
/// con el numero pesa mas que el tamano.
List<pw.Widget> _laminas(
  DatosInformeTecnico d,
  Map<int, pw.MemoryImage> imagenes,
) {
  final indices = imagenes.keys.toList()..sort();
  if (indices.isEmpty) return [];

  const porFila = 3;
  final filas = <pw.Widget>[];

  for (var i = 0; i < indices.length; i += porFila) {
    final grupo = indices.skip(i).take(porFila).toList();
    filas.add(
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 9),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            for (var j = 0; j < porFila; j++) ...[
              pw.Expanded(
                child: j < grupo.length
                    ? _lamina(grupo[j], imagenes[grupo[j]]!, d)
                    // El hueco de la fila incompleta, para que la ultima foto
                    // no se estire al ancho de tres.
                    : pw.SizedBox(),
              ),
              if (j < porFila - 1) pw.SizedBox(width: 9),
            ],
          ],
        ),
      ),
    );
  }
  return filas;
}

pw.Widget _lamina(
  int indice,
  pw.MemoryImage imagen,
  DatosInformeTecnico d,
) {
  final e = d.evidencias[indice];
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Container(
        height: 110,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PaletaInforme.borde, width: 0.8),
        ),
        child: pw.ClipRect(child: pw.Image(imagen, fit: pw.BoxFit.cover)),
      ),
      pw.SizedBox(height: 3),
      pw.Text(
        'Foto ${(indice + 1).toString().padLeft(2, '0')}',
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: pw.FontWeight.bold,
          color: PaletaInforme.tinta,
        ),
      ),
      pw.Text(
        e.tieneGps ? coordenadaDecimal(e.latitud!, e.longitud!) : 'sin GPS',
        style: const pw.TextStyle(fontSize: 6.5, color: PaletaInforme.seccion),
      ),
    ],
  );
}

List<pw.Widget> _seccionAudio(DatosInformeTecnico d, FormatoInforme f) {
  if (d.grabaciones.isEmpty) {
    return [
      _banda('8.', 'Audio de la visita'),
      pw.SizedBox(height: 8),
      _vacio(
        'No se grabó audio en esta visita. Los datos de la sección 5, si hay, '
        'los registró el visitador a mano.',
      ),
      pw.SizedBox(height: 14),
    ];
  }

  return [
    _banda('8.', 'Audio de la visita'),
    pw.SizedBox(height: 8),
    _tabla(
      encabezados: ['Tramo', 'Inicio', 'Duración', 'Peso', 'Motor', 'Transcrito'],
      anchos: [10, 14, 16, 14, 26, 20],
      filas: [
        for (final g in d.grabaciones)
          [
            g.orden.toString().padLeft(2, '0'),
            f.hora(g.inicio),
            duracionLegible(Duration(seconds: g.duracionSeg)),
            pesoLegible(g.tamanoBytes),
            g.motor ?? '—',
            si(g.transcrita),
          ],
      ],
    ),
    _nota(
      'Audio total: ${duracionLegible(d.audioTotal)}. La visita puede tener '
      'varios tramos: pausas, llamadas entrantes o un «seguir grabando». El '
      'archivo de cada uno vive en el bucket, bajo el código de la visita.',
    ),
    pw.SizedBox(height: 14),
  ];
}

List<pw.Widget> _seccionConsentimiento(
  DatosInformeTecnico d,
  FormatoInforme f,
) {
  final c = d.consentimiento;
  final p = d.productor;

  return [
    _banda('9.', 'Consentimiento (Ley 1581 de 2012)'),
    pw.SizedBox(height: 8),
    _ficha([
      ['Grabar el audio', si(c.audio)],
      ['Tomar fotos', si(c.fotos)],
      ['Uso de los datos', si(c.usoDatos)],
      ['Consta en el audio', 'minuto ${marcaAudio(c.segundoConsentimiento)}'],
      [
        'Autorización del productor',
        p == null ? 'Sin registrar' : si(p.consentimientoDatos),
      ],
      [
        'Fecha de la autorización',
        p?.fechaConsentimiento == null
            ? '—'
            : f.fechaLarga(p!.fechaConsentimiento!),
      ],
      ['Marcada para eliminación', si(c.marcadaParaEliminacion)],
      ['', ''],
    ]),
    _nota(
      'El permiso de grabar y de fotografiar se pide en cada visita. La '
      'autorización de tratamiento de datos es de la persona y se da una sola '
      'vez. El minuto del audio es la prueba: ahí el productor lo dice con su '
      'voz.',
    ),
    pw.SizedBox(height: 14),
  ];
}

List<pw.Widget> _seccionTrazabilidad(DatosInformeTecnico d, FormatoInforme f) {
  return [
    _banda('10.', 'Trazabilidad del documento'),
    pw.SizedBox(height: 8),
    _ficha([
      ['Generado el', '${f.fechaLarga(d.generadoEn)}, ${f.hora(d.generadoEn)}'],

      ['Versión del informe', '${d.version}'],
      ['Código de visita', d.codigoVisita],
      ['Origen de los datos', 'Base local de la app'],
      ['Modelo de IA registrado', d.modeloIa ?? 'No registrado'],
    ]),
    _nota(
      'Las coordenadas, áreas y perímetros de este documento se calculan '
      'sobre los puntos que capturó el GPS del teléfono. Ningún número de '
      'este informe lo escribió un modelo de lenguaje: el modelo solo extrajo '
      'los datos de la sección 5 a partir de la conversación, y cada uno '
      'lleva su certeza.',
    ),
  ];
}

/// Las firmas.
///
/// Van aunque el documento se entregue como PDF: el informe tecnico se imprime
/// y se archiva en carpeta, y una carpeta con hojas sin firmar no respalda
/// nada. El nombre del visitador va impreso —la app lo sabe— y la linea de
/// revision queda en blanco porque quien revisa no es quien visita.
///
/// Al final del todo, despues del anexo de vertices: lo ultimo que se ve al
/// pasar la carpeta tiene que ser la firma.
pw.Widget _firmas(DatosInformeTecnico d) {
  return pw.Row(
    children: [
      pw.Expanded(child: _firma('Visitó', d.visitador)),
      pw.SizedBox(width: 30),
      pw.Expanded(child: _firma('Revisó', null)),
    ],
  );
}

pw.Widget _firma(String rol, String? nombre) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.SizedBox(height: 22),
      pw.Container(height: 0.8, color: PaletaInforme.cuerpo),
      pw.SizedBox(height: 4),
      pw.Text(
        rol,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: PaletaInforme.tinta,
        ),
      ),
      pw.Text(
        nombre ?? '',
        style: const pw.TextStyle(fontSize: 8, color: PaletaInforme.cuerpo),
      ),
    ],
  );
}

/// El anexo con cada vertice caminado.
///
/// Es la parte que hace auditable el documento. Sin el, las areas de la
/// seccion 4 son numeros que nadie puede verificar; con el, cualquiera puede
/// rehacer el poligono en QGIS y llegar al mismo valor — o encontrar el punto
/// que lo desvio.
///
/// Va al final y no en la seccion 4 porque son tablas largas: cuarenta
/// vertices de tres lotes empujarian todo lo demas a la tercera pagina.
List<pw.Widget> _anexoVertices(DatosInformeTecnico d, FormatoInforme f) {
  final conPuntos = [for (final t in d.trazados) if (t.puntos.isNotEmpty) t];
  if (conPuntos.isEmpty) return [];

  final widgets = <pw.Widget>[
    pw.SizedBox(height: 20),
    _banda('A.', 'Anexo: vértices capturados'),
    pw.SizedBox(height: 8),
    pw.Text(
      'Cada punto con el radio de error que reportó el GPS y cómo se puso. Es '
      'lo que permite, meses después, distinguir un lindero mal caminado de '
      'un salto del GPS bajo los árboles.',
      style: const pw.TextStyle(fontSize: 8, color: PaletaInforme.cuerpo),
    ),
    pw.SizedBox(height: 10),
  ];

  for (final t in conPuntos) {
    final centroide = t.centroide;
    widgets
      ..add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                t.nombre,
                style: pw.TextStyle(
                  fontSize: 9.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PaletaInforme.tinta,
                ),
              ),
              pw.Text(
                [
                  t.tipo,
                  if (t.esPoligono) t.cerrado ? 'cerrado' : 'sin cerrar',
                  'captura ${t.modoCaptura}',
                  if (centroide != null)
                    'centro ${coordenadaDecimal(centroide.latitud, centroide.longitud)}',
                  if (t.precisionPeorM != null)
                    'peor precisión ${precision(t.precisionPeorM)}',
                ].join('  ·  '),
                style: const pw.TextStyle(
                  fontSize: 7.5,
                  color: PaletaInforme.seccion,
                ),
              ),
              if (t.notas != null && t.notas!.isNotEmpty)
                pw.Text(
                  t.notas!,
                  style: const pw.TextStyle(
                    fontSize: 7.5,
                    color: PaletaInforme.cuerpo,
                  ),
                ),
            ],
          ),
        ),
      )
      ..add(
        _tabla(
          encabezados: [
            '#',
            'Latitud',
            'Longitud',
            'Altitud',
            'Precisión',
            'Hora',
            'Puesto',
            'Nota',
          ],
          anchos: [5, 16, 16, 10, 12, 11, 11, 19],
          filas: [
            for (final p in t.puntos)
              [
                p.orden.toString().padLeft(2, '0'),
                p.latitud.toStringAsFixed(6).replaceAll('.', ','),
                p.longitud.toStringAsFixed(6).replaceAll('.', ','),
                p.altitud == null ? '—' : '${p.altitud!.round()} m',
                precision(p.precisionM),
                f.hora(p.capturadoEn),
                p.automatico ? 'reloj' : 'a mano',
                p.nota ?? '—',
              ],
          ],
        ),
      )
      ..add(pw.SizedBox(height: 12));
  }

  widgets.add(
    _nota(
      'Coordenadas en grados decimales, WGS84 (EPSG:4326). «Puesto a mano» es '
      'un punto que marcó el visitador con el botón; «reloj» es la captura '
      'automática por intervalo.',
    ),
  );

  return widgets;
}
