import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/db/app_database.dart';
import '../state/asistencia.dart';
import '../state/providers.dart';
import '../state/red.dart';
import 'evento_asistencia_page.dart';
import 'marca.dart';

/// Los eventos donde se tomo asistencia en este telefono.
///
/// La asistencia se toma dentro de un evento para que los registros no queden
/// sueltos: el visitador abre el evento al llegar al taller, registra ahi a
/// todos, y la lista en PDF sale del evento.
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

  Future<void> _nuevoEvento() async {
    final datos = await pedirDatosEvento(context);
    if (datos == null || !mounted) return;
    final id = await ref
        .read(asistenciaRepoProvider)
        .crearEvento(nombre: datos.nombre, fecha: datos.fecha);
    if (!mounted) return;
    _abrir(id);
  }

  void _abrir(String? eventoId) => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => EventoAsistenciaPage(eventoId: eventoId)),
  );

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

    final eventos = ref.watch(eventosAsistenciaProvider);
    final registros =
        ref.watch(asistenciasProvider).valueOrNull ?? const <Asistencia>[];
    final pendientes =
        ref.watch(asistenciasPendientesProvider).valueOrNull ?? const [];
    final pendientesIds = {for (final p in pendientes) p.entidadId};
    final subida = ref.watch(subidaAsistenciasProvider);
    final red = ref.watch(redProvider);

    final porEvento = <String?, List<Asistencia>>{};
    for (final a in registros) {
      porEvento.putIfAbsent(a.eventoId, () => []).add(a);
    }
    final ids = {for (final e in eventos.valueOrNull ?? const []) e.id};
    // Los registros de antes de los eventos se juntan en «Sin evento» para
    // que nadie quede escondido.
    final sueltos = [
      for (final MapEntry(:key, :value) in porEvento.entries)
        if (key == null || !ids.contains(key)) ...value,
    ];

    return Scaffold(
      appBar: const AppBarMarca(titulo: 'Asistencia'),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'nuevo-evento',
        onPressed: _nuevoEvento,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo evento'),
      ),
      body: Column(
        children: [
          if (pendientes.isNotEmpty)
            BarraPendientesAsistencia(
              cantidad: pendientes.length,
              enLinea: red == EstadoRed.enLinea,
              trabajando: subida.trabajando,
              onSubir: () =>
                  ref.read(subidaAsistenciasProvider.notifier).subir(),
            ),
          Expanded(
            child: switch (eventos) {
              AsyncError(:final error) => EstadoVacio(
                icono: Icons.error_outline,
                titulo: 'No se pudieron leer los eventos',
                detalle: '$error',
                tono: TonoPildora.error,
              ),
              AsyncData(value: final lista)
                  when lista.isEmpty && sueltos.isEmpty =>
                const EstadoVacio(
                  icono: Icons.event_available_outlined,
                  titulo: 'Todavia no hay eventos',
                  detalle:
                      'Toca «Nuevo evento» al llegar al taller o la jornada, '
                      'y registra ahi a cada persona.\nFunciona sin senal.',
                ),
              AsyncData(value: final lista) => ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                children: [
                  for (final e in lista) ...[
                    _TarjetaEvento(
                      titulo: e.nombre,
                      fecha: e.fecha,
                      registros: porEvento[e.id] ?? const [],
                      pendientes: pendientesIds,
                      onTap: () => _abrir(e.id),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (sueltos.isNotEmpty)
                    _TarjetaEvento(
                      titulo: 'Sin evento',
                      fecha: null,
                      registros: sueltos,
                      pendientes: pendientesIds,
                      onTap: () => _abrir(null),
                    ),
                ],
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}

class _TarjetaEvento extends StatelessWidget {
  const _TarjetaEvento({
    required this.titulo,
    required this.fecha,
    required this.registros,
    required this.pendientes,
    required this.onTap,
  });

  final String titulo;
  final DateTime? fecha;
  final List<Asistencia> registros;
  final Set<String> pendientes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final n = registros.length;
    final porSubir = registros.where((a) => pendientes.contains(a.id)).length;
    final piden = registros.where((a) => a.quiereVisita).length;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: fecha == null
                    ? Icon(
                        Icons.inventory_2_outlined,
                        color: scheme.onSurfaceVariant,
                      )
                    : const PuntosSirius(),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: tema.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (fecha != null)
                          DateFormat("d 'de' MMMM 'de' y", 'es').format(fecha!)
                        else
                          'Registros de antes de los eventos',
                        '$n ${n == 1 ? 'persona' : 'personas'}',
                      ].join(' · '),
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (porSubir > 0 || piden > 0) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (porSubir > 0)
                            Pildora(
                              texto: '$porSubir por subir',
                              tono: TonoPildora.aviso,
                              icono: Icons.cloud_upload_outlined,
                            ),
                          if (piden > 0)
                            Pildora(
                              texto: '$piden piden visita',
                              tono: TonoPildora.exito,
                              icono: Icons.agriculture_outlined,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
