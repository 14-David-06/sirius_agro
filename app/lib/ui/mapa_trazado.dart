import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/geo.dart';
import '../data/db/app_database.dart';
import 'theme.dart';

/// El trazado sobre un mapa de verdad, para ubicarlo en el terreno.
///
/// Complementa al croquis, no lo reemplaza: el croquis se dibuja siempre
/// porque no necesita red, y el mapa necesita bajar teselas. En una vereda sin
/// datos las teselas no llegan y el mapa queda en blanco — por eso la pantalla
/// deja volver al croquis con un toque y arranca en croquis cuando no hay red.
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
/// Es una variable suelta y no una preferencia guardada a proposito: quien
/// prende el satelite lo prende para el lote que esta mirando ahora, y que
/// siga asi al abrir el trazado del vecino es lo que se espera. Guardarlo en
/// disco seria decidir por el visitador de la semana que viene.
CapaMapa _capaElegida = CapaMapa.calles;

/// Imagen satelital de Esri (World Imagery). No pide llave ni cuenta.
///
/// Ojo con el orden: esta va `{z}/{y}/{x}`, al reves del `{z}/{x}/{y}` de OSM.
/// Cambiarlo por descuido no da error, da el mundo espejado.
const _urlSatelite = 'https://server.arcgisonline.com/ArcGIS/rest/services/'
    'World_Imagery/MapServer/tile/{z}/{y}/{x}';

/// Nombres y vias encima del satelite. Sin esto la imagen es bonita y muda:
/// no se sabe cual mancha verde es la finca de quien.
const _urlEtiquetas = 'https://server.arcgisonline.com/ArcGIS/rest/services/'
    'Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}';

const _urlCalles = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

/// Zoom con el que se abre un trazado de un solo punto, donde no hay extension
/// de la cual deducirlo. 17 muestra la manzana o el potrero, no el municipio.
const _zoomPunto = 17.0;

class MapaTrazado extends StatefulWidget {
  const MapaTrazado({
    super.key,
    required this.puntos,
    required this.cerrado,
    this.resaltado,
    this.altura = 300,
    this.onTocar,
    this.centroPorDefecto,
  });

  final List<PuntoTrazado> puntos;
  final bool cerrado;

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

  @override
  State<MapaTrazado> createState() => _MapaTrazadoState();
}

class _MapaTrazadoState extends State<MapaTrazado> {
  final _mapa = MapController();

  /// Se reencuadra solo mientras el visitador no haya movido el mapa. Apenas
  /// arrastra o hace zoom, la vista es suya: reencuadrar sobre un punto nuevo
  /// mientras alguien esta mirando otra esquina del lote es de lo mas molesto
  /// que puede hacer una pantalla en campo.
  bool _encuadreLibre = true;
  int _puntosAlEncuadrar = 0;

  CapaMapa _capa = _capaElegida;

  List<LatLng> get _coordenadas => [
        for (final p in widget.puntos) LatLng(p.latitud, p.longitud),
      ];

  @override
  void didUpdateWidget(MapaTrazado anterior) {
    super.didUpdateWidget(anterior);
    if (_encuadreLibre && widget.puntos.length != _puntosAlEncuadrar) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _encuadrar());
    }
  }

  /// Encaja todos los puntos en pantalla. Con uno solo no hay extension que
  /// encajar y se centra con un zoom fijo.
  void _encuadrar() {
    if (!mounted) return;
    final coords = _coordenadas;
    if (coords.isEmpty) return;

    _puntosAlEncuadrar = coords.length;
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

    final centro = coords.isNotEmpty
        ? coords.first
        : widget.centroPorDefecto == null
            ? null
            : LatLng(
                widget.centroPorDefecto!.latitud,
                widget.centroPorDefecto!.longitud,
              );

    // Sin puntos y sin coordenada de la visita no hay donde poner el mapa. Se
    // dice por que, en vez de mostrar el Atlantico frente a Africa, que es a
    // donde va a parar un mapa centrado en (0,0).
    if (centro == null) {
      return _Marco(
        altura: widget.altura,
        color: scheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Text(
            'El mapa aparece con el primer punto, o cuando la visita tenga '
            'su coordenada de llegada.',
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
                  : (_, punto) => widget.onTocar!(
                        punto.latitude,
                        punto.longitude,
                      ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    _capa == CapaMapa.satelite ? _urlSatelite : _urlCalles,
                userAgentPackageName: _paquete,
                // Ninguno de los dos servicios sirve mas alla de z19; pedirle
                // z20 devuelve teselas en blanco. `maxNativeZoom` hace que a
                // mas zoom se estire la ultima que si existe: sale borrosa,
                // pero sale.
                maxNativeZoom: 19,
                // Las teselas que ya bajaron quedan en el cache del sistema, y
                // eso hace que un lote revisado con senal se siga viendo un
                // rato despues sin ella. No es cache offline de verdad, pero
                // es gratis y en campo se nota.
                tileProvider: NetworkTileProvider(),
              ),
              if (_capa == CapaMapa.satelite)
                TileLayer(
                  urlTemplate: _urlEtiquetas,
                  userAgentPackageName: _paquete,
                  maxNativeZoom: 19,
                  tileProvider: NetworkTileProvider(),
                ),
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
              if (!anillo && coords.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: coords,
                      color: tema.marca.exito,
                      strokeWidth: 3,
                    ),
                  ],
                ),
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
                        color: i == 0 ? scheme.primary : tema.marca.exito,
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
        ],
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
            BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1)),
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
