import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/db/app_database.dart';
import '../data/sesion_repository.dart';
import '../state/providers.dart';
import '../state/sesion.dart';
import 'acciones_visitas.dart';
import 'chat_page.dart';
import 'marca.dart';
import 'nueva_visita_page.dart';
import 'theme.dart';
import 'visita_page.dart';

class VisitasPage extends ConsumerStatefulWidget {
  const VisitasPage({super.key});

  @override
  ConsumerState<VisitasPage> createState() => _VisitasPageState();
}

class _VisitasPageState extends ConsumerState<VisitasPage> {
  /// Que visitas estan marcadas. Vacio significa que no hay modo seleccion:
  /// no hace falta un segundo booleano que pueda quedar desincronizado.
  final Set<String> _seleccion = {};

  bool get _seleccionando => _seleccion.isNotEmpty;

  void _alternar(String id) => setState(() {
        if (!_seleccion.remove(id)) _seleccion.add(id);
      });

  void _limpiar() => setState(_seleccion.clear);

  Future<void> _eliminar() async {
    final ids = _seleccion.toList();
    final borrado = await confirmarYEliminar(context, ref, ids);
    if (!mounted || !borrado) return;

    _limpiar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ids.length == 1
              ? 'Visita eliminada del telefono.'
              : '${ids.length} visitas eliminadas del telefono.',
        ),
      ),
    );
  }

  Future<void> _descargar() async {
    final ids = _seleccion.toList();
    await descargarVisitas(context, ref, ids);
    if (mounted) _limpiar();
  }

  @override
  Widget build(BuildContext context) {
    // La semilla tiene que estar antes de dejar crear una visita: sin veredas
    // ni obligatorios, la app no sabe donde esta ni que preguntar.
    final semilla = ref.watch(semillaProvider);
    final visitas = ref.watch(visitasProvider);
    final sesion = ref.watch(sesionProvider).valueOrNull;

    // Una visita puede desaparecer de la lista mientras esta marcada (se
    // borro, o la borro otra pantalla). Si su id sigue en la seleccion, los
    // botones de abajo actuarian sobre algo que ya no existe.
    final lista = visitas.valueOrNull ?? const <Visita>[];
    if (_seleccionando && visitas.hasValue) {
      final vivas = lista.map((v) => v.id).toSet();
      _seleccion.removeWhere((id) => !vivas.contains(id));
    }

    return Scaffold(
      appBar: _seleccionando
          ? _AppBarSeleccion(
              cantidad: _seleccion.length,
              total: lista.length,
              onCerrar: _limpiar,
              onTodas: () => setState(() {
                _seleccion
                  ..clear()
                  ..addAll(lista.map((v) => v.id));
              }),
            )
          : AppBarMarca(
              titulo: 'Visitas de campo',
              actions: [if (sesion != null) _MenuSesion(sesion: sesion)],
            ),
      // Las dos acciones abajo y con texto: se tocan con el pulgar y con
      // guantes, y «Eliminar» no puede ser un icono que se confunda.
      bottomNavigationBar: _seleccionando
          ? _BarraAcciones(
              cantidad: _seleccion.length,
              onDescargar: _descargar,
              onEliminar: _eliminar,
            )
          : null,
      // El chat va ARRIBA de «Nueva visita» y mas chico: consultar es lo que
      // se hace de paso, crear la visita es a lo que se vino. Si los dos
      // pesaran igual, el pulgar erraria justo al llegar a la finca.
      floatingActionButton: semilla.hasValue && !_seleccionando
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.small(
                  heroTag: 'chat',
                  tooltip: 'Asistente de campo',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ChatPage()),
                  ),
                  child: const Icon(Icons.auto_awesome),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'nueva',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NuevaVisitaPage()),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva visita'),
                ),
              ],
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
                itemBuilder: (_, i) => _VisitaCard(
                  visita: lista[i],
                  seleccionando: _seleccionando,
                  seleccionada: _seleccion.contains(lista[i].id),
                  onAlternar: () => _alternar(lista[i].id),
                ),
              ),
            _ => const Center(child: CircularProgressIndicator()),
          },
      },
    );
  }
}

class _VisitaCard extends ConsumerWidget {
  const _VisitaCard({
    required this.visita,
    required this.seleccionando,
    required this.seleccionada,
    required this.onAlternar,
  });

  final Visita visita;
  final bool seleccionando;
  final bool seleccionada;
  final VoidCallback onAlternar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final pendientes = ref.watch(pendientesSyncProvider(visita.id));
    final porSubir = pendientes.valueOrNull?.length ?? 0;

    final fecha = DateFormat("EEEE d 'de' MMMM", 'es').format(visita.inicio);
    final hora = DateFormat('h:mm a', 'es').format(visita.inicio);

    return Card(
      // La tarjeta marcada se tine y se enmarca. Solo el check no alcanza:
      // al sol, en la pantalla del telefono, un cuadrito no se ve.
      color: seleccionada ? scheme.primaryContainer : null,
      shape: seleccionada
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: scheme.primary, width: 1.5),
            )
          : null,
      child: InkWell(
        // Sostener entra al modo seleccion; una vez dentro, el toque marca y
        // desmarca en vez de abrir la visita. Es como se comporta la galeria
        // del telefono, y es el gesto que el visitador ya conoce.
        onLongPress: seleccionando ? null : onAlternar,
        onTap: seleccionando
            ? onAlternar
            : () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => VisitaPage(visitaId: visita.id),
                  ),
                ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (seleccionando)
                // Mismo tamano que el anillo que reemplaza, para que la fila
                // no salte al entrar y salir del modo seleccion.
                SizedBox(
                  width: 46,
                  height: 46,
                  child: Center(
                    child: Icon(
                      seleccionada
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: seleccionada
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                      size: 26,
                    ),
                  ),
                )
              else
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
              // El chevron dice «esto abre». En modo seleccion el toque marca,
              // asi que la flecha estaria mintiendo.
              if (!seleccionando)
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

/// La barra de arriba mientras hay visitas marcadas. Reemplaza la de la marca
/// para que quede claro que la pantalla esta en otro modo.
class _AppBarSeleccion extends StatelessWidget implements PreferredSizeWidget {
  const _AppBarSeleccion({
    required this.cantidad,
    required this.total,
    required this.onCerrar,
    required this.onTodas,
  });

  final int cantidad;
  final int total;
  final VoidCallback onCerrar;
  final VoidCallback onTodas;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 64,
      leading: IconButton(
        icon: const Icon(Icons.close),
        tooltip: 'Salir de la seleccion',
        onPressed: onCerrar,
      ),
      title: Text(
        cantidad == 1 ? '1 visita' : '$cantidad visitas',
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
      actions: [
        if (cantidad < total)
          TextButton(onPressed: onTodas, child: const Text('Todas')),
        const SizedBox(width: 8),
      ],
    );
  }
}

/// Descargar y eliminar, abajo y con texto.
///
/// «Eliminar» va en rojo y a la derecha, separado del otro: son las dos
/// acciones mas distintas que tiene la app — una guarda y la otra destruye — y
/// se van a tocar con el telefono en una mano.
class _BarraAcciones extends StatelessWidget {
  const _BarraAcciones({
    required this.cantidad,
    required this.onDescargar,
    required this.onEliminar,
  });

  final int cantidad;
  final VoidCallback onDescargar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sufijo = cantidad == 1 ? 'visita' : 'visitas';

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: onDescargar,
                icon: const Icon(Icons.download_outlined),
                label: Text('Descargar $sufijo'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: onEliminar,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Eliminar'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 50),
                foregroundColor: scheme.error,
                side: BorderSide(color: scheme.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
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
