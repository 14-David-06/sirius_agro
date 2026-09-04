import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../core/config.dart';

/// Que tan lejos llega el telefono en este momento.
///
/// Son cuatro estados y no dos porque en campo "sin senal" y "el servidor no
/// contesta" se arreglan distinto: el primero se resuelve caminando hasta
/// donde entre la senal, el segundo no se resuelve caminando.
enum EstadoRed {
  /// Todavia no hay veredicto (arranque de la app o revision en curso).
  verificando,

  /// Hay red y el servidor de Sirius contesta: se puede sincronizar.
  enLinea,

  /// El telefono cree tener red, pero el servidor no responde. Puede ser una
  /// senal que no navega (portal de wifi, datos agotados) o el backend caido.
  sinServidor,

  /// El sistema operativo dice que no hay ninguna interfaz de red.
  sinRed,
}

/// Vigila la conexion y avisa en cuanto cambia.
///
/// Dos fuentes, porque una sola miente:
///  - `connectivity_plus` dispara al instante cuando el wifi o los datos se
///    caen o vuelven, pero solo sabe de la interfaz: un wifi de finca sin
///    salida a Internet le parece conexion.
///  - una llamada a `/health` del backend es la unica prueba de que lo que la
///    app necesita hacer (subir, transcribir, sincronizar) va a funcionar.
///
/// Por eso el estado verde exige las dos cosas, y el sondeo se repite en un
/// intervalo corto: en una vereda la senal aparece y desaparece sola, sin que
/// la interfaz cambie nunca.
class VigilanteRed extends StateNotifier<EstadoRed> {
  VigilanteRed({http.Client? client, Connectivity? connectivity})
      : _client = client ?? http.Client(),
        _connectivity = connectivity ?? Connectivity(),
        super(EstadoRed.verificando) {
    _suscripcion = _connectivity.onConnectivityChanged.listen((_) => revisar());
    revisar();
    _timer = Timer.periodic(_cada, (_) => revisar());
  }

  /// Suficientemente seguido para que el icono sirva de semaforo, y no tanto
  /// como para gastar bateria: `/health` responde nueve bytes.
  static const _cada = Duration(seconds: 20);

  /// En campo, esperar mas que esto es lo mismo que no tener conexion.
  static const _limite = Duration(seconds: 6);

  final http.Client _client;
  final Connectivity _connectivity;
  late final StreamSubscription<List<ConnectivityResult>> _suscripcion;
  late final Timer _timer;

  bool _revisando = false;

  /// Vuelve a mirar. La llama el timer, el cambio de interfaz y el visitador
  /// cuando toca el icono.
  Future<void> revisar() async {
    if (_revisando) return;
    _revisando = true;

    try {
      final interfaces = await _connectivity.checkConnectivity();
      final hayInterfaz = interfaces.any((i) => i != ConnectivityResult.none);
      if (!hayInterfaz) {
        _publicar(EstadoRed.sinRed);
        return;
      }

      // Sin baseUrl no hay nada que sondear: el APK se compilo sin servidor y
      // eso lo grita [AppConfig.problemaDeCompilacion], no este icono.
      if (AppConfig.baseUrl.isEmpty) {
        _publicar(EstadoRed.sinServidor);
        return;
      }

      _publicar(await _servidorResponde()
          ? EstadoRed.enLinea
          : EstadoRed.sinServidor);
    } finally {
      _revisando = false;
    }
  }

  /// `/health` esta fuera de `/v1`: no pide `X-API-Key`, asi que un APK mal
  /// compilado igual puede distinguir "no hay red" de "no hay llave".
  Future<bool> _servidorResponde() async {
    try {
      final r = await _client
          .get(Uri.parse('${AppConfig.baseUrl}/health'))
          .timeout(_limite);
      // Un 5xx es servidor vivo pero roto: para la app es lo mismo que caido.
      return r.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  void _publicar(EstadoRed nuevo) {
    if (mounted && state != nuevo) state = nuevo;
  }

  @override
  void dispose() {
    _timer.cancel();
    _suscripcion.cancel();
    _client.close();
    super.dispose();
  }
}

/// Vive mientras viva la app: el icono aparece en todas las pantallas y no
/// tiene que volver a sondear cada vez que se navega.
final redProvider = StateNotifierProvider<VigilanteRed, EstadoRed>(
  (ref) => VigilanteRed(),
);
