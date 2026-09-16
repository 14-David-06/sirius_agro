import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'grabacion.dart';
import 'providers.dart';

/// Tope de una nota de voz suelta.
///
/// No es un limite tecnico sino de uso: esto es para decir una frase que
/// falto, no para grabar otra visita. Una nota larga tambien tarda mas en
/// transcribir, y el visitador esta esperando con el telefono en la mano.
const maxNotaVoz = Duration(minutes: 2);

/// Lo que la nota de voz necesita del microfono.
///
/// Es una interfaz y no el plugin directo para poder probar el controlador sin
/// microfono: en un test no hay permisos ni dispositivo de audio.
abstract class GrabadoraNota {
  Future<bool> tienePermiso();

  Future<void> iniciar(String path);

  /// Devuelve el archivo que quedo escrito, o null si no quedo nada.
  Future<String?> detener();

  Future<void> liberar();
}

/// La de verdad: el mismo plugin `record` que graba la visita.
///
/// Instancia propia y no la del grabador de la visita a proposito: son dos
/// grabaciones con vidas distintas, y compartir el objeto haria que detener la
/// nota cerrara el tramo de la conversacion.
class GrabadoraNotaRecord implements GrabadoraNota {
  final _recorder = AudioRecorder();

  @override
  Future<bool> tienePermiso() => _recorder.hasPermission();

  @override
  Future<void> iniciar(String path) => _recorder.start(
        // Mismo perfil que los tramos de la visita: es lo que el backend ya
        // sabe transcribir, y para voz de cerca alcanza de sobra.
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 32000,
          sampleRate: 22050,
          numChannels: 1,
        ),
        path: path,
      );

  @override
  Future<String?> detener() => _recorder.stop();

  @override
  Future<void> liberar() => _recorder.dispose();
}

/// Se sobreescribe en los tests con una grabadora falsa.
final grabadoraNotaProvider =
    Provider<GrabadoraNota>((ref) => GrabadoraNotaRecord());

class NotaVozState {
  const NotaVozState({
    this.grabando = false,
    this.transcribiendo = false,
    this.segundos = 0,
    this.error,
  });

  final bool grabando;

  /// El audio ya se cerro y esta viajando al servidor. Es un estado aparte de
  /// `grabando` porque la pantalla tiene que dejar de mostrar el reloj y
  /// empezar a mostrar que esta esperando: son dos esperas distintas y la
  /// segunda si necesita señal.
  final bool transcribiendo;

  final int segundos;

  final String? error;

  bool get ocupada => grabando || transcribiendo;
}

/// Una nota de voz para el chat de la visita.
///
/// Graba, la manda a transcribir y devuelve el texto. NO lo envia: el texto
/// cae en el campo de escribir para que el visitador lo lea antes de mandarlo.
///
/// Eso no es un detalle de comodidad. Lo que se manda por este chat entra
/// directo al registro de la visita, y una palabra mal transcrita en un numero
/// —«seiscientos» por «setecientos»— quedaria como dato sin que nadie la haya
/// leido. El paso por el campo de texto es donde se atrapa.
///
/// El audio no se guarda: se borra apenas vuelve la transcripcion. La
/// procedencia de lo que entra por aca ya la lleva el propio chat —cada dato
/// queda como `Manual`, del visitador, con la frase con que lo dijo— y
/// conservar el archivo agregaria una cola de subida para algo que no es
/// evidencia de nada.
class NotaVozController extends StateNotifier<NotaVozState> {
  NotaVozController(this._ref, this.visitaId)
      : _grabadora = _ref.read(grabadoraNotaProvider),
        super(const NotaVozState());

  final Ref _ref;
  final String visitaId;

  /// Se toma al construir y no en cada uso: `dispose` tiene que poder soltar
  /// el microfono cuando el contenedor ya se esta yendo, y ahi leer un
  /// provider ya no es legal.
  final GrabadoraNota _grabadora;

  Timer? _reloj;
  String? _path;

  Future<void> iniciar() async {
    if (state.ocupada) return;

    // El microfono en Android es exclusivo: abrirlo aca en medio de una visita
    // le arranca el microfono al grabador y corta la conversacion. Es el mismo
    // motivo por el que la camara de la app no usa la del sistema.
    if (_ref.read(visitaGrabandoProvider(visitaId))) {
      state = const NotaVozState(
        error: 'Se esta grabando la visita. Detene la grabacion antes de '
            'dictar una nota.',
      );
      return;
    }

    if (!await _grabadora.tienePermiso()) {
      state = const NotaVozState(error: 'Sin permiso de microfono.');
      return;
    }

    try {
      final dir = await getTemporaryDirectory();
      final path = p.join(
        dir.path,
        'nota-$visitaId-${DateTime.now().millisecondsSinceEpoch}.m4a',
      );
      await _grabadora.iniciar(path);
      _path = path;
    } catch (e) {
      state = NotaVozState(error: 'No se pudo abrir el microfono: $e');
      return;
    }

    state = const NotaVozState(grabando: true);
    _reloj = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final segundos = state.segundos + 1;
      // El tope se aplica solo: si el visitador se olvida del telefono
      // abierto, la nota se cierra y se transcribe en vez de crecer sin
      // limite. Se corta, no se descarta — lo que ya dijo sirve.
      if (segundos >= maxNotaVoz.inSeconds) {
        unawaited(detenerYTranscribir());
        return;
      }
      state = NotaVozState(grabando: true, segundos: segundos);
    });
  }

  /// Cierra la nota, la transcribe y devuelve el texto. Null si algo fallo o
  /// si no se entendio nada.
  Future<String?> detenerYTranscribir() async {
    if (!state.grabando) return null;
    _pararReloj();

    final path = await _cerrar();
    if (path == null) {
      state = const NotaVozState(error: 'No quedo audio de la nota.');
      return null;
    }

    final archivo = File(path);
    state = const NotaVozState(transcribiendo: true);
    try {
      final bytes = await archivo.readAsBytes();
      if (bytes.isEmpty) {
        state = const NotaVozState(error: 'La nota quedo vacia.');
        return null;
      }

      // Los mismos terminos que se le pasan al audio de la visita: el apellido
      // del productor y su vereda son justo lo que un motor generico escribe
      // mal, y aca se dictan nombres tanto como en la conversacion.
      final terminos =
          await _ref.read(repoProvider).terminosDeVisita(visitaId);

      final resultado = await _ref.read(apiProvider).transcribir(
            audio: bytes,
            filename: p.basename(path),
            terminos: terminos,
            // Habla una sola persona: separar voces no aporta nada y el
            // texto llega mas limpio, sin marcas de hablante que despues
            // habria que quitarle al campo de escribir.
            diarizar: false,
          );

      final texto = resultado.texto.trim();
      if (texto.isEmpty) {
        state = const NotaVozState(
          error: 'No se entendio nada en la nota. Proba de nuevo mas cerca.',
        );
        return null;
      }

      state = const NotaVozState();
      return texto;
    } catch (e) {
      state = NotaVozState(error: _mensaje(e));
      return null;
    } finally {
      // El audio no sobrevive al turno, pase lo que pase. Se espera y no se
      // lanza al aire: cuando esto devuelve, el temporal ya no esta.
      await _borrar(archivo);
    }
  }

  /// Tira la nota sin transcribirla.
  Future<void> descartar() async {
    if (!state.grabando) return;
    _pararReloj();
    final path = await _cerrar();
    if (path != null) await _borrar(File(path));
    state = const NotaVozState();
  }

  Future<String?> _cerrar() async {
    try {
      return await _grabadora.detener() ?? _path;
    } catch (_) {
      return _path;
    } finally {
      _path = null;
    }
  }

  Future<void> _borrar(File archivo) async {
    try {
      if (await archivo.exists()) await archivo.delete();
    } catch (_) {
      // Es un temporal: que quede no rompe nada.
    }
  }

  /// La transcripcion necesita señal, y en campo no siempre la hay. El mensaje
  /// tiene que decir que hacer, no el codigo HTTP.
  String _mensaje(Object e) {
    final texto = '$e';
    if (e is SocketException ||
        texto.contains('SocketException') ||
        texto.contains('Failed host lookup')) {
      return 'Sin señal para transcribir la nota. Podes escribirla a mano.';
    }
    return 'No se pudo transcribir la nota: $texto';
  }

  void limpiarError() {
    if (state.error == null) return;
    state = const NotaVozState();
  }

  void _pararReloj() {
    _reloj?.cancel();
    _reloj = null;
  }

  @override
  void dispose() {
    _pararReloj();
    final path = _path;
    if (path != null) unawaited(_borrar(File(path)));
    unawaited(_grabadora.liberar());
    super.dispose();
  }
}

final notaVozProvider =
    StateNotifierProvider.family<NotaVozController, NotaVozState, String>(
  (ref, visitaId) => NotaVozController(ref, visitaId),
);
