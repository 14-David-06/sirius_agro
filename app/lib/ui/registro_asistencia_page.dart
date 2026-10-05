import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/ubicacion.dart';
import '../data/asistencia_repository.dart';
import '../state/asistencia.dart';
import '../state/nota_voz.dart';
import '../state/providers.dart';
import '../state/red.dart';
import '../state/sesion.dart';
import 'firma_pad.dart';
import 'marca.dart';
import 'theme.dart';

/// Lo que la persona tiene que decir en la nota. Es tambien lo que el backend
/// busca en la transcripcion, asi que el orden y las palabras importan.
const guionAsistencia = [
  'Su nombre completo',
  'Su numero de cedula',
  'Su telefono',
  'La vereda donde vive',
  'Que cultivos tiene sembrados',
  'Cuantas hectareas tiene sembradas',
  'Si quiere que lo visite un tecnico',
];

/// Una persona que se registra en un taller o jornada.
///
/// En el campo solo se graba y se firma: la persona dice sus datos en una
/// nota de voz y firma. No se procesa nada aqui —con veinte personas haciendo
/// fila, esperar a que el telefono entienda cada nota hacia lento el taller—.
/// Todo queda guardado en el telefono y, cuando hay red, el backend transcribe
/// la nota, saca los datos y llena el registro en Airtable.
class RegistroAsistenciaPage extends ConsumerStatefulWidget {
  const RegistroAsistenciaPage({super.key});

  @override
  ConsumerState<RegistroAsistenciaPage> createState() =>
      _RegistroAsistenciaPageState();
}

class _RegistroAsistenciaPageState
    extends ConsumerState<RegistroAsistenciaPage> {
  final _firma = FirmaController();
  final _reproductor = AudioPlayer();
  bool _guardando = false;

  /// La coordenada se pide al abrir y no al enviar: en una caseta comunal el
  /// GPS tarda, y la persona no tiene por que esperar a que lo encuentre. Si
  /// no llega, el registro sale sin ella.
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    _firma.addListener(_alCambiarFirma);
    unawaited(_tomarUbicacion());
  }

  void _alCambiarFirma() => setState(() {});

  Future<void> _tomarUbicacion() async {
    try {
      final pos = await ubicacionActual(limite: const Duration(seconds: 15));
      if (!mounted) return;
      _lat = pos.latitude;
      _lng = pos.longitude;
    } catch (_) {
      // Sin GPS el registro vale igual.
    }
  }

  @override
  void dispose() {
    _firma.removeListener(_alCambiarFirma);
    _firma.dispose();
    _reproductor.dispose();
    super.dispose();
  }

  Future<void> _abrirTerminos() async {
    final ok = await launchUrl(
      Uri.parse(terminosAsistenciaUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo abrir el enlace. Sin senal, la direccion queda '
            'escrita en el aviso para consultarla despues.',
          ),
        ),
      );
    }
  }

  Future<void> _enviar() async {
    final nota = ref.read(notaAsistenciaProvider);
    if (_guardando || !nota.tieneNota || !_firma.tieneFirma) return;

    setState(() => _guardando = true);
    try {
      final sesion = ref.read(sesionProvider).valueOrNull;
      final png = await _firma.exportarPng();
      await _reproductor.stop();

      await ref
          .read(asistenciaRepoProvider)
          .registrar(
            notaVozTemporal: nota.path!,
            duracionNotaSeg: nota.segundos,
            firmaPng: png,
            latitud: _lat,
            longitud: _lng,
            visitadorIdEmpleado: sesion?.credencial.idEmpleado,
            visitadorNombre: sesion?.credencial.nombre,
          );
      ref.read(notaAsistenciaProvider.notifier).entregada();

      // Con red se sube de una vez; sin red queda en la cola y sube cuando
      // vuelva. En los dos casos el registro ya esta a salvo.
      final enLinea = ref.read(redProvider) == EstadoRed.enLinea;
      if (enLinea) {
        unawaited(ref.read(subidaAsistenciasProvider.notifier).subir());
      }

      if (!mounted) return;
      Navigator.of(context).pop(
        enLinea
            ? 'Registro guardado. Subiendo y procesando la nota...'
            : 'Registro guardado en el telefono. Se procesa cuando haya '
                  'senal.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el registro: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final nota = ref.watch(notaAsistenciaProvider);
    final listo = nota.tieneNota && _firma.tieneFirma;

    final falta = [
      if (!nota.tieneNota) 'la nota de voz',
      if (!_firma.tieneFirma) 'la firma',
    ];

    return Scaffold(
      appBar: const AppBarMarca(titulo: 'Registro de asistencia'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          const TituloSeccion('1. Nota de voz'),
          _NotaDeVoz(reproductor: _reproductor),
          const SizedBox(height: 24),
          TituloSeccion(
            '2. Firma',
            accion: TextButton.icon(
              onPressed: _firma.borrar,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Borrar'),
            ),
          ),
          FirmaPad(controller: _firma),
          const SizedBox(height: 24),
          _AvisoTerminos(onAbrir: _abrirTerminos),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: listo && !_guardando ? _enviar : null,
            icon: _guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: const Text('Enviar registro'),
          ),
          const SizedBox(height: 10),
          Text(
            falta.isEmpty
                ? 'Funciona sin senal: la nota y la firma quedan en el '
                      'telefono y los datos se sacan cuando haya conexion.'
                : 'Falta ${falta.join(' y ')}.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: tema.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// El banner de terminos. Va justo encima del boton a proposito: lo ultimo
/// que se lee antes de enviar es que enviar es aceptar.
class _AvisoTerminos extends StatelessWidget {
  const _AvisoTerminos({required this.onAbrir});

  final VoidCallback onAbrir;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final estilo = TextStyle(
      fontSize: 13.5,
      height: 1.45,
      color: scheme.onPrimaryContainer,
    );
    return Card(
      color: scheme.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.verified_user_outlined,
              size: 20,
              color: scheme.onPrimaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Al enviar sus datos, usted acepta los terminos y '
                    'condiciones y la politica de tratamiento de datos '
                    'personales de Sirius Regenerative (Ley 1581 de 2012), '
                    'que puede consultar en el siguiente enlace:',
                    style: estilo,
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: onAbrir,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        terminosAsistenciaUrl,
                        style: estilo.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// La nota de voz con su guion.
///
/// El guion no se esconde al grabar: es justo mientras la persona habla
/// cuando hace falta ver que le queda por decir.
class _NotaDeVoz extends ConsumerWidget {
  const _NotaDeVoz({required this.reproductor});

  final AudioPlayer reproductor;

  String _mmss(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:'
      '${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final nota = ref.watch(notaAsistenciaProvider);
    final control = ref.read(notaAsistenciaProvider.notifier);

    final borde = nota.grabando
        ? scheme.error
        : nota.tieneNota
        ? tema.marca.exito.withValues(alpha: 0.5)
        : scheme.outlineVariant;

    final Widget acciones;
    if (nota.grabando) {
      acciones = Row(
        children: [
          Icon(Icons.fiber_manual_record, color: scheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Grabando ${_mmss(nota.segundos)} / '
              '${_mmss(maxNotaVoz.inSeconds)}',
              style: tema.textTheme.titleSmall,
            ),
          ),
          IconButton(
            onPressed: control.descartar,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Descartar',
          ),
          FilledButton.icon(
            onPressed: control.detener,
            style: FilledButton.styleFrom(backgroundColor: scheme.error),
            icon: const Icon(Icons.stop),
            label: const Text('Terminar'),
          ),
        ],
      );
    } else if (nota.tieneNota) {
      acciones = Row(
        children: [
          StreamBuilder<PlayerState>(
            stream: reproductor.playerStateStream,
            builder: (context, snap) {
              final sonando =
                  (snap.data?.playing ?? false) &&
                  snap.data?.processingState != ProcessingState.completed;
              return IconButton.filledTonal(
                tooltip: sonando ? 'Pausar' : 'Escuchar',
                icon: Icon(sonando ? Icons.pause : Icons.play_arrow),
                onPressed: () async {
                  if (sonando) {
                    await reproductor.pause();
                    return;
                  }
                  // Siempre desde el archivo actual: si se volvio a grabar,
                  // el reproductor no puede quedarse con la nota anterior.
                  await reproductor.setFilePath(nota.path!);
                  await reproductor.play();
                },
              );
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Nota grabada (${_mmss(nota.segundos)})',
              style: tema.textTheme.titleSmall,
            ),
          ),
          TextButton.icon(
            onPressed: () async {
              await reproductor.stop();
              await control.iniciar();
            },
            icon: const Icon(Icons.mic, size: 18),
            label: const Text('Repetir'),
          ),
        ],
      );
    } else {
      acciones = FilledButton.icon(
        onPressed: () async {
          await reproductor.stop();
          await control.iniciar();
        },
        icon: const Icon(Icons.mic),
        label: const Text('Grabar nota de voz'),
      );
    }

    return Card(
      color: nota.grabando
          ? scheme.errorContainer.withValues(alpha: 0.35)
          : nota.tieneNota
          ? tema.marca.exitoSuave
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borde, width: nota.grabando ? 2 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              nota.grabando
                  ? 'Diga en voz alta:'
                  : 'La persona debe decir en voz alta:',
              style: tema.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            for (final (i, linea) in guionAsistencia.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        '${i + 1}.',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        linea,
                        style: const TextStyle(fontSize: 15, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            Text(
              'Ejemplo: «Me llamo Maria Lopez, mi cedula es 1 234 567, mi '
              'telefono es 300 123 4567, vivo en la vereda Guaicaramo, '
              'siembro cafe y platano, tengo 3 hectareas y si quiero la '
              'visita».',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                fontStyle: FontStyle.italic,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            acciones,
            if (nota.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  nota.error!,
                  style: TextStyle(color: scheme.error, fontSize: 12.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
