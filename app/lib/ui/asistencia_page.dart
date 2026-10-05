import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/db/app_database.dart';
import '../state/asistencia.dart';
import '../state/providers.dart';
import '../state/red.dart';
import 'lista_asistencia_pdf_sheet.dart';
import 'marca.dart';
import 'registro_asistencia_page.dart';
import 'theme.dart';

/// Los registros de asistencia tomados en este telefono, y su estado de
/// subida a Airtable.
class AsistenciaPage extends ConsumerStatefulWidget {
  const AsistenciaPage({super.key});

  @override
  ConsumerState<AsistenciaPage> createState() => _AsistenciaPageState();
}

class _AsistenciaPageState extends ConsumerState<AsistenciaPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _subirSiHayRed());
  }

  Future<void> _subirSiHayRed() async {
    if (!mounted || ref.read(redProvider) != EstadoRed.enLinea) return;
    final pendientes = await ref.read(asistenciaRepoProvider).pendientes();
    if (pendientes.isEmpty || !mounted) return;
    await ref.read(subidaAsistenciasProvider.notifier).subir();
  }

  Future<void> _nuevo() async {
    final mensaje = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const RegistroAsistenciaPage()),
    );
    if (mensaje != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensaje)));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cuando vuelve la senal, lo pendiente sube solo.
    ref.listen<EstadoRed>(redProvider, (antes, ahora) {
      if (ahora == EstadoRed.enLinea && antes != EstadoRed.enLinea) {
        unawaited(_subirSiHayRed());
      }
    });
    ref.listen<SubidaAsistenciasState>(subidaAsistenciasProvider, (_, s) {
      final mensaje = s.mensaje;
      if (!s.trabajando && mensaje != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(mensaje)));
      }
    });

    final registros = ref.watch(asistenciasProvider);
    final pendientes =
        ref.watch(asistenciasPendientesProvider).valueOrNull ?? const [];
    final porId = {for (final p in pendientes) p.entidadId: p};
    final subida = ref.watch(subidaAsistenciasProvider);
    final red = ref.watch(redProvider);
    final veredas = {
      for (final v in ref.watch(veredasProvider).valueOrNull ?? const <Vereda>[])
        v.id: '${v.vereda} · ${v.municipio}',
    };

    return Scaffold(
      appBar: AppBarMarca(
        titulo: 'Asistencia',
        actions: [
          IconButton(
            tooltip: 'Lista en PDF',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () => abrirListaAsistenciaPdf(
              context,
              ref,
              registros.valueOrNull ?? const [],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'nueva-asistencia',
        onPressed: _nuevo,
        icon: const Icon(Icons.how_to_reg),
        label: const Text('Registrar asistencia'),
      ),
      body: Column(
        children: [
          if (pendientes.isNotEmpty)
            _BarraPendientes(
              cantidad: pendientes.length,
              enLinea: red == EstadoRed.enLinea,
              trabajando: subida.trabajando,
              onSubir: () =>
                  ref.read(subidaAsistenciasProvider.notifier).subir(),
            ),
          Expanded(
            child: switch (registros) {
              AsyncError(:final error) => EstadoVacio(
                  icono: Icons.error_outline,
                  titulo: 'No se pudieron leer los registros',
                  detalle: '$error',
                  tono: TonoPildora.error,
                ),
              AsyncData(value: final lista) when lista.isEmpty =>
                const EstadoVacio(
                  icono: Icons.how_to_reg_outlined,
                  titulo: 'Todavia no hay registros',
                  detalle: 'Toca «Registrar asistencia» para tomar los datos y '
                      'la firma de cada persona.\nFunciona sin senal.',
                ),
              AsyncData(value: final lista) => ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                  itemCount: lista.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _FilaAsistencia(
                    asistencia: lista[i],
                    vereda: veredas[lista[i].veredaLocalId],
                    pendiente: porId[lista[i].id],
                  ),
                ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}

class _BarraPendientes extends StatelessWidget {
  const _BarraPendientes({
    required this.cantidad,
    required this.enLinea,
    required this.trabajando,
    required this.onSubir,
  });

  final int cantidad;
  final bool enLinea;
  final bool trabajando;
  final VoidCallback onSubir;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Container(
      width: double.infinity,
      color: tema.marca.avisoSuave,
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          Icon(Icons.cloud_upload_outlined, size: 18, color: tema.marca.aviso),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              enLinea
                  ? '$cantidad registro(s) por subir a Airtable.'
                  : '$cantidad registro(s) guardados. Suben solos cuando '
                      'haya senal.',
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: tema.marca.aviso,
              ),
            ),
          ),
          TextButton(
            onPressed: enLinea && !trabajando ? onSubir : null,
            child: trabajando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Subir ahora'),
          ),
        ],
      ),
    );
  }
}

class _FilaAsistencia extends StatelessWidget {
  const _FilaAsistencia({
    required this.asistencia,
    this.pendiente,
    this.vereda,
  });

  final Asistencia asistencia;
  final String? vereda;
  final SyncItem? pendiente;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final a = asistencia;
    final cultivos = a.cultivos.split('\n').where((c) => c.isNotEmpty);
    final fallo = pendiente?.estado == EstadoSync.fallida;

    final pildora = a.procesado && pendiente == null
        ? const Pildora(
            texto: 'En Airtable',
            tono: TonoPildora.exito,
            icono: Icons.cloud_done_outlined,
          )
        : fallo
            ? const Pildora(
                texto: 'Reintentando',
                tono: TonoPildora.error,
                icono: Icons.error_outline,
              )
            : const Pildora(
                texto: 'Por procesar',
                tono: TonoPildora.aviso,
                icono: Icons.cloud_off_outlined,
              );
    final hora = DateFormat('d MMM yyyy, HH:mm', 'es').format(a.registradoEn);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  // Hasta que el backend procese la nota no se sabe quien
                  // es: se muestra la hora, que es como el visitador lo
                  // recuerda en la fila del taller.
                  child: Text(
                    a.nombreCompleto ?? 'Registro de las $hora',
                    style: tema.textTheme.titleMedium,
                  ),
                ),
                pildora,
              ],
            ),
            const SizedBox(height: 4),
            Text(
              [
                if (a.cedula != null) 'CC ${a.cedula}',
                if (a.telefono != null) a.telefono!,
                if (a.nombreCompleto != null)
                  hora
                else
                  'Los datos salen de la nota al subir',
              ].join(' · '),
              style: tema.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (vereda != null) ...[
              const SizedBox(height: 2),
              Text(
                vereda!,
                style: tema.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (a.quiereVisita)
                  const Pildora(
                    texto: 'Pide visita',
                    tono: TonoPildora.exito,
                    icono: Icons.agriculture_outlined,
                  ),
                for (final c in cultivos) Pildora(texto: c),
                if (a.areaSembradaHa != null)
                  Pildora(texto: '${a.areaSembradaHa} ha'),
                const Pildora(
                  texto: 'Firmado',
                  tono: TonoPildora.info,
                  icono: Icons.draw_outlined,
                ),
                if (a.notaVozPath != null)
                  Pildora(
                    texto: 'Nota de voz'
                        '${a.duracionNotaSeg != null ? ' ${a.duracionNotaSeg}s' : ''}',
                    tono: TonoPildora.info,
                    icono: Icons.mic_none,
                  ),
              ],
            ),
            if (fallo && pendiente?.ultimoError != null) ...[
              const SizedBox(height: 8),
              Text(
                pendiente!.ultimoError!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: scheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
