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

/// Los registros de un evento. Con [eventoId] null son los registros que se
/// tomaron antes de que existieran los eventos: se pueden ver, sacar en PDF y
/// borrar, pero no se registra nadie nuevo ahi.
class EventoAsistenciaPage extends ConsumerWidget {
  const EventoAsistenciaPage({super.key, required this.eventoId});

  final String? eventoId;

  Future<void> _registrar(BuildContext context, EventoAsistencia evento) async {
    final mensaje = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => RegistroAsistenciaPage(
          eventoId: evento.id,
          eventoNombre: evento.nombre,
        ),
      ),
    );
    if (mensaje != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje)),
      );
    }
  }

  Future<void> _renombrar(
    BuildContext context,
    WidgetRef ref,
    EventoAsistencia evento,
  ) async {
    final datos = await pedirDatosEvento(context, inicial: evento);
    if (datos == null) return;
    await ref.read(asistenciaRepoProvider).renombrarEvento(evento.id, datos.nombre);
  }

  Future<void> _eliminarEvento(
    BuildContext context,
    WidgetRef ref,
    String titulo,
    List<Asistencia> registros,
  ) async {
    final repo = ref.read(asistenciaRepoProvider);
    final sinSubir = await repo.sinSubir(registros.map((a) => a.id));
    if (!context.mounted) return;
    final n = registros.length;
    final ok = await confirmarBorrado(
      context,
      titulo: eventoId == null
          ? '¿Borrar los $n registros sin evento?'
          : '¿Borrar «$titulo» del teléfono?',
      detalle: [
        if (eventoId != null)
          n == 0
              ? 'El evento no tiene registros.'
              : 'Se borran también ${n == 1 ? 'su registro' : 'sus $n registros'}.',
        avisoSinSubir(sinSubir),
      ].join('\n\n'),
    );
    if (!ok || !context.mounted) return;
    await repo.eliminarEvento(eventoId);
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Borrado del teléfono.')),
      );
    }
  }

  Future<void> _eliminarRegistro(
    BuildContext context,
    WidgetRef ref,
    Asistencia a,
  ) async {
    final repo = ref.read(asistenciaRepoProvider);
    final sinSubir = await repo.sinSubir([a.id]);
    if (!context.mounted) return;
    final ok = await confirmarBorrado(
      context,
      titulo: a.nombreCompleto == null
          ? '¿Borrar este registro del teléfono?'
          : '¿Borrar a ${a.nombreCompleto} del teléfono?',
      detalle: avisoSinSubir(sinSubir),
    );
    if (!ok) return;
    await repo.eliminarAsistencia(a.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final eventos = ref.watch(eventosAsistenciaProvider).valueOrNull ?? const [];
    final evento = eventoId == null
        ? null
        : eventos.where((e) => e.id == eventoId).firstOrNull;
    final todos = ref.watch(asistenciasProvider);
    final ids = {for (final e in eventos) e.id};
    final registros = (todos.valueOrNull ?? const <Asistencia>[])
        .where(
          (a) => eventoId == null
              // «Sin evento» tambien recoge los de un evento que ya no esta.
              ? a.eventoId == null || !ids.contains(a.eventoId)
              : a.eventoId == eventoId,
        )
        .toList();
    final pendientes =
        ref.watch(asistenciasPendientesProvider).valueOrNull ?? const [];
    final porId = {for (final p in pendientes) p.entidadId: p};
    final pendientesAqui = registros.where((a) => porId[a.id] != null).length;
    final subida = ref.watch(subidaAsistenciasProvider);
    final red = ref.watch(redProvider);
    final veredas = {
      for (final v in ref.watch(veredasProvider).valueOrNull ?? const <Vereda>[])
        v.id: '${v.vereda} · ${v.municipio}',
    };
    final titulo = evento?.nombre ?? 'Sin evento';

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
              registros,
              evento: evento?.nombre,
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (op) => switch (op) {
              'renombrar' when evento != null => _renombrar(context, ref, evento),
              'eliminar' => _eliminarEvento(context, ref, titulo, registros),
              _ => null,
            },
            itemBuilder: (_) => [
              if (evento != null)
                const PopupMenuItem(
                  value: 'renombrar',
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Editar evento'),
                  ),
                ),
              PopupMenuItem(
                value: 'eliminar',
                child: ListTile(
                  leading: Icon(Icons.delete_outline, color: tema.colorScheme.error),
                  title: Text(
                    evento != null ? 'Borrar evento del teléfono' : 'Borrar todos',
                    style: TextStyle(color: tema.colorScheme.error),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: evento == null
          ? null
          : FloatingActionButton.extended(
              heroTag: 'nueva-asistencia',
              onPressed: () => _registrar(context, evento),
              icon: const Icon(Icons.how_to_reg),
              label: const Text('Registrar asistencia'),
            ),
      body: Column(
        children: [
          if (pendientesAqui > 0)
            BarraPendientesAsistencia(
              cantidad: pendientesAqui,
              enLinea: red == EstadoRed.enLinea,
              trabajando: subida.trabajando,
              onSubir: () => ref.read(subidaAsistenciasProvider.notifier).subir(),
            ),
          _CabeceraEvento(
            titulo: titulo,
            fecha: evento?.fecha,
            personas: registros.length,
            piden: registros.where((a) => a.quiereVisita).length,
          ),
          Expanded(
            child: switch (todos) {
              AsyncError(:final error) => EstadoVacio(
                icono: Icons.error_outline,
                titulo: 'No se pudieron leer los registros',
                detalle: '$error',
                tono: TonoPildora.error,
              ),
              AsyncData() when registros.isEmpty => const EstadoVacio(
                icono: Icons.how_to_reg_outlined,
                titulo: 'Todavia no hay nadie registrado',
                detalle:
                    'Toca «Registrar asistencia» para grabar la nota de voz y '
                    'la firma de cada persona.\nFunciona sin senal.',
              ),
              AsyncData() => ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                itemCount: registros.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) => FilaAsistencia(
                  asistencia: registros[i],
                  vereda: veredas[registros[i].veredaLocalId],
                  pendiente: porId[registros[i].id],
                  onEliminar: () =>
                      _eliminarRegistro(context, ref, registros[i]),
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

/// El nombre del evento con dos puntos de color delante: los mismos dos del
/// logo, el azul cielo y el verde.
class _CabeceraEvento extends StatelessWidget {
  const _CabeceraEvento({
    required this.titulo,
    required this.fecha,
    required this.personas,
    required this.piden,
  });

  final String titulo;
  final DateTime? fecha;
  final int personas;
  final int piden;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final dia = fecha == null
        ? 'Registros tomados antes de los eventos'
        : _capital(DateFormat("EEEE d 'de' MMMM 'de' y", 'es').format(fecha!));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 10),
            child: PuntosSirius(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: tema.textTheme.titleLarge),
                const SizedBox(height: 2),
                Text(
                  '$dia\n$personas ${personas == 1 ? 'persona' : 'personas'}'
                  '${piden > 0 ? ' · $piden piden visita' : ''}',
                  style: tema.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _capital(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

/// Los dos puntos del logo de Sirius, en vertical.
class PuntosSirius extends StatelessWidget {
  const PuntosSirius({super.key, this.tamano = 9});

  final double tamano;

  @override
  Widget build(BuildContext context) {
    Widget punto(Color c) => Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    );
    return Column(
      children: [
        punto(const Color(0xFF00A3FF)),
        SizedBox(height: tamano * 0.45),
        punto(const Color(0xFF00B602)),
      ],
    );
  }
}

/// Lo que hay que saber antes de borrar: si algo todavia no subio, se pierde.
String avisoSinSubir(int sinSubir) => sinSubir == 0
    ? 'Solo se borra de este teléfono. Lo que ya está en Airtable se queda allá.'
    : '${sinSubir == 1 ? 'Un registro todavía no se ha subido' : '$sinSubir registros todavía no se han subido'} '
          'a Airtable: si lo borras, su nota de voz y su firma se pierden.';

Future<bool> confirmarBorrado(
  BuildContext context, {
  required String titulo,
  required String detalle,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(Icons.delete_outline, color: scheme.error),
      title: Text(titulo),
      content: Text(detalle),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: scheme.error),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Borrar'),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Pide nombre y fecha de un evento. Con [inicial] edita uno que ya existe.
Future<({String nombre, DateTime fecha})?> pedirDatosEvento(
  BuildContext context, {
  EventoAsistencia? inicial,
}) {
  return showDialog<({String nombre, DateTime fecha})>(
    context: context,
    builder: (_) => _DialogoEvento(inicial: inicial),
  );
}

class _DialogoEvento extends StatefulWidget {
  const _DialogoEvento({this.inicial});

  final EventoAsistencia? inicial;

  @override
  State<_DialogoEvento> createState() => _DialogoEventoState();
}

class _DialogoEventoState extends State<_DialogoEvento> {
  late final _nombre = TextEditingController(text: widget.inicial?.nombre);
  late DateTime _fecha = widget.inicial?.fecha ?? DateTime.now();

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  void _guardar() {
    final nombre = _nombre.text.trim();
    if (nombre.isEmpty) return;
    Navigator.of(context).pop((nombre: nombre, fecha: _fecha));
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.inicial != null;
    return AlertDialog(
      title: Text(editando ? 'Editar evento' : 'Nuevo evento'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nombre,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _guardar(),
            decoration: const InputDecoration(
              labelText: 'Nombre del evento',
              hintText: 'Ej: Taller de bioinsumos, La Esperanza',
            ),
          ),
          if (!editando) ...[
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: Text(DateFormat("d 'de' MMMM 'de' y", 'es').format(_fecha)),
              trailing: const Text('Cambiar'),
              onTap: () async {
                final elegida = await showDatePicker(
                  context: context,
                  initialDate: _fecha,
                  firstDate: DateTime(2024),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (elegida != null) setState(() => _fecha = elegida);
              },
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _nombre.text.trim().isEmpty ? null : _guardar,
          child: Text(editando ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }
}

class BarraPendientesAsistencia extends StatelessWidget {
  const BarraPendientesAsistencia({
    super.key,
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

class FilaAsistencia extends StatelessWidget {
  const FilaAsistencia({
    super.key,
    required this.asistencia,
    required this.onEliminar,
    this.pendiente,
    this.vereda,
  });

  final Asistencia asistencia;
  final String? vereda;
  final SyncItem? pendiente;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final a = asistencia;
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
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
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
                IconButton(
                  tooltip: 'Borrar del teléfono',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.delete_outline, color: scheme.onSurfaceVariant),
                  onPressed: onEliminar,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [
                      if (a.cedula != null) 'CC ${a.cedula}',
                      if (a.telefono != null) a.telefono!,
                      if (a.nombreCompleto != null)
                        hora
                      else
                        'Los datos salen de la nota al subir',
                    ].join(' · '),
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (a.correo != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      a.correo!,
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (vereda != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      vereda!,
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
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
                      const Pildora(
                        texto: 'Firmado',
                        tono: TonoPildora.info,
                        icono: Icons.draw_outlined,
                      ),
                      if (a.notaVozPath != null)
                        Pildora(
                          texto:
                              'Nota de voz'
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
          ],
        ),
      ),
    );
  }
}
