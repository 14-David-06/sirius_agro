import 'package:bcrypt/bcrypt.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import 'db/app_database.dart';

/// Como fallo un intento de entrar. La UI necesita distinguirlos porque cada
/// uno se arregla distinto, y "no se pudo entrar" no le sirve a alguien que
/// esta a una hora del pueblo.
enum FalloLogin {
  /// Identificador desconocido o contrasena mala.
  credenciales,

  /// No hay red Y esta persona nunca entro en este telefono.
  sinCacheOffline,

  /// Entro antes, pero paso el plazo sin hablar con el backend.
  cacheVencido,

  /// El backend contesto algo que no es un login fallido.
  backend,
}

class ErrorLogin implements Exception {
  const ErrorLogin(this.tipo, this.mensaje);

  final FalloLogin tipo;
  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Datos que el backend devuelve al verificar la contrasena contra nomina.
class CredencialRemota {
  const CredencialRemota({
    required this.idEmpleado,
    required this.cedula,
    required this.nombre,
    required this.email,
    required this.rolApp,
    required this.nivelAcceso,
    required this.ordenNivel,
    required this.hashBcrypt,
    required this.diasMaxOffline,
  });

  final String idEmpleado;
  final String cedula;
  final String nombre;
  final String email;
  final String rolApp;
  final String nivelAcceso;
  final int ordenNivel;
  final String hashBcrypt;
  final int diasMaxOffline;
}

/// bcrypt tarda ~100 ms a proposito. En el hilo de UI eso es un tiron visible
/// al tocar «Entrar», asi que se verifica en otro isolate.
bool _verificar((String, String) par) => BCrypt.checkpw(par.$1, par.$2);

Future<bool> verificarBcrypt(String password, String hash) =>
    compute(_verificar, (password, hash));

/// Guarda las credenciales que permiten entrar sin senal y la sesion abierta.
///
/// La regla que gobierna todo el archivo: la contrasena en claro nunca se
/// escribe en disco. Lo unico que persiste es el hash bcrypt que ya estaba en
/// nomina, y solo el de quien acerto la contrasena en ESTE telefono.
class SesionRepository {
  SesionRepository(this._db);

  final AppDatabase _db;

  /// La cedula, sin puntos ni espacios. Tiene que coincidir con lo que hace
  /// el backend (`solo_digitos`), o el login online guardaria la credencial
  /// bajo una llave que el login offline no encuentra.
  static String normalizar(String cedula) =>
      cedula.replaceAll(RegExp(r'\D'), '');

  /// Guarda (o refresca) la credencial despues de un login con red.
  Future<CredencialLocal> guardarTrasLoginOnline(
    String cedula,
    CredencialRemota remota, {
    DateTime? ahora,
  }) async {
    final momento = ahora ?? DateTime.now();
    final fila = CredencialesLocalesCompanion.insert(
      cedula: normalizar(cedula),
      idEmpleado: remota.idEmpleado,
      nombre: remota.nombre,
      email: Value(remota.email),
      hashBcrypt: remota.hashBcrypt,
      rolApp: Value(remota.rolApp),
      nivelAcceso: Value(remota.nivelAcceso),
      ordenNivel: Value(remota.ordenNivel),
      ultimoLoginOnline: momento,
      validoHasta: momento.add(Duration(days: remota.diasMaxOffline)),
    );

    await _db
        .into(_db.credencialesLocales)
        .insertOnConflictUpdate(fila);

    return leerCredencial(cedula).then((c) => c!);
  }

  Future<CredencialLocal?> leerCredencial(String cedula) =>
      (_db.select(_db.credencialesLocales)
            ..where((c) => c.cedula.equals(normalizar(cedula))))
          .getSingleOrNull();

  /// Login sin red. Falla distinto segun por que no se puede, para que la app
  /// sepa si conviene buscar senal o si la contrasena esta mal y punto.
  Future<CredencialLocal> entrarOffline(
    String cedula,
    String password, {
    DateTime? ahora,
  }) async {
    final momento = ahora ?? DateTime.now();
    final credencial = await leerCredencial(cedula);

    if (credencial == null) {
      throw const ErrorLogin(
        FalloLogin.sinCacheOffline,
        'Esta persona no ha entrado nunca en este telefono. El primer login '
        'necesita internet: buscá señal una vez y despues ya funciona sin.',
      );
    }

    // El plazo se revisa ANTES de la contrasena. No es un tema de seguridad
    // sino de mensaje: si venció, acertar la contrasena tampoco iba a servir,
    // y decir "contrasena incorrecta" mandaria a probar contrasenas al pedo.
    if (!momento.isBefore(credencial.validoHasta)) {
      throw const ErrorLogin(
        FalloLogin.cacheVencido,
        'Pasaron demasiados dias desde el ultimo login con internet. Hay que '
        'entrar una vez con señal para volver a habilitar el modo sin red.',
      );
    }

    if (!await verificarBcrypt(password, credencial.hashBcrypt)) {
      throw const ErrorLogin(
        FalloLogin.credenciales,
        'Usuario o contrasena incorrectos.',
      );
    }

    return credencial;
  }

  Future<void> abrirSesion(String cedula, {required bool offline}) =>
      _db.into(_db.sesiones).insertOnConflictUpdate(
            SesionesCompanion.insert(
              // El 0 va explicito. `unica` es INTEGER PRIMARY KEY, o sea alias
              // del rowid: si no se manda, SQLite ignora el default y
              // autoasigna, y entonces se acumula una sesion por cada login en
              // vez de reemplazarse.
              unica: const Value(0),
              cedula: normalizar(cedula),
              abierta: DateTime.now(),
              offline: Value(offline),
            ),
          );

  /// Cerrar sesion NO borra la credencial: si la borrara, el siguiente login
  /// de esa persona exigiria internet, y cerrar sesion en una vereda dejaria
  /// el telefono inservible hasta volver al pueblo.
  Future<void> cerrarSesion() => _db.delete(_db.sesiones).go();

  /// La sesion abierta con los datos de quien la abrio, o null si no hay.
  Stream<SesionActiva?> observarSesion() {
    final consulta = _db.select(_db.sesiones).join([
      innerJoin(
        _db.credencialesLocales,
        _db.credencialesLocales.cedula.equalsExp(_db.sesiones.cedula),
      ),
    ]);

    return consulta.watchSingleOrNull().map((fila) {
      if (fila == null) return null;
      return SesionActiva(
        credencial: fila.readTable(_db.credencialesLocales),
        offline: fila.readTable(_db.sesiones).offline,
      );
    });
  }

  /// El `Visitador` del espejo de nomina que corresponde a quien inicio
  /// sesion. Es lo que enlaza la sesion con `Visitas.visitadorLocalId`.
  ///
  /// Se busca por `idEmpleado` porque es la llave estable entre las dos bases:
  /// el correo se puede cambiar, el id de empleado no.
  Future<Visitador?> visitadorDe(CredencialLocal credencial) =>
      (_db.select(_db.visitadores)
            ..where((v) => v.idEmpleado.equals(credencial.idEmpleado)))
          .getSingleOrNull();
}

class SesionActiva {
  const SesionActiva({required this.credencial, required this.offline});

  final CredencialLocal credencial;

  /// El ultimo login se resolvio contra la copia local, sin hablar con nomina.
  final bool offline;

  bool get esCoordinador => credencial.rolApp == 'Coordinador';
}
