import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../data/db/app_database.dart';
import '../data/sesion_repository.dart';
import 'providers.dart';

final sesionRepoProvider = Provider<SesionRepository>(
  (ref) => SesionRepository(ref.watch(dbProvider)),
);

/// Quien esta usando la app, o null si nadie entro todavia.
final sesionProvider = StreamProvider<SesionActiva?>(
  (ref) => ref.watch(sesionRepoProvider).observarSesion(),
);

/// El `Visitador` del espejo de nomina que corresponde a la sesion abierta.
/// Es lo que se guarda en `Visitas.visitadorLocalId`.
final visitadorSesionProvider = FutureProvider<Visitador?>((ref) async {
  final sesion = await ref.watch(sesionProvider.future);
  if (sesion == null) return null;
  // La semilla tiene que estar sembrada o el espejo esta vacio.
  await ref.watch(semillaProvider.future);
  return ref.watch(sesionRepoProvider).visitadorDe(sesion.credencial);
});

class LoginState {
  const LoginState({this.trabajando = false, this.error, this.tipo});

  final bool trabajando;
  final String? error;
  final FalloLogin? tipo;

  /// Vale la pena ofrecer «reintentar cuando haya señal»: el problema no es la
  /// contrasena sino que este telefono nunca vio a esta persona.
  bool get necesitaRed =>
      tipo == FalloLogin.sinCacheOffline || tipo == FalloLogin.cacheVencido;
}

class LoginController extends StateNotifier<LoginState> {
  LoginController(this._ref) : super(const LoginState());

  final Ref _ref;

  /// Intenta primero contra nomina y, si no hay red, contra la copia local.
  ///
  /// El orden importa y no es negociable: el backend es lo unico que sabe si
  /// la persona sigue activa en la empresa y si le cambiaron la contrasena.
  /// La copia local es el plan B de una vereda sin señal, no un atajo — por
  /// eso solo se usa cuando la red efectivamente falla, y NO cuando el backend
  /// contesta que las credenciales estan mal.
  Future<bool> entrar(String cedula, String password) async {
    if (state.trabajando) return false;
    state = const LoginState(trabajando: true);

    final repo = _ref.read(sesionRepoProvider);
    final api = _ref.read(apiProvider);

    try {
      final remota = await api.login(cedula: cedula, password: password);
      await repo.guardarTrasLoginOnline(cedula, remota);
      // Despues de guardar la credencial y antes de abrir la sesion: la fila
      // ya existe, asi que el UPDATE de la ruta encuentra donde escribir.
      await repo.guardarFotoPerfil(cedula, remota.fotoUrl, api.descargarArchivo);
      await repo.abrirSesion(cedula, offline: false);
      state = const LoginState();
      return true;
    } on ApiException catch (e) {
      // 401 y 403 son respuestas del backend, no falta de red: el login fallo
      // de verdad y caer al modo offline seria dejar entrar a quien nomina
      // acaba de rechazar.
      if (_esRechazo(e)) {
        state = LoginState(error: e.message, tipo: FalloLogin.credenciales);
        return false;
      }
      return _intentarOffline(repo, cedula, password, e.message);
    } catch (e) {
      return _intentarOffline(repo, cedula, password, '$e');
    }
  }

  bool _esRechazo(ApiException e) =>
      e.message.startsWith('HTTP 401') || e.message.startsWith('HTTP 403');

  Future<bool> _intentarOffline(
    SesionRepository repo,
    String cedula,
    String password,
    String motivoRed,
  ) async {
    try {
      await repo.entrarOffline(cedula, password);
      await repo.abrirSesion(cedula, offline: true);
      state = const LoginState();
      return true;
    } on ErrorLogin catch (e) {
      state = LoginState(
        error: e.tipo == FalloLogin.credenciales
            ? e.mensaje
            // Se dice tambien por que no se pudo preguntarle al backend: sin
            // eso, "necesita internet" parece un capricho de la app.
            : '${e.mensaje}\n\nNo se pudo consultar el servidor: $motivoRed',
        tipo: e.tipo,
      );
      return false;
    }
  }

  void limpiarError() => state = const LoginState();
}

final loginProvider =
    StateNotifierProvider<LoginController, LoginState>(LoginController.new);
