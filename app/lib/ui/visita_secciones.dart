import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/db/app_database.dart';
import '../state/informe.dart';
import '../state/procesador.dart';
import '../state/providers.dart';
import 'camara_page.dart';
import 'galeria_fotos.dart';
import 'informe_page.dart';
import 'theme.dart';
import 'visita_page.dart';

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

/// El botón que cumple lo que se le prometió al productor en el
/// consentimiento: "con eso le armo un informe de su finca y se lo entrego".
///
/// Necesita señal y no se encola: el visitador lo pide para leérselo antes de
/// irse de la finca, y un informe que llega tres días después ya no es eso.
class SeccionInforme extends ConsumerWidget {
  const SeccionInforme({super.key, required this.visitaId});

  final String visitaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final estado = ref.watch(informeProvider(visitaId));
    final informes = ref.watch(informesProvider(visitaId)).valueOrNull ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.description_outlined,
                    color: estado.error != null ? scheme.error : scheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informe para el productor',
                        style: tema.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        estado.error ??
                            (informes.isEmpty
                                ? 'Se arma con la conversacion. Necesita senal.'
                                : '${informes.length} generado(s)'),
                        style: tema.textTheme.bodySmall?.copyWith(
                          color: estado.error != null
                              ? scheme.error
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: estado.trabajando
                    ? null
                    : () async {
                        final informe = await ref
                            .read(informeProvider(visitaId).notifier)
                            .generar();
                        if (informe != null && context.mounted) {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => InformePage(informe: informe),
                            ),
                          );
                        }
                      },
                icon: estado.trabajando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(informes.isEmpty ? Icons.auto_stories : Icons.refresh),
                label: Text(
                  estado.trabajando
                      ? 'Escribiendo el informe...'
                      : informes.isEmpty
                          ? 'Generar informe'
                          : 'Generar de nuevo',
                ),
              ),
            ),
            // Los anteriores no se borran: si el nuevo sale peor, el que ya se
            // le mostro al productor sigue estando.
            if (informes.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              for (final i in informes)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  dense: true,
                  leading: Icon(
                    i.entregado ? Icons.mark_email_read_outlined : Icons.article_outlined,
                    color: i.entregado ? tema.marca.exito : scheme.onSurfaceVariant,
                  ),
                  title: Text('Version ${i.version}', style: tema.textTheme.bodyLarge),
                  subtitle: Text(
                    DateFormat("d 'de' MMMM, h:mm a", 'es').format(i.generadoEn),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => InformePage(informe: i)),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
