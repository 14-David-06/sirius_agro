import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../core/servicio_grabacion.dart';
import '../data/visita_repository.dart';
import 'providers.dart';

/// Cada cuanto se cierra el tramo en curso y se abre el siguiente.
///
/// Esta es la respuesta concreta a "escribir el audio por tramos, no al final".
/// Un archivo AAC solo queda reproducible cuando el encoder lo cierra: si el
/// proceso muere a mitad de grabacion, ese archivo no se puede abrir. Cerrando
/// cada 5 minutos, lo maximo que se puede perder son los ultimos 5 minutos, y
/// todo lo anterior queda en disco, completo y ya encolado para subir.
///
/// Cinco minutos es un compromiso: mas corto multiplica archivos y llamadas a
/// la base; mas largo aumenta lo que se pierde en el peor caso.
const duracionTramo = Duration(minutes: 5);

/// Cada cuanto se revisa que el microfono siga realmente grabando.
const _intervaloVigilancia = Duration(seconds: 5);

class GrabacionState {
  const GrabacionState({
    this.grabando = false,
    this.pausada = false,
    this.segundos = 0,
    this.segundosTramo = 0,
    this.tramo = 0,
    this.servicioActivo = false,
    this.error,
    this.aviso,
  });

  final bool grabando;
  final bool pausada;

  /// Segundos acumulados de TODA la visita, no del tramo actual. Es el reloj
  /// que se usa para marcar el segundo de una foto o del consentimiento: si se
  /// reiniciara en cada tramo, las citas apuntarian al lugar equivocado.
  final int segundos;

  /// Segundos del tramo en curso. Solo sirve para saber cuando rotar.
  final int segundosTramo;

  /// Cuantos tramos se han cerrado o estan en curso.
  final int tramo;

  /// Si el servicio en primer plano esta corriendo. Si es false mientras se
  /// graba, la grabacion NO va a sobrevivir a la pantalla apagada.
  final bool servicioActivo;

  final String? error;

  /// Algo que el visitador deberia saber pero que no rompio nada: una llamada
  /// entrante que corto el tramo, una rotacion. Se muestra y se puede ignorar.
  final String? aviso;

  GrabacionState copyWith({
    bool? grabando,
    bool? pausada,
    int? segundos,
    int? segundosTramo,
    int? tramo,
    bool? servicioActivo,
    String? error,
    String? aviso,
    bool limpiarError = false,
    bool limpiarAviso = false,
  }) =>
      GrabacionState(
        grabando: grabando ?? this.grabando,
        pausada: pausada ?? this.pausada,
        segundos: segundos ?? this.segundos,
        segundosTramo: segundosTramo ?? this.segundosTramo,
        tramo: tramo ?? this.tramo,
        servicioActivo: servicioActivo ?? this.servicioActivo,
        error: limpiarError ? null : (error ?? this.error),
        aviso: limpiarAviso ? null : (aviso ?? this.aviso),
      );
}

final grabacionProvider =
    StateNotifierProvider.family<GrabacionController, GrabacionState, String>(
  (ref, visitaId) => GrabacionController(visitaId, ref.watch(repoProvider)),
);

/// Si el microfono esta tomado por la grabacion de la visita.
///
/// Existe aparte del estado completo para que quien solo necesita saber ESO
/// —la nota de voz del chat, por ejemplo— no tenga que despertar al grabador
/// entero con su microfono detras. En un test tampoco: se sobreescribe con un
/// bool y no hay plugin de audio de por medio.
final visitaGrabandoProvider = Provider.family<bool, String>(
  (ref, visitaId) =>
      ref.watch(grabacionProvider(visitaId).select((s) => s.grabando)),
);

class GrabacionController extends StateNotifier<GrabacionState> {
  GrabacionController(this.visitaId, this._repo)
      : super(const GrabacionState()) {
    _recuperar();
  }

  final String visitaId;
  final VisitaRepository _repo;
  final _recorder = AudioRecorder();

  Timer? _reloj;
  Timer? _vigilante;
  String? _pathActual;
  DateTime? _inicioTramo;

  /// Al abrir una visita, retoma la cuenta donde quedo y rescata los archivos
  /// que quedaron en disco sin registrar — lo que pasa si la app murio.
  Future<void> _recuperar() async {
    try {
      final rescatados = await _repo.rescatarTramosHuerfanos(visitaId);
      final tramos = await _repo.grabacionesDeVisita(visitaId);
      if (!mounted) return;

      state = state.copyWith(
        tramo: tramos.fold<int>(0, (max, g) => g.orden > max ? g.orden : max),
        segundos: tramos.fold<int>(0, (t, g) => t + g.duracionSeg),
        aviso: rescatados > 0
            ? 'Se recuperaron $rescatados tramo(s) que quedaron sin registrar.'
            : null,
      );
    } catch (_) {
      // Que falle la recuperacion no puede impedir grabar de nuevo.
    }
  }

  /// Arranca la grabacion: servicio en primer plano y primer tramo.
  ///
  /// El consentimiento se verifica aqui y no solo en la UI: si la regla vive
  /// unicamente en el boton, cualquier camino nuevo a esta pantalla la saltea.
  Future<void> iniciar() async {
    if (!await _repo.puedeGrabar(visitaId)) {
      state = state.copyWith(
        error: 'Falta el consentimiento para grabar audio.',
      );
      return;
    }

    if (!await _recorder.hasPermission()) {
      state = state.copyWith(error: 'Sin permiso de microfono.');
      return;
    }

    await ServicioGrabacion.iniciar(
      titulo: 'Grabando visita',
      texto: 'Toca para volver a la app.',
    );
    final servicio = await ServicioGrabacion.activo;

    final ok = await _abrirTramo();
    if (!ok) return;

    state = state.copyWith(
      grabando: true,
      pausada: false,
      servicioActivo: servicio,
      limpiarError: true,
    );
    _arrancarReloj();
    _arrancarVigilante();
  }

  /// Abre un archivo nuevo y empieza a escribir en el.
  Future<bool> _abrirTramo() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final carpeta = Directory('${dir.path}/visitas/$visitaId');
      await carpeta.create(recursive: true);

      final orden = state.tramo + 1;
      final path = '${carpeta.path}/tramo-$orden.m4a';

      // AAC mono a 32 kbps: ~14 MB por hora. Un tramo de 5 min pesa ~1,2 MB,
      // que la cola sube en dos o tres partes de 512 KB.
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 32000,
        sampleRate: 22050,
        numChannels: 1,
      );

      await _recorder.start(config, path: path);
      _pathActual = path;
      _inicioTramo = DateTime.now();
      state = state.copyWith(tramo: orden, segundosTramo: 0);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'No se pudo abrir el audio: $e');
      return false;
    }
  }

  /// Cierra el archivo en curso, lo registra y lo encola.
  ///
  /// Devuelve false si no quedo nada utilizable en disco, para que quien llame
  /// pueda avisar en vez de dar por hecho que el audio se guardo.
  Future<bool> _cerrarTramo() async {
    final path = await _recorder.stop() ?? _pathActual;
    if (path == null || path.isEmpty) return false;

    final archivo = File(path);
    if (!await archivo.exists()) return false;

    final bytes = await archivo.length();
    // Un archivo de pocos bytes es un encabezado sin audio: pasa cuando el
    // sistema corta el microfono al instante. Se borra en vez de encolar
    // basura que va a fallar en la transcripcion.
    if (bytes < 1024) {
      await archivo.delete();
      return false;
    }

    final inicio = _inicioTramo ?? DateTime.now();
    await _repo.registrarGrabacion(
      visitaId: visitaId,
      orden: state.tramo,
      archivoPath: path,
      inicio: inicio,
      duracionSeg: state.segundosTramo,
      tamanoBytes: bytes,
    );
    return true;
  }

  void _arrancarReloj() {
    _reloj?.cancel();
    _reloj = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (state.pausada || !state.grabando) return;

      state = state.copyWith(
        segundos: state.segundos + 1,
        segundosTramo: state.segundosTramo + 1,
      );

      // La notificacion se refresca cada 10 s, no cada segundo: actualizarla
      // sin parar gasta bateria y no aporta nada.
      if (state.segundos % 10 == 0) {
        await ServicioGrabacion.actualizar(
          titulo: 'Grabando visita · ${_reloj_(state.segundos)}',
          texto: 'Tramo ${state.tramo}. Toca para volver a la app.',
        );
      }

      if (state.segundosTramo >= duracionTramo.inSeconds) {
        await _rotar();
      }
    });
  }

  static String _reloj_(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }

  /// Cierra el tramo actual y abre el siguiente sin detener la visita.
  ///
  /// Hay un hueco de milisegundos entre `stop` y `start` en el que no se
  /// captura audio. Es el precio de tener archivos cerrados y reproducibles:
  /// perder una silaba cada 5 minutos es mucho mejor que perder media hora.
  Future<void> _rotar() async {
    await _cerrarTramo();
    final ok = await _abrirTramo();
    if (!ok) {
      _detenerRelojes();
      state = state.copyWith(grabando: false);
    }
  }

  /// Revisa que el microfono siga abierto de verdad.
  ///
  /// Una llamada entrante le quita el microfono a la app sin avisar: el estado
  /// interno sigue diciendo "grabando" mientras el archivo ya no crece. Sin
  /// esta vigilancia, el visitador conversa media hora creyendo que se esta
  /// grabando. Es la falla mas caras de todas, porque no se nota hasta que se
  /// va a buscar la cita que respalda un dato.
  void _arrancarVigilante() {
    _vigilante?.cancel();
    _vigilante = Timer.periodic(_intervaloVigilancia, (_) async {
      if (!state.grabando || state.pausada) return;

      final grabandoDeVerdad = await _recorder.isRecording();
      if (grabandoDeVerdad) return;

      // El sistema nos quito el microfono. Se rescata lo grabado y se intenta
      // retomar en un tramo nuevo.
      final rescatado = await _cerrarTramo();
      final reabierto = await _abrirTramo();

      if (!mounted) return;
      state = state.copyWith(
        grabando: reabierto,
        aviso: reabierto
            ? 'Se interrumpio la grabacion (¿una llamada?). '
                '${rescatado ? 'El audio anterior quedo guardado. ' : ''}'
                'Ya se retomo en un tramo nuevo.'
            : null,
        error: reabierto
            ? null
            : 'Se interrumpio la grabacion y no se pudo retomar. '
                'Toca «Seguir grabando».',
      );
      if (!reabierto) _detenerRelojes();
    });
  }

  Future<void> alternarPausa() async {
    if (!state.grabando) return;

    if (state.pausada) {
      await _recorder.resume();
      state = state.copyWith(pausada: false);
      await ServicioGrabacion.actualizar(
        titulo: 'Grabando visita',
        texto: 'Tramo ${state.tramo}. Toca para volver a la app.',
      );
    } else {
      await _recorder.pause();
      state = state.copyWith(pausada: true);
      await ServicioGrabacion.actualizar(
        titulo: 'Visita en pausa',
        texto: 'La grabacion esta detenida. Toca para reanudar.',
      );
    }
  }

  /// Cierra la grabacion de la visita: ultimo tramo y servicio abajo.
  Future<bool> detener() async {
    if (!state.grabando) return false;

    _detenerRelojes();
    final ok = await _cerrarTramo();
    await ServicioGrabacion.detener();

    if (!mounted) return ok;
    state = state.copyWith(
      grabando: false,
      pausada: false,
      servicioActivo: false,
      error: ok ? null : 'El ultimo tramo no quedo en disco.',
    );
    return ok;
  }

  void limpiarAviso() => state = state.copyWith(limpiarAviso: true);

  void _detenerRelojes() {
    _reloj?.cancel();
    _vigilante?.cancel();
  }

  @override
  void dispose() {
    _detenerRelojes();
    _recorder.dispose();
    super.dispose();
  }
}
