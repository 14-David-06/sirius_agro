import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// La foto de la persona que se registra en un evento.
///
/// Abre en la camara frontal porque lo comun es que la persona se tome la
/// foto ella misma, viendose en la pantalla. Con un toque se pasa a la
/// trasera, para cuando el visitador se la toma de frente.
///
/// Camara propia y no la del sistema por lo mismo que en la visita
/// (`enableAudio: false`): no le pide el microfono al sistema. Y porque la
/// del sistema no respeta en todos los Android la peticion de abrir en la
/// frontal.
///
/// Devuelve la ruta del JPG tomado, o null si se cancelo. La ruta es un
/// temporal: quien la recibe la copia a la carpeta del registro.
class FotoAsistenciaPage extends StatefulWidget {
  const FotoAsistenciaPage({super.key});

  @override
  State<FotoAsistenciaPage> createState() => _FotoAsistenciaPageState();
}

class _FotoAsistenciaPageState extends State<FotoAsistenciaPage> {
  List<CameraDescription> _camaras = const [];
  CameraController? _camara;
  CameraLensDirection _lente = CameraLensDirection.front;
  String? _error;
  bool _tomando = false;

  /// La foto recien tomada, para mirarla antes de aceptarla.
  XFile? _tomada;

  @override
  void initState() {
    super.initState();
    _abrir();
  }

  @override
  void dispose() {
    _camara?.dispose();
    super.dispose();
  }

  bool get _hayDosLentes =>
      _camaras.any((c) => c.lensDirection == CameraLensDirection.front) &&
      _camaras.any((c) => c.lensDirection == CameraLensDirection.back);

  Future<void> _abrir() async {
    try {
      if (_camaras.isEmpty) _camaras = await availableCameras();
      if (_camaras.isEmpty) throw 'El telefono no reporta camaras.';

      final elegida = _camaras.firstWhere(
        (c) => c.lensDirection == _lente,
        orElse: () => _camaras.first,
      );
      final anterior = _camara;
      if (mounted) setState(() => _camara = null);
      await anterior?.dispose();

      final ctrl = CameraController(
        elegida,
        // medium (~720p): sobra para reconocer una cara y pesa 200-400 KB,
        // que la cola sube sin problema desde una vereda con poca senal.
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await ctrl.initialize();
      if (!mounted) {
        await ctrl.dispose();
        return;
      }
      setState(() {
        _camara = ctrl;
        _lente = elegida.lensDirection;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _voltear() async {
    if (_tomando) return;
    _lente = _lente == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    await _abrir();
  }

  Future<void> _disparar() async {
    final camara = _camara;
    if (camara == null || _tomando) return;
    setState(() => _tomando = true);
    try {
      final foto = await camara.takePicture();
      if (!mounted) return;
      setState(() {
        _tomada = foto;
        _tomando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo tomar la foto: $e';
        _tomando = false;
      });
    }
  }

  Future<void> _repetir() async {
    final tomada = _tomada;
    setState(() => _tomada = null);
    if (tomada != null) {
      try {
        await File(tomada.path).delete();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final camara = _camara;
    final tomada = _tomada;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(tomada == null ? 'Foto de la persona' : '¿Queda bien?'),
      ),
      body: Column(
        children: [
          Expanded(
            child: tomada != null
                ? Center(child: Image.file(File(tomada.path)))
                : switch ((_error, camara)) {
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
                    (_, final CameraController c) => Center(
                      child: CameraPreview(c),
                    ),
                    _ => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  },
          ),
          Container(
            color: Colors.black,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: tomada != null
                ? Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _repetir,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Repetir'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () =>
                              Navigator.of(context).pop(tomada.path),
                          icon: const Icon(Icons.check),
                          label: const Text('Usar foto'),
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(width: 56),
                      GestureDetector(
                        onTap: _disparar,
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          padding: const EdgeInsets.all(5),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _tomando ? Colors.white54 : Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 56,
                        child: _hayDosLentes
                            ? IconButton(
                                tooltip: _lente == CameraLensDirection.front
                                    ? 'Usar la camara de atras'
                                    : 'Usar la camara de adelante',
                                iconSize: 30,
                                color: Colors.white,
                                onPressed: _voltear,
                                icon: const Icon(Icons.cameraswitch_outlined),
                              )
                            : null,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
