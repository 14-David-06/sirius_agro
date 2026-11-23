import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/teselas.dart';
import '../data/db/app_database.dart';
import '../data/mapa_sin_senal.dart';
import 'providers.dart';
import 'red.dart';

/// Cuantas teselas se dejan bajar de una vez con el boton del mapa. Son unos
/// 25 MB: lo que se le puede gastar a un plan de datos sin preguntar dos
/// veces. Si la zona en pantalla pide mas, se baja con menos detalle y se le
/// dice al visitador que acerque el mapa.
const maximoTeselasZona = 3000;

class EstadoMapaSinSenal {
  const EstadoMapaSinSenal({
    this.trabajando = false,
    this.manual = false,
    this.hechas = 0,
    this.total = 0,
    this.mensaje,
  });

  final bool trabajando;

  /// La pidio el visitador con el boton, y no la descarga automatica: solo
  /// esa merece un aviso en pantalla al terminar.
  final bool manual;
  final int hechas;
  final int total;

  /// Como termino la ultima descarga, en una linea para el visitador.
  final String? mensaje;

  double? get avance => total == 0 ? null : hechas / total;
}

/// Tiene el satelite guardado al dia, para que se vea sin senal.
///
/// Dos formas de bajar:
///  - Automatica, solo con wifi: el municipio entero hasta z16 y el detalle
///    fino alrededor de cada finca y cada visita con coordenada. No se hace
///    con datos moviles porque son decenas de megas y el plan es del
///    visitador, igual que la sincronizacion, que tampoco arranca sola.
///  - Manual, con el boton del mapa: la zona que el visitador esta mirando.
///    Ahi si vale con datos moviles, porque lo decidio el.
///
/// Ademas, todo lo que se mira con senal queda guardado solo (ver
/// [buscarImagen]): un lote revisado en la oficina se ve despues en campo.
class MapaSinSenal extends StateNotifier<EstadoMapaSinSenal> {
  MapaSinSenal(
    this._db,
    this._servidor,
    this._almacen, {
    Connectivity? connectivity,
  })  : _connectivity = connectivity ?? Connectivity(),
        super(const EstadoMapaSinSenal());

  final AppDatabase _db;
  final ServidorSatelite _servidor;
  final Future<AlmacenTeselas> _almacen;
  final Connectivity _connectivity;

  /// La automatica corre una vez por sesion de la app. Si se corta (se fue el
  /// wifi), queda pendiente y vuelve a intentar cuando regrese la conexion.
  bool _automaticaCompleta = false;
  bool _cancelar = false;

  Future<bool> _hayWifi() async {
    final redes = await _connectivity.checkConnectivity();
    return redes.contains(ConnectivityResult.wifi) ||
        redes.contains(ConnectivityResult.ethernet);
  }

  /// Coordenadas conocidas: fincas y llegadas de visitas.
  Future<List<({double latitud, double longitud})>> puntosConocidos() async {
    final fincas = await (_db.select(_db.fincas)
          ..where((f) => f.latitud.isNotNull() & f.longitud.isNotNull()))
        .get();
    final visitas = await (_db.select(_db.visitas)
          ..where((v) => v.latitud.isNotNull() & v.longitud.isNotNull()))
        .get();
    return [
      for (final f in fincas)
        if (_valida(f.latitud!, f.longitud!))
          (latitud: f.latitud!, longitud: f.longitud!),
      for (final v in visitas)
        if (_valida(v.latitud!, v.longitud!))
          (latitud: v.latitud!, longitud: v.longitud!),
    ];
  }

  /// (0, 0) es lo que deja un GPS que no fijo: el Atlantico frente a Africa.
  static bool _valida(double lat, double lon) =>
      !(lat == 0 && lon == 0) && lat.abs() <= 85 && lon.abs() <= 180;

  /// La descarga de fondo. Se llama cada vez que vuelve la conexion; ella
  /// misma decide si toca.
  Future<void> automatica() async {
    if (state.trabajando || _automaticaCompleta) return;
    if (!await _hayWifi()) return;

    final plan = planDescarga(
      zonaBase: zonaBarrancaDeUpia,
      puntos: await puntosConocidos(),
    );
    final r = await _descargar(plan, manual: false);
    if (r != null && !r.cortada) _automaticaCompleta = true;
  }

  /// Guarda la zona que el visitador tiene en pantalla, con un margen.
  Future<void> guardarZona(Caja visible) async {
    if (state.trabajando) return;
    final redes = await _connectivity.checkConnectivity();
    if (redes.every((r) => r == ConnectivityResult.none)) {
      state = const EstadoMapaSinSenal(
        manual: true,
        mensaje: 'Sin senal no se puede bajar el mapa. Guardalo donde haya '
            'senal o wifi, antes de salir a la finca.',
      );
      return;
    }

    final zona = _conMargen(visible, 0.25);
    var zMax = zoomMaximoDetalle;
    while (zMax > zoomMinimoDetalle &&
        zona.contar(zoomMinimoDetalle, zMax) > maximoTeselasZona) {
      zMax--;
    }
    await _descargar(
      zona.teselas(zoomMinimoDetalle, zMax).toList(),
      manual: true,
      mensajeListo: zMax < zoomMaximoDetalle
          ? 'Zona guardada, pero sin el maximo detalle porque es muy grande. '
              'Acerca el mapa al lote y vuelve a guardar.'
          : 'Zona guardada: se puede ver sin senal.',
    );
  }

  void cancelar() => _cancelar = true;

  Future<ResultadoDescarga?> _descargar(
    List<Tesela> teselas, {
    required bool manual,
    String mensajeListo = 'Mapa guardado para verlo sin senal.',
  }) async {
    _cancelar = false;
    state = EstadoMapaSinSenal(
      trabajando: true,
      manual: manual,
      total: teselas.length,
    );

    try {
      final r = await descargarTeselas(
        teselas,
        almacen: await _almacen,
        servidor: _servidor,
        cancelada: () => _cancelar || !mounted,
        progreso: (hechas, total) {
          // Un aviso cada 20 teselas: la barra se mueve igual y la pantalla
          // no se redibuja miles de veces.
          if (mounted && (hechas % 20 == 0 || hechas == total)) {
            state = EstadoMapaSinSenal(
              trabajando: true,
              manual: manual,
              hechas: hechas,
              total: total,
            );
          }
        },
      );
      if (mounted) {
        state = EstadoMapaSinSenal(
          manual: manual,
          hechas: r.hechas,
          total: r.total,
          mensaje: r.cortada
              ? 'Se corto la descarga del mapa (${r.hechas} de ${r.total}). '
                  'Lo bajado quedo guardado; sigue cuando vuelva la conexion.'
              : mensajeListo,
        );
      }
      return r;
    } catch (e) {
      if (mounted) {
        state = EstadoMapaSinSenal(
          manual: manual,
          mensaje: 'No se pudo guardar el mapa: $e',
        );
      }
      return null;
    }
  }

  static Caja _conMargen(Caja c, double fraccion) {
    final dLat = (c.norte - c.sur) * fraccion;
    final dLon = (c.este - c.oeste) * fraccion;
    return Caja(
      sur: c.sur - dLat,
      norte: c.norte + dLat,
      oeste: c.oeste - dLon,
      este: c.este + dLon,
    );
  }
}

final servidorSateliteProvider = Provider<ServidorSatelite>((ref) {
  final servidor = ServidorSatelite();
  ref.onDispose(servidor.cerrar);
  return servidor;
});

final almacenSateliteProvider =
    Provider<Future<AlmacenTeselas>>((ref) => AlmacenTeselas.abrir());

final mapaSinSenalProvider =
    StateNotifierProvider<MapaSinSenal, EstadoMapaSinSenal>(
  (ref) => MapaSinSenal(
    ref.watch(dbProvider),
    ref.watch(servidorSateliteProvider),
    ref.watch(almacenSateliteProvider),
  ),
);

/// Arranca la descarga automatica cada vez que la app recupera la conexion.
///
/// No devuelve nada a proposito: quien la vigila (la pantalla de visitas) no
/// se redibuja con el avance de la descarga, solo la mantiene viva.
final precargaMapasProvider = Provider<void>((ref) {
  ref.listen<EstadoRed>(
    redProvider,
    (_, red) {
      if (red == EstadoRed.enLinea) {
        ref.read(mapaSinSenalProvider.notifier).automatica();
      }
    },
    fireImmediately: true,
  );
});
