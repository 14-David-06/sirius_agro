import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../core/geo.dart';
import '../data/db/app_database.dart';
import '../state/providers.dart';
import '../state/trazado.dart';
import 'croquis.dart';
import 'marca.dart';

/// La pantalla donde se dibuja un lote caminandolo.
///
/// Principio que ordena todo lo de aca: **el visitador decide**. La app no
/// elige por el si el lote se marca esquina por esquina o con un reloj, ni
/// cada cuanto, ni con que precision minima, ni cuando se cierra el anillo.
/// Un lindero de potrero con cuatro mojones y el contorno de un cafetal en
/// ladera no se capturan igual, y quien sabe cual es cual esta parado ahi.
///
/// Lo unico que la app se reserva es no mentir: cada punto guarda su precision
/// y si lo puso el dedo o el reloj, y eso se ve en pantalla.
class TrazadoPage extends ConsumerWidget {
  const TrazadoPage({
    super.key,
    required this.visitaId,
    required this.trazadoId,
  });

  final String visitaId;
  final String trazadoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trazado = ref.watch(trazadoProvider(trazadoId)).valueOrNull;
    final puntos = ref.watch(puntosTrazadoProvider(trazadoId)).valueOrNull ?? [];
    final captura = ref.watch(capturaProvider(trazadoId));
    final ctrl = ref.read(capturaProvider(trazadoId).notifier);

    if (trazado == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBarMarca(
        titulo: trazado.nombre,
        actions: [
          IconButton(
            tooltip: 'Renombrar',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _editarFicha(context, ref, trazado),
          ),
          IconButton(
            tooltip: 'Eliminar trazado',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _eliminar(context, ref, trazado),
          ),
        ],
      ),
      body: Column(
        children: [
          if (captura.error != null)
            Banda(
              texto: captura.error!,
              icono: Icons.error_outline,
              tono: TonoPildora.error,
              onCerrar: ctrl.limpiarError,
            ),
          if (captura.aviso != null)
            Banda(
              texto: captura.aviso!,
              icono: Icons.info_outline,
              onCerrar: ctrl.limpiarAviso,
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Croquis(puntos: puntos, cerrado: _cerradoEfectivo(trazado)),
                const SizedBox(height: 14),
                _Medidas(trazado: trazado, puntos: puntos),
                const SizedBox(height: 24),
                const TituloSeccion('Como se captura'),
                _PanelCaptura(
                  trazado: trazado,
                  puntos: puntos,
                  estado: captura,
                ),
                const SizedBox(height: 24),
                const TituloSeccion('Puntos'),
                _ListaPuntos(trazado: trazado, puntos: puntos),
                const SizedBox(height: 24),
                const TituloSeccion('Salida'),
                _PanelExportar(visitaId: visitaId, trazado: trazado, puntos: puntos),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editarFicha(
    BuildContext context,
    WidgetRef ref,
    Trazado trazado,
  ) async {
    final datos = await mostrarFichaTrazado(context, trazado: trazado);
    if (datos == null) return;
    await ref.read(trazadoRepoProvider).actualizarTrazado(
          trazado.id,
          nombre: datos.nombre,
          tipo: datos.tipo,
          etiqueta: datos.etiqueta ?? '',
          notas: datos.notas ?? '',
        );
  }

  Future<void> _eliminar(
    BuildContext context,
    WidgetRef ref,
    Trazado trazado,
  ) async {
    final puntos = await ref.read(trazadoRepoProvider).puntosDeTrazado(trazado.id);
    if (!context.mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('¿Eliminar «${trazado.nombre}»?'),
        // Se dice cuantos puntos se pierden: son pasos caminados en el lote y
        // no se pueden volver a tomar desde el escritorio.
        content: Text(
          puntos.isEmpty
              ? 'No tiene puntos capturados.'
              : 'Se van ${puntos.length} punto(s) que se caminaron en la '
                  'finca. Esto no se deshace.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    ref.read(capturaProvider(trazado.id).notifier).detener();
    await ref.read(trazadoRepoProvider).eliminarTrazado(trazado.id);
    if (context.mounted) Navigator.of(context).pop();
  }
}

/// Un poligono solo se dibuja cerrado cuando de verdad es un anillo. Con dos
/// puntos, cerrarlo dibujaria la misma linea de ida y de vuelta.
bool _cerradoEfectivo(Trazado t) => t.tipo.esPoligono && t.cerrado;

/// Area, perimetro y cuenta de puntos. Es el numero por el que existe la
/// funcion: reemplaza «seran unas diez hectareas» por una medida.
class _Medidas extends StatelessWidget {
  const _Medidas({required this.trazado, required this.puntos});

  final Trazado trazado;
  final List<PuntoTrazado> puntos;

  @override
  Widget build(BuildContext context) {
    final geos = [for (final p in puntos) PuntoGeo(p.latitud, p.longitud)];
    final anillo = _cerradoEfectivo(trazado);

    // Se calcula aca y no se lee de la fila: la fila se refresca en cada
    // cambio, pero si alguna vez las dos se separan, lo que el visitador ve
    // tiene que ser lo que dicen los puntos que tiene al lado.
    final area = anillo && geos.length >= 3 ? areaM2(geos) : null;
    final largo = longitudMetros(geos, cerrado: anillo);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _Dato(
              etiqueta: 'Puntos',
              valor: '${puntos.length}',
              icono: Icons.place_outlined,
            ),
            _Dato(
              etiqueta: area != null ? 'Area' : 'Sin area',
              valor: area != null ? formatearArea(area) : '—',
              icono: Icons.crop_square,
              // Un poligono abierto no tiene area y hay que decir por que, o
              // parece que la app no supo calcularla.
              ayuda: area == null
                  ? (trazado.tipo.esPoligono
                      ? 'El anillo esta abierto o falta un tercer punto.'
                      : 'Un ${trazado.tipo.airtable.toLowerCase()} no encierra area.')
                  : null,
            ),
            _Dato(
              etiqueta: anillo ? 'Perimetro' : 'Recorrido',
              valor: formatearDistancia(largo),
              icono: Icons.straighten,
            ),
          ]
              .map((w) => Expanded(child: w))
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({
    required this.etiqueta,
    required this.valor,
    required this.icono,
    this.ayuda,
  });

  final String etiqueta;
  final String valor;
  final IconData icono;
  final String? ayuda;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;

    return Tooltip(
      message: ayuda ?? '',
      triggerMode: ayuda == null ? TooltipTriggerMode.manual : null,
      child: Column(
        children: [
          Icon(icono, size: 18, color: scheme.primary),
          const SizedBox(height: 6),
          Text(
            valor,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            etiqueta,
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// El panel que le da el control al visitador: marcar a mano, o prender el
/// reloj con los filtros que el elija.
class _PanelCaptura extends ConsumerWidget {
  const _PanelCaptura({
    required this.trazado,
    required this.puntos,
    required this.estado,
  });

  final Trazado trazado;
  final List<PuntoTrazado> puntos;
  final CapturaState estado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final ctrl = ref.read(capturaProvider(trazado.id).notifier);
    final repo = ref.read(trazadoRepoProvider);
    final esPunto = trazado.tipo == TipoTrazado.punto;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- A mano ---
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: estado.buscandoGps ||
                        (esPunto && puntos.isNotEmpty)
                    ? null
                    : () => ctrl.marcarPunto(),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                icon: estado.buscandoGps
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_location_alt_outlined),
                label: Text(
                  estado.buscandoGps
                      ? 'Fijando posicion...'
                      : esPunto && puntos.isNotEmpty
                          ? 'Este trazado ya tiene su punto'
                          : 'Marcar un punto aqui',
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Un punto marcado a mano entra siempre, con la precision que '
              'haya. Los filtros de abajo son solo para el modo automatico.',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.35,
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (puntos.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: ctrl.deshacerUltimo,
                      icon: const Icon(Icons.undo, size: 18),
                      label: const Text('Deshacer ultimo'),
                    ),
                  ),
                  if (trazado.tipo.esPoligono) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        // Cerrar es del visitador: mientras esto este en
                        // abierto, el KML sale como linea y no como lote.
                        onPressed: () => repo.actualizarTrazado(
                          trazado.id,
                          cerrado: !trazado.cerrado,
                        ),
                        icon: Icon(
                          trazado.cerrado ? Icons.lock_open : Icons.polyline,
                          size: 18,
                        ),
                        label: Text(trazado.cerrado ? 'Abrir' : 'Cerrar'),
                      ),
                    ),
                  ],
                ],
              ),
            ],

            if (!esPunto) ...[
              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // --- El reloj ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.timer_outlined,
                      color: estado.capturando ? scheme.error : scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Marcar cada cierto tiempo',
                          style: tema.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          estado.capturando
                              ? 'Capturando cada ${_intervalo(trazado)} s. '
                                  'Camina el contorno.'
                              : 'Para contornos curvos, donde marcar esquina '
                                  'por esquina daria un lote de seis lados.',
                          style: tema.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _Opciones(trazado: trazado, bloqueado: estado.capturando),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: estado.capturando
                    ? FilledButton.icon(
                        onPressed: ctrl.detener,
                        style: FilledButton.styleFrom(
                          backgroundColor: scheme.error,
                          foregroundColor: scheme.onError,
                          minimumSize: const Size(0, 48),
                        ),
                        icon: const Icon(Icons.stop),
                        label: const Text('Detener'),
                      )
                    : FilledButton.tonalIcon(
                        onPressed: () => ctrl.iniciar(_intervalo(trazado)),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 48),
                        ),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Empezar el recorrido'),
                      ),
              ),
              if (estado.capturando) ...[
                const SizedBox(height: 12),
                _Contadores(estado: estado),
                const SizedBox(height: 10),
                // Lo mismo que hace el panel de grabacion: decir la verdad
                // sobre lo que pasa si se apaga la pantalla, en vez de
                // esconderlo y perder el recorrido.
                const Pildora(
                  texto: 'Deja la app abierta mientras camines',
                  tono: TonoPildora.aviso,
                  icono: Icons.phone_android,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  int _intervalo(Trazado t) =>
      (t.intervaloSeg == null || t.intervaloSeg! < 3) ? 10 : t.intervaloSeg!;
}

/// Intervalo, distancia minima y precision maxima, en chips y no en un menu:
/// se tocan con guantes, de pie, sin dejar de mirar el lote.
class _Opciones extends ConsumerWidget {
  const _Opciones({required this.trazado, required this.bloqueado});

  final Trazado trazado;

  /// Mientras el reloj corre, cambiar el intervalo obligaria a reiniciarlo. Se
  /// deshabilita en vez de reiniciar solo: un recorrido que se corta a la
  /// mitad porque alguien toco un chip no es aceptable.
  final bool bloqueado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(trazadoRepoProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FilaOpcion(
          titulo: 'Un punto cada',
          opciones: const {'5 s': 5, '10 s': 10, '15 s': 15, '30 s': 30, '1 min': 60},
          actual: (trazado.intervaloSeg == null || trazado.intervaloSeg! < 3)
              ? 10
              : trazado.intervaloSeg!,
          bloqueado: bloqueado,
          onElegir: (v) => repo.actualizarTrazado(trazado.id, intervaloSeg: v),
        ),
        const SizedBox(height: 10),
        _FilaOpcion(
          titulo: 'Ignorar si esta a menos de',
          opciones: const {'Nada': 0.0, '2 m': 2.0, '5 m': 5.0, '10 m': 10.0, '20 m': 20.0},
          actual: trazado.distanciaMinM ?? 5.0,
          bloqueado: false,
          onElegir: (v) => repo.actualizarTrazado(trazado.id, distanciaMinM: v),
        ),
        const SizedBox(height: 10),
        _FilaOpcion(
          titulo: 'Descartar si el GPS falla mas de',
          opciones: const {'Sin limite': 0.0, '10 m': 10.0, '20 m': 20.0, '50 m': 50.0},
          actual: trazado.precisionMaxM ?? 0.0,
          bloqueado: false,
          onElegir: (v) => repo.actualizarTrazado(trazado.id, precisionMaxM: v),
        ),
      ],
    );
  }
}

class _FilaOpcion<T> extends StatelessWidget {
  const _FilaOpcion({
    required this.titulo,
    required this.opciones,
    required this.actual,
    required this.bloqueado,
    required this.onElegir,
  });

  final String titulo;
  final Map<String, T> opciones;
  final T actual;
  final bool bloqueado;
  final void Function(T) onElegir;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 0.3,
            fontWeight: FontWeight.w700,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final o in opciones.entries)
              ChoiceChip(
                label: Text(o.key),
                selected: o.value == actual,
                onSelected:
                    bloqueado ? null : (_) => onElegir(o.value),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ],
    );
  }
}

/// Lo que entro, lo que se descarto y por que. Es lo que responde «¿esto esta
/// funcionando?» sin tener que confiar.
class _Contadores extends StatelessWidget {
  const _Contadores({required this.estado});

  final CapturaState estado;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Pildora(
              texto: '${estado.agregados} en esta corrida',
              tono: TonoPildora.exito,
              icono: Icons.check,
            ),
            if (estado.descartadosCerca > 0)
              Pildora(
                texto: '${estado.descartadosCerca} muy cerca',
                icono: Icons.filter_alt_outlined,
              ),
            if (estado.descartadosPrecision > 0)
              Pildora(
                texto: '${estado.descartadosPrecision} sin precision',
                tono: TonoPildora.aviso,
                icono: Icons.gps_off,
              ),
            if (estado.precisionUltima != null)
              Pildora(
                texto: 'GPS ±${estado.precisionUltima!.round()} m',
                tono: estado.precisionUltima! > 15
                    ? TonoPildora.aviso
                    : TonoPildora.info,
                icono: Icons.gps_fixed,
              ),
          ],
        ),
        if (estado.descartadosPrecision > 0) ...[
          const SizedBox(height: 8),
          Text(
            'Los descartes por precision suelen ser sombra de arboles o '
            'nubes bajas. Salir al claro los arregla.',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.35,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// Cada punto con su huella: hora, precision y si lo puso el dedo o el reloj.
/// Se puede borrar uno solo, que es la unica defensa contra el salto de GPS.
class _ListaPuntos extends ConsumerStatefulWidget {
  const _ListaPuntos({required this.trazado, required this.puntos});

  final Trazado trazado;
  final List<PuntoTrazado> puntos;

  @override
  ConsumerState<_ListaPuntos> createState() => _ListaPuntosState();
}

class _ListaPuntosState extends ConsumerState<_ListaPuntos> {
  String? _abierto;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final puntos = widget.puntos;

    if (puntos.isEmpty) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.place_outlined),
          title: Text('Sin puntos todavia'),
          subtitle: Text('Marca uno a mano o prende el recorrido.'),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          for (var i = 0; i < puntos.length; i++)
            ListTile(
              dense: true,
              selected: puntos[i].id == _abierto,
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: puntos[i].automatico
                    ? scheme.surfaceContainerHighest
                    : scheme.primaryContainer,
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: puntos[i].automatico
                        ? scheme.onSurfaceVariant
                        : scheme.onPrimaryContainer,
                  ),
                ),
              ),
              title: Text(
                '${puntos[i].latitud.toStringAsFixed(6)}, '
                '${puntos[i].longitud.toStringAsFixed(6)}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              subtitle: Text(
                [
                  DateFormat('h:mm:ss a', 'es').format(puntos[i].capturadoEn),
                  if (puntos[i].precisionM != null)
                    '±${puntos[i].precisionM!.round()} m',
                  puntos[i].automatico ? 'reloj' : 'a mano',
                  if (puntos[i].nota != null) puntos[i].nota!,
                ].join(' · '),
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
              trailing: IconButton(
                tooltip: 'Borrar este punto',
                icon: const Icon(Icons.close, size: 18),
                onPressed: () =>
                    ref.read(trazadoRepoProvider).eliminarPunto(puntos[i].id),
              ),
              onTap: () => setState(
                () => _abierto = _abierto == puntos[i].id ? null : puntos[i].id,
              ),
            ),
        ],
      ),
    );
  }
}

/// El KML. Es la razon por la que se capturan los puntos: que el lote salga
/// del telefono y se pueda abrir en Google Earth o en QGIS.
class _PanelExportar extends ConsumerStatefulWidget {
  const _PanelExportar({
    required this.visitaId,
    required this.trazado,
    required this.puntos,
  });

  final String visitaId;
  final Trazado trazado;
  final List<PuntoTrazado> puntos;

  @override
  ConsumerState<_PanelExportar> createState() => _PanelExportarState();
}

class _PanelExportarState extends ConsumerState<_PanelExportar> {
  bool _soloEste = true;
  bool _conVertices = false;
  bool _conFotos = true;
  bool _trabajando = false;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final hayPuntos = widget.puntos.isNotEmpty;

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
                  child: Icon(Icons.public, color: scheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Exportar a KML', style: tema.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        'Abre en Google Earth, QGIS y en la mayoria de los '
                        'programas de mapas. No necesita señal.',
                        style: tema.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: _soloEste,
              onChanged: (v) => setState(() => _soloEste = v),
              title: const Text('Solo este trazado', style: TextStyle(fontSize: 13)),
              subtitle: Text(
                _soloEste
                    ? 'Sale «${widget.trazado.nombre}» y nada mas.'
                    : 'Salen todos los lotes y recorridos de la visita.',
                style: const TextStyle(fontSize: 11.5),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: _conVertices,
              onChanged: (v) => setState(() => _conVertices = v),
              title: const Text(
                'Incluir cada punto como marca',
                style: TextStyle(fontSize: 13),
              ),
              subtitle: const Text(
                'Con su hora y su precision. Util para revisar la captura; '
                'en un recorrido largo son cientos de marcas.',
                style: TextStyle(fontSize: 11.5),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: _conFotos,
              onChanged: (v) => setState(() => _conFotos = v),
              title: const Text(
                'Incluir donde se tomaron las fotos',
                style: TextStyle(fontSize: 13),
              ),
              subtitle: const Text(
                'Las fotos de la visita que tengan coordenada.',
                style: TextStyle(fontSize: 11.5),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: hayPuntos && !_trabajando ? _exportar : null,
                icon: _trabajando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.share_outlined),
                label: Text(
                  _trabajando
                      ? 'Armando el KML...'
                      : hayPuntos
                          ? 'Exportar y compartir'
                          : 'Falta capturar puntos',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportar() async {
    final mensajero = ScaffoldMessenger.of(context);
    final caja = context.findRenderObject() as RenderBox?;
    setState(() => _trabajando = true);

    try {
      final archivo = await ref.read(trazadoRepoProvider).exportarKml(
            widget.visitaId,
            soloTrazadoId: _soloEste ? widget.trazado.id : null,
            incluirVertices: _conVertices,
            incluirFotos: _conFotos,
          );

      await SharePlus.instance.share(
        ShareParams(
          // El tipo MIME es el que hace que Android ofrezca Google Earth en la
          // lista en vez de tratarlo como un texto cualquiera.
          files: [
            XFile(
              archivo.path,
              mimeType: 'application/vnd.google-earth.kml+xml',
            ),
          ],
          subject: widget.trazado.nombre,
          sharePositionOrigin:
              caja == null ? null : caja.localToGlobal(Offset.zero) & caja.size,
        ),
      );
    } catch (e) {
      mensajero.showSnackBar(
        SnackBar(content: Text('No se pudo exportar el KML: $e')),
      );
    } finally {
      if (mounted) setState(() => _trabajando = false);
    }
  }
}

/// Lo que se le pregunta al crear o renombrar un trazado. Corto a proposito:
/// el resto se decide caminando.
class FichaTrazado {
  const FichaTrazado({
    required this.nombre,
    required this.tipo,
    this.etiqueta,
    this.notas,
  });

  final String nombre;
  final TipoTrazado tipo;
  final String? etiqueta;
  final String? notas;
}

/// Hoja de creacion/edicion. Devuelve null si el visitador se arrepintio.
///
/// El nombre puede quedar vacio: el repositorio pone «Lote 2» y eso alcanza
/// para arrancar. Obligar a nombrar antes de capturar es poner un formulario
/// entre el visitador y el lote.
Future<FichaTrazado?> mostrarFichaTrazado(
  BuildContext context, {
  Trazado? trazado,
}) {
  return showModalBottomSheet<FichaTrazado>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _HojaFicha(trazado: trazado),
  );
}

class _HojaFicha extends StatefulWidget {
  const _HojaFicha({this.trazado});

  final Trazado? trazado;

  @override
  State<_HojaFicha> createState() => _HojaFichaState();
}

class _HojaFichaState extends State<_HojaFicha> {
  late final _nombre = TextEditingController(text: widget.trazado?.nombre ?? '');
  late final _etiqueta =
      TextEditingController(text: widget.trazado?.etiqueta ?? '');
  late final _notas = TextEditingController(text: widget.trazado?.notas ?? '');
  late TipoTrazado _tipo = widget.trazado?.tipo ?? TipoTrazado.poligono;

  @override
  void dispose() {
    _nombre.dispose();
    _etiqueta.dispose();
    _notas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final editando = widget.trazado != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            editando ? 'Editar trazado' : 'Nuevo trazado',
            style: tema.textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Text(
            '¿QUE SE VA A DIBUJAR?',
            style: TextStyle(
              fontSize: 10.5,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
              color: tema.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          RadioGroup<TipoTrazado>(
            groupValue: _tipo,
            onChanged: (v) => setState(() => _tipo = v ?? _tipo),
            child: Column(
              children: [
                for (final t in TipoTrazado.values)
                  RadioListTile<TipoTrazado>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: t,
                    title: Text(
                      _tituloTipo(t),
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      _ayudaTipo(t),
                      style: const TextStyle(fontSize: 11.5, height: 1.3),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nombre,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              hintText: 'Lote de arriba, lindero con el vecino...',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _etiqueta,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Que hay sembrado (opcional)',
              hintText: 'Platano, pasto, cacao joven...',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notas,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Notas (opcional)',
              hintText: 'Lo que haya que recordar de este pedazo',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(
              FichaTrazado(
                nombre: _nombre.text,
                tipo: _tipo,
                etiqueta: _etiqueta.text,
                notas: _notas.text,
              ),
            ),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            child: Text(editando ? 'Guardar' : 'Crear y empezar'),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  String _tituloTipo(TipoTrazado t) => switch (t) {
        TipoTrazado.poligono => 'Un lote (poligono con area)',
        TipoTrazado.ruta => 'Un recorrido (linea)',
        TipoTrazado.punto => 'Un punto suelto',
      };

  String _ayudaTipo(TipoTrazado t) => switch (t) {
        TipoTrazado.poligono =>
          'Se camina el contorno y se cierra. Da hectareas.',
        TipoTrazado.ruta =>
          'El lindero, el camino de acceso, la ronda por el cultivo. Da largo.',
        TipoTrazado.punto =>
          'La bocatoma, el arbol enfermo, donde se saco la muestra de suelo.',
      };
}
