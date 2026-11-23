import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';

import '../core/teselas.dart';
import '../data/mapa_sin_senal.dart';

/// Las teselas del satelite para flutter_map, leyendo primero del telefono.
///
/// Reemplaza al `NetworkTileProvider` solo en la capa satelital. La diferencia
/// que se ve en campo: sin senal muestra lo guardado, y donde no hay la tesela
/// exacta estira una de menos zoom en vez de dejar un cuadro vacio.
class ProveedorSatelite extends TileProvider {
  ProveedorSatelite({
    required this.almacen,
    required this.servidor,
    required this.intentarRed,
  });

  final Future<AlmacenTeselas> almacen;
  final ServidorSatelite servidor;

  /// Se consulta en cada tesela y no una vez: la senal de una vereda va y
  /// viene mientras el mapa esta abierto.
  final bool Function() intentarRed;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      _TeselaSatelite(Tesela(coordinates.z, coordinates.x, coordinates.y), this);

  // Nada que cerrar: el cliente HTTP es de la app, no de esta capa, y
  // flutter_map llama a esto cada vez que la capa se quita de la pantalla.
  @override
  void dispose() {}
}

class _TeselaSatelite extends ImageProvider<_TeselaSatelite> {
  const _TeselaSatelite(this.tesela, this.proveedor);

  final Tesela tesela;
  final ProveedorSatelite proveedor;

  @override
  Future<_TeselaSatelite> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  /// Por fuera de la cache de imagenes de Flutter, a proposito.
  ///
  /// Esa cache recuerda lo que cargo una vez con la misma llave, y aqui la
  /// misma tesela puede salir estirada (sin senal) y un minuto despues exacta
  /// (volvio la senal): con cache seguiria saliendo borrosa toda la sesion. La
  /// cache que importa es la del disco, y leer de ahi toma milisegundos.
  @override
  void resolveStreamForKey(
    ImageConfiguration configuration,
    ImageStream stream,
    _TeselaSatelite key,
    ImageErrorListener handleError,
  ) {
    if (stream.completer != null) return;
    stream.setCompleter(
      loadImage(key, PaintingBinding.instance.instantiateImageCodecWithSize),
    );
  }

  @override
  ImageStreamCompleter loadImage(
    _TeselaSatelite key,
    ImageDecoderCallback decode,
  ) =>
      MultiFrameImageStreamCompleter(codec: _cargar(decode), scale: 1);

  Future<ui.Codec> _cargar(ImageDecoderCallback decode) async {
    final almacen = await proveedor.almacen;
    final imagen = await buscarImagen(
      tesela,
      almacen: almacen,
      servidor: proveedor.servidor,
      intentarRed: proveedor.intentarRed(),
    );
    if (imagen == null) {
      throw StateError('Sin imagen guardada ni senal para la tesela $tesela');
    }

    if (imagen.niveles == 0) {
      try {
        return await decode(await ui.ImmutableBuffer.fromUint8List(imagen.bytes));
      } catch (_) {
        // Un archivo danado no se arregla solo: se borra para que la proxima
        // vez con senal se vuelva a bajar.
        await almacen.borrar(tesela);
        rethrow;
      }
    }

    return estirar(imagen, decode);
  }

  @override
  bool operator ==(Object other) =>
      other is _TeselaSatelite && other.tesela == tesela;

  @override
  int get hashCode => tesela.hashCode;
}

/// Recorta de la madre la casilla que le toca y la agranda al tamano de una
/// tesela. Sale borroso —es la misma imagen de menos zoom, mas grande— pero
/// es el terreno que es, en el lugar que es.
Future<ui.Codec> estirar(ImagenTesela imagen, ImageDecoderCallback decode) async {
  final codecMadre =
      await decode(await ui.ImmutableBuffer.fromUint8List(imagen.bytes));
  final madre = (await codecMadre.getNextFrame()).image;
  codecMadre.dispose();

  final partes = 1 << imagen.niveles;
  final ancho = madre.width / partes;
  final alto = madre.height / partes;
  final lado = madre.width;

  final grabadora = ui.PictureRecorder();
  Canvas(grabadora).drawImageRect(
    madre,
    Rect.fromLTWH(imagen.columna * ancho, imagen.fila * alto, ancho, alto),
    Rect.fromLTWH(0, 0, lado.toDouble(), lado.toDouble()),
    Paint()..filterQuality = FilterQuality.medium,
  );
  final recorte = await grabadora.endRecording().toImage(lado, lado);
  madre.dispose();

  final png = await recorte.toByteData(format: ui.ImageByteFormat.png);
  recorte.dispose();
  return decode(
    await ui.ImmutableBuffer.fromUint8List(Uint8List.sublistView(png!)),
  );
}
