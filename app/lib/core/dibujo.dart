import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'geo.dart';

/// La geometria de dibujar un lote con el dedo sobre el mapa.
///
/// Vive aparte de la pantalla porque es lo que decide que tan fiel queda el
/// lote dibujado, y eso tiene que poder probarse sin un telefono: un trazo de
/// pincel trae cientos de posiciones del dedo, y guardarlas todas daria un
/// lote con 600 vertices encimados que nadie puede revisar ni corregir.

/// Un vertice dibujado sobre el mapa, con la herramienta que lo puso.
///
/// La herramienta viaja hasta el punto guardado como su nota: un lindero
/// dibujado con el dedo sobre la foto satelital no se mide igual que uno
/// caminado con GPS, y quien lo revise despues tiene que poder saberlo.
typedef VerticeDibujado = ({double latitud, double longitud, bool conPincel});

/// La nota de un punto que salio de un trazo de pincel.
const notaPincel = 'dibujado con pincel en el mapa';

/// La nota de un punto puesto con un toque sobre el mapa. Es la misma que ya
/// usaba la pantalla del trazado al tocar el mapa, para que los dos caminos se
/// lean igual.
const notaToque = 'marcado en el mapa';

/// Cuantos pixeles se puede mover el borde al simplificar un trazo. Tres es
/// menos que el grosor de la linea que se ve en pantalla: lo que se quita es
/// el temblor del dedo, no la forma.
const toleranciaTrazoPx = 3.0;

/// Tope de vertices de un lote dibujado con pincel. Mas que esto no agrega
/// forma visible a la escala en que se dibuja y vuelve ilegible la lista de
/// puntos.
const maximoVerticesTrazo = 150;

/// Douglas-Peucker sobre las posiciones del dedo, en pixeles de pantalla.
///
/// Se simplifica en pantalla y no en grados porque la tolerancia que importa
/// es la que se ve: a zoom 18 tres pixeles son medio metro, a zoom 14 son
/// ocho. Lo que el visitador no pudo distinguir al dibujar no es forma.
List<Offset> simplificarTrazo(
  List<Offset> puntos, {
  double tolerancia = toleranciaTrazoPx,
}) {
  if (puntos.length < 3) return List.of(puntos);

  final conservar = List<bool>.filled(puntos.length, false);
  conservar[0] = true;
  conservar[puntos.length - 1] = true;

  // Iterativo y no recursivo: un trazo largo y tembloroso puede tener miles
  // de posiciones, y la recursion se come la pila en un telefono modesto.
  final pendientes = <(int, int)>[(0, puntos.length - 1)];
  while (pendientes.isNotEmpty) {
    final (inicio, fin) = pendientes.removeLast();
    var mayor = 0.0;
    var indice = -1;
    for (var i = inicio + 1; i < fin; i++) {
      final d = _distanciaASegmento(puntos[i], puntos[inicio], puntos[fin]);
      if (d > mayor) {
        mayor = d;
        indice = i;
      }
    }
    if (indice != -1 && mayor > tolerancia) {
      conservar[indice] = true;
      pendientes
        ..add((inicio, indice))
        ..add((indice, fin));
    }
  }

  return [
    for (var i = 0; i < puntos.length; i++)
      if (conservar[i]) puntos[i],
  ];
}

/// El trazo listo para guardarse: simplificado y con a lo sumo [maximo]
/// vertices.
///
/// Si con la tolerancia normal quedan demasiados, se va subiendo hasta que
/// quepan: un contorno muy largo dibujado de lejos tiene mas detalle del que
/// cabe, y es mejor perder el temblor que cortar el lote a la mitad.
///
/// En un poligono ([cerrado]) se quita el ultimo punto si cae encima del
/// primero: el dedo termina donde empezo, y repetir el vertice le pondria al
/// anillo un lado de largo cero.
List<Offset> prepararTrazo(
  List<Offset> crudo, {
  required bool cerrado,
  double tolerancia = toleranciaTrazoPx,
  int maximo = maximoVerticesTrazo,
}) {
  final sinRepetidos = <Offset>[];
  for (final p in crudo) {
    if (sinRepetidos.isEmpty || (sinRepetidos.last - p).distance > 0.5) {
      sinRepetidos.add(p);
    }
  }

  var tol = tolerancia;
  var resultado = simplificarTrazo(sinRepetidos, tolerancia: tol);
  while (resultado.length > maximo) {
    tol *= 1.5;
    resultado = simplificarTrazo(sinRepetidos, tolerancia: tol);
  }

  if (cerrado &&
      resultado.length > 3 &&
      (resultado.last - resultado.first).distance <= math.max(tol * 4, 12)) {
    resultado = resultado.sublist(0, resultado.length - 1);
  }
  return resultado;
}

/// Si el contorno se cruza consigo mismo.
///
/// Un ocho no es un lote: su area con la formula del poligono resta un lado
/// del otro y da un numero que no corresponde a nada. Pasa sobre todo con el
/// pincel, cuando el dedo vuelve a entrar al lote para cerrar. No se corrige
/// sola —no hay forma de saber cual de las dos figuras queria el visitador—
/// pero se le dice antes de guardar.
bool seCruza(List<PuntoGeo> puntos, {required bool cerrado}) {
  final n = puntos.length;
  if (n < 4) return false;

  final lados = cerrado ? n : n - 1;
  for (var i = 0; i < lados; i++) {
    final a1 = puntos[i];
    final a2 = puntos[(i + 1) % n];
    for (var j = i + 1; j < lados; j++) {
      // Los lados vecinos comparten un vertice: tocarse ahi no es cruzarse.
      if (j == i + 1) continue;
      if (cerrado && i == 0 && j == n - 1) continue;
      final b1 = puntos[j];
      final b2 = puntos[(j + 1) % n];
      if (_segmentosSeCortan(a1, a2, b1, b2)) return true;
    }
  }
  return false;
}

double _distanciaASegmento(Offset p, Offset a, Offset b) {
  final ab = b - a;
  final largo2 = ab.dx * ab.dx + ab.dy * ab.dy;
  if (largo2 == 0) return (p - a).distance;
  final t = (((p.dx - a.dx) * ab.dx + (p.dy - a.dy) * ab.dy) / largo2).clamp(
    0.0,
    1.0,
  );
  final proyeccion = Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);
  return (p - proyeccion).distance;
}

/// Corte propio de dos segmentos, en grados. A la escala de un lote la
/// curvatura no cambia de que lado cae un punto, asi que no hace falta
/// proyectar.
bool _segmentosSeCortan(PuntoGeo a, PuntoGeo b, PuntoGeo c, PuntoGeo d) {
  final o1 = _orientacion(a, b, c);
  final o2 = _orientacion(a, b, d);
  final o3 = _orientacion(c, d, a);
  final o4 = _orientacion(c, d, b);
  return o1 * o2 < 0 && o3 * o4 < 0;
}

double _orientacion(PuntoGeo p, PuntoGeo q, PuntoGeo r) =>
    (q.longitud - p.longitud) * (r.latitud - p.latitud) -
    (q.latitud - p.latitud) * (r.longitud - p.longitud);
