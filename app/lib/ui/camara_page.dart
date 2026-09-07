import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../state/grabacion.dart';
import '../state/providers.dart';
import 'galeria_fotos.dart';
import 'theme.dart';

/// Camara dentro de la app, no la del sistema.
///
/// La razon es una sola y es la que importa: `enableAudio: false`. La camara
/// del sistema abre el microfono para poder grabar video, y en Android el
/// microfono es exclusivo — abrirla en medio de una visita le arranca el
/// microfono al grabador y corta la conversacion. Con la camara propia y el
/// audio deshabilitado, la grabacion sigue corriendo mientras se fotografia.
///
/// Tampoco se sale de la pantalla de la visita ni se detiene nada: se toman
/// varias fotos seguidas y se vuelve. El reloj de arriba sigue avanzando.
class CamaraPage extends ConsumerStatefulWidget {
  const CamaraPage({super.key, required this.visitaId}) : retrato = false;

  /// La foto de perfil del agricultor.
  ///
  /// Es la misma camara —con el mismo `enableAudio: false`, que es lo que
  /// permite fotografiar sin cortar la grabacion— con tres diferencias: mira
  /// hacia adelante, se toma UNA y se vuelve, y la foto no entra a
  /// `Evidencias` sino a la ficha del productor.
  const CamaraPage.retrato({super.key, required this.visitaId})
      : retrato = true;

  final String visitaId;
  final bool retrato;

  @override
  ConsumerState<CamaraPage> createState() => _CamaraPageState();
}

class _CamaraPageState extends ConsumerState<CamaraPage> {
  CameraController? _camara;
  String? _error;
  bool _tomando = false;
  int _tomadas = 0;

  @override
  void initState() {
    super.initState();
    _abrirCamara();
  }

  @override
  void dispose() {
    _camara?.dispose();
    super.dispose();
  }

  Future<void> _abrirCamara() async {
    try {
      final camaras = await availableCameras();
      if (camaras.isEmpty) throw 'El telefono no reporta camaras.';

      // Para el retrato, la frontal: el visitador esta del otro lado del
      // telefono y no puede ver el encuadre de la cara del agricultor si la
      // camara apunta al contrario. Si el equipo no tiene frontal, se usa la
      // que haya y se encuadra al reves, que es peor pero no impide la foto.
      final lente = widget.retrato
          ? CameraLensDirection.front
          : CameraLensDirection.back;
      final elegida = camaras.firstWhere(
        (c) => c.lensDirection == lente,
        orElse: () => camaras.first,
      );

      final ctrl = CameraController(
        elegida,
        // medium (~720p) da fotos de 200-400 KB. Suficiente para leer una
        // etiqueta y para que la cola las suba desde una vereda sin senal.
        ResolutionPreset.medium,
        // LA linea que hace que esto funcione: sin audio, la camara no le
        // pide el microfono al sistema y la grabacion no se interrumpe.
        enableAudio: false,
      );

      await ctrl.initialize();
      if (!mounted) {
        await ctrl.dispose();
        return;
      }
      setState(() => _camara = ctrl);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _tomar() async {
    final camara = _camara;
    if (camara == null || _tomando) return;
    setState(() => _tomando = true);

    try {
      final foto = await camara.takePicture();

      if (widget.retrato) {
        await _guardarRetrato(foto);
        return;
      }

      // El segundo del audio en el momento del disparo. Es lo que permite
      // volver a lo que se estaba hablando mientras se fotografiaba.
      final grabacion = ref.read(grabacionProvider(widget.visitaId));

      final base = await getApplicationDocumentsDirectory();
      final carpeta =
          Directory(p.join(base.path, 'visitas', widget.visitaId, 'fotos'));
      await carpeta.create(recursive: true);

      final destino = p.join(
        carpeta.path,
        'foto-${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await File(foto.path).copy(destino);
      await File(foto.path).delete();

      await ref.read(repoProvider).registrarEvidencia(
            visitaId: widget.visitaId,
            archivoPath: destino,
            tomadaEn: DateTime.now(),
            segundoAudio: grabacion.grabando ? grabacion.segundos : null,
          );

      if (!mounted) return;
      setState(() {
        _tomadas++;
        _tomando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo guardar la foto: $e';
        _tomando = false;
      });
    }
  }

  /// Guarda el retrato en la ficha del agricultor y se vuelve.
  ///
  /// Nombre fijo `perfil.jpg`: la foto de perfil es una. Tomarla de nuevo
  /// reemplaza la que habia, en el telefono y en el bucket, en vez de
  /// acumular retratos que despues nadie sabe cual es el vigente.
  Future<void> _guardarRetrato(XFile foto) async {
    final carpeta = await ref.read(repoProvider).carpetaPerfil(widget.visitaId);
    final destino = p.join(carpeta.path, 'perfil.jpg');

    await File(foto.path).copy(destino);
    await File(foto.path).delete();

    await ref.read(repoProvider).registrarFotoAgricultor(
          visitaId: widget.visitaId,
          archivoPath: destino,
        );

    if (!mounted) return;
    // Una sola foto y se vuelve: quien esta tomando un retrato no viene a
    // tomar seis. La ficha ya muestra la foto al volver.
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final grabacion = ref.watch(grabacionProvider(widget.visitaId));
    final fotos =
        ref.watch(evidenciasProvider(widget.visitaId)).valueOrNull ?? const [];
    final camara = _camara;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.retrato
              ? 'Foto del agricultor'
              : _tomadas == 0
                  ? 'Foto'
                  : '$_tomadas foto(s)',
        ),
        actions: [
          // Confirmacion visible de que la grabacion NO se detuvo. Es la duda
          // que el visitador va a tener la primera vez que abra la camara.
          if (grabacion.grabando)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  const Icon(Icons.mic, size: 16, color: Colors.redAccent),
                  const SizedBox(width: 6),
                  Text(
                    formatDuration(grabacion.segundos),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: switch ((_error, camara)) {
              (final String e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      e,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              (_, final CameraController c) => CameraPreview(c),
              _ => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
            },
          ),
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                if (grabacion.grabando)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'La grabacion sigue corriendo',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Miniatura de la ultima foto, a la izquierda del disparo,
                    // como en la camara del sistema: es la confirmacion de que
                    // la foto salio y el atajo para revisar las anteriores sin
                    // volver a la visita.
                    SizedBox(
                      width: 74,
                      // En el retrato no hay galeria que abrir: la foto de
                      // perfil es una y se ve en la ficha al volver.
                      child: fotos.isEmpty || widget.retrato
                          ? null
                          : Center(
                              child: GestureDetector(
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => VisorFotos(
                                      fotos: fotos,
                                      inicial: fotos.length - 1,
                                    ),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: Image.file(
                                      File(fotos.last.archivoPath),
                                      fit: BoxFit.cover,
                                      cacheWidth: 144,
                                      gaplessPlayback: true,
                                      errorBuilder: (_, _, _) => Container(
                                        color: Colors.white24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 24),
                    GestureDetector(
                      onTap: camara == null ? null : _tomar,
                      child: Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _tomando ? Colors.white30 : Colors.white,
                          border: Border.all(color: Colors.white54, width: 3),
                        ),
                        child: _tomando
                            ? const Padding(
                                padding: EdgeInsets.all(22),
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : null,
                      ),
                    ),
                    // Contrapeso del ancho de la miniatura, para que el boton
                    // de disparo quede centrado en la pantalla.
                    const SizedBox(width: 24),
                    const SizedBox(width: 74),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.retrato
                      ? 'Una foto para reconocerlo en la proxima visita. '
                          'Pedile permiso antes de tomarla.'
                      : 'Toca para fotografiar. Podes tomar varias seguidas.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
