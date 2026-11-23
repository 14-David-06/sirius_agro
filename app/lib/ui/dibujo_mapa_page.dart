import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../core/dibujo.dart';
import '../core/geo.dart';
import '../data/db/app_database.dart';
import '../state/providers.dart';
import '../state/trazado.dart';
import 'mapa_trazado.dart';
import 'marca.dart';
import 'theme.dart';

/// Como se esta usando el dedo sobre el mapa.
///
/// Tiene que ser una eleccion explicita y no adivinarse del gesto: en un mapa
/// arrastrar significa «mover la vista», y si de repente significa «dibujar»
/// sin que el visitador lo haya pedido, el lote se llena de rayones.
enum HerramientaDibujo {
  mover('Mover', Icons.pan_tool_outlined),
  pincel('Pincel', Icons.brush_outlined),
  vertices('Vertices', Icons.polyline_outlined);

  const HerramientaDibujo(this.titulo, this.icono);

  final String titulo;
  final IconData icono;
}

/// Dibujar el lote directamente sobre el mapa satelital, a pantalla completa.
///
/// Es la otra forma de capturar un lote, junto a caminarlo: cuando el lindero
/// se ve en la imagen, cuando el lote esta del otro lado del rio, o cuando no
/// hay tiempo de recorrerlo. Dos herramientas:
///
/// - **Pincel**: se rodea el lote con el dedo sin soltar y al soltar se cierra
///   solo. El trazo se simplifica para quitarle el temblor del dedo.
/// - **Vertices**: un toque por esquina, en orden. Es lo que sirve para un
///   lindero recto con mojones que se ven en la imagen.
///
/// Lo dibujado es un borrador hasta que se guarda, y al guardar REEMPLAZA los
/// puntos que el trazado tuviera — con confirmacion si alguno se camino con
/// GPS. Cada punto queda con nota de con que se dibujo y sin precision: no la
/// midio ningun GPS, y fingir que si seria mentirle a quien revise el lindero.
class DibujoMapaPage extends ConsumerStatefulWidget {
  const DibujoMapaPage({
    super.key,
    required this.visitaId,
    required this.trazadoId,
  });

  final String visitaId;
  final String trazadoId;

  @override
  ConsumerState<DibujoMapaPage> createState() => _DibujoMapaPageState();
}

class _DibujoMapaPageState extends ConsumerState<DibujoMapaPage> {
  final _mapa = MapController();

  /// Null hasta saber el tipo del trazado: un punto no se dibuja con pincel.
  HerramientaDibujo? _herramienta;

  final List<VerticeDibujado> _borrador = [];

  /// Las posiciones del dedo mientras dibuja con el pincel, en pixeles del
  /// mapa. Se convierten a coordenadas al soltar, no antes: convertir cada
  /// posicion mientras el dedo se mueve no agrega nada y cuesta cuadros.
  List<Offset> _trazoEnVivo = const [];

  bool _guardando = false;

  /// Ya se guardo: salir no tiene nada que perder.
  bool _guardado = false;

  HerramientaDibujo _porDefecto(Trazado t) => t.tipo == TipoTrazado.punto
      ? HerramientaDibujo.vertices
      : HerramientaDibujo.pincel;

  @override
  Widget build(BuildContext context) {
    final trazado = ref.watch(trazadoProvider(widget.trazadoId)).valueOrNull;
    final puntosGuardados = ref.watch(puntosTrazadoProvider(widget.trazadoId));
    final existentes = puntosGuardados.valueOrNull ?? const <PuntoTrazado>[];
    final visita = ref.watch(visitaProvider(widget.visitaId)).valueOrNull;

    // Se espera a los puntos que ya tiene antes de abrir el mapa: el primer
    // encuadre es el que los muestra, y despues el mapa ya no se mueve solo.
    if (trazado == null || !puntosGuardados.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final herramienta = _herramienta ?? _porDefecto(trazado);
    final cerrado = trazado.tipo.esPoligono;

    // Donde abrir: el trazado que ya existe, o la coordenada de llegada de la
    // visita. Sin ninguna de las dos el mapa no sabe en que vereda esta.
    final centro = existentes.isNotEmpty
        ? _centroide(existentes)
        : visita?.latitud != null && visita?.longitud != null
        ? PuntoGeo(visita!.latitud!, visita.longitud!)
        : null;

    return PopScope(
      canPop: _borrador.isEmpty || _guardado,
      onPopInvokedWithResult: (salio, _) async {
        if (salio) return;
        if (await _confirmarDescartar() && context.mounted) {
          setState(() => _borrador.clear());
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBarMarca(titulo: 'Dibujar · ${trazado.nombre}'),
        body: Column(
          children: [
            Expanded(
              child: MapaTrazado(
                puntos: _comoPuntos(trazado.id),
                cerrado: cerrado,
                unirPuntos: trazado.tipo.unePuntos,
                altura: double.infinity,
                centroPorDefecto: centro,
                encuadrarTambien: [
                  for (final p in existentes) PuntoGeo(p.latitud, p.longitud),
                ],
                controlador: _mapa,
                // El mapa no se mueve solo mientras se dibuja: cada esquina
                // nueva reencuadraria la vista debajo del dedo.
                seguirPuntos: false,
                // Un trazo de pincel trae decenas de vertices; numerarlos
                // todos tapa el lote que se esta dibujando.
                mostrarVertices:
                    herramienta == HerramientaDibujo.vertices ||
                    _borrador.length <= 30,
                capasExtra: [
                  if (existentes.isNotEmpty)
                    _capaExistente(existentes, trazado: trazado),
                ],
                onTocar: herramienta == HerramientaDibujo.vertices
                    ? _agregarVertice
                    : null,
                // El lienzo va encima del mapa y debajo de los botones: con
                // el pincel puesto se puede seguir cambiando de capa o ir a
                // «mi ubicacion».
                encima: herramienta == HerramientaDibujo.pincel
                    ? _LienzoPincel(
                        trazo: _trazoEnVivo,
                        cerrado: cerrado,
                        onInicio: (p) => setState(() => _trazoEnVivo = [p]),
                        onMovimiento: (p) {
                          // Menos de dos pixeles es el dedo quieto: no es
                          // forma.
                          if (_trazoEnVivo.isNotEmpty &&
                              (_trazoEnVivo.last - p).distance < 2) {
                            return;
                          }
                          setState(() => _trazoEnVivo = [..._trazoEnVivo, p]);
                        },
                        onFin: () => _terminarTrazo(cerrado),
                      )
                    : null,
              ),
            ),
            _Panel(
              trazado: trazado,
              herramienta: herramienta,
              borrador: _borrador,
              existentes: existentes.length,
              guardando: _guardando,
              onHerramienta: (h) => setState(() => _herramienta = h),
              onDeshacer: _borrador.isEmpty
                  ? null
                  : () => setState(() => _borrador.removeLast()),
              onBorrar: _borrador.isEmpty
                  ? null
                  : () => setState(() => _borrador.clear()),
              onGuardar: () => _guardar(trazado),
            ),
          ],
        ),
      ),
    );
  }

  /// El borrador con la forma que pide el mapa. Son filas de mentira —sin id
  /// real ni fecha— que solo existen para dibujarse; lo que se guarda sale de
  /// [_borrador], no de aca.
  List<PuntoTrazado> _comoPuntos(String trazadoId) => [
    for (var i = 0; i < _borrador.length; i++)
      PuntoTrazado(
        id: 'borrador-$i',
        trazadoId: trazadoId,
        orden: i + 1,
        latitud: _borrador[i].latitud,
        longitud: _borrador[i].longitud,
        capturadoEn: DateTime.fromMillisecondsSinceEpoch(0),
        automatico: false,
      ),
  ];

  /// Lo que el trazado ya tiene, punteado y claro: es la referencia para
  /// corregirlo, no lo que se esta dibujando.
  Widget _capaExistente(List<PuntoTrazado> puntos, {required Trazado trazado}) {
    final coords = [for (final p in puntos) LatLng(p.latitud, p.longitud)];
    const color = Colors.white;
    final patron = StrokePattern.dashed(segments: const [10, 7]);
    // Un grupo de puntos sueltos no tiene contorno: se marca cada uno.
    if (!trazado.tipo.unePuntos || coords.length == 1) {
      return CircleLayer(
        circles: [
          for (final c in coords)
            CircleMarker(
              point: c,
              radius: 6,
              color: color.withValues(alpha: 0.35),
              borderColor: color.withValues(alpha: 0.9),
              borderStrokeWidth: 1.5,
            ),
        ],
      );
    }
    if (trazado.tipo.esPoligono && coords.length > 2) {
      return PolygonLayer(
        polygons: [
          Polygon(
            points: coords,
            borderColor: color.withValues(alpha: 0.85),
            borderStrokeWidth: 2,
            pattern: patron,
            color: color.withValues(alpha: 0.06),
          ),
        ],
      );
    }
    return PolylineLayer(
      polylines: [
        Polyline(
          points: coords,
          color: color.withValues(alpha: 0.85),
          strokeWidth: 2,
          pattern: patron,
        ),
      ],
    );
  }

  /// Un toque, un vertice al final del borrador. En un trazado de tipo punto
  /// cada toque es un punto suelto mas (las plantas de un lote, por ejemplo).
  void _agregarVertice(double latitud, double longitud) {
    setState(() {
      _borrador.add((latitud: latitud, longitud: longitud, conPincel: false));
    });
  }

  void _terminarTrazo(bool cerrado) {
    final crudo = _trazoEnVivo;
    setState(() => _trazoEnVivo = const []);

    final listo = prepararTrazo(crudo, cerrado: cerrado);
    if (listo.length < (cerrado ? 3 : 2)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            // Un toque suelto con el pincel tambien llega aca: es la senal de
            // que el visitador quiso tocar, no dibujar.
            content: Text(
              crudo.length < 2
                  ? 'Con el pincel se dibuja arrastrando. Para mover el mapa, '
                        'elige «Mover».'
                  : 'El trazo es muy corto. Rodea el lote con el dedo sin '
                        'soltar.',
            ),
          ),
        );
      return;
    }

    final camara = _mapa.camera;
    setState(() {
      // Cada trazo de pincel es el lote entero, no un pedazo: reemplaza al
      // anterior. Para corregir una esquina estan los vertices.
      _borrador
        ..clear()
        ..addAll([
          for (final p in listo)
            () {
              final c = camara.screenOffsetToLatLng(p);
              return (
                latitud: c.latitude,
                longitud: c.longitude,
                conPincel: true,
              );
            }(),
        ]);
    });
  }

  Future<bool> _confirmarDescartar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Salir sin guardar?'),
        content: const Text('Lo que dibujaste no se guarda.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Seguir dibujando'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _guardar(Trazado trazado) async {
    if (_guardando) return;
    final cerrado = trazado.tipo.esPoligono;
    final minimo = switch (trazado.tipo) {
      TipoTrazado.poligono => 3,
      TipoTrazado.ruta => 2,
      TipoTrazado.punto => 1,
    };
    if (_borrador.length < minimo) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            minimo == 1
                ? 'Toca el mapa donde va el punto.'
                : 'Faltan puntos: un ${cerrado ? 'lote' : 'recorrido'} necesita '
                      'al menos $minimo.',
          ),
        ),
      );
      return;
    }

    final geos = [for (final v in _borrador) PuntoGeo(v.latitud, v.longitud)];
    if (trazado.tipo != TipoTrazado.punto &&
        seCruza(geos, cerrado: cerrado) &&
        !await _confirmar(
          titulo: 'El dibujo se cruza consigo mismo',
          texto:
              'Asi el area no corresponde al lote: se resta una parte de '
              'la otra. Lo mejor es borrarlo y volver a dibujarlo.',
          aceptar: 'Guardar igual',
        )) {
      return;
    }

    final repo = ref.read(trazadoRepoProvider);
    final existentes = await repo.puntosDeTrazado(trazado.id);
    if (existentes.isNotEmpty) {
      final conGps = existentes.where((p) => p.precisionM != null).length;
      if (!mounted) return;
      final ok = await _confirmar(
        titulo: '¿Reemplazar los puntos de «${trazado.nombre}»?',
        texto: conGps == 0
            ? 'Tiene ${existentes.length} punto(s). Se cambian por los '
                  '${_borrador.length} que dibujaste.'
            : 'Tiene ${existentes.length} punto(s), $conGps de ellos '
                  'caminados con GPS. Se cambian por los ${_borrador.length} que '
                  'dibujaste, y los caminados no se pueden recuperar.',
        aceptar: 'Reemplazar',
      );
      if (!ok) return;
    }

    setState(() => _guardando = true);
    try {
      await repo.reemplazarPuntos(trazado.id, List.of(_borrador));
      if (!mounted) return;
      setState(() => _guardado = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Se guardaron ${_borrador.length} puntos.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el dibujo: $e')),
      );
    }
  }

  Future<bool> _confirmar({
    required String titulo,
    required String texto,
    required String aceptar,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(texto),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(aceptar),
          ),
        ],
      ),
    );
    return ok == true;
  }
}

PuntoGeo _centroide(List<PuntoTrazado> puntos) {
  var lat = 0.0;
  var lon = 0.0;
  for (final p in puntos) {
    lat += p.latitud;
    lon += p.longitud;
  }
  return PuntoGeo(lat / puntos.length, lon / puntos.length);
}

/// La capa que recibe el dedo cuando el pincel esta activo.
///
/// Va ENCIMA del mapa y se queda con todos los toques: mientras se dibuja, el
/// mapa no se arrastra ni se acerca. Para mover la vista esta la herramienta
/// «Mover»; mezclar las dos en el mismo gesto es como se arruina un contorno.
class _LienzoPincel extends StatelessWidget {
  const _LienzoPincel({
    required this.trazo,
    required this.cerrado,
    required this.onInicio,
    required this.onMovimiento,
    required this.onFin,
  });

  final List<Offset> trazo;
  final bool cerrado;
  final ValueChanged<Offset> onInicio;
  final ValueChanged<Offset> onMovimiento;
  final VoidCallback onFin;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (d) => onInicio(d.localPosition),
      onPanUpdate: (d) => onMovimiento(d.localPosition),
      onPanEnd: (_) => onFin(),
      onPanCancel: onFin,
      child: CustomPaint(
        painter: _PintorTrazo(
          trazo: trazo,
          cerrado: cerrado,
          color: Theme.of(context).marca.aviso,
        ),
      ),
    );
  }
}

class _PintorTrazo extends CustomPainter {
  const _PintorTrazo({
    required this.trazo,
    required this.cerrado,
    required this.color,
  });

  final List<Offset> trazo;
  final bool cerrado;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (trazo.length < 2) return;
    final camino = Path()..moveTo(trazo.first.dx, trazo.first.dy);
    for (final p in trazo.skip(1)) {
      camino.lineTo(p.dx, p.dy);
    }

    if (cerrado) {
      // El relleno muestra el lote que va a quedar al soltar, ya cerrado.
      canvas.drawPath(
        Path.from(camino)..close(),
        Paint()..color = color.withValues(alpha: 0.18),
      );
    }
    // Un borde oscuro debajo del trazo: sobre el verde del satelite una linea
    // clara sola se pierde.
    canvas.drawPath(
      camino,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      camino,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_PintorTrazo antes) =>
      antes.trazo != trazo || antes.cerrado != cerrado || antes.color != color;
}

/// Abajo del mapa: la herramienta, lo que mide el borrador y los botones.
class _Panel extends StatelessWidget {
  const _Panel({
    required this.trazado,
    required this.herramienta,
    required this.borrador,
    required this.existentes,
    required this.guardando,
    required this.onHerramienta,
    required this.onDeshacer,
    required this.onBorrar,
    required this.onGuardar,
  });

  final Trazado trazado;
  final HerramientaDibujo herramienta;
  final List<VerticeDibujado> borrador;
  final int existentes;
  final bool guardando;
  final ValueChanged<HerramientaDibujo> onHerramienta;
  final VoidCallback? onDeshacer;
  final VoidCallback? onBorrar;
  final VoidCallback onGuardar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final cerrado = trazado.tipo.esPoligono;
    final esPunto = trazado.tipo == TipoTrazado.punto;

    final geos = [for (final v in borrador) PuntoGeo(v.latitud, v.longitud)];
    final area = cerrado && geos.length >= 3 ? areaM2(geos) : null;
    final largo = longitudMetros(geos, cerrado: cerrado);
    final cruza = !esPunto && seCruza(geos, cerrado: cerrado);

    final ayuda = switch (herramienta) {
      HerramientaDibujo.mover =>
        'Arrastra y pellizca para ubicar el lote. El dedo no dibuja.',
      HerramientaDibujo.pincel =>
        cerrado
            ? 'Rodea el lote con el dedo sin soltar. Al soltar se cierra solo; '
                  'un trazo nuevo reemplaza al anterior.'
            : 'Recorre el camino con el dedo sin soltar. Un trazo nuevo '
                  'reemplaza al anterior.',
      HerramientaDibujo.vertices =>
        esPunto
            ? 'Toca el mapa donde va cada punto.'
            : 'Toca cada esquina en orden. Se agregan al final de lo dibujado.',
    };

    return Material(
      color: scheme.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<HerramientaDibujo>(
                segments: [
                  for (final h in HerramientaDibujo.values)
                    ButtonSegment(
                      value: h,
                      icon: Icon(h.icono, size: 18),
                      label: Text(h.titulo),
                      // Un punto no tiene contorno que rodear.
                      enabled: !(esPunto && h == HerramientaDibujo.pincel),
                    ),
                ],
                selected: {herramienta},
                showSelectedIcon: false,
                onSelectionChanged: (s) => onHerramienta(s.first),
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  textStyle: WidgetStatePropertyAll(tema.textTheme.labelMedium),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ayuda,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                [
                  '${borrador.length} punto(s)',
                  if (area != null) formatearArea(area),
                  if (!esPunto && geos.length > 1)
                    '${cerrado ? 'perimetro' : 'largo'} ${formatearDistancia(largo)}',
                  if (existentes > 0)
                    'reemplaza ${existentes == 1 ? 'el punto' : 'los $existentes puntos'} que tiene',
                ].join(' · '),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (cruza) ...[
                const SizedBox(height: 4),
                Text(
                  'El contorno se cruza consigo mismo: el area no seria real.',
                  style: TextStyle(fontSize: 12, color: scheme.error),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Deshacer el ultimo punto',
                    onPressed: onDeshacer,
                    icon: const Icon(Icons.undo),
                  ),
                  IconButton(
                    tooltip: 'Borrar lo dibujado',
                    onPressed: onBorrar,
                    icon: const Icon(Icons.delete_sweep_outlined),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: borrador.isEmpty || guardando ? null : onGuardar,
                    icon: guardando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Guardar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
