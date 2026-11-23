import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../core/geo.dart';
import '../core/teselas.dart';
import '../core/ubicacion.dart';
import '../data/db/app_database.dart';
import '../state/mapa_sin_senal.dart';
import '../state/mi_ubicacion.dart';
import '../state/red.dart';
import 'capa_mi_ubicacion.dart';
import 'proveedor_satelite.dart';
import 'theme.dart';

/// El trazado sobre un mapa de verdad, para ubicarlo en el terreno.
///
/// Complementa al croquis, no lo reemplaza: el croquis se dibuja siempre
/// porque no necesita nada, y el mapa necesita teselas. El satelite se guarda
/// en el telefono (el municipio, el detalle de las fincas y todo lo que se
/// mira con senal; ver [MapaSinSenal]) y se ve sin red. Las calles no: sin red
/// pueden salir en blanco.
///
/// Ninguna de las dos capas pide llave ni cuenta. Las calles son de
/// OpenStreetMap, que en zona rural colombiana tiene las vias y poco mas; el
/// satelite es la imagen de Esri (World Imagery), que si muestra el cultivo y
/// el lindero real. Por eso se alterna: una dice donde estas, la otra que hay.
///
/// La regla de uso del servidor publico de OSM pide identificar la app en el
/// user agent, y eso es [_paquete].
const _paquete = 'com.siriusregenerative.sirius_agro';

/// Las dos formas de mirar el terreno.
///
/// No sobra ninguna: el satelite muestra el cultivo, la ronda del cano y donde
/// termina el potrero —lo que un croquis nunca va a mostrar— pero se pierde
/// para ubicarse, porque no tiene nombres. Las calles tienen la via y el
/// caserio y no tienen ni un arbol. En campo se alterna entre las dos.
enum CapaMapa {
  calles('Calles', Icons.map_outlined),
  satelite('Satelite', Icons.satellite_alt);

  const CapaMapa(this.titulo, this.icono);

  final String titulo;
  final IconData icono;

  CapaMapa get otra => this == calles ? satelite : calles;
}

/// La capa elegida sobrevive a cerrar la pantalla, pero no a cerrar la app.
///
/// Arranca en satelite: en la finca lo que se busca es el cultivo y el
/// lindero, y eso solo lo muestra la imagen. Las calles quedan a un toque
/// para ubicarse.
///
/// Es una variable suelta y no una preferencia guardada a proposito: quien
/// cambia a calles lo hace para el lote que esta mirando ahora, y que siga asi
/// al abrir el trazado del vecino es lo que se espera. Guardarlo en disco
/// seria decidir por el visitador de la semana que viene.
CapaMapa _capaElegida = CapaMapa.satelite;

/// Imagen satelital de Esri (World Imagery). No pide llave ni cuenta.
///
/// Ojo con el orden: esta va `{z}/{y}/{x}`, al reves del `{z}/{x}/{y}` de OSM.
/// Cambiarlo por descuido no da error, da el mundo espejado.
const _urlSatelite =
    'https://server.arcgisonline.com/ArcGIS/rest/services/'
    'World_Imagery/MapServer/tile/{z}/{y}/{x}';

/// Nombres y vias encima del satelite. Sin esto la imagen es bonita y muda:
/// no se sabe cual mancha verde es la finca de quien.
const _urlEtiquetas =
    'https://server.arcgisonline.com/ArcGIS/rest/services/'
    'Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}';

const _urlCalles = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

/// Zoom con el que se abre un trazado de un solo punto, donde no hay extension
/// de la cual deducirlo. 17 muestra la manzana o el potrero, no el municipio.
const _zoomPunto = 17.0;

/// Hasta que zoom tiene imagen de verdad cada capa.
///
/// Se midio en Barranca de Upia (25 puntos repartidos por todo el municipio,
/// noviembre de 2026): Esri tiene satelite a z17 y z18 en todos y a z19 en
/// ninguno. Lo que devuelve a z19 no es un error sino una tesela gris que dice
/// "Map data not yet available", y eso era lo que se veia al acercar el
/// satelite. OSM si sirve z19 y a z20 ya contesta 400.
///
/// Pasado el zoom nativo, flutter_map estira la ultima tesela que existe: sale
/// borrosa, pero sale. Si algun dia se trabaja en una zona con mejor imagen,
/// subir [_zoomNativoSatelite] a 19 se ve en el acto: o mejora, o sale gris.
const _zoomNativoSatelite = 18;
const _zoomNativoCalles = 19;

/// Tope del pellizco. Sin tope el mapa se deja acercar hasta que la tesela es
/// una mancha; a z20 el satelite ya va estirado cuatro veces y no hay nada mas
/// que ver, solo menos.
const _zoomMaximo = 20.0;

/// Las teselas que fallan se vuelven a pedir cuando salen de la vista o se
/// cambia de zoom. El valor por defecto de flutter_map (`none`) guarda el error
/// en cache y esa tesela queda en blanco toda la sesion: con la senal de una
/// vereda, un solo corte al acercar dejaba huecos que no se llenaban nunca.
const _reintentarTeselas = EvictErrorTileStrategy.notVisibleRespectMargin;

class MapaTrazado extends ConsumerStatefulWidget {
  const MapaTrazado({
    super.key,
    required this.puntos,
    required this.cerrado,
    this.unirPuntos = true,
    this.resaltado,
    this.altura = 300,
    this.onTocar,
    this.centroPorDefecto,
    this.controlador,
    this.seguirPuntos = true,
    this.mostrarVertices = true,
    this.capasExtra = const [],
    this.encima,
    this.encuadrarTambien = const [],
  });

  final List<PuntoTrazado> puntos;
  final bool cerrado;

  /// false en un grupo de puntos sueltos (las plantas de un lote): cada punto
  /// es una marca aparte y no se dibuja la linea que los uniria.
  final bool unirPuntos;

  /// Id del punto seleccionado en la lista. Se dibuja mas grande, igual que en
  /// el croquis, para poder mirar las dos cosas y saber cual es cual.
  final String? resaltado;

  final double altura;

  /// Que hacer cuando el visitador toca el mapa. Si es nulo, el mapa es solo
  /// para mirar: tocar no agrega nada.
  final void Function(double latitud, double longitud)? onTocar;

  /// Donde abrir el mapa cuando el trazado todavia no tiene puntos. Sale de la
  /// coordenada de llegada de la visita; sin ella el mapa no sabe en que
  /// continente esta y no se muestra.
  final PuntoGeo? centroPorDefecto;

  /// El controlador del mapa, cuando quien lo usa necesita convertir entre
  /// pixeles y coordenadas (el pincel de [DibujoMapaPage]). Si es nulo, el
  /// mapa usa uno propio.
  final MapController? controlador;

  /// Si el mapa se reencuadra solo cuando cambian los puntos. Al dibujar va en
  /// false: cada esquina nueva moveria la vista debajo del dedo.
  final bool seguirPuntos;

  /// Si se dibujan las chinchetas numeradas. Un trazo de pincel trae decenas
  /// de vertices y numerarlos todos tapa el lote.
  final bool mostrarVertices;

  /// Capas que van entre las teselas y el trazado: lo que el trazado tenia
  /// antes de redibujarlo, por ejemplo.
  final List<Widget> capasExtra;

  /// Un widget encima del mapa y debajo de los botones flotantes: el lienzo
  /// del pincel. Ocupa todo el mapa, asi que sus coordenadas locales son las
  /// mismas que las del [controlador].
  final Widget? encima;

  /// Puntos que el encuadre tiene que mostrar ademas de [puntos]: al
  /// redibujar un lote, el que ya tenia, para que se vea entero desde el
  /// principio aunque el borrador este vacio.
  final List<PuntoGeo> encuadrarTambien;

  @override
  ConsumerState<MapaTrazado> createState() => _MapaTrazadoState();
}

class _MapaTrazadoState extends ConsumerState<MapaTrazado> {
  late final _mapa = widget.controlador ?? MapController();

  /// Si vale la pena pedirle teselas al servidor. Se actualiza en cada build
  /// con el estado de la red y lo lee el proveedor en cada tesela.
  ///
  /// Con "sin servidor" (wifi de finca sin salida, datos agotados) tampoco:
  /// cada tesela esperaria su tiempo agotado antes de mostrar lo guardado.
  bool _intentarRed = true;

  /// Uno solo para toda la vida del mapa: lo que cambia entre builds es la
  /// red, y eso lo lee de [_intentarRed].
  late final _proveedorSatelite = ProveedorSatelite(
    almacen: ref.read(almacenSateliteProvider),
    servidor: ref.read(servidorSateliteProvider),
    intentarRed: () => _intentarRed,
  );

  void _guardarZona() {
    final b = _mapa.camera.visibleBounds;
    ref
        .read(mapaSinSenalProvider.notifier)
        .guardarZona(
          Caja(sur: b.south, norte: b.north, oeste: b.west, este: b.east),
        );
  }

  /// Se reencuadra solo mientras el visitador no haya movido el mapa. Apenas
  /// arrastra o hace zoom, la vista es suya: reencuadrar sobre un punto nuevo
  /// mientras alguien esta mirando otra esquina del lote es de lo mas molesto
  /// que puede hacer una pantalla en campo.
  bool _encuadreLibre = true;
  int _puntosAlEncuadrar = 0;

  CapaMapa _capa = _capaElegida;

  /// Mientras se espera el primer fijo del GPS el boton gira, para que tocarlo
  /// y no ver nada no se sienta roto.
  bool _buscandoMiUbicacion = false;

  /// Lleva el mapa a donde esta parado el visitador.
  ///
  /// Es aca donde se pide el permiso si falta, y no al abrir el mapa: el
  /// visitador acaba de tocar "mi ubicacion" y sabe para que se lo piden.
  Future<void> _irAMiUbicacion() async {
    if (_buscandoMiUbicacion) return;
    final mensajero = ScaffoldMessenger.maybeOf(context);
    void avisar(String texto) => mensajero
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));

    setState(() => _buscandoMiUbicacion = true);
    try {
      await asegurarPermisoUbicacion();
      if (!mounted) return;
      var pos = ref.read(miUbicacionProvider).valueOrNull;
      if (pos == null) {
        // Sin posicion puede ser que el proveedor arranco sin permiso y se
        // quedo callado: con el permiso recien dado, se vuelve a arrancar.
        ref.invalidate(miUbicacionProvider);
        pos = await ref
            .read(miUbicacionProvider.future)
            .timeout(const Duration(seconds: 20));
      }
      if (!mounted) return;
      final zoom = _mapa.camera.zoom;
      _mapa.move(
        LatLng(pos.latitude, pos.longitude),
        zoom < _zoomPunto ? _zoomPunto : zoom,
      );
      // La vista ya no es la del trazado: aparece el boton para volver a el.
      setState(() => _encuadreLibre = false);
    } on ErrorUbicacion catch (e) {
      avisar(e.mensaje);
    } catch (_) {
      avisar(
        'El GPS todavia no fija la posicion. Si estas bajo arboles, '
        'sali al claro y volve a intentar.',
      );
    } finally {
      if (mounted) setState(() => _buscandoMiUbicacion = false);
    }
  }

  List<LatLng> get _coordenadas => [
    for (final p in widget.puntos) LatLng(p.latitud, p.longitud),
  ];

  @override
  void didUpdateWidget(MapaTrazado anterior) {
    super.didUpdateWidget(anterior);
    if (widget.seguirPuntos &&
        _encuadreLibre &&
        widget.puntos.length != _puntosAlEncuadrar) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _encuadrar());
    }
  }

  /// Encaja todos los puntos en pantalla. Con uno solo no hay extension que
  /// encajar y se centra con un zoom fijo.
  void _encuadrar() {
    if (!mounted) return;
    _puntosAlEncuadrar = widget.puntos.length;
    final coords = [
      ..._coordenadas,
      for (final p in widget.encuadrarTambien) LatLng(p.latitud, p.longitud),
    ];
    if (coords.isEmpty) return;

    if (coords.length == 1) {
      _mapa.move(coords.first, _zoomPunto);
      return;
    }
    _mapa.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(coords),
        padding: const EdgeInsets.all(36),
        maxZoom: 18,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final coords = _coordenadas;

    final red = ref.watch(redProvider);
    _intentarRed = red == EstadoRed.enLinea || red == EstadoRed.verificando;

    // Solo la descarga que pidio el visitador avisa al terminar; la automatica
    // trabaja callada. `listen` y no `watch`: el avance no redibuja el mapa.
    ref.listen<EstadoMapaSinSenal>(mapaSinSenalProvider, (antes, ahora) {
      final mensaje = ahora.mensaje;
      if (ahora.manual && !ahora.trabajando && mensaje != null) {
        ScaffoldMessenger.maybeOf(context)
          ?..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(mensaje)));
      }
    });

    // Sin puntos ni coordenada de llegada, el mapa todavia puede abrir donde
    // esta parado el visitador, si el telefono ya lo sabe. Se mira solo en
    // ese caso: con un centro de verdad, cada lectura del GPS redibujaria el
    // mapa entero para nada (el punto azul se redibuja solo).
    final aca = coords.isEmpty && widget.centroPorDefecto == null
        ? ref.watch(miUbicacionProvider).valueOrNull
        : null;

    final centro = coords.isNotEmpty
        ? coords.first
        : widget.centroPorDefecto != null
        ? LatLng(
            widget.centroPorDefecto!.latitud,
            widget.centroPorDefecto!.longitud,
          )
        : aca != null
        ? LatLng(aca.latitude, aca.longitude)
        : null;

    // Sin puntos, sin coordenada de la visita y sin GPS no hay donde poner el
    // mapa. Se dice por que, en vez de mostrar el Atlantico frente a Africa,
    // que es a donde va a parar un mapa centrado en (0,0).
    if (centro == null) {
      return _Marco(
        altura: widget.altura,
        color: scheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Text(
            'El mapa aparece con el primer punto, con la coordenada de '
            'llegada de la visita o cuando el GPS ubique el telefono.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
          ),
        ),
      );
    }

    final anillo = widget.cerrado && coords.length > 2;

    return _Marco(
      altura: widget.altura,
      color: scheme.surfaceContainerHighest,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapa,
            options: MapOptions(
              initialCenter: centro,
              initialZoom: _zoomPunto,
              maxZoom: _zoomMaximo,
              // Sin rotacion: el croquis tiene el norte arriba y el mapa
              // tambien, o comparar los dos deja de ser gratis.
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onMapReady: _encuadrar,
              onPositionChanged: (_, porGesto) {
                if (porGesto && _encuadreLibre) {
                  setState(() => _encuadreLibre = false);
                }
              },
              onTap: widget.onTocar == null
                  ? null
                  : (_, punto) =>
                        widget.onTocar!(punto.latitude, punto.longitude),
            ),
            children: [
              TileLayer(
                // Una capa nueva por cada cambio, no la misma con otra URL. Si
                // se reusa, flutter_map vuelve a pedir con la URL nueva las
                // teselas que ya tenia, en su zoom: pasar de calles a satelite
                // acercado pedia satelite a z19 y salia gris.
                key: ValueKey(_capa),
                urlTemplate: _capa == CapaMapa.satelite
                    ? _urlSatelite
                    : _urlCalles,
                userAgentPackageName: _paquete,
                maxNativeZoom: _capa == CapaMapa.satelite
                    ? _zoomNativoSatelite
                    : _zoomNativoCalles,
                evictErrorTileStrategy: _reintentarTeselas,
                // El satelite sale del telefono primero y del servidor solo si
                // falta. Las calles van por el cache de flutter_map, que dura
                // lo que diga OSM: no se guardan aparte porque la regla de uso
                // de OSM prohibe bajar teselas por adelantado.
                tileProvider: _capa == CapaMapa.satelite
                    ? _proveedorSatelite
                    : NetworkTileProvider(),
              ),
              if (_capa == CapaMapa.satelite)
                TileLayer(
                  urlTemplate: _urlEtiquetas,
                  userAgentPackageName: _paquete,
                  // Las etiquetas si existen a z19 (son casi todas
                  // transparentes en lo rural); estirarlas solo daria letra
                  // borrosa.
                  maxNativeZoom: 19,
                  evictErrorTileStrategy: _reintentarTeselas,
                  tileProvider: NetworkTileProvider(),
                ),
              ...widget.capasExtra,
              if (anillo)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: coords,
                      borderColor: tema.marca.exito,
                      borderStrokeWidth: 3,
                      color: tema.marca.exito.withValues(alpha: 0.22),
                    ),
                  ],
                ),
              if (!anillo && widget.unirPuntos && coords.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: coords,
                      color: tema.marca.exito,
                      strokeWidth: 3,
                    ),
                  ],
                ),
              // Debajo de las chinchetas: parado en un vertice, el numero del
              // punto importa mas que el azul, que igual se ve alrededor.
              ...capasMiUbicacion(),
              if (widget.mostrarVertices)
                MarkerLayer(
                  markers: [
                    for (var i = 0; i < widget.puntos.length; i++)
                      Marker(
                        point: coords[i],
                        width: 30,
                        height: 30,
                        child: _Chincheta(
                          numero: i + 1,
                          // El primero distinto: en un lindero, saber donde
                          // empezo el recorrido es la mitad de leerlo.
                          // En un grupo no hay primero: son plantas, no un
                          // recorrido.
                          color: i == 0 && widget.unirPuntos
                              ? scheme.primary
                              : tema.marca.exito,
                          grande: widget.puntos[i].id == widget.resaltado,
                        ),
                      ),
                  ],
                ),
              // Atribucion obligatoria, y cambia con la capa: las teselas
              // de calles son de OSM y las de satelite son de Esri y sus
              // proveedores de imagen. Quitarla es usar los dos servicios
              // fuera de sus terminos.
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    _capa == CapaMapa.satelite
                        ? 'Esri, Maxar, Earthstar Geographics'
                        : 'OpenStreetMap contributors',
                  ),
                ],
              ),
            ],
          ),
          if (widget.encima != null) Positioned.fill(child: widget.encima!),
          Positioned(
            top: 8,
            right: 8,
            child: Column(
              children: [
                // Un solo boton que alterna, no un menu: son dos capas y el
                // dedo esta con guante o mojado. El icono muestra a donde
                // lleva, no donde se esta.
                _BotonFlotante(
                  icono: _capa.otra.icono,
                  tooltip: 'Ver ${_capa.otra.titulo.toLowerCase()}',
                  onPressed: () => setState(() {
                    _capa = _capa.otra;
                    _capaElegida = _capa;
                  }),
                ),
                const SizedBox(height: 8),
                _BotonMiUbicacion(
                  buscando: _buscandoMiUbicacion,
                  onPressed: _irAMiUbicacion,
                ),
                if (_capa == CapaMapa.satelite) ...[
                  const SizedBox(height: 8),
                  _BotonGuardarZona(onPressed: _guardarZona),
                ],
                if (!_encuadreLibre) ...[
                  const SizedBox(height: 8),
                  _BotonFlotante(
                    icono: Icons.center_focus_strong,
                    tooltip: 'Volver a encuadrar el trazado',
                    onPressed: () {
                      setState(() => _encuadreLibre = true);
                      _encuadrar();
                    },
                  ),
                ],
              ],
            ),
          ),
          const Positioned(left: 8, top: 8, child: _AvanceDescarga()),
        ],
      ),
    );
  }
}

/// Guarda en el telefono el satelite de lo que se ve en pantalla, para verlo
/// despues sin senal. Mientras baja, el boton gira y no se deja volver a tocar.
class _BotonGuardarZona extends ConsumerWidget {
  const _BotonGuardarZona({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trabajando = ref.watch(
      mapaSinSenalProvider.select((e) => e.trabajando),
    );
    if (!trabajando) {
      return _BotonFlotante(
        icono: Icons.download_for_offline_outlined,
        tooltip: 'Guardar esta zona para verla sin senal',
        onPressed: onPressed,
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      elevation: 2,
      child: const SizedBox(
        width: 48,
        height: 48,
        child: Padding(
          padding: EdgeInsets.all(14),
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}

/// Centra el mapa en el visitador. Mientras el GPS fija, gira.
class _BotonMiUbicacion extends StatelessWidget {
  const _BotonMiUbicacion({required this.buscando, required this.onPressed});

  final bool buscando;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (!buscando) {
      return _BotonFlotante(
        icono: Icons.my_location,
        tooltip: 'Ir a mi ubicacion',
        onPressed: onPressed,
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      elevation: 2,
      child: const SizedBox(
        width: 48,
        height: 48,
        child: Padding(
          padding: EdgeInsets.all(14),
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}

/// Una pastilla con el avance cuando el telefono esta guardando satelite,
/// sea la descarga automatica (con wifi) o la del boton.
class _AvanceDescarga extends ConsumerWidget {
  const _AvanceDescarga();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(mapaSinSenalProvider);
    if (!estado.trabajando) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final porcentaje = ((estado.avance ?? 0) * 100).round();
    return Material(
      color: scheme.surface.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.download_for_offline_outlined,
              size: 16,
              color: scheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'Guardando mapa sin senal $porcentaje%',
              style: TextStyle(fontSize: 12, color: scheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}

class _Marco extends StatelessWidget {
  const _Marco({
    required this.altura,
    required this.color,
    required this.child,
  });

  final double altura;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: altura,
        color: color,
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

/// El vertice sobre el mapa, con su numero: es el que permite mirar la lista
/// de puntos de abajo y saber cual es cual en el terreno.
class _Chincheta extends StatelessWidget {
  const _Chincheta({
    required this.numero,
    required this.color,
    required this.grande,
  });

  final int numero;
  final Color color;
  final bool grande;

  @override
  Widget build(BuildContext context) {
    final lado = grande ? 28.0 : 20.0;
    return Center(
      child: Container(
        width: lado,
        height: lado,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          '$numero',
          style: TextStyle(
            color: Colors.white,
            fontSize: grande ? 12 : 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _BotonFlotante extends StatelessWidget {
  const _BotonFlotante({
    required this.icono,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icono;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      elevation: 2,
      child: IconButton(
        tooltip: tooltip,
        iconSize: 20,
        icon: Icon(icono),
        onPressed: onPressed,
      ),
    );
  }
}
