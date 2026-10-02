import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/asistencia_repository.dart';
import '../data/db/app_database.dart';
import 'nota_voz.dart';
import 'providers.dart';
import 'sincronizador.dart';

// ------------------------------------------------------------- nota de voz

class NotaAsistenciaState {
  const NotaAsistenciaState({
    this.grabando = false,
    this.segundos = 0,
    this.path,
    this.error,
  });

  final bool grabando;
  final int segundos;

  /// El audio ya cerrado, en un temporal. Null mientras no haya nota.
  final String? path;
  final String? error;

  bool get tieneNota => path != null && !grabando;
}

/// La nota de voz del registro de asistencia: ahi la persona dice sus datos.
///
/// En el telefono solo se graba. No se transcribe ni se procesa: eso hacia
/// lento el registro en el taller, con veinte personas haciendo fila. La nota
/// se guarda con el registro y el backend la procesa cuando hay red.
///
/// Usa la misma [GrabadoraNota] (y por eso el mismo perfil de audio) que el
/// chat, para que los tests la reemplacen igual.
class NotaAsistenciaController extends StateNotifier<NotaAsistenciaState> {
  NotaAsistenciaController(this._grabadora)
    : super(const NotaAsistenciaState());

  final GrabadoraNota _grabadora;
  Timer? _reloj;
  String? _grabandoEn;

  Future<void> iniciar() async {
    if (state.grabando) return;
    if (!await _grabadora.tienePermiso()) {
      state = const NotaAsistenciaState(error: 'Sin permiso de microfono.');
      return;
    }

    // Grabar de nuevo reemplaza la nota anterior.
    await _borrar(state.path);

    try {
      final dir = await getTemporaryDirectory();
      final path = p.join(
        dir.path,
        'asistencia-nota-${DateTime.now().millisecondsSinceEpoch}.m4a',
      );
      await _grabadora.iniciar(path);
      _grabandoEn = path;
    } catch (e) {
      state = NotaAsistenciaState(
        error:
            'No se pudo abrir el microfono. Si hay una visita grabando, '
            'detenela primero. ($e)',
      );
      return;
    }

    state = const NotaAsistenciaState(grabando: true);
    _reloj = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final segundos = state.segundos + 1;
      // Mismo tope que la nota del chat: se corta y se conserva lo dicho.
      if (segundos >= maxNotaVoz.inSeconds) {
        unawaited(detener());
        return;
      }
      state = NotaAsistenciaState(grabando: true, segundos: segundos);
    });
  }

  Future<void> detener() async {
    if (!state.grabando) return;
    _pararReloj();
    final segundos = state.segundos;
    String? path;
    try {
      path = await _grabadora.detener() ?? _grabandoEn;
    } catch (_) {
      path = _grabandoEn;
    } finally {
      _grabandoEn = null;
    }

    if (path == null ||
        !await File(path).exists() ||
        await File(path).length() == 0) {
      state = const NotaAsistenciaState(error: 'La nota quedo vacia.');
      return;
    }
    state = NotaAsistenciaState(path: path, segundos: segundos);
  }

  Future<void> descartar() async {
    if (state.grabando) {
      _pararReloj();
      try {
        await _grabadora.detener();
      } catch (_) {}
      await _borrar(_grabandoEn);
      _grabandoEn = null;
    } else {
      await _borrar(state.path);
    }
    state = const NotaAsistenciaState();
  }

  /// El registro ya copio el archivo a su carpeta: el temporal deja de ser
  /// de este controlador y no hay que borrarlo al salir.
  void entregada() {
    state = const NotaAsistenciaState();
  }

  Future<void> _borrar(String? path) async {
    if (path == null) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  void _pararReloj() {
    _reloj?.cancel();
    _reloj = null;
  }

  @override
  void dispose() {
    _pararReloj();
    // Salir sin enviar no deja audio huerfano en el telefono.
    unawaited(_borrar(_grabandoEn ?? state.path));
    unawaited(_grabadora.liberar());
    super.dispose();
  }
}

/// autoDispose: el microfono se suelta en cuanto se cierra el formulario.
final notaAsistenciaProvider =
    StateNotifierProvider.autoDispose<
      NotaAsistenciaController,
      NotaAsistenciaState
    >((ref) => NotaAsistenciaController(ref.read(grabadoraNotaProvider)));

// ------------------------------------------------------------------ subida

class SubidaAsistenciasState {
  const SubidaAsistenciasState({this.trabajando = false, this.mensaje});

  final bool trabajando;
  final String? mensaje;
}

/// Sube los registros de asistencia pendientes, y solo esos.
///
/// A diferencia de la visita, esto si arranca solo cuando vuelve la red: un
/// registro pesa medio mega como mucho y el coordinador lo espera el mismo
/// dia. Lo que no hace es arrastrar la cola de las visitas — el audio de una
/// conversacion de media hora sigue esperando a que el visitador lo pida.
class SubidaAsistenciasController
    extends StateNotifier<SubidaAsistenciasState> {
  SubidaAsistenciasController(this._sync, this._repo)
      : super(const SubidaAsistenciasState());

  final Sincronizador _sync;
  final AsistenciaRepository _repo;

  Future<void> subir() async {
    if (state.trabajando) return;
    state = const SubidaAsistenciasState(trabajando: true);

    final subidos = await _sync.procesar(entidad: entidadAsistencia);
    final pendientes = await _repo.pendientes();
    final fallidos =
        pendientes.where((q) => q.estado == EstadoSync.fallida).toList();

    if (!mounted) return;
    state = SubidaAsistenciasState(
      mensaje: switch ((pendientes.length, fallidos.length)) {
        (0, _) when subidos == 0 => 'No habia registros por subir.',
        (0, _) => subidos == 1
            ? '1 registro subido a Airtable.'
            : '$subidos registros subidos a Airtable.',
        (_, 0) => '${pendientes.length} pendiente(s), se reintentan solos.',
        _ => '${fallidos.length} con error: '
            '${fallidos.first.ultimoError ?? "sin detalle"}',
      },
    );
  }
}

final subidaAsistenciasProvider = StateNotifierProvider<
    SubidaAsistenciasController, SubidaAsistenciasState>(
  (ref) => SubidaAsistenciasController(
    ref.watch(sincronizadorProvider),
    ref.watch(asistenciaRepoProvider),
  ),
);

/// Ids de los registros que siguen en la cola, para pintar cada fila.
final asistenciasPendientesProvider = StreamProvider<List<SyncItem>>(
  (ref) => ref.watch(asistenciaRepoProvider).observarPendientes(),
);
