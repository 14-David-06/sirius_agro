import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

/// La tipografia corporativa dentro del PDF.
///
/// El generador de PDF no lee el registro de fuentes de Flutter: hay que
/// cargarle los archivos a mano y decirle cual es cada peso. Por eso esto vive
/// aqui y no en `theme.dart`, y por eso los dos informes —el del productor y
/// el tecnico— lo comparten: dos documentos de la misma visita se archivan
/// juntos y no pueden estar escritos en tipografias distintas.
///
/// Museo Slab va convertida a TrueType (ver `assets/fuentes/`): las originales
/// llevan contornos CFF y este generador solo sabe leer TrueType.
class FuentesInforme {
  const FuentesInforme({
    required this.base,
    required this.negrita,
    required this.iconos,
  });

  final pw.Font base;
  final pw.Font negrita;

  /// Los iconos de modulo, recortados de la tipografia de Material. Se dibujan
  /// con [pw.Text] sobre esta fuente, que es como el generador de PDF entiende
  /// un icono.
  final pw.Font iconos;

  static Future<FuentesInforme> cargar() async {
    Future<pw.Font> cargarUna(String archivo) async =>
        pw.Font.ttf(await rootBundle.load('assets/fuentes/$archivo'));

    return FuentesInforme(
      base: await cargarUna('MuseoSlab-500.ttf'),
      negrita: await cargarUna('MuseoSlab-700.ttf'),
      iconos: await cargarUna('IconosModulo.ttf'),
    );
  }

  /// El tema del documento.
  ///
  /// Roboto queda de reserva y no de titular: Museo Slab cubre todo el latin
  /// que estos informes escriben —tildes, «», —, °, ±, ²— pero un dato que
  /// venga de Airtable con un caracter raro tiene que salir impreso, aunque
  /// sea en otra letra, y no como un cuadro vacio en el papel que se le
  /// entrega al productor.
  Future<pw.ThemeData> tema() async {
    final reserva = pw.Font.ttf(
      await rootBundle.load('assets/fuentes/Roboto-Regular.ttf'),
    );
    return pw.ThemeData.withFont(
      base: base,
      bold: negrita,
      icons: iconos,
      fontFallback: [reserva],
    );
  }
}
