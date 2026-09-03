import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/db/app_database.dart';
import '../data/sesion_repository.dart';
import '../state/providers.dart';
import '../state/sesion.dart';
import 'marca.dart';
import 'nueva_visita_page.dart';
import 'theme.dart';
import 'visita_page.dart';

class VisitasPage extends ConsumerWidget {
  const VisitasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // La semilla tiene que estar antes de dejar crear una visita: sin veredas
    // ni obligatorios, la app no sabe donde esta ni que preguntar.
    final semilla = ref.watch(semillaProvider);
    final visitas = ref.watch(visitasProvider);
    final sesion = ref.watch(sesionProvider).valueOrNull;

    return Scaffold(
      appBar: AppBarMarca(
        titulo: 'Visitas de campo',
        actions: [if (sesion != null) _MenuSesion(sesion: sesion)],
      ),
      floatingActionButton: semilla.hasValue
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NuevaVisitaPage()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Nueva visita'),
            )
          : null,
      body: switch (semilla) {
        AsyncError(:final error) => EstadoVacio(
            icono: Icons.error_outline,
            titulo: 'No se pudo preparar la app',
            detalle: '$error',
            tono: TonoPildora.error,
          ),
        AsyncLoading() => const Center(child: CircularProgressIndicator()),
        _ => switch (visitas) {
            AsyncError(:final error) => EstadoVacio(
                icono: Icons.error_outline,
                titulo: 'No se pudieron leer las visitas',
                detalle: '$error',
                tono: TonoPildora.error,
              ),
            AsyncData(value: final lista) when lista.isEmpty =>
              const EstadoVacio(
                icono: Icons.landscape_outlined,
                titulo: 'Todavia no hay visitas',
                detalle:
                    'Toca «Nueva visita» al llegar a la finca.\nFunciona sin senal.',
              ),
            AsyncData(value: final lista) => ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: lista.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _VisitaCard(visita: lista[i]),
              ),
            _ => const Center(child: CircularProgressIndicator()),
          },
      },
    );
  }
}

class _VisitaCard extends ConsumerWidget {
  const _VisitaCard({required this.visita});

  final Visita visita;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final pendientes = ref.watch(pendientesSyncProvider(visita.id));
    final porSubir = pendientes.valueOrNull?.length ?? 0;

    final fecha = DateFormat("EEEE d 'de' MMMM", 'es').format(visita.inicio);
    final hora = DateFormat('h:mm a', 'es').format(visita.inicio);

    return Card(
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => VisitaPage(visitaId: visita.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnilloCompletitud(pct: visita.completitudPct),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      // La fecha en mayuscula inicial: `EEEE` en espanol viene
                      // en minuscula y arranca la tarjeta con cara de dato.
                      fecha.isEmpty
                          ? fecha
                          : fecha[0].toUpperCase() + fecha.substring(1),
                      style: tema.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hora,
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Pildora(
                          texto: visita.estado,
                          tono: visita.estado == 'cerrada'
                              ? TonoPildora.exito
                              : TonoPildora.info,
                        ),
                        if (!visita.consienteAudio)
                          const Pildora(
                            texto: 'Sin consentimiento',
                            tono: TonoPildora.error,
                            icono: Icons.mic_off_outlined,
                          ),
                        if (porSubir > 0)
                          Pildora(
                            texto: '$porSubir por subir',
                            tono: TonoPildora.aviso,
                            icono: Icons.cloud_upload_outlined,
                          ),
                        if (visita.sincronizada)
                          const Pildora(
                            texto: 'Sincronizada',
                            tono: TonoPildora.exito,
                            icono: Icons.check_rounded,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12, left: 4),
                child: Icon(
                  Icons.chevron_right,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// Quien esta adentro y como salir. Muestra tambien si la sesion se valido
/// contra la copia local: si alguien salio de la empresa y este telefono no
/// habla con el backend hace dias, el visitador merece saberlo.
class _MenuSesion extends ConsumerWidget {
  const _MenuSesion({required this.sesion});

  final SesionActiva sesion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final credencial = sesion.credencial;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<String>(
        tooltip: credencial.nombre,
        position: PopupMenuPosition.under,
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: scheme.primaryContainer,
              foregroundColor: scheme.onPrimaryContainer,
              child: Text(
                _iniciales(credencial.nombre),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            if (sesion.offline)
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: tema.marca.aviso,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.surfaceContainerLowest,
                        width: 2),
                  ),
                ),
              ),
          ],
        ),
        onSelected: (v) {
          if (v == 'salir') ref.read(sesionRepoProvider).cerrarSesion();
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            enabled: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(credencial.nombre, style: tema.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  '${credencial.rolApp} · ${credencial.idEmpleado}',
                  style: tema.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (sesion.offline) ...[
                  const SizedBox(height: 8),
                  const Pildora(
                    texto: 'Sesion validada sin internet',
                    tono: TonoPildora.aviso,
                    icono: Icons.cloud_off,
                  ),
                ],
              ],
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'salir',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.logout),
              title: Text('Cerrar sesion'),
            ),
          ),
        ],
      ),
    );
  }

  String _iniciales(String nombre) {
    final partes =
        nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return (partes.first[0] + partes.last[0]).toUpperCase();
  }
}
