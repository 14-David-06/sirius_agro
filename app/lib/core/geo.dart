import 'dart:math' as math;

/// Geometria sobre la esfera, sin dependencias de Flutter ni de la base.
///
/// Vive aparte porque es lo unico de la funcion de trazados que se puede
/// probar sin telefono y sin GPS: si el area de un lote sale mal, el error
/// esta aca y una prueba unitaria lo caza.

/// Radio ecuatorial WGS84. Es el mismo que usa Google Earth para calcular
/// areas, y eso importa: el KML que sale de la app se abre alli, y dos
/// numeros distintos para el mismo poligono hacen dudar de los dos.
const double radioTierraM = 6378137.0;

double _rad(double grados) => grados * math.pi / 180.0;

/// Un punto capturado, sin metadatos. Lo que necesita la geometria y nada mas.
class PuntoGeo {
  const PuntoGeo(this.latitud, this.longitud);

  final double latitud;
  final double longitud;

  @override
  String toString() =>
      '${latitud.toStringAsFixed(6)}, ${longitud.toStringAsFixed(6)}';
}

/// Distancia entre dos puntos por haversine.
///
/// Se usa para el filtro de distancia minima durante la captura automatica,
/// donde los tramos son de metros. A esa escala la diferencia con una formula
/// elipsoidal es de centimetros — muy por debajo del error del GPS de un
/// telefono, que en campo abierto anda entre 3 y 10 m.
double distanciaMetros(PuntoGeo a, PuntoGeo b) {
  final dLat = _rad(b.latitud - a.latitud);
  final dLon = _rad(b.longitud - a.longitud);
  final lat1 = _rad(a.latitud);
  final lat2 = _rad(b.latitud);

  final h = math.pow(math.sin(dLat / 2), 2) +
      math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLon / 2), 2);
  return 2 * radioTierraM * math.asin(math.min(1.0, math.sqrt(h)));
}

/// Largo del recorrido. Con [cerrado] suma el tramo del ultimo punto al
/// primero, que es lo que convierte un largo en un perimetro.
double longitudMetros(List<PuntoGeo> puntos, {bool cerrado = false}) {
  if (puntos.length < 2) return 0;
  var total = 0.0;
  for (var i = 0; i < puntos.length - 1; i++) {
    total += distanciaMetros(puntos[i], puntos[i + 1]);
  }
  if (cerrado) total += distanciaMetros(puntos.last, puntos.first);
  return total;
}

/// Area del poligono en metros cuadrados, por excedente esferico.
///
/// No es la formula plana del zapatero: un lote de 40 ha medido con
/// coordenadas geograficas tratadas como si fueran cartesianas se equivoca
/// por el achatamiento del grado de longitud. Esta es la misma que usa
/// `SphericalUtil.computeArea` de Google Maps, asi que el numero que muestra
/// la app coincide con el que da Google Earth sobre el KML exportado.
///
/// El anillo se cierra solo: no hace falta repetir el primer punto al final.
/// Devuelve 0 con menos de tres puntos — un area de dos puntos no existe, y
/// devolver algo distinto de 0 seria inventarle superficie a un lote.
double areaM2(List<PuntoGeo> puntos) {
  final anillo = _sinCierreDuplicado(puntos);
  if (anillo.length < 3) return 0;

  var total = 0.0;
  for (var i = 0; i < anillo.length; i++) {
    final p1 = anillo[i];
    final p2 = anillo[(i + 1) % anillo.length];
    total += (_rad(p2.longitud) - _rad(p1.longitud)) *
        (2 + math.sin(_rad(p1.latitud)) + math.sin(_rad(p2.latitud)));
  }

  // El valor absoluto borra el sentido del recorrido: caminar el lote en
  // contra del reloj no puede dar area negativa.
  return (total * radioTierraM * radioTierraM / 2.0).abs();
}

double areaHectareas(List<PuntoGeo> puntos) => areaM2(puntos) / 10000.0;

/// Quita el punto final si repite el primero. Un KML cierra el anillo
/// repitiendolo, pero sumarlo dos veces en el perimetro agrega un tramo de
/// cero y en el area agrega un vertice degenerado.
List<PuntoGeo> _sinCierreDuplicado(List<PuntoGeo> puntos) {
  if (puntos.length > 1 &&
      puntos.first.latitud == puntos.last.latitud &&
      puntos.first.longitud == puntos.last.longitud) {
    return puntos.sublist(0, puntos.length - 1);
  }
  return puntos;
}

/// Centro del encuadre. Es lo que se usa para la etiqueta del lote en el KML:
/// Google Earth pone el nombre donde uno le diga, y en el centro del poligono
/// es donde se lee.
PuntoGeo? centro(List<PuntoGeo> puntos) {
  if (puntos.isEmpty) return null;
  final e = Encuadre.de(puntos)!;
  return PuntoGeo((e.latMin + e.latMax) / 2, (e.lonMin + e.lonMax) / 2);
}

/// Coordenada dentro del croquis, en el rango 0..1. `y` crece hacia abajo,
/// como en una pantalla.
class PuntoPlano {
  const PuntoPlano(this.x, this.y);

  final double x;
  final double y;
}

/// La caja que contiene todos los puntos, y la proyeccion al croquis.
///
/// El croquis existe porque la app tiene que poder dibujar el lote SIN RED:
/// un mapa de verdad necesita descargar teselas, y en la vereda no hay de
/// donde. Un croquis con la forma real, la escala y el norte alcanza para lo
/// unico que se necesita en campo: confirmar que el poligono cerro bien y que
/// ningun punto quedo disparado por un salto del GPS.
class Encuadre {
  Encuadre._(this.latMin, this.latMax, this.lonMin, this.lonMax);

  final double latMin;
  final double latMax;
  final double lonMin;
  final double lonMax;

  static Encuadre? de(List<PuntoGeo> puntos) {
    if (puntos.isEmpty) return null;
    var latMin = puntos.first.latitud;
    var latMax = latMin;
    var lonMin = puntos.first.longitud;
    var lonMax = lonMin;
    for (final p in puntos) {
      latMin = math.min(latMin, p.latitud);
      latMax = math.max(latMax, p.latitud);
      lonMin = math.min(lonMin, p.longitud);
      lonMax = math.max(lonMax, p.longitud);
    }
    return Encuadre._(latMin, latMax, lonMin, lonMax);
  }

  double get latCentro => (latMin + latMax) / 2;
  double get lonCentro => (lonMin + lonMax) / 2;

  /// Cuanto mide el grado de longitud a esta latitud, comparado con el de
  /// latitud. En Barranca de Upia (4.5 N) es 0.997: casi uno, pero aplicarlo
  /// es lo que evita que un lote cuadrado se vea rectangular.
  double get _achatamiento => math.cos(_rad(latCentro)).abs();

  double get anchoM => distanciaMetros(
        PuntoGeo(latCentro, lonMin),
        PuntoGeo(latCentro, lonMax),
      );

  double get altoM => distanciaMetros(
        PuntoGeo(latMin, lonCentro),
        PuntoGeo(latMax, lonCentro),
      );

  /// Lado del cuadrado que hay que dibujar, en grados de latitud. Se toma el
  /// mayor de los dos ejes para que la figura entre completa, y nunca 0: un
  /// solo punto capturado tiene que poder dibujarse igual.
  double get _lado {
    final ancho = (lonMax - lonMin) * _achatamiento;
    final alto = latMax - latMin;
    final mayor = math.max(ancho, alto);
    return mayor <= 0 ? 1e-7 : mayor;
  }

  /// Metros que representa el lado del croquis. Alimenta la barra de escala:
  /// sin ella el croquis no dice si el lote tiene 30 m o 300.
  double get ladoM => math.max(math.max(anchoM, altoM), 1.0);

  /// El resultado esta en 0..1 por construccion — el lado del cuadro es el
  /// mayor de los dos ejes. El recorte solo absorbe el ruido de coma flotante:
  /// un punto en el borde exacto sale como -9,9e-14 y el pintor no tiene por
  /// que saber de eso.
  PuntoPlano proyectar(PuntoGeo p) => PuntoPlano(
        (0.5 + ((p.longitud - lonCentro) * _achatamiento) / _lado)
            .clamp(0.0, 1.0),
        (0.5 - (p.latitud - latCentro) / _lado).clamp(0.0, 1.0),
      );
}

/// «1,4 ha» / «820 m²». Debajo de media hectarea la hectarea no comunica: un
/// almacigo de 300 m² leido como «0,03 ha» no le dice nada a nadie.
String formatearArea(double m2) {
  if (m2 <= 0) return '—';
  if (m2 < 5000) return '${m2.round()} m²';
  final ha = m2 / 10000;
  return '${ha.toStringAsFixed(ha < 10 ? 2 : 1).replaceAll('.', ',')} ha';
}

String formatearDistancia(double metros) {
  if (metros <= 0) return '—';
  if (metros < 1000) return '${metros.round()} m';
  return '${(metros / 1000).toStringAsFixed(2).replaceAll('.', ',')} km';
}
