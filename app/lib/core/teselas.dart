import 'dart:math' as math;

/// Una tesela del mapa en el esquema XYZ, el mismo de OSM y de Esri: zoom,
/// columna (de oeste a este) y fila (de norte a sur).
///
/// Es la unidad de todo el mapa sin senal: lo que se baja, lo que se guarda en
/// disco y lo que el mapa pide son teselas.
class Tesela {
  const Tesela(this.z, this.x, this.y);

  final int z;
  final int x;
  final int y;

  /// La tesela de [niveles] zooms mas arriba que contiene a esta, y en que
  /// casilla de ella cae. A [niveles] = 2 la madre se parte en 4x4 casillas y
  /// [columna] y [fila] van de 0 a 3.
  ///
  /// Es lo que permite mostrar algo sin senal cuando la tesela exacta no se
  /// bajo: se estira el pedazo que le toca de una madre que si esta guardada.
  ({Tesela madre, int columna, int fila}) ancestro(int niveles) {
    assert(niveles > 0 && niveles <= z);
    final madre = Tesela(z - niveles, x >> niveles, y >> niveles);
    final mascara = (1 << niveles) - 1;
    return (madre: madre, columna: x & mascara, fila: y & mascara);
  }

  @override
  bool operator ==(Object other) =>
      other is Tesela && other.z == z && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(z, x, y);

  @override
  String toString() => '$z/$x/$y';
}

/// La tesela que contiene un punto a un zoom dado (proyeccion Web Mercator).
Tesela teselaDe(double latitud, double longitud, int z) {
  final n = 1 << z;
  final lat = latitud * math.pi / 180;
  final x = ((longitud + 180) / 360 * n).floor();
  final y = ((1 - math.log(math.tan(lat) + 1 / math.cos(lat)) / math.pi) / 2 * n)
      .floor();
  return Tesela(z, x.clamp(0, n - 1), y.clamp(0, n - 1));
}

/// Un rectangulo en grados. Es como se dice "esta zona" para bajarla.
class Caja {
  const Caja({
    required this.sur,
    required this.norte,
    required this.oeste,
    required this.este,
  });

  /// La caja que encierra un circulo de [radioM] metros alrededor del punto.
  factory Caja.alrededor(double latitud, double longitud, double radioM) {
    const metrosPorGrado = 111320.0;
    final dLat = radioM / metrosPorGrado;
    final dLon = radioM / (metrosPorGrado * math.cos(latitud * math.pi / 180));
    return Caja(
      sur: latitud - dLat,
      norte: latitud + dLat,
      oeste: longitud - dLon,
      este: longitud + dLon,
    );
  }

  final double sur;
  final double norte;
  final double oeste;
  final double este;

  /// Las teselas que cubren la caja en cada zoom de [zMin] a [zMax], de la
  /// mas general a la mas detallada.
  Iterable<Tesela> teselas(int zMin, int zMax) sync* {
    for (var z = zMin; z <= zMax; z++) {
      final noroeste = teselaDe(norte, oeste, z);
      final sureste = teselaDe(sur, este, z);
      for (var x = noroeste.x; x <= sureste.x; x++) {
        for (var y = noroeste.y; y <= sureste.y; y++) {
          yield Tesela(z, x, y);
        }
      }
    }
  }

  /// Cuantas teselas son, sin generarlas.
  int contar(int zMin, int zMax) {
    var total = 0;
    for (var z = zMin; z <= zMax; z++) {
      final noroeste = teselaDe(norte, oeste, z);
      final sureste = teselaDe(sur, este, z);
      total += (sureste.x - noroeste.x + 1) * (sureste.y - noroeste.y + 1);
    }
    return total;
  }
}

/// Barranca de Upia, Meta: el limite del municipio segun OpenStreetMap
/// (Nominatim, noviembre de 2026). Todas las veredas de la semilla estan aqui.
const zonaBarrancaDeUpia = Caja(
  sur: 4.3542903,
  norte: 4.7372077,
  oeste: -73.0915699,
  este: -72.8434032,
);

/// Hasta que zoom se baja el municipio entero. A z16 una tesela cubre unos
/// 600 m y se ve el potrero, la ronda del cano y el cultivo, a unos 2,4 m por
/// pixel. Con eso todo el municipio son ~4.400 teselas y ~43 MB, medido.
/// Un zoom mas cuadruplica la cuenta (z17: ~12.800 y ~115 MB), y por eso el
/// detalle fino se baja solo donde hay fincas.
const zoomMaximoBase = 16;
const zoomMinimoBase = 10;

/// El detalle fino alrededor de cada finca o visita con coordenada: hasta z18,
/// que es lo maximo que Esri tiene en la zona.
const zoomMaximoDetalle = 18;

/// Desde donde se baja el detalle de un punto. Por debajo de z12 la zona base
/// ya lo cubre todo; si el punto queda fuera del municipio, esto le da algo
/// de contexto sin bajar media Colombia.
const zoomMinimoDetalle = 12;

/// Radio del detalle fino alrededor de cada punto. 700 m cubren la finca
/// tipica de la zona con margen (una caja de 1,4 km de lado, ~200 ha) y
/// cuestan ~170 teselas, unos 1,4 MB por finca.
const radioDetalleM = 700.0;

/// Que bajar para que el satelite se vea sin senal, en el orden en que
/// conviene bajarlo.
///
/// El orden importa porque una descarga puede cortarse a la mitad (se va el
/// wifi, cierran la app): primero lo general del municipio, que es poco y lo
/// cubre todo; luego el detalle de las fincas, que es donde se trabaja; y al
/// final el z16 del municipio, que es lo mas pesado de la base. Asi lo que
/// quede bajado a medias siempre sirve.
///
/// [puntos] son las coordenadas conocidas: fincas y llegadas de visitas. Se
/// repiten mucho (varias visitas a la misma finca) y la lista no las duplica.
List<Tesela> planDescarga({
  required Caja zonaBase,
  required Iterable<({double latitud, double longitud})> puntos,
}) {
  // Un literal de conjunto en Dart conserva el orden de insercion.
  final plan = <Tesela>{};
  plan.addAll(zonaBase.teselas(zoomMinimoBase, zoomMaximoBase - 1));

  // Dos visitas a 20 m una de otra piden el mismo detalle: se agrupan por la
  // tesela z16 en que caen y se baja una vez por grupo.
  final vistos = <Tesela>{};
  for (final p in puntos) {
    if (!vistos.add(teselaDe(p.latitud, p.longitud, 16))) continue;
    plan.addAll(
      Caja.alrededor(p.latitud, p.longitud, radioDetalleM)
          .teselas(zoomMinimoDetalle, zoomMaximoDetalle),
    );
  }

  plan.addAll(zonaBase.teselas(zoomMaximoBase, zoomMaximoBase));
  return plan.toList();
}
