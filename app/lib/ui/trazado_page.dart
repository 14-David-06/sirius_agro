import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../core/geo.dart';
import '../data/db/app_database.dart';
import '../data/trazado_repository.dart';
import '../state/providers.dart';
import '../state/red.dart';
import '../state/trazado.dart';
import 'croquis.dart';
import 'dibujo_mapa_page.dart';
import 'mapa_trazado.dart';
import 'marca.dart';
import 'theme.dart';

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
class TrazadoPage extends ConsumerStatefulWidget {
  const TrazadoPage({
    super.key,
    required this.visitaId,
    required this.trazadoId,
  });

  final String visitaId;
  final String trazadoId;

  @override
  ConsumerState<TrazadoPage> createState() => _TrazadoPageState();
}

class _TrazadoPageState extends ConsumerState<TrazadoPage> {
  /// Mapa o croquis. Arranca en nulo: mientras el visitador no elija, manda la
  /// red — con senal el mapa, sin senal el croquis, que es lo unico que se ve
  /// igual en los dos casos. Apenas toca el selector, la eleccion es suya y no
  /// se la cambia una barra de senal que va y viene.
  bool? _verMapa;

  /// Si tocar el mapa agrega un vertice. Arranca apagado a proposito: el
  /// primer gesto de cualquiera sobre un mapa es arrastrarlo, y un trazado que
  /// gana puntos fantasma mientras alguien lo mira es peor que uno vacio.
  bool _tocarAgrega = false;

  String get visitaId => widget.visitaId;
  String get trazadoId => widget.trazadoId;

  @override
  Widget build(BuildContext context) {
    final trazado = ref.watch(trazadoProvider(trazadoId)).valueOrNull;
    final puntos =
        ref.watch(puntosTrazadoProvider(trazadoId)).valueOrNull ?? [];
    final captura = ref.watch(capturaProvider(trazadoId));
    final ctrl = ref.read(capturaProvider(trazadoId).notifier);

    if (trazado == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
                if (trazado.grupo != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.folder_outlined,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Del grupo «${trazado.grupo}»',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                _Vista(
                  trazado: trazado,
                  puntos: puntos,
                  verMapa: _verMapa,
                  tocarAgrega: _tocarAgrega,
                  visita: ref.watch(visitaProvider(visitaId)).valueOrNull,
                  onVista: (mapa) => setState(() => _verMapa = mapa),
                  onTocarAgrega: (v) => setState(() => _tocarAgrega = v),
                  onPunto: _agregarDesdeMapa,
                ),
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
                _PanelExportar(
                  visitaId: visitaId,
                  trazado: trazado,
                  puntos: puntos,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Un vertice puesto con el dedo sobre el mapa.
  ///
  /// No es lo mismo que uno caminado y hay que decirlo: va sin precision —no
  /// la tiene, no la midio ningun GPS— y con la nota «marcado en el mapa», que
  /// es lo que va a leer quien revise el lindero seis meses despues y se
  /// pregunte por que ese punto no tiene error asociado.
  Future<void> _agregarDesdeMapa(double latitud, double longitud) async {
    final trazado = ref.read(trazadoProvider(trazadoId)).valueOrNull;
    if (trazado == null) return;

    // Un trazado de tipo punto acepta varios: es un grupo de puntos sueltos
    // (las plantas de un lote), y cada toque es una planta mas.
    await ref
        .read(trazadoRepoProvider)
        .agregarPunto(
          trazadoId: trazadoId,
          latitud: latitud,
          longitud: longitud,
          nota: 'marcado en el mapa',
        );
  }

  Future<void> _editarFicha(
    BuildContext context,
    WidgetRef ref,
    Trazado trazado,
  ) async {
    final repo = ref.read(trazadoRepoProvider);
    final grupos = TrazadoRepository.gruposDe(
      await repo.trazadosDeVisita(trazado.visitaId),
    );
    if (!context.mounted) return;
    final datos = await mostrarFichaTrazado(
      context,
      trazado: trazado,
      grupos: grupos,
    );
    if (datos == null) return;
    await repo.actualizarTrazado(
      trazado.id,
      nombre: datos.nombre,
      tipo: datos.tipo,
      etiqueta: datos.etiqueta ?? '',
      notas: datos.notas ?? '',
      grupo: datos.grupo ?? '',
    );
  }

  Future<void> _eliminar(
    BuildContext context,
    WidgetRef ref,
    Trazado trazado,
  ) async {
    final puntos = await ref
        .read(trazadoRepoProvider)
        .puntosDeTrazado(trazado.id);
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

/// El dibujo de arriba: croquis o mapa, con el selector para cambiar.
///
/// Los dos muestran lo mismo —los puntos, en orden, con el primero distinto—
/// y por eso se pueden alternar sin perder el hilo. La diferencia es lo que
/// hay debajo: el croquis no necesita nada y el mapa necesita red.
class _Vista extends ConsumerWidget {
  const _Vista({
    required this.trazado,
    required this.puntos,
    required this.verMapa,
    required this.tocarAgrega,
    required this.visita,
    required this.onVista,
    required this.onTocarAgrega,
    required this.onPunto,
  });

  final Trazado trazado;
  final List<PuntoTrazado> puntos;
  final bool? verMapa;
  final bool tocarAgrega;
  final Visita? visita;
  final ValueChanged<bool> onVista;
  final ValueChanged<bool> onTocarAgrega;
  final void Function(double latitud, double longitud) onPunto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final red = ref.watch(redProvider);
    // El mapa solo necesita bajar teselas de OSM, y para eso alcanza con que
    // el telefono tenga salida a Internet: que el backend de Sirius no
    // conteste no le impide funcionar.
    final hayRed = red == EstadoRed.enLinea || red == EstadoRed.sinServidor;
    final mapa = verMapa ?? hayRed;

    final centro = visita?.latitud != null && visita?.longitud != null
        ? PuntoGeo(visita!.latitud!, visita!.longitud!)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              icon: Icon(Icons.gesture, size: 18),
              label: Text('Croquis'),
            ),
            ButtonSegment(
              value: true,
              icon: Icon(Icons.map_outlined, size: 18),
              label: Text('Mapa'),
            ),
          ],
          selected: {mapa},
          showSelectedIcon: false,
          onSelectionChanged: (s) => onVista(s.first),
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            textStyle: WidgetStatePropertyAll(tema.textTheme.labelMedium),
          ),
        ),
        const SizedBox(height: 10),
        if (!mapa)
          Croquis(
            puntos: puntos,
            cerrado: _cerradoEfectivo(trazado),
            unirPuntos: trazado.tipo.unePuntos,
          )
        else ...[
          MapaTrazado(
            puntos: puntos,
            cerrado: _cerradoEfectivo(trazado),
            unirPuntos: trazado.tipo.unePuntos,
            centroPorDefecto: centro,
            onTocar: tocarAgrega ? onPunto : null,
          ),
          const SizedBox(height: 6),
          SwitchListTile(
            value: tocarAgrega,
            onChanged: onTocarAgrega,
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Tocar el mapa agrega puntos',
              style: TextStyle(fontSize: 13),
            ),
            subtitle: Text(
              tocarAgrega
                  ? 'Cada toque deja un vertice donde tocaste, sin precision '
                        'de GPS. Para el lindero real, caminalo.'
                  : 'Prendelo para dibujar el lote sobre el mapa con el dedo.',
              style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
            ),
          ),
          if (!hayRed)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Sin red el satelite muestra lo guardado en el telefono (el '
                'municipio y alrededor de las fincas); las calles pueden salir '
                'en blanco. Los puntos se guardan igual.',
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.35,
                  color: tema.marca.aviso,
                ),
              ),
            ),
        ],
        const SizedBox(height: 8),
        // A pantalla completa y con herramientas propias: dibujar en el mapa
        // chico de arriba, dentro de una pantalla que se desplaza, peleaba con
        // el dedo que quiere mover la lista.
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DibujoMapaPage(
                visitaId: trazado.visitaId,
                trazadoId: trazado.id,
              ),
            ),
          ),
          icon: const Icon(Icons.draw_outlined, size: 18),
          label: Text(switch (trazado.tipo) {
            TipoTrazado.poligono => 'Dibujar en el mapa (uno o varios lotes)',
            TipoTrazado.ruta => 'Dibujar en el mapa (pincel o vertices)',
            TipoTrazado.punto => 'Marcar puntos en el mapa',
          }),
        ),
      ],
    );
  }
}

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

    // Un grupo de puntos sueltos no tiene area ni largo. Lo que importa de un
    // grupo de plantas es cuantas son, que tan bien las ubico el GPS y que
    // tan repartidas estan.
    if (!trazado.tipo.unePuntos) {
      final precisiones = [
        for (final p in puntos)
          if (p.precisionM != null) p.precisionM!,
      ];
      final media = precisiones.isEmpty
          ? null
          : precisiones.reduce((a, b) => a + b) / precisiones.length;
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              _Dato(
                etiqueta: 'Puntos',
                valor: '${puntos.length}',
                icono: Icons.scatter_plot_outlined,
              ),
              _Dato(
                etiqueta: 'GPS promedio',
                valor: media == null ? '—' : '±${media.round()} m',
                icono: Icons.gps_fixed,
                ayuda: media == null
                    ? 'Los puntos marcados en el mapa no tienen precision.'
                    : null,
              ),
              _Dato(
                etiqueta: 'Mas separados',
                valor: geos.length < 2
                    ? '—'
                    : formatearDistancia(_mayorSeparacion(geos)),
                icono: Icons.open_in_full,
                ayuda: 'La distancia entre los dos puntos mas alejados.',
              ),
            ].map((w) => Expanded(child: w)).toList(growable: false),
          ),
        ),
      );
    }

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
          ].map((w) => Expanded(child: w)).toList(growable: false),
        ),
      ),
    );
  }
}

/// La distancia entre los dos puntos mas alejados del grupo. Es cuadratica,
/// pero un grupo son decenas de plantas, no miles.
double _mayorSeparacion(List<PuntoGeo> geos) {
  var mayor = 0.0;
  for (var i = 0; i < geos.length; i++) {
    for (var j = i + 1; j < geos.length; j++) {
      final d = distanciaMetros(geos[i], geos[j]);
      if (d > mayor) mayor = d;
    }
  }
  return mayor;
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
                onPressed: estado.buscandoGps ? null : () => ctrl.marcarPunto(),
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
                      ? 'Marcar otro punto aqui (${puntos.length + 1})'
                      : 'Marcar un punto aqui',
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              esPunto
                  ? 'Parate junto a cada planta (o foco, o arbol) y toca el '
                        'boton: cada toque guarda un punto aparte, numerado, con '
                        'su hora y su precision. En la lista de abajo se le pone '
                        'una nota a cada uno.'
                  : 'Un punto marcado a mano entra siempre, con la precision '
                        'que haya. Los filtros de abajo son solo para el modo '
                        'automatico.',
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
          opciones: const {
            '5 s': 5,
            '10 s': 10,
            '15 s': 15,
            '30 s': 30,
            '1 min': 60,
          },
          actual: (trazado.intervaloSeg == null || trazado.intervaloSeg! < 3)
              ? 10
              : trazado.intervaloSeg!,
          bloqueado: bloqueado,
          onElegir: (v) => repo.actualizarTrazado(trazado.id, intervaloSeg: v),
        ),
        const SizedBox(height: 10),
        _FilaOpcion(
          titulo: 'Ignorar si esta a menos de',
          opciones: const {
            'Nada': 0.0,
            '2 m': 2.0,
            '5 m': 5.0,
            '10 m': 10.0,
            '20 m': 20.0,
          },
          actual: trazado.distanciaMinM ?? 5.0,
          bloqueado: false,
          onElegir: (v) => repo.actualizarTrazado(trazado.id, distanciaMinM: v),
        ),
        const SizedBox(height: 10),
        _FilaOpcion(
          titulo: 'Descartar si el GPS falla mas de',
          opciones: const {
            'Sin limite': 0.0,
            '10 m': 10.0,
            '20 m': 20.0,
            '50 m': 50.0,
          },
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
                onSelected: bloqueado ? null : (_) => onElegir(o.value),
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

  /// La nota es lo que dice que es cada punto de un grupo: «con monilia»,
  /// «injerto nuevo». Sale en la lista, en el KML y en la ficha de Google
  /// Earth al tocar la marca.
  Future<void> _editarNota(PuntoTrazado punto, int numero) async {
    final nota = await showDialog<String>(
      context: context,
      builder: (_) => _DialogoNota(numero: numero, inicial: punto.nota),
    );
    if (nota == null) return;
    await ref.read(trazadoRepoProvider).actualizarNotaPunto(punto.id, nota);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final puntos = widget.puntos;

    if (puntos.isEmpty) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.place_outlined),
          title: const Text('Sin puntos todavia'),
          subtitle: Text(
            widget.trazado.tipo.unePuntos
                ? 'Marca uno a mano o prende el recorrido.'
                : 'Marca el primero con el boton de arriba.',
          ),
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
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: puntos[i].nota == null
                        ? 'Agregar una nota'
                        : 'Cambiar la nota',
                    icon: const Icon(Icons.edit_note, size: 20),
                    onPressed: () => _editarNota(puntos[i], i + 1),
                  ),
                  IconButton(
                    tooltip: 'Borrar este punto',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => ref
                        .read(trazadoRepoProvider)
                        .eliminarPunto(puntos[i].id),
                  ),
                ],
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

/// Pide la nota de un punto. Devuelve el texto (vacio = borrar la nota) o
/// null si se cancelo.
class _DialogoNota extends StatefulWidget {
  const _DialogoNota({required this.numero, this.inicial});

  final int numero;
  final String? inicial;

  @override
  State<_DialogoNota> createState() => _DialogoNotaState();
}

class _DialogoNotaState extends State<_DialogoNota> {
  late final _control = TextEditingController(text: widget.inicial ?? '');

  @override
  void dispose() {
    _control.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Nota del punto ${widget.numero}'),
      content: TextField(
        controller: _control,
        autofocus: true,
        maxLines: 2,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          hintText: 'Con monilia, injerto nuevo, la mas alta...',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_control.text),
          child: const Text('Guardar'),
        ),
      ],
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
              title: const Text(
                'Solo este trazado',
                style: TextStyle(fontSize: 13),
              ),
              subtitle: Text(
                _soloEste
                    ? 'Sale «${widget.trazado.nombre}» y nada mas.'
                    : 'Salen todos los lotes y recorridos de la visita.',
                style: const TextStyle(fontSize: 11.5),
              ),
            ),
            // En un grupo de puntos sueltos cada punto ya sale como marca
            // propia: el interruptor no cambiaria nada.
            if (widget.trazado.tipo.unePuntos)
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
      final archivo = await ref
          .read(trazadoRepoProvider)
          .exportarKml(
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
          sharePositionOrigin: caja == null
              ? null
              : caja.localToGlobal(Offset.zero) & caja.size,
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
    this.grupo,
  });

  final String nombre;
  final TipoTrazado tipo;
  final String? etiqueta;
  final String? notas;

  /// Vacio o null = suelto, fuera de cualquier grupo.
  final String? grupo;
}

/// Hoja de creacion/edicion. Devuelve null si el visitador se arrepintio.
///
/// El nombre puede quedar vacio: el repositorio pone «Lote 2» y eso alcanza
/// para arrancar. Obligar a nombrar antes de capturar es poner un formulario
/// entre el visitador y el lote.
///
/// [grupos] son los que ya tiene la visita: se ofrecen con un toque, porque
/// meter un lote en un grupo existente escribiendo el nombre a mano es como
/// terminan «Finca El Recreo» y «finca el recreo» siendo dos grupos.
Future<FichaTrazado?> mostrarFichaTrazado(
  BuildContext context, {
  Trazado? trazado,
  List<String> grupos = const [],
}) {
  return showModalBottomSheet<FichaTrazado>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _HojaFicha(trazado: trazado, grupos: grupos),
  );
}

class _HojaFicha extends StatefulWidget {
  const _HojaFicha({this.trazado, this.grupos = const []});

  final Trazado? trazado;
  final List<String> grupos;

  @override
  State<_HojaFicha> createState() => _HojaFichaState();
}

class _HojaFichaState extends State<_HojaFicha> {
  late final _nombre = TextEditingController(
    text: widget.trazado?.nombre ?? '',
  );
  late final _etiqueta = TextEditingController(
    text: widget.trazado?.etiqueta ?? '',
  );
  late final _notas = TextEditingController(text: widget.trazado?.notas ?? '');
  late final _grupo = TextEditingController(text: widget.trazado?.grupo ?? '');
  late TipoTrazado _tipo = widget.trazado?.tipo ?? TipoTrazado.poligono;

  @override
  void dispose() {
    _nombre.dispose();
    _etiqueta.dispose();
    _notas.dispose();
    _grupo.dispose();
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
      // Con el teclado abierto y el grupo, la hoja ya no cabe en un telefono
      // chico: se desplaza en vez de desbordarse.
      child: SingleChildScrollView(
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
            const SizedBox(height: 12),
            TextField(
              controller: _grupo,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Grupo (opcional)',
                hintText: 'Finca El Recreo, cacao...',
                helperText:
                    'Los trazados con el mismo grupo se ven juntos y '
                    'suman su area. Vacio = suelto.',
                suffixIcon: _grupo.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Sacarlo del grupo',
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(_grupo.clear),
                      ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (widget.grupos.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final g in widget.grupos)
                    ChoiceChip(
                      avatar: const Icon(Icons.folder_outlined, size: 16),
                      label: Text(g),
                      selected: _grupo.text.trim() == g,
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => setState(() => _grupo.text = g),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(
                FichaTrazado(
                  nombre: _nombre.text,
                  tipo: _tipo,
                  etiqueta: _etiqueta.text,
                  notas: _notas.text,
                  grupo: _grupo.text,
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
      ),
    );
  }

  String _tituloTipo(TipoTrazado t) => switch (t) {
    TipoTrazado.poligono => 'Un lote (poligono con area)',
    TipoTrazado.ruta => 'Un recorrido (linea)',
    TipoTrazado.punto => 'Puntos sueltos (uno o un grupo)',
  };

  String _ayudaTipo(TipoTrazado t) => switch (t) {
    TipoTrazado.poligono => 'Se camina el contorno y se cierra. Da hectareas.',
    TipoTrazado.ruta =>
      'El lindero, el camino de acceso, la ronda por el cultivo. Da largo.',
    TipoTrazado.punto =>
      'La bocatoma, o un grupo: las plantas enfermas de un lote, los '
          'focos de plaga, los arboles de sombra. Cada punto queda aparte, '
          'numerado y con su nota.',
  };
}
