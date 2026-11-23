import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/teselas.dart';

/// El satelite guardado en el telefono, para verlo sin senal.
///
/// Por que hace falta esto y no basta el cache de flutter_map: ese cache vive
/// en la carpeta de cache del sistema (Android la puede vaciar cuando quiera)
/// y respeta la vigencia que dice el servidor. Esri dice que una tesela vale
/// un dia (`max-age=86400`), y pasado ese dia flutter_map ya no la muestra si
/// no puede preguntarle al servidor. Resultado: el satelite que se vio ayer en
/// la oficina, hoy en la vereda sin senal, sale en blanco.
///
/// Aqui una tesela guardada se muestra siempre. La imagen satelital de una
/// vereda cambia cada varios anos, no cada dia.
///
/// Vive en la carpeta de soporte de la app (no en cache) y esta excluida del
/// respaldo de Android: ver `res/xml/backup_rules.xml`.
class AlmacenTeselas {
  AlmacenTeselas(this.raiz);

  final Directory raiz;

  static Future<AlmacenTeselas> abrir({String capa = 'satelite'}) async {
    final base = await getApplicationSupportDirectory();
    return AlmacenTeselas(Directory(p.join(base.path, 'mapas', capa)));
  }

  File _archivo(Tesela t) =>
      File(p.join(raiz.path, '${t.z}', '${t.x}', '${t.y}'));

  Future<bool> tiene(Tesela t) => _archivo(t).exists();

  Future<Uint8List?> leer(Tesela t) async {
    try {
      return await _archivo(t).readAsBytes();
    } on FileSystemException {
      return null;
    }
  }

  /// Escribe a un temporal y lo renombra: si la app muere a mitad de
  /// escritura no queda una tesela cortada que despues no se pueda leer.
  Future<void> guardar(Tesela t, Uint8List bytes) async {
    final destino = _archivo(t);
    await destino.parent.create(recursive: true);
    final temporal =
        File('${destino.path}.${DateTime.now().microsecondsSinceEpoch}.tmp');
    await temporal.writeAsBytes(bytes, flush: true);
    await temporal.rename(destino.path);
  }

  Future<void> borrar(Tesela t) async {
    try {
      await _archivo(t).delete();
    } on FileSystemException {
      // Ya no estaba: era lo que se queria.
    }
  }

  /// Cuanto hay guardado. Recorre la carpeta entera, asi que no es para
  /// llamarlo en cada cuadro.
  Future<({int teselas, int bytes})> medir() async {
    var teselas = 0;
    var bytes = 0;
    if (!await raiz.exists()) return (teselas: 0, bytes: 0);
    await for (final e in raiz.list(recursive: true, followLinks: false)) {
      if (e is File && !e.path.endsWith('.tmp')) {
        teselas++;
        bytes += await e.length();
      }
    }
    return (teselas: teselas, bytes: bytes);
  }
}

/// El servidor no contesto algo usable (ni imagen ni "no tengo imagen").
class FallaServidorSatelite implements Exception {
  const FallaServidorSatelite(this.motivo);
  final String motivo;

  @override
  String toString() => 'FallaServidorSatelite: $motivo';
}

/// La imagen satelital de Esri (World Imagery), pedida de modo que diga la
/// verdad cuando no tiene imagen.
///
/// Sin `blankTile=false`, donde Esri no tiene imagen devuelve un 200 con una
/// tesela gris que dice "Map data not yet available". Eso no se puede guardar:
/// quedaria en el telefono como si fuera el terreno. Con el parametro contesta
/// 404, y la app sabe que tiene que estirar una tesela de menos zoom.
class ServidorSatelite {
  ServidorSatelite({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Identifica la app ante el servidor, como piden los terminos de uso de los
  /// servicios publicos de teselas.
  static const agente = 'SiriusAgro (com.siriusregenerative.sirius_agro)';

  static Uri url(Tesela t) => Uri.parse(
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/'
        'MapServer/tile/${t.z}/${t.y}/${t.x}?blankTile=false',
      );

  /// Los bytes de la tesela, o `null` si Esri no tiene imagen ahi.
  ///
  /// Lanza si no hubo una respuesta que sirva (sin red, tiempo agotado, error
  /// del servidor): eso no dice nada del terreno y no se debe recordar.
  Future<Uint8List?> bajar(
    Tesela t, {
    Duration limite = const Duration(seconds: 10),
  }) async {
    final r = await _client
        .get(url(t), headers: const {'User-Agent': agente})
        .timeout(limite);
    if (r.statusCode == 404) return null;
    if (r.statusCode != 200) {
      throw FallaServidorSatelite('HTTP ${r.statusCode}');
    }
    final tipo = r.headers['content-type'] ?? '';
    if (r.bodyBytes.isEmpty || !tipo.startsWith('image/')) {
      throw FallaServidorSatelite('respuesta sin imagen ($tipo)');
    }
    return r.bodyBytes;
  }

  void cerrar() => _client.close();
}

/// Lo que el mapa puede mostrar para una tesela: la imagen exacta
/// ([niveles] = 0) o una madre de [niveles] zooms menos, de la que hay que
/// recortar la casilla ([columna], [fila]) y estirarla.
typedef ImagenTesela = ({
  Uint8List bytes,
  int niveles,
  int columna,
  int fila,
});

/// Hasta cuantos zooms hacia arriba se busca una madre para estirar. Seis
/// niveles es estirar 64 veces: ya no se ve el lote pero si el color del
/// terreno, que sigue siendo mejor que un cuadro vacio.
const nivelesMaximosHaciaArriba = 6;

/// Busca que mostrar para [t], en este orden:
///  1. lo guardado en el telefono (sirve con y sin senal);
///  2. si [intentarRed], el servidor, y lo que baje se guarda para la
///     proxima vez que no haya senal;
///  3. una madre guardada, para estirar.
///
/// Devuelve `null` solo si no hay nada de nada: ni guardado, ni red, ni madre.
Future<ImagenTesela?> buscarImagen(
  Tesela t, {
  required AlmacenTeselas almacen,
  required ServidorSatelite servidor,
  required bool intentarRed,
  Duration limite = const Duration(seconds: 8),
}) async {
  final guardada = await almacen.leer(t);
  if (guardada != null) {
    return (bytes: guardada, niveles: 0, columna: 0, fila: 0);
  }

  if (intentarRed) {
    try {
      final bajada = await servidor.bajar(t, limite: limite);
      if (bajada != null) {
        await almacen.guardar(t, bajada);
        return (bytes: bajada, niveles: 0, columna: 0, fila: 0);
      }
    } catch (_) {
      // Sin red o servidor caido: se sigue con lo que haya en el telefono.
    }
  }

  final tope = t.z < nivelesMaximosHaciaArriba ? t.z : nivelesMaximosHaciaArriba;
  for (var n = 1; n <= tope; n++) {
    final a = t.ancestro(n);
    final bytes = await almacen.leer(a.madre);
    if (bytes != null) {
      return (bytes: bytes, niveles: n, columna: a.columna, fila: a.fila);
    }
  }
  return null;
}

/// Como termino una descarga.
class ResultadoDescarga {
  const ResultadoDescarga({
    required this.total,
    required this.bajadas,
    required this.yaEstaban,
    required this.sinImagen,
    required this.fallidas,
    required this.cortada,
  });

  final int total;
  final int bajadas;
  final int yaEstaban;

  /// Esri no tiene imagen ahi (404). No es un error: no hay nada que bajar.
  final int sinImagen;
  final int fallidas;

  /// Se paro antes de terminar: se cancelo o se perdio la conexion.
  final bool cortada;

  int get hechas => bajadas + yaEstaban + sinImagen + fallidas;
}

/// Baja las [teselas] que falten en [almacen], de a [simultaneas] a la vez.
///
/// Pocas a la vez a proposito: es un servicio publico y gratuito, y bajar el
/// municipio de un tiron con cien conexiones es la forma de que bloqueen la
/// app. Con cuatro, la base del municipio baja en pocos minutos por wifi.
///
/// Si fallan [fallasParaCortar] seguidas se asume que se fue la conexion y se
/// para: seguir seria recorrer miles de teselas esperando un tiempo agotado
/// en cada una. Lo bajado queda guardado y la proxima corrida sigue de ahi,
/// porque lo que ya esta se salta.
Future<ResultadoDescarga> descargarTeselas(
  List<Tesela> teselas, {
  required AlmacenTeselas almacen,
  required ServidorSatelite servidor,
  void Function(int hechas, int total)? progreso,
  bool Function()? cancelada,
  int simultaneas = 4,
  int fallasParaCortar = 12,
}) async {
  var siguiente = 0;
  var bajadas = 0;
  var yaEstaban = 0;
  var sinImagen = 0;
  var fallidas = 0;
  var fallasSeguidas = 0;
  var cortada = false;

  void avisar() =>
      progreso?.call(bajadas + yaEstaban + sinImagen + fallidas, teselas.length);

  Future<void> trabajador() async {
    while (true) {
      if (cortada || (cancelada?.call() ?? false)) {
        cortada = true;
        return;
      }
      // Sin carreras: Dart corre en un solo hilo y entre el `if` y el `++` no
      // hay ningun `await`.
      if (siguiente >= teselas.length) return;
      final t = teselas[siguiente++];

      if (await almacen.tiene(t)) {
        yaEstaban++;
      } else {
        try {
          final bytes = await servidor.bajar(t);
          if (bytes == null) {
            sinImagen++;
          } else {
            await almacen.guardar(t, bytes);
            bajadas++;
          }
          fallasSeguidas = 0;
        } catch (_) {
          fallidas++;
          if (++fallasSeguidas >= fallasParaCortar) cortada = true;
        }
      }
      avisar();
    }
  }

  await Future.wait([for (var i = 0; i < simultaneas; i++) trabajador()]);

  return ResultadoDescarga(
    total: teselas.length,
    bajadas: bajadas,
    yaEstaban: yaEstaban,
    sinImagen: sinImagen,
    fallidas: fallidas,
    cortada: cortada,
  );
}
