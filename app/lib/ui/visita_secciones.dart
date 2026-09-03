import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../state/procesador.dart';
import '../state/providers.dart';
import 'camara_page.dart';
import 'galeria_fotos.dart';
import 'visita_page.dart';
import 'theme.dart';

/// Fotos durante la conversacion, sin detener la grabacion.
class SeccionFotos extends ConsumerWidget {
  const SeccionFotos({super.key, required this.visitaId, required this.visita});

  final String visitaId;
  final Visita visita;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final fotos = ref.watch(evidenciasProvider(visitaId)).valueOrNull ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.photo_camera_outlined, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fotos', style: tema.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        fotos.isEmpty
                            ? 'Cultivo, suelo y etiquetas'
                            : '${fotos.length} tomada(s)',
                        style: tema.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  // El consentimiento de fotos gobierna la camara, igual que
                  // el de audio gobierna el grabador. Cada permiso lo suyo.
                  onPressed: visita.consienteFotos
                      ? () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CamaraPage(visitaId: visitaId),
                            ),
                          )
                      : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Tomar'),
                ),
              ],
            ),
            // Igual que con el audio: el permiso de fotos se puede volver a
            // pedir sin abandonar la visita.
            if (!visita.consienteFotos)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'El productor no autorizo las fotos.',
                        style: TextStyle(fontSize: 12.5, color: scheme.error),
                      ),
                    ),
                    TextButton(
                      onPressed: () => pedirPermisoDeNuevo(context, visitaId),
                      child: const Text('Pedir permiso'),
                    ),
                  ],
                ),
              ),
            // Las fotos mismas, no una lista de metadatos: el visitador tiene
            // que poder confirmar que la foto salio bien sin salir de la
            // visita. Cada miniatura lleva encima el segundo del audio, que es
            // lo que permite volver a lo que se hablaba cuando se tomo.
            if (fotos.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: GrillaFotos(fotos: fotos),
              ),
          ],
        ),
      ),
    );
  }
}

/// Lo que le faltaba a la app: hacer algo con el audio.
///
/// Transcribe cada tramo y extrae los hallazgos. Cada paso se salta si ya
/// esta hecho, asi que reintentar despues de un fallo retoma donde quedo en
/// vez de volver a pagar la transcripcion de un tramo ya transcrito.
class SeccionProcesar extends ConsumerWidget {
  const SeccionProcesar({super.key, required this.visitaId});

  final String visitaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final estado = ref.watch(procesadorProvider(visitaId));
    final ctrl = ref.read(procesadorProvider(visitaId).notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              // Arriba y no al centro: el titulo puede irse a dos lineas y el
              // icono flotando en la mitad se ve accidental.
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    estado.fallo
                        ? Icons.error_outline
                        : Icons.auto_awesome_outlined,
                    color: estado.fallo ? scheme.error : scheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Procesar la conversacion',
                        style: tema.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        estado.mensaje.isEmpty
                            ? 'Transcribe el audio y extrae los datos. Necesita senal.'
                            : estado.mensaje,
                        style: tema.textTheme.bodySmall?.copyWith(
                          color: estado.fallo
                              ? scheme.error
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (estado.trabajando)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  )
                else
                  FilledButton.tonal(
                    onPressed: ctrl.procesar,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(estado.fallo ? 'Reintentar' : 'Procesar'),
                  ),
              ],
            ),
            if (estado.pasos.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              for (final paso in estado.pasos)
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        switch (paso.estado) {
                          EstadoPaso.listo => Icons.check_circle,
                          EstadoPaso.fallo => Icons.cancel,
                          EstadoPaso.enCurso => Icons.more_horiz,
                        },
                        size: 16,
                        color: switch (paso.estado) {
                          EstadoPaso.listo => tema.marca.exito,
                          EstadoPaso.fallo => scheme.error,
                          EstadoPaso.enCurso => scheme.outline,
                        },
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          paso.detalle,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            color: paso.estado == EstadoPaso.fallo
                                ? scheme.error
                                : scheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
