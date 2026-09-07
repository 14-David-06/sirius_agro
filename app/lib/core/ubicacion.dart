import 'package:geolocator/geolocator.dart';

/// El acceso al GPS, en un solo lugar.
///
/// Lo piden dos cosas con expectativas distintas: la pantalla de nueva visita
/// (una coordenada al llegar a la finca) y la captura de trazados (una
/// coordenada cada pocos segundos mientras se camina el lote). Tener el mismo
/// manejo de permisos en las dos evita el caso feo: que el trazado falle
/// callado porque alguien nego el permiso en una pantalla que ni recuerda.

/// Mensajes de error en el idioma del visitador, no del sistema. Se muestran
/// tal cual en pantalla.
class ErrorUbicacion implements Exception {
  const ErrorUbicacion(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Pide el permiso si hace falta. Lanza [ErrorUbicacion] si no lo hay.
Future<void> asegurarPermisoUbicacion() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw const ErrorUbicacion(
      'La ubicacion del telefono esta apagada. Prendela y volve a intentar.',
    );
  }

  var permiso = await Geolocator.checkPermission();
  if (permiso == LocationPermission.denied) {
    permiso = await Geolocator.requestPermission();
  }
  if (permiso == LocationPermission.denied) {
    throw const ErrorUbicacion('Sin permiso de ubicacion.');
  }
  if (permiso == LocationPermission.deniedForever) {
    throw const ErrorUbicacion(
      'El permiso de ubicacion quedo negado para siempre. Hay que habilitarlo '
      'en los ajustes del telefono.',
    );
  }
}

/// Una coordenada, con la mejor precision que el telefono pueda dar en
/// [limite].
///
/// La precision se pide `best` y no `high`: la diferencia se paga en bateria y
/// en segundos, y aca se esta dibujando el lindero de una finca. Para la
/// coordenada de llegada `high` alcanzaba; para un poligono, cada metro de
/// error es area que despues se traduce en dosis de insumo.
Future<Position> ubicacionActual({
  Duration limite = const Duration(seconds: 20),
  LocationAccuracy precision = LocationAccuracy.best,
}) async {
  await asegurarPermisoUbicacion();
  return Geolocator.getCurrentPosition(
    locationSettings: LocationSettings(accuracy: precision, timeLimit: limite),
  );
}
