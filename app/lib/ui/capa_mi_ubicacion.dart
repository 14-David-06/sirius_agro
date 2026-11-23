import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../state/mi_ubicacion.dart';

/// El azul de "usted esta aca". Se sale de la paleta de la marca a proposito:
/// es el color que todo el mundo ya lee asi en cualquier mapa del telefono, y
/// no se confunde con el verde del trazado ni con el primer punto.
const _azul = Color(0xFF1A73E8);

/// Mas alla de esto el circulo de precision tapa el lote entero y no dice
/// nada: con ese error el punto azul tampoco, pero al menos no estorba.
const _precisionMaximaDibujada = 150.0;

/// Las capas de la posicion del visitador, para ponerlas dentro de un
/// [FlutterMap]: el circulo de lo que el GPS no sabe y, encima, el punto.
///
/// Son dos capas y no una porque flutter_map apila cada hijo como capa aparte
/// y el circulo va en metros (crece con el zoom) mientras el punto va en
/// pixeles (mide lo mismo siempre). Cada una mira la posicion por su cuenta:
/// asi el mapa de abajo no se redibuja entero con cada lectura del GPS.
List<Widget> capasMiUbicacion() => const [_CirculoPrecision(), _PuntoAzul()];

class _CirculoPrecision extends ConsumerWidget {
  const _CirculoPrecision();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pos = ref.watch(miUbicacionProvider).valueOrNull;
    if (pos == null || pos.accuracy <= 0) return const SizedBox.shrink();
    return CircleLayer(
      circles: [
        CircleMarker(
          point: LatLng(pos.latitude, pos.longitude),
          radius: pos.accuracy.clamp(0, _precisionMaximaDibujada).toDouble(),
          useRadiusInMeter: true,
          color: _azul.withValues(alpha: 0.15),
          borderColor: _azul.withValues(alpha: 0.45),
          borderStrokeWidth: 1,
        ),
      ],
    );
  }
}

class _PuntoAzul extends ConsumerWidget {
  const _PuntoAzul();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pos = ref.watch(miUbicacionProvider).valueOrNull;
    if (pos == null) return const SizedBox.shrink();
    return MarkerLayer(
      markers: [
        Marker(
          point: LatLng(pos.latitude, pos.longitude),
          width: 22,
          height: 22,
          child: Container(
            decoration: BoxDecoration(
              color: _azul,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
