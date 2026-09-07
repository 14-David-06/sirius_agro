import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/ubicacion.dart';
import '../data/db/app_database.dart';
import '../data/trazado_repository.dart';
import 'providers.dart';

/// Lo que la pantalla necesita saber de la captura en curso.
///
/// Los tres contadores no son estadistica: son la respuesta a «¿esto esta
/// funcionando?» estando parado en el lote. Un intervalo de 10 s que llevo 6
/// puntos y descarto 14 por cercania esta trabajando bien — el visitador se
/// quedo hablando. Uno que descarto 20 por precision esta diciendo que bajo
/// los arboles no hay señal y que hay que salir al claro.
class CapturaState {
  const CapturaState({
    this.capturando = false,
    this.buscandoGps = false,
    this.agregados = 0,
    this.descartadosCerca = 0,
    this.descartadosPrecision = 0,
    this.precisionUltima,
    this.ultimoIntentoEn,
    this.error,
    this.aviso,
  });

  final bool capturando;

  /// Hay una consulta al GPS en vuelo. Se muestra para que un toque en
  /// «Marcar punto» no parezca perdido: fijar posicion tarda segundos.
  final bool buscandoGps;

  final int agregados;
  final int descartadosCerca;
  final int descartadosPrecision;

  /// Precision del ultimo punto que llego del GPS, entrara o no. Es el numero
  /// que dice si vale la pena marcar el lindero ahora o esperar un minuto.
  final double? precisionUltima;

  final DateTime? ultimoIntentoEn;
  final String? error;
  final String? aviso;

  int get descartados => descartadosCerca + descartadosPrecision;

  CapturaState copyWith({
    bool? capturando,
    bool? buscandoGps,
    int? agregados,
    int? descartadosCerca,
    int? descartadosPrecision,
    double? precisionUltima,
    DateTime? ultimoIntentoEn,
    String? error,
    String? aviso,
    bool limpiarError = false,
    bool limpiarAviso = false,
  }) =>
      CapturaState(
        capturando: capturando ?? this.capturando,
        buscandoGps: buscandoGps ?? this.buscandoGps,
        agregados: agregados ?? this.agregados,
        descartadosCerca: descartadosCerca ?? this.descartadosCerca,
        descartadosPrecision:
            descartadosPrecision ?? this.descartadosPrecision,
        precisionUltima: precisionUltima ?? this.precisionUltima,
        ultimoIntentoEn: ultimoIntentoEn ?? this.ultimoIntentoEn,
        error: limpiarError ? null : (error ?? this.error),
        aviso: limpiarAviso ? null : (aviso ?? this.aviso),
      );
}

/// El que pone los puntos.
///
/// Dos modos y ninguno automatico por defecto: hasta que el visitador toque
/// «Empezar», este objeto no habla con el GPS. La funcion entera se diseño
/// para que capturar sea una decision explicita — la app no anda registrando
/// por donde camina la gente.
class CapturaTrazado extends StateNotifier<CapturaState> {
  CapturaTrazado(this._repo, this._trazadoId) : super(const CapturaState());

  final TrazadoRepository _repo;
  final String _trazadoId;

  Timer? _reloj;

  /// Evita que dos consultas al GPS se pisen. Con intervalo de 5 s y un
  /// telefono que tarda 8 en fijar, sin esto se encolan peticiones y el
  /// contador salta de tres en tres.
  bool _enVuelo = false;

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  void limpiarAviso() => state = state.copyWith(limpiarAviso: true);
  void limpiarError() => state = state.copyWith(limpiarError: true);

  /// Un punto, ahora, porque el visitador esta parado donde quiere el vertice.
  ///
  /// No pasa por los filtros: ver [TrazadoRepository.agregarPunto]. Si la
  /// precision viene mala se avisa, pero el punto entra — quien esta en la
  /// esquina del lote es el.
  Future<void> marcarPunto({String? nota}) async {
    if (state.buscandoGps) return;
    state = state.copyWith(buscandoGps: true, limpiarError: true);

    try {
      final pos = await ubicacionActual();
      await _repo.agregarPunto(
        trazadoId: _trazadoId,
        latitud: pos.latitude,
        longitud: pos.longitude,
        altitud: pos.altitude,
        precisionM: pos.accuracy,
        automatico: false,
        nota: nota,
      );

      state = state.copyWith(
        buscandoGps: false,
        agregados: state.agregados + 1,
        precisionUltima: pos.accuracy,
        ultimoIntentoEn: DateTime.now(),
        aviso: pos.accuracy > 15
            ? 'El punto entro, pero el GPS reporto ${pos.accuracy.round()} m '
                'de error. Si el lindero importa, vale la pena repetirlo.'
            : null,
      );
    } on ErrorUbicacion catch (e) {
      state = state.copyWith(buscandoGps: false, error: e.mensaje);
    } catch (e) {
      state = state.copyWith(
        buscandoGps: false,
        error: 'No se pudo fijar la posicion: $e',
      );
    }
  }

  /// Arranca el reloj. [intervaloSeg] ya viene guardado en el trazado; se pasa
  /// aparte para no volver a leer la fila en cada arranque.
  Future<void> iniciar(int intervaloSeg) async {
    if (state.capturando) return;
    final intervalo = intervaloSeg < 3 ? 3 : intervaloSeg;

    // El permiso se resuelve ANTES de prender el reloj: arrancar y fallar en
    // cada tic dejaria al visitador caminando el lote entero creyendo que
    // captura.
    try {
      await asegurarPermisoUbicacion();
    } on ErrorUbicacion catch (e) {
      state = state.copyWith(error: e.mensaje);
      return;
    }

    state = state.copyWith(capturando: true, limpiarError: true);
    _reloj = Timer.periodic(Duration(seconds: intervalo), (_) => _tic(intervalo));
    // El primer punto va de inmediato: esperar el primer intervalo hace que
    // «Empezar» se sienta roto.
    await _tic(intervalo);
  }

  Future<void> _tic(int intervalo) async {
    if (_enVuelo || !state.capturando) return;
    _enVuelo = true;
    state = state.copyWith(buscandoGps: true);

    try {
      // El limite se queda por debajo del intervalo para que una consulta
      // colgada no se coma el tic siguiente.
      final pos = await ubicacionActual(
        limite: Duration(seconds: (intervalo * 2).clamp(8, 30)),
      );
      final resultado = await _repo.agregarPunto(
        trazadoId: _trazadoId,
        latitud: pos.latitude,
        longitud: pos.longitude,
        altitud: pos.altitude,
        precisionM: pos.accuracy,
        automatico: true,
      );

      state = state.copyWith(
        buscandoGps: false,
        precisionUltima: pos.accuracy,
        ultimoIntentoEn: DateTime.now(),
        agregados: resultado == ResultadoPunto.agregado
            ? state.agregados + 1
            : state.agregados,
        descartadosCerca: resultado == ResultadoPunto.muyCerca
            ? state.descartadosCerca + 1
            : state.descartadosCerca,
        descartadosPrecision: resultado == ResultadoPunto.precisionInsuficiente
            ? state.descartadosPrecision + 1
            : state.descartadosPrecision,
      );
    } on ErrorUbicacion catch (e) {
      // Perder el permiso a mitad del recorrido SI detiene la captura: seguir
      // con el reloj andando y sin puntos es mentirle a la pantalla.
      _reloj?.cancel();
      state = state.copyWith(
        capturando: false,
        buscandoGps: false,
        error: e.mensaje,
      );
    } catch (e) {
      // Un timeout suelto NO detiene nada: en la finca el GPS se pierde bajo
      // los arboles y vuelve al salir al claro. Se cuenta y se sigue.
      state = state.copyWith(
        buscandoGps: false,
        ultimoIntentoEn: DateTime.now(),
        aviso: 'Un punto no se pudo tomar (sin señal de GPS). El recorrido '
            'sigue.',
      );
    } finally {
      _enVuelo = false;
    }
  }

  /// Detiene el reloj. Los puntos ya capturados no se tocan: parar no es
  /// deshacer.
  void detener() {
    _reloj?.cancel();
    _reloj = null;
    state = state.copyWith(capturando: false, buscandoGps: false);
  }

  Future<void> deshacerUltimo() async {
    await _repo.deshacerUltimoPunto(_trazadoId);
    state = state.copyWith(
      agregados: state.agregados > 0 ? state.agregados - 1 : 0,
    );
  }
}

/// Uno por trazado: dos lotes se pueden estar capturando en la misma visita, y
/// el estado de uno no puede contaminar al otro.
final capturaProvider =
    StateNotifierProvider.family<CapturaTrazado, CapturaState, String>(
  (ref, trazadoId) =>
      CapturaTrazado(ref.watch(trazadoRepoProvider), trazadoId),
);

final trazadosProvider =
    StreamProvider.family<List<Trazado>, String>((ref, visitaId) {
  return ref.watch(dbProvider).observarTrazados(visitaId);
});

final trazadoProvider =
    StreamProvider.family<Trazado?, String>((ref, trazadoId) {
  final db = ref.watch(dbProvider);
  return (db.select(db.trazados)..where((t) => t.id.equals(trazadoId)))
      .watchSingleOrNull();
});

final puntosTrazadoProvider =
    StreamProvider.family<List<PuntoTrazado>, String>((ref, trazadoId) {
  return ref.watch(dbProvider).observarPuntos(trazadoId);
});
