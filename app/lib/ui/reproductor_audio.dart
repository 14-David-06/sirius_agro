import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../data/db/app_database.dart';
import '../state/providers.dart';
import 'theme.dart';

/// El audio de una visita traida de Airtable.
///
/// Existe porque el espejo bajaba los tramos al telefono y no habia con que
/// abrirlos: la fila quedaba en la base, el archivo en disco, y la pantalla
/// no los mencionaba. Consultar una visita ajena sin poder oir la
/// conversacion deja fuera lo unico que no se puede resumir.
///
/// Solo en espejos, no en visitas propias: reproducir mientras se graba le
/// disputa el audio al microfono, y una visita propia puede estar grabando
/// ahora mismo.
class SeccionAudioSoloLectura extends ConsumerStatefulWidget {
  const SeccionAudioSoloLectura({super.key, required this.visitaId});

  final String visitaId;

  @override
  ConsumerState<SeccionAudioSoloLectura> createState() =>
      _SeccionAudioSoloLecturaState();
}

class _SeccionAudioSoloLecturaState
    extends ConsumerState<SeccionAudioSoloLectura> {
  final _reproductor = AudioPlayer();

  /// El tramo cargado ahora mismo. Null si no se ha tocado ninguno.
  String? _tramoId;

  String? _error;

  @override
  void dispose() {
    _reproductor.dispose();
    super.dispose();
  }

  Future<void> _alternar(Grabacion tramo) async {
    // Tocar el tramo que ya suena es pausarlo; tocar otro cambia de archivo.
    if (_tramoId == tramo.id) {
      if (_reproductor.playing) {
        await _reproductor.pause();
      } else {
        await _reproductor.play();
      }
      return;
    }

    setState(() {
      _tramoId = tramo.id;
      _error = null;
    });

    try {
      await _reproductor.setFilePath(tramo.archivoPath);
      await _reproductor.play();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _tramoId = null;
        _error = 'No se pudo abrir el tramo ${tramo.orden}.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final tramos = ref.watch(grabacionesProvider(widget.visitaId)).valueOrNull;

    if (tramos == null || tramos.isEmpty) return const SizedBox.shrink();

    final minutos = tramos.fold<int>(0, (t, g) => t + g.duracionSeg) ~/ 60;
    // Los que no bajaron: la fila se queda porque lleva la transcripcion, pero
    // no hay archivo que abrir. Decirlo es mejor que un boton que no hace nada.
    final sinArchivo = tramos.where((g) => g.archivoPath.isEmpty).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.graphic_eq, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${tramos.length} tramo(s) de audio'
                    '${minutos > 0 ? ' · $minutos min' : ''}',
                    style: tema.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: TextStyle(fontSize: 12.5, color: scheme.error),
              ),
            ],
            if (sinArchivo > 0) ...[
              const SizedBox(height: 10),
              Text(
                sinArchivo == 1
                    ? 'A 1 tramo no se le pudo bajar el audio. Vuelve a abrir '
                        'la visita con señal para reintentarlo.'
                    : 'A $sinArchivo tramos no se les pudo bajar el audio. '
                        'Vuelve a abrir la visita con señal para reintentarlo.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 6),
            for (final tramo in tramos)
              _FilaTramo(
                tramo: tramo,
                reproductor: _reproductor,
                activo: _tramoId == tramo.id,
                onTocar: () => _alternar(tramo),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilaTramo extends StatelessWidget {
  const _FilaTramo({
    required this.tramo,
    required this.reproductor,
    required this.activo,
    required this.onTocar,
  });

  final Grabacion tramo;
  final AudioPlayer reproductor;
  final bool activo;
  final VoidCallback onTocar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final hayArchivo = tramo.archivoPath.isNotEmpty &&
        File(tramo.archivoPath).existsSync();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              StreamBuilder<PlayerState>(
                stream: reproductor.playerStateStream,
                builder: (context, snap) {
                  final sonando = activo && (snap.data?.playing ?? false);
                  return IconButton.filledTonal(
                    onPressed: hayArchivo ? onTocar : null,
                    icon: Icon(sonando ? Icons.pause : Icons.play_arrow),
                    tooltip: hayArchivo
                        ? (sonando ? 'Pausar' : 'Reproducir')
                        : 'El audio de este tramo no esta en el telefono',
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tramo ${tramo.orden}',
                      style: tema.textTheme.titleSmall,
                    ),
                    Text(
                      hayArchivo
                          ? formatDuration(tramo.duracionSeg)
                          : 'sin audio en el telefono',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // La barra solo del tramo que suena: una por tramo seria ruido, y
          // ademas solo una tiene posicion de verdad.
          if (activo && hayArchivo)
            _Barra(reproductor: reproductor, duracionSeg: tramo.duracionSeg),
        ],
      ),
    );
  }
}

/// Donde va el tramo y a donde se puede saltar.
///
/// Poder saltar no es comodidad: los hallazgos del historial traen el segundo
/// del audio en que se dijeron, y oir esa frase es como se confirma un dato
/// que alguien mas registro.
class _Barra extends StatelessWidget {
  const _Barra({required this.reproductor, required this.duracionSeg});

  final AudioPlayer reproductor;
  final int duracionSeg;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return StreamBuilder<Duration>(
      stream: reproductor.positionStream,
      builder: (context, snap) {
        final total = reproductor.duration ??
            Duration(seconds: duracionSeg == 0 ? 1 : duracionSeg);
        final posicion = snap.data ?? Duration.zero;
        final segundos = posicion.inSeconds
            .clamp(0, total.inSeconds == 0 ? 1 : total.inSeconds)
            .toDouble();

        return Column(
          children: [
            Slider(
              value: segundos,
              max: (total.inSeconds == 0 ? 1 : total.inSeconds).toDouble(),
              onChanged: (v) =>
                  reproductor.seek(Duration(seconds: v.round())),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatDuration(posicion.inSeconds),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    formatDuration(total.inSeconds),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
