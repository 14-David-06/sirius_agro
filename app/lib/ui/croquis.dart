import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/geo.dart';
import '../data/db/app_database.dart';
import 'theme.dart';

/// El dibujo del trazado, sin mapa.
///
/// Es deliberadamente un croquis y no un mapa: un mapa necesita descargar
/// teselas y en la vereda no hay de donde. Lo que se necesita en campo es mas
/// modesto y esto si lo resuelve — ver que la figura cerro donde debia, que no
/// hay un punto disparado por un salto del GPS, y de que tamano es la cosa.
///
/// El norte esta arriba y la escala esta escrita: sin esas dos cosas el dibujo
/// no es un croquis, es una mancha.
class Croquis extends StatelessWidget {
  const Croquis({
    super.key,
    required this.puntos,
    required this.cerrado,
    this.resaltado,
    this.altura = 240,
  });

  final List<PuntoTrazado> puntos;
  final bool cerrado;

  /// Id del punto que la lista tiene seleccionado. Se dibuja mas grande para
  /// poder mirar la lista y el dibujo a la vez y saber cual es cual.
  final String? resaltado;

  final double altura;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;

    if (puntos.isEmpty) {
      return Container(
        height: altura,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Text(
            'Todavia no hay puntos. El dibujo aparece con el primero.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: altura,
        color: scheme.surfaceContainerHighest,
        child: CustomPaint(
          painter: _PintorCroquis(
            puntos: puntos,
            cerrado: cerrado,
            resaltado: resaltado,
            trazo: tema.marca.exito,
            relleno: tema.marca.exito.withValues(alpha: 0.18),
            tenue: scheme.onSurfaceVariant,
            inicio: scheme.primary,
            fondoTexto: scheme.surface,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _PintorCroquis extends CustomPainter {
  _PintorCroquis({
    required this.puntos,
    required this.cerrado,
    required this.resaltado,
    required this.trazo,
    required this.relleno,
    required this.tenue,
    required this.inicio,
    required this.fondoTexto,
  });

  final List<PuntoTrazado> puntos;
  final bool cerrado;
  final String? resaltado;
  final Color trazo;
  final Color relleno;
  final Color tenue;
  final Color inicio;
  final Color fondoTexto;

  @override
  void paint(Canvas lienzo, Size tamano) {
    final geos = [for (final p in puntos) PuntoGeo(p.latitud, p.longitud)];
    final encuadre = Encuadre.de(geos)!;

    // Margen para que un vertice pegado al borde no quede cortado a la mitad,
    // y para que quepan la escala y la rosa del norte.
    const margen = 26.0;
    final lado = math.min(tamano.width, tamano.height) - margen * 2;
    final origen = Offset(
      (tamano.width - lado) / 2,
      (tamano.height - lado) / 2,
    );

    Offset aPantalla(PuntoGeo g) {
      final plano = encuadre.proyectar(g);
      return Offset(origen.dx + plano.x * lado, origen.dy + plano.y * lado);
    }

    final pantalla = [for (final g in geos) aPantalla(g)];

    if (pantalla.length > 1) {
      final camino = Path()..moveTo(pantalla.first.dx, pantalla.first.dy);
      for (final o in pantalla.skip(1)) {
        camino.lineTo(o.dx, o.dy);
      }
      if (cerrado && pantalla.length > 2) camino.close();

      if (cerrado && pantalla.length > 2) {
        lienzo.drawPath(camino, Paint()..color = relleno);
      }
      lienzo.drawPath(
        camino,
        Paint()
          ..color = trazo
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round,
      );
    }

    for (var i = 0; i < pantalla.length; i++) {
      final destacado = puntos[i].id == resaltado;
      final esPrimero = i == 0;
      // El primer punto se marca distinto: en un poligono es donde cierra el
      // anillo, y saber donde arranco es lo que permite entender la figura.
      lienzo
        ..drawCircle(
          pantalla[i],
          destacado ? 7.5 : (esPrimero ? 5.5 : 3.5),
          Paint()..color = esPrimero ? inicio : trazo,
        )
        ..drawCircle(
          pantalla[i],
          destacado ? 7.5 : (esPrimero ? 5.5 : 3.5),
          Paint()
            ..color = fondoTexto
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
    }

    _escala(lienzo, tamano, encuadre, lado);
    _norte(lienzo, tamano);
  }

  /// Barra de escala. Se calcula sobre el lado real del encuadre, asi que dice
  /// la verdad aunque el lote sea de 20 m o de 900.
  void _escala(Canvas lienzo, Size tamano, Encuadre encuadre, double lado) {
    final metrosPorPixel = encuadre.ladoM / (lado <= 0 ? 1 : lado);
    // Un numero redondo cercano a un cuarto del ancho: 10, 25, 50, 100...
    const objetivoPx = 70.0;
    final crudo = metrosPorPixel * objetivoPx;
    final escalones = [5, 10, 20, 25, 50, 100, 200, 250, 500, 1000];
    final metros = escalones.firstWhere(
      (m) => m >= crudo,
      orElse: () => escalones.last,
    );
    final anchoPx = metros / metrosPorPixel;

    final y = tamano.height - 14;
    final x0 = 14.0;
    final lapiz = Paint()
      ..color = tenue
      ..strokeWidth = 2;
    lienzo
      ..drawLine(Offset(x0, y), Offset(x0 + anchoPx, y), lapiz)
      ..drawLine(Offset(x0, y - 4), Offset(x0, y + 4), lapiz)
      ..drawLine(
        Offset(x0 + anchoPx, y - 4),
        Offset(x0 + anchoPx, y + 4),
        lapiz,
      );

    _texto(lienzo, '$metros m', Offset(x0, y - 20), tenue);
  }

  void _norte(Canvas lienzo, Size tamano) {
    final x = tamano.width - 22;
    const y = 20.0;
    final lapiz = Paint()
      ..color = tenue
      ..strokeWidth = 2;
    lienzo
      ..drawLine(Offset(x, y + 12), Offset(x, y - 6), lapiz)
      ..drawLine(Offset(x, y - 6), Offset(x - 4, y - 1), lapiz)
      ..drawLine(Offset(x, y - 6), Offset(x + 4, y - 1), lapiz);
    _texto(lienzo, 'N', Offset(x - 4, y + 14), tenue);
  }

  void _texto(Canvas lienzo, String texto, Offset donde, Color color) {
    TextPainter(
      text: TextSpan(
        text: texto,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: color),
      ),
      textDirection: TextDirection.ltr,
    )
      ..layout()
      ..paint(lienzo, donde);
  }

  @override
  bool shouldRepaint(_PintorCroquis viejo) =>
      viejo.puntos != puntos ||
      viejo.cerrado != cerrado ||
      viejo.resaltado != resaltado;
}
