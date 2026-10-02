import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Los trazos de una firma, fuera del widget para que el formulario pueda
/// preguntar si hay firma, borrarla y exportarla sin llaves globales.
class FirmaController extends ChangeNotifier {
  final List<List<Offset>> _trazos = [];
  Size _lienzo = Size.zero;

  List<List<Offset>> get trazos => _trazos;

  /// Un toque suelto no es una firma: hace falta al menos un trazo con
  /// recorrido. Evita que un dedo que roza el recuadro habilite el envio.
  bool get tieneFirma => _trazos.any((t) => t.length > 3);

  void _empezar(Offset punto) {
    _trazos.add([punto]);
    notifyListeners();
  }

  void _seguir(Offset punto) {
    if (_trazos.isEmpty) return;
    _trazos.last.add(punto);
    notifyListeners();
  }

  void borrar() {
    _trazos.clear();
    notifyListeners();
  }

  /// PNG con fondo blanco y tinta oscura, al doble de resolucion.
  ///
  /// Fondo blanco y no transparente: Airtable y cualquier visor muestran la
  /// transparencia en negro o en cuadritos, y una firma negra sobre negro no
  /// se ve.
  Future<Uint8List> exportarPng({double escala = 2}) async {
    final tamano = _lienzo == Size.zero ? const Size(600, 220) : _lienzo;
    final grabador = ui.PictureRecorder();
    final canvas = Canvas(grabador)..scale(escala);
    canvas.drawRect(
      Offset.zero & tamano,
      Paint()..color = Colors.white,
    );
    _PintorFirma.dibujar(canvas, _trazos, const Color(0xFF1A1A1A));
    final imagen = await grabador.endRecording().toImage(
          (tamano.width * escala).round(),
          (tamano.height * escala).round(),
        );
    final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
    imagen.dispose();
    return datos!.buffer.asUint8List();
  }
}

/// El recuadro donde la persona firma con el dedo.
class FirmaPad extends StatelessWidget {
  const FirmaPad({super.key, required this.controller, this.alto = 200});

  final FirmaController controller;
  final double alto;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: alto,
        decoration: BoxDecoration(
          // Siempre blanco, tambien en tema oscuro: es como va a quedar el
          // papel, y la tinta tiene que contrastar igual en los dos.
          color: Colors.white,
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(14),
        ),
        child: LayoutBuilder(
          builder: (context, restricciones) {
            controller._lienzo = restricciones.biggest;
            return GestureDetector(
              // Sin esto, firmar de arriba abajo desplaza el formulario.
              onVerticalDragStart: (d) => controller._empezar(d.localPosition),
              onVerticalDragUpdate: (d) => controller._seguir(d.localPosition),
              onHorizontalDragStart: (d) =>
                  controller._empezar(d.localPosition),
              onHorizontalDragUpdate: (d) =>
                  controller._seguir(d.localPosition),
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) => CustomPaint(
                  size: Size.infinite,
                  painter: _PintorFirma(controller.trazos),
                  child: controller.trazos.isEmpty
                      ? const Center(
                          child: Text(
                            'Firme aqui con el dedo',
                            style: TextStyle(
                              color: Color(0xFF9E9E9E),
                              fontSize: 14,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PintorFirma extends CustomPainter {
  _PintorFirma(this.trazos);

  final List<List<Offset>> trazos;

  static void dibujar(Canvas canvas, List<List<Offset>> trazos, Color color) {
    final pincel = Paint()
      ..color = color
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final trazo in trazos) {
      if (trazo.length == 1) {
        canvas.drawCircle(trazo.first, 1.3, pincel..style = PaintingStyle.fill);
        pincel.style = PaintingStyle.stroke;
        continue;
      }
      final camino = Path()..moveTo(trazo.first.dx, trazo.first.dy);
      for (final punto in trazo.skip(1)) {
        camino.lineTo(punto.dx, punto.dy);
      }
      canvas.drawPath(camino, pincel);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Linea guia de firma, como en el papel. No sale en el PNG.
    final guia = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(24, size.height - 36),
      Offset(size.width - 24, size.height - 36),
      guia,
    );
    dibujar(canvas, trazos, const Color(0xFF1A1A1A));
  }

  // Los trazos se mutan en el mismo objeto: siempre se repinta.
  @override
  bool shouldRepaint(_PintorFirma oldDelegate) => true;
}
