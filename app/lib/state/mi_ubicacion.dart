import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Hasta que edad sirve la ultima posicion que el telefono ya tenia.
///
/// Con ella el punto azul sale apenas abre el mapa, sin esperar a que el GPS
/// fije. Pero una de hace una hora puede ser la finca anterior, y un punto
/// azul en el lote equivocado es peor que ninguno.
const _ultimaConocidaVigente = Duration(minutes: 2);

/// Donde esta parado el visitador, en vivo, mientras haya un mapa mirandolo.
///
/// No pide permiso: si no lo hay o el GPS esta apagado, no emite nada y el
/// mapa queda como siempre. El permiso lo pide el boton de "mi ubicacion" (o
/// la captura del trazado), que es cuando el visitador sabe para que se lo
/// piden. Despues de darlo hay que invalidar este proveedor para que arranque.
///
/// Es `autoDispose`: al cerrar el mapa se suelta el GPS. Un flujo de
/// posiciones abierto es bateria, y en campo la bateria es el dia de trabajo.
final miUbicacionProvider = StreamProvider.autoDispose<Position>((ref) async* {
  if (!await Geolocator.isLocationServiceEnabled()) return;
  final permiso = await Geolocator.checkPermission();
  if (permiso == LocationPermission.denied ||
      permiso == LocationPermission.deniedForever ||
      permiso == LocationPermission.unableToDetermine) {
    return;
  }

  final ultima = await Geolocator.getLastKnownPosition();
  if (ultima != null &&
      DateTime.now().difference(ultima.timestamp) < _ultimaConocidaVigente) {
    yield ultima;
  }

  // `high` y no `best`: es para ubicarse en el mapa, no para medir el lindero
  // (eso lo hace la captura con su propia consulta). El filtro de 2 m evita
  // redibujar el mapa por el temblor del GPS con el visitador quieto.
  yield* Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 2,
    ),
  );
});
