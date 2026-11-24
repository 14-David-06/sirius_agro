import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../core/dibujo.dart';
import '../core/geo.dart';
import '../data/db/app_database.dart';
import '../data/trazado_repository.dart';
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

/// Otro trazado de la misma visita, con sus puntos: se muestra de referencia.
typedef _TrazadoVecino = ({Trazado trazado, List<PuntoTrazado> puntos});

/// Un poligono de esta pasada: lo que se dibujo y el nombre que se le puso.
class _Figura {
  final List<VerticeDibujado> vertices = [];

  /// El nombre que le puso el visitador. Null = el de siempre: el del
  /// trazado que se abrio, o «Lote 3» para uno nuevo.
  String? nombre;
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
/// En un lote se pueden dibujar varios poligonos de una vez con «Otro lote»,
/// cada uno con el nombre que se le quiera poner: la finca entera en una sola
/// pasada. Quedan como un **grupo**: el primero es el trazado que se abrio y
/// cada uno de los demas se guarda como un lote nuevo de la visita, con su
/// propia area, y todos con el mismo nombre de grupo. Los otros trazados de la
/// visita se ven de referencia, para no volver a dibujar uno que ya esta.
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

  /// Lo dibujado, un poligono por lote. El primero es el del trazado que se
  /// abrio; cada uno de los demas se guarda como un lote nuevo. Siempre hay
  /// al menos uno, aunque este vacio.
  final List<_Figura> _figuras = [_Figura()];

  /// El poligono que reciben el pincel, los toques y el boton de deshacer.
  int _activa = 0;

  /// El nombre del grupo, si se escribio en esta pasada. Null = el de por
  /// defecto («Grupo 1»). Solo cuenta si el trazado que se abrio no tenia
  /// grupo: si ya lo tenia, los nuevos se suman a ese.
  String? _grupoNuevo;

  List<VerticeDibujado> get _borrador => _figuras[_activa].vertices;

  bool get _hayDibujo => _figuras.any((f) => f.vertices.isNotEmpty);

  /// Hay algo que se perderia al salir: lo dibujado, o el nombre nuevo del
  /// trazado que se abrio (los de los demas no existen sin dibujo).
  bool get _hayCambios => _hayDibujo || _figuras[0].nombre != null;

  /// Las posiciones del dedo mientras dibuja con el pincel, en pixeles del
  /// mapa. Se convierten a coordenadas al soltar, no antes: convertir cada
  /// posicion mientras el dedo se mueve no agrega nada y cuesta cuadros.
  List<Offset> _trazoEnVivo = const [];

  /// Ya cargo lo necesario para abrir el mapa. Despues no se vuelve a
  /// esperar: al guardar aparecen lotes nuevos con puntos que todavia se
  /// estan leyendo, y eso no es razon para tapar el mapa con un spinner.
  bool _abierto = false;

  /// Los trazados que la visita tenia al abrir el mapa. Los lotes que se
  /// crean al guardar no se cuelan como referencia en el ultimo cuadro antes
  /// de salir, ni corren la numeracion de los que se estan guardando. Null si
  /// la lista no se pudo leer: entonces vale la que haya.
  Set<String>? _alAbrir;

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
    final deLaVisita = ref.watch(trazadosProvider(widget.visitaId));
    final previos = deLaVisita.valueOrNull == null
        ? null
        : [
            for (final t in deLaVisita.value!)
              if (_alAbrir?.contains(t.id) ?? true) t,
          ];
    final otrosAsync = [
      for (final t in previos ?? const <Trazado>[])
        if (t.id != widget.trazadoId)
          (trazado: t, puntos: ref.watch(puntosTrazadoProvider(t.id))),
    ];

    // Se espera a los puntos que ya tiene —y a los de los otros lotes— antes
    // de abrir el mapa: el primer encuadre es el que los muestra, y despues
    // el mapa ya no se mueve solo.
    bool listo(AsyncValue<Object?> v) => v.hasValue || v.hasError;
    if (trazado == null ||
        !puntosGuardados.hasValue ||
        (!_abierto &&
            (!listo(deLaVisita) || otrosAsync.any((o) => !listo(o.puntos))))) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_abierto) {
      _abierto = true;
      _alAbrir = previos == null ? null : {for (final t in previos) t.id};
    }

    final otros = <_TrazadoVecino>[
      for (final o in otrosAsync)
        if (o.puntos.valueOrNull?.isNotEmpty ?? false)
          (trazado: o.trazado, puntos: o.puntos.value!),
    ];

    final herramienta = _herramienta ?? _porDefecto(trazado);
    final cerrado = trazado.tipo.esPoligono;
    // Varios a la vez solo en lotes: un recorrido o un grupo de puntos ya se
    // dibujan enteros en una sola figura.
    final varias = trazado.tipo == TipoTrazado.poligono;
    final nombres = _nombres(trazado, previos);
    final grupo = _grupo(trazado, previos);

    // Donde abrir: el trazado que ya existe, la coordenada de llegada de la
    // visita o los otros lotes. Sin ninguna el mapa no sabe en que vereda
    // esta.
    final deReferencia = [
      for (final o in otros)
        for (final p in o.puntos) PuntoGeo(p.latitud, p.longitud),
    ];
    final centroMapa = existentes.isNotEmpty
        ? centro([for (final p in existentes) PuntoGeo(p.latitud, p.longitud)])
        : visita?.latitud != null && visita?.longitud != null
        ? PuntoGeo(visita!.latitud!, visita.longitud!)
        : centro(deReferencia);

    return PopScope(
      canPop: !_hayCambios || _guardado,
      onPopInvokedWithResult: (salio, _) async {
        if (salio) return;
        if (await _confirmarDescartar() && context.mounted) {
          setState(() {
            _figuras
              ..clear()
              ..add(_Figura());
            _activa = 0;
          });
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBarMarca(titulo: 'Dibujar · ${nombres[0]}'),
        body: Column(
          children: [
            Expanded(
              child: MapaTrazado(
                puntos: _comoPuntos(trazado.id),
                cerrado: cerrado,
                unirPuntos: trazado.tipo.unePuntos,
                altura: double.infinity,
                centroPorDefecto: centroMapa,
                // Lo que el trazado ya tiene; si no tiene nada, los otros
                // lotes de la visita: el nuevo casi siempre esta al lado. Y
                // los lotes de esta pasada, para que «volver a encuadrar» los
                // muestre todos y no solo el activo.
                encuadrarTambien: [
                  if (existentes.isNotEmpty)
                    for (final p in existentes) PuntoGeo(p.latitud, p.longitud)
                  else
                    ...deReferencia,
                  for (final f in _figuras)
                    for (final v in f.vertices) PuntoGeo(v.latitud, v.longitud),
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
                  for (final o in otros)
                    _capaReferencia(
                      o.puntos,
                      tipo: o.trazado.tipo,
                      tenue: true,
                    ),
                  if (existentes.isNotEmpty)
                    _capaReferencia(existentes, tipo: trazado.tipo),
                  ..._capasFiguras(context, cerrado: cerrado),
                  _capaRotulos(otros, nombres: nombres, varias: varias),
                ],
                onTocar: switch (herramienta) {
                  HerramientaDibujo.vertices => _agregarVertice,
                  // Con «Mover», tocar un lote dibujado lo elige para seguir
                  // con el. Solo hace falta si hay mas de uno.
                  HerramientaDibujo.mover when _figuras.length > 1 =>
                    _elegirTocando,
                  _ => null,
                },
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
              figuras: [for (final f in _figuras) f.vertices],
              activa: _activa,
              nombres: nombres,
              varias: varias,
              grupo: grupo,
              existentes: existentes.length,
              guardando: _guardando,
              hayCambios: _hayCambios,
              onHerramienta: (h) => setState(() => _herramienta = h),
              // Tocar el lote elegido es la forma de ponerle nombre: es lo que
              // se le ocurre a cualquiera al ver «Lote 3» y querer «Palma».
              onTocarFigura: (i) => i == _activa
                  ? _nombrarFigura(i, nombres[i])
                  : setState(() => _activa = i),
              // El grupo se nombra aca solo si es nuevo. Si el lote ya tenia
              // grupo, cambiarle el nombre es cosa de la lista de la visita:
              // aca renombraria lotes que no estan en pantalla.
              onNombrarGrupo: grupo != null && trazado.grupo == null
                  ? () => _nombrarGrupo(grupo)
                  : null,
              // Un lote nuevo a la vez: mientras haya uno de mas sin dibujar,
              // no se abre otro.
              onOtroLote: _figuras.skip(1).any((f) => f.vertices.isEmpty)
                  ? null
                  : _otroLote,
              onDeshacer: _borrador.isEmpty
                  ? null
                  : () => setState(() => _borrador.removeLast()),
              onBorrar: _borrador.isEmpty && _activa == 0
                  ? null
                  : _borrarFigura,
              onGuardar: () => _guardar(trazado, nombres, grupo),
            ),
          ],
        ),
      ),
    );
  }

  /// Como se va a llamar cada poligono: el nombre que le puso el visitador o,
  /// si no le puso, el que ya tenia el trazado que se abrio y, para los
  /// nuevos, el que les va a poner el repositorio al crearlos —«Lote 3»,
  /// «Lote 4»—, que numera por tipo dentro de la visita.
  List<String> _nombres(Trazado trazado, List<Trazado>? deLaVisita) {
    final n = (deLaVisita ?? const <Trazado>[])
        .where((t) => t.tipo == trazado.tipo)
        .length;
    return [
      _figuras[0].nombre ?? trazado.nombre,
      for (var i = 1; i < _figuras.length; i++)
        _figuras[i].nombre ??
            (deLaVisita == null ? 'Lote nuevo $i' : 'Lote ${n + i}'),
    ];
  }

  /// El grupo en que quedan los poligonos al guardar. Si el trazado que se
  /// abrio ya tenia grupo, ese; si no, uno nuevo apenas hay mas de un
  /// poligono. Null con uno solo y sin grupo: no hay nada que juntar.
  String? _grupo(Trazado trazado, List<Trazado>? deLaVisita) {
    if (trazado.grupo != null) return trazado.grupo;
    if (_figuras.length < 2) return null;
    return _grupoNuevo ??
        TrazadoRepository.grupoPorDefecto(deLaVisita ?? const []);
  }

  /// La figura activa con la forma que pide el mapa. Son filas de mentira
  /// —sin id real ni fecha— que solo existen para dibujarse; lo que se guarda
  /// sale de [_figuras], no de aca.
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

  /// Un trazado ya guardado, punteado y claro: es la referencia para
  /// corregirlo o para no volver a dibujarlo, no lo que se esta dibujando.
  /// [tenue] para los otros trazados de la visita, que importan menos que el
  /// que se abrio.
  Widget _capaReferencia(
    List<PuntoTrazado> puntos, {
    required TipoTrazado tipo,
    bool tenue = false,
  }) {
    final coords = [for (final p in puntos) LatLng(p.latitud, p.longitud)];
    final alfa = tenue ? 0.55 : 1.0;
    const color = Colors.white;
    final patron = StrokePattern.dashed(segments: const [10, 7]);
    // Un grupo de puntos sueltos no tiene contorno: se marca cada uno.
    if (!tipo.unePuntos || coords.length == 1) {
      return CircleLayer(
        circles: [
          for (final c in coords)
            CircleMarker(
              point: c,
              radius: 6,
              color: color.withValues(alpha: 0.35 * alfa),
              borderColor: color.withValues(alpha: 0.9 * alfa),
              borderStrokeWidth: 1.5,
            ),
        ],
      );
    }
    if (tipo.esPoligono && coords.length > 2) {
      return PolygonLayer(
        polygons: [
          Polygon(
            points: coords,
            borderColor: color.withValues(alpha: 0.85 * alfa),
            borderStrokeWidth: 2,
            pattern: patron,
            color: color.withValues(alpha: 0.06 * alfa),
          ),
        ],
      );
    }
    return PolylineLayer(
      polylines: [
        Polyline(
          points: coords,
          color: color.withValues(alpha: 0.85 * alfa),
          strokeWidth: 2,
          pattern: patron,
        ),
      ],
    );
  }

  /// Los lotes dibujados que no son el activo: con linea fina y sin numeros,
  /// para que se lea cual es el que recibe el dedo.
  List<Widget> _capasFiguras(BuildContext context, {required bool cerrado}) {
    final color = Theme.of(context).marca.exito;
    final quietas = [
      for (var i = 0; i < _figuras.length; i++)
        if (i != _activa && _figuras[i].vertices.isNotEmpty)
          [for (final v in _figuras[i].vertices) LatLng(v.latitud, v.longitud)],
    ];
    if (quietas.isEmpty) return const [];
    return [
      PolygonLayer(
        polygons: [
          for (final f in quietas)
            if (cerrado && f.length > 2)
              Polygon(
                points: f,
                borderColor: color.withValues(alpha: 0.8),
                borderStrokeWidth: 2,
                color: color.withValues(alpha: 0.12),
              ),
        ],
      ),
      PolylineLayer(
        polylines: [
          for (final f in quietas)
            if (f.length == 2 || (!cerrado && f.length > 1))
              Polyline(
                points: f,
                color: color.withValues(alpha: 0.8),
                strokeWidth: 2,
              ),
        ],
      ),
      CircleLayer(
        circles: [
          for (final f in quietas)
            if (f.length == 1)
              CircleMarker(
                point: f.first,
                radius: 5,
                color: color.withValues(alpha: 0.8),
              ),
        ],
      ),
    ];
  }

  /// El nombre de cada lote en su centro: con varios en pantalla, sin nombre
  /// no se sabe cual es «Lote 3» en la lista de la visita.
  Widget _capaRotulos(
    List<_TrazadoVecino> otros, {
    required List<String> nombres,
    required bool varias,
  }) {
    Marker rotulo(List<PuntoGeo> puntos, String texto, {bool activo = false}) {
      final c = centro(puntos)!;
      return Marker(
        point: LatLng(c.latitud, c.longitud),
        width: 150,
        height: 26,
        child: IgnorePointer(
          child: Center(
            child: _Rotulo(texto: texto, activo: activo),
          ),
        ),
      );
    }

    return MarkerLayer(
      markers: [
        for (final o in otros)
          if (o.trazado.tipo.esPoligono && o.puntos.length > 2)
            rotulo([
              for (final p in o.puntos) PuntoGeo(p.latitud, p.longitud),
            ], o.trazado.nombre),
        // Con una sola figura el nombre ya esta en la barra de arriba.
        if (varias && _figuras.length > 1)
          for (var i = 0; i < _figuras.length; i++)
            if (_figuras[i].vertices.length > 2)
              rotulo(
                [
                  for (final v in _figuras[i].vertices)
                    PuntoGeo(v.latitud, v.longitud),
                ],
                nombres[i],
                activo: i == _activa,
              ),
      ],
    );
  }

  /// Un toque, un vertice al final de la figura activa. En un trazado de tipo
  /// punto cada toque es un punto suelto mas (las plantas de un lote, por
  /// ejemplo).
  void _agregarVertice(double latitud, double longitud) {
    setState(() {
      _borrador.add((latitud: latitud, longitud: longitud, conPincel: false));
    });
  }

  /// Con «Mover», un toque dentro de un lote dibujado lo vuelve el activo.
  void _elegirTocando(double latitud, double longitud) {
    final toque = PuntoGeo(latitud, longitud);
    for (var i = 0; i < _figuras.length; i++) {
      if (i == _activa) continue;
      final anillo = [
        for (final v in _figuras[i].vertices) PuntoGeo(v.latitud, v.longitud),
      ];
      if (contienePunto(anillo, toque)) {
        setState(() => _activa = i);
        return;
      }
    }
  }

  void _otroLote() {
    setState(() {
      _figuras.add(_Figura());
      _activa = _figuras.length - 1;
    });
  }

  /// Borra lo dibujado en la figura activa. Un lote de mas se quita entero,
  /// con su nombre; el primero solo se vacia, porque es el trazado que se
  /// abrio y vacio quiere decir «este no se toca».
  void _borrarFigura() {
    setState(() {
      if (_activa == 0) {
        _figuras[0].vertices.clear();
      } else {
        _figuras.removeAt(_activa);
        _activa--;
      }
    });
  }

  Future<void> _nombrarFigura(int i, String actual) async {
    final nombre = await _pedirNombre(
      titulo: i == 0 ? 'Nombre de este lote' : 'Nombre del lote nuevo',
      actual: actual,
      ayuda: 'Palma 2015, potrero de abajo, cacao del rio...',
      // Vacio vuelve al de siempre. Para el primero no hay «de siempre» que
      // borrar: vacio deja el que ya tenia.
      nota: i == 0
          ? 'Vacio deja el nombre que ya tenia.'
          : 'Vacio deja el nombre de por defecto.',
    );
    // Aceptar sin cambiar nada no es un cambio: no tiene que preguntar al
    // salir si se descarta.
    if (nombre == null || nombre == actual) return;
    if (!mounted || i >= _figuras.length) return;
    setState(() => _figuras[i].nombre = nombre.isEmpty ? null : nombre);
  }

  Future<void> _nombrarGrupo(String actual) async {
    final nombre = await _pedirNombre(
      titulo: 'Nombre del grupo',
      actual: actual,
      ayuda: 'Finca El Recreo, cacao, lotes de palma...',
      nota: 'Vacio deja el nombre de por defecto.',
    );
    if (nombre == null || nombre == actual || !mounted) return;
    setState(() => _grupoNuevo = nombre.isEmpty ? null : nombre);
  }

  /// El texto escrito, ya recortado ('' si lo dejo vacio), o null si se
  /// cancelo.
  Future<String?> _pedirNombre({
    required String titulo,
    required String actual,
    required String ayuda,
    required String nota,
  }) async {
    final nombre = await showDialog<String>(
      context: context,
      builder: (_) => DialogoNombre(
        titulo: titulo,
        inicial: actual,
        ayuda: ayuda,
        nota: nota,
      ),
    );
    return nombre?.trim();
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
      // que se esta dibujando. Para corregir una esquina estan los vertices, y
      // para otro lote, «Otro lote».
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

  Future<void> _guardar(
    Trazado trazado,
    List<String> nombres,
    String? grupo,
  ) async {
    if (_guardando) return;
    final cerrado = trazado.tipo.esPoligono;
    final minimo = switch (trazado.tipo) {
      TipoTrazado.poligono => 3,
      TipoTrazado.ruta => 2,
      TipoTrazado.punto => 1,
    };
    void avisar(String texto) => ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));

    if (!_hayCambios) {
      avisar(
        minimo == 1
            ? 'Toca el mapa donde va el punto.'
            : 'Faltan puntos: un ${cerrado ? 'lote' : 'recorrido'} necesita '
                  'al menos $minimo.',
      );
      return;
    }
    // Un lote de mas que quedo vacio no es un lote: se ignora. Uno con dos
    // puntos si es un error, y se lleva al visitador a el para que lo termine.
    for (var i = 0; i < _figuras.length; i++) {
      final n = _figuras[i].vertices.length;
      if (n == 0 || n >= minimo) continue;
      setState(() => _activa = i);
      avisar(
        _figuras.length == 1
            ? 'Faltan puntos: un ${cerrado ? 'lote' : 'recorrido'} necesita '
                  'al menos $minimo.'
            : 'A «${nombres[i]}» le faltan puntos: un lote necesita al menos '
                  '$minimo. Terminalo o quitalo.',
      );
      return;
    }

    if (trazado.tipo != TipoTrazado.punto) {
      final cruzados = [
        for (var i = 0; i < _figuras.length; i++)
          if (seCruza([
            for (final v in _figuras[i].vertices)
              PuntoGeo(v.latitud, v.longitud),
          ], cerrado: cerrado))
            nombres[i],
      ];
      if (cruzados.isNotEmpty &&
          !await _confirmar(
            titulo: _figuras.length == 1
                ? 'El dibujo se cruza consigo mismo'
                : 'Se cruza consigo mismo: '
                      '${cruzados.map((n) => '«$n»').join(', ')}',
            texto:
                'Asi el area no corresponde al lote: se resta una parte de '
                'la otra. Lo mejor es borrarlo y volver a dibujarlo.',
            aceptar: 'Guardar igual',
          )) {
        return;
      }
    }

    final propios = List.of(_figuras[0].vertices);
    final nuevos = <LoteDibujado>[
      for (final f in _figuras.skip(1))
        if (f.vertices.isNotEmpty)
          (vertices: List.of(f.vertices), nombre: f.nombre),
    ];
    final nombresNuevos = [
      for (var i = 1; i < _figuras.length; i++)
        if (_figuras[i].vertices.isNotEmpty) nombres[i],
    ];

    final repo = ref.read(trazadoRepoProvider);
    final existentes = await repo.puntosDeTrazado(trazado.id);
    // Si el primero quedo vacio no se reemplaza nada: no hay que preguntar.
    if (propios.isNotEmpty && existentes.isNotEmpty) {
      final conGps = existentes.where((p) => p.precisionM != null).length;
      if (!mounted) return;
      final ok = await _confirmar(
        titulo: '¿Reemplazar los puntos de «${trazado.nombre}»?',
        texto: conGps == 0
            ? 'Tiene ${existentes.length} punto(s). Se cambian por los '
                  '${propios.length} que dibujaste.'
            : 'Tiene ${existentes.length} punto(s), $conGps de ellos '
                  'caminados con GPS. Se cambian por los ${propios.length} que '
                  'dibujaste, y los caminados no se pueden recuperar.',
        aceptar: 'Reemplazar',
      );
      if (!ok) return;
    }

    setState(() => _guardando = true);
    try {
      final ids = await repo.guardarDibujo(
        trazadoId: trazado.id,
        propios: propios,
        nombrePropio: _figuras[0].nombre,
        nuevos: nuevos,
        // Un poligono solo no hace grupo: si los de mas quedaron vacios, el
        // trazado que se abrio sigue como estaba.
        grupo: nuevos.isEmpty ? null : grupo,
      );
      final creados = [
        for (var i = 0; i < ids.length; i++)
          (await repo.porId(ids[i]))?.nombre ?? nombresNuevos[i],
      ];
      if (!mounted) return;
      setState(() => _guardado = true);
      final guardados = [if (propios.isNotEmpty) nombres[0], ...creados];
      final enGrupo = creados.isEmpty || grupo == null ? '' : ' en «$grupo»';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            creados.isEmpty
                ? propios.isEmpty
                      ? 'Ahora se llama «${nombres[0]}».'
                      : 'Se guardaron ${propios.length} puntos.'
                : guardados.length == 1
                ? 'Lote nuevo guardado$enGrupo: «${creados.first}».'
                : 'Se guardaron ${guardados.length} lotes$enGrupo: '
                      '${_enumerar(guardados)}.',
          ),
        ),
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

/// «A, B y C».
String _enumerar(List<String> nombres) => nombres.length < 2
    ? nombres.join()
    : '${nombres.sublist(0, nombres.length - 1).join(', ')} y ${nombres.last}';

/// Pide un nombre: el de un lote dibujado o el de un grupo. Devuelve lo
/// escrito, sin recortar, o null si se cancelo. Es un widget con estado y no
/// un controlador suelto porque el controlador tiene que vivir lo que dura la
/// animacion de cierre.
class DialogoNombre extends StatefulWidget {
  const DialogoNombre({
    super.key,
    required this.titulo,
    required this.inicial,
    required this.ayuda,
    this.nota,
  });

  final String titulo;
  final String inicial;
  final String ayuda;

  /// Lo que conviene saber antes de escribir, dicho debajo del campo.
  final String? nota;

  @override
  State<DialogoNombre> createState() => _DialogoNombreState();
}

class _DialogoNombreState extends State<DialogoNombre> {
  // Arranca con el nombre escrito y seleccionado: lo comun es reemplazar
  // «Lote 3» entero, y asi basta con empezar a escribir.
  late final _control = TextEditingController(text: widget.inicial)
    ..selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.inicial.length,
    );

  @override
  void dispose() {
    _control.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: TextField(
        controller: _control,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          hintText: widget.ayuda,
          helperText: widget.nota,
        ),
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_control.text),
          child: const Text('Listo'),
        ),
      ],
    );
  }
}

/// El nombre de un lote sobre el mapa. Oscuro y chico: tiene que leerse
/// encima del satelite sin tapar el lindero.
class _Rotulo extends StatelessWidget {
  const _Rotulo({required this.texto, required this.activo});

  final String texto;
  final bool activo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: activo
            ? Theme.of(context).marca.exito.withValues(alpha: 0.9)
            : Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        texto,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
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

/// Abajo del mapa: el grupo y sus lotes, la herramienta, lo que mide el lote
/// activo y los botones.
class _Panel extends StatelessWidget {
  const _Panel({
    required this.trazado,
    required this.herramienta,
    required this.figuras,
    required this.activa,
    required this.nombres,
    required this.varias,
    required this.grupo,
    required this.existentes,
    required this.guardando,
    required this.hayCambios,
    required this.onHerramienta,
    required this.onTocarFigura,
    required this.onNombrarGrupo,
    required this.onOtroLote,
    required this.onDeshacer,
    required this.onBorrar,
    required this.onGuardar,
  });

  final Trazado trazado;
  final HerramientaDibujo herramienta;
  final List<List<VerticeDibujado>> figuras;
  final int activa;
  final List<String> nombres;

  /// Si se pueden dibujar varios lotes: solo cuando el trazado es un lote.
  final bool varias;

  /// El grupo en que quedan al guardar, o null si no se agrupan.
  final String? grupo;
  final int existentes;
  final bool guardando;
  final bool hayCambios;
  final ValueChanged<HerramientaDibujo> onHerramienta;

  /// Tocar un lote que no es el elegido lo elige; tocar el elegido le pone
  /// nombre.
  final ValueChanged<int> onTocarFigura;

  /// Null si el grupo ya existia: se renombra desde la lista de la visita.
  final VoidCallback? onNombrarGrupo;
  final VoidCallback? onOtroLote;
  final VoidCallback? onDeshacer;
  final VoidCallback? onBorrar;
  final VoidCallback onGuardar;

  List<PuntoGeo> _geos(int i) => [
    for (final v in figuras[i]) PuntoGeo(v.latitud, v.longitud),
  ];

  /// Lo que dice el chip de cada lote: el nombre y cuanto mide.
  String _chip(int i) {
    final n = figuras[i].length;
    final detalle = n == 0
        ? (i == 0 && existentes > 0 ? 'sin cambios' : 'vacio')
        : n > 2
        ? formatearArea(areaM2(_geos(i)))
        : '$n pt';
    return '${nombres[i]} · $detalle';
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final cerrado = trazado.tipo.esPoligono;
    final esPunto = trazado.tipo == TipoTrazado.punto;
    final borrador = figuras[activa];

    final geos = _geos(activa);
    final area = cerrado && geos.length >= 3 ? areaM2(geos) : null;
    final largo = longitudMetros(geos, cerrado: cerrado);
    final cruza = !esPunto && seCruza(geos, cerrado: cerrado);
    final aGuardar = figuras.where((f) => f.isNotEmpty).length;

    final otro = varias
        ? ' «Otro lote» agrega uno mas; tocar el lote elegido le pone nombre.'
        : '';
    final ayuda = switch (herramienta) {
      HerramientaDibujo.mover =>
        'Arrastra y pellizca para ubicar el lote. El dedo no dibuja.'
            '${figuras.length > 1 ? ' Toca un lote dibujado para seguir con el.' : ''}',
      HerramientaDibujo.pincel =>
        cerrado
            ? 'Rodea el lote con el dedo sin soltar. Al soltar se cierra solo; '
                  'un trazo nuevo reemplaza al anterior.$otro'
            : 'Recorre el camino con el dedo sin soltar. Un trazo nuevo '
                  'reemplaza al anterior.',
      HerramientaDibujo.vertices =>
        esPunto
            ? 'Toca el mapa donde va cada punto.'
            : 'Toca cada esquina en orden. Se agregan al final de lo '
                  'dibujado.$otro',
    };

    final resumen = borrador.isEmpty
        ? (activa == 0 && existentes > 0
              ? 'Sin dibujar: «${nombres[0]}» se queda con '
                    '${existentes == 1 ? 'su punto' : 'sus $existentes puntos'}'
              : 'Sin dibujar todavia')
        : [
            '${borrador.length} punto(s)',
            if (area != null) formatearArea(area),
            if (!esPunto && geos.length > 1)
              '${cerrado ? 'perimetro' : 'largo'} ${formatearDistancia(largo)}',
            if (activa == 0 && existentes > 0)
              'reemplaza ${existentes == 1 ? 'el punto' : 'los $existentes puntos'} que tiene',
            if (activa > 0) 'lote nuevo',
          ].join(' · ');

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
              if (varias) ...[
                // El grupo y los lotes de esta pasada. El elegido es el que
                // recibe el dedo; los demas quedan quietos en el mapa.
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (grupo != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: onNombrarGrupo == null
                              // Ya existia: se dice a cual se suman, y que su
                              // nombre se cambia en otra parte.
                              ? Tooltip(
                                  triggerMode: TooltipTriggerMode.tap,
                                  message:
                                      'Los lotes nuevos se suman a este grupo. '
                                      'Su nombre se cambia desde la visita.',
                                  child: Chip(
                                    avatar: const Icon(
                                      Icons.folder_outlined,
                                      size: 18,
                                    ),
                                    label: Text(grupo!),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                )
                              : InputChip(
                                  avatar: const Icon(
                                    Icons.create_new_folder_outlined,
                                    size: 18,
                                  ),
                                  label: Text(grupo!),
                                  visualDensity: VisualDensity.compact,
                                  onPressed: onNombrarGrupo,
                                  deleteIcon: const Icon(Icons.edit, size: 16),
                                  deleteButtonTooltipMessage:
                                      'Cambiarle el nombre al grupo',
                                  onDeleted: onNombrarGrupo,
                                ),
                        ),
                      for (var i = 0; i < figuras.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          // El lapiz solo en el elegido: tocarlo otra vez es
                          // ponerle nombre.
                          child: InputChip(
                            label: Text(_chip(i)),
                            selected: i == activa,
                            showCheckmark: false,
                            visualDensity: VisualDensity.compact,
                            onSelected: (_) => onTocarFigura(i),
                            deleteIcon: const Icon(Icons.edit, size: 16),
                            deleteButtonTooltipMessage: 'Ponerle nombre',
                            onDeleted: i == activa
                                ? () => onTocarFigura(i)
                                : null,
                          ),
                        ),
                      ActionChip(
                        avatar: const Icon(Icons.add, size: 18),
                        label: const Text('Otro lote'),
                        visualDensity: VisualDensity.compact,
                        onPressed: onOtroLote,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
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
                resumen,
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
                    tooltip: activa == 0
                        ? 'Borrar lo dibujado'
                        : 'Quitar «${nombres[activa]}»',
                    onPressed: onBorrar,
                    icon: const Icon(Icons.delete_sweep_outlined),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: !hayCambios || guardando ? null : onGuardar,
                    icon: guardando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(
                      aGuardar > 1 ? 'Guardar $aGuardar lotes' : 'Guardar',
                    ),
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
