import 'dart:io';

import 'package:bcrypt/bcrypt.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter_test/flutter_test.dart';
import 'package:sirius_agro/data/db/app_database.dart';
import 'package:sirius_agro/data/sesion_repository.dart';

/// El login offline.
///
/// Lo que se protege: que la contrasena en claro no toque el disco, que el
/// telefono no deje entrar a quien nunca entro con red, y que la copia local
/// caduque — es lo unico que puede enterarse de que alguien salio de la
/// empresa cuando el telefono lleva dias en una vereda.
const _URL = 'https://v5.airtableusercontent.com/retrato.jpg';
// Los primeros bytes de un JPEG de verdad: lo que importa es que lo que baja
// es lo que se escribe en disco, byte por byte.
const _JPEG = [0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46];

void main() {
  // La foto se escribe donde la app guarda sus archivos, y eso lo resuelve
  // path_provider, que en un test no tiene plataforma detras. Se le da una
  // carpeta temporal para comprobar que el archivo queda escrito de verdad:
  // que la credencial tenga ruta y en disco no haya nada es justo el fallo
  // que hay que atrapar.
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SesionRepository repo;
  late Directory documentos;

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => documentos.path,
    );
  });

  const password = 'Contrasena-de-prueba-1';
  // rounds bajo a proposito: el test corre en CI, no protege nada.
  final hash = BCrypt.hashpw(password, BCrypt.gensalt(logRounds: 4));

  const cedula = '1234567890';

  CredencialRemota remota({int diasMaxOffline = 30, String fotoUrl = ''}) =>
      CredencialRemota(
        idEmpleado: 'SIRIUS-PER-0007',
        cedula: cedula,
        nombre: 'Persona De Prueba',
        email: cedula,
        rolApp: 'Visitador',
        nivelAcceso: 'Usuario',
        ordenNivel: 3,
        hashBcrypt: hash,
        diasMaxOffline: diasMaxOffline,
        fotoUrl: fotoUrl,
      );

  setUp(() async {
    documentos = await Directory.systemTemp.createTemp('docs-sesion-');
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = SesionRepository(db);
  });

  tearDown(() => db.close());

  group('la foto de perfil del visitador', () {
    test('se baja al entrar con red y queda apuntada en la credencial',
        () async {
      await repo.guardarTrasLoginOnline(cedula, remota(fotoUrl: _URL));
      await repo.guardarFotoPerfil(cedula, _URL, (_) async => _JPEG);

      final guardada = await repo.leerCredencial(cedula);
      expect(guardada!.fotoUrl, _URL);
      expect(guardada.fotoPath, isNotNull);
      expect(File(guardada.fotoPath!).readAsBytesSync(), _JPEG);
    });

    test('si no se puede bajar, se entra igual y quedan las iniciales',
        () async {
      // Sin red, con la URL ya caducada, o sin retrato cargado en nomina. Un
      // fallo bajando un retrato no puede dejar a nadie sin poder trabajar.
      await repo.guardarTrasLoginOnline(cedula, remota(fotoUrl: _URL));
      await repo.guardarFotoPerfil(cedula, _URL, (_) async => null);

      final guardada = await repo.leerCredencial(cedula);
      expect(guardada, isNotNull);
      expect(guardada!.fotoPath, isNull);
    });

    test('quien no tiene foto en nomina no dispara ninguna descarga', () async {
      var llamadas = 0;
      await repo.guardarTrasLoginOnline(cedula, remota());
      await repo.guardarFotoPerfil(cedula, '', (_) async {
        llamadas++;
        return _JPEG;
      });

      expect(llamadas, 0);
    });
  });

  group('la credencial que habilita el modo sin red', () {
    test('el primer login con red la deja guardada', () async {
      await repo.guardarTrasLoginOnline(cedula, remota());

      final guardada = await repo.leerCredencial(cedula);
      expect(guardada, isNotNull);
      expect(guardada!.idEmpleado, 'SIRIUS-PER-0007');
      expect(guardada.hashBcrypt, hash);
    });

    test('LA CONTRASENA EN CLARO NO QUEDA EN NINGUNA COLUMNA', () async {
      await repo.guardarTrasLoginOnline(cedula, remota());
      await repo.entrarOffline(cedula, password);
      await repo.abrirSesion(cedula, offline: true);

      // Se barre la base entera, no solo las columnas que uno recuerda.
      final volcado = await db
          .customSelect('SELECT * FROM credenciales_locales')
          .get();
      final sesiones = await db.customSelect('SELECT * FROM sesiones').get();
      final texto = [
        ...volcado.map((f) => f.data.toString()),
        ...sesiones.map((f) => f.data.toString()),
      ].join(' ');

      expect(texto.contains(password), isFalse);
      expect(texto.contains(hash), isTrue);
    });

    test('da igual como se teclee la cedula: con puntos o sin ellos', () async {
      // Tiene que coincidir con `solo_digitos` del backend. Si no, el login
      // online guardaria bajo una llave que el offline no encuentra.
      await repo.guardarTrasLoginOnline('1.234.567.890', remota());

      for (final tecleada in ['1234567890', '1.234.567.890', ' 1 234 567 890 ']) {
        final c = await repo.entrarOffline(tecleada, password);
        expect(c.idEmpleado, 'SIRIUS-PER-0007', reason: tecleada);
      }
    });

    test('volver a entrar con red refresca el hash y corre el vencimiento',
        () async {
      final viejo = DateTime(2026, 1, 1);
      await repo.guardarTrasLoginOnline(
        cedula,
        remota(),
        ahora: viejo,
      );

      // En nomina le cambiaron la contrasena.
      final otro = BCrypt.hashpw('Otra-distinta-9', BCrypt.gensalt(logRounds: 4));
      final nuevo = DateTime(2026, 3, 1);
      await repo.guardarTrasLoginOnline(
        cedula,
        CredencialRemota(
          idEmpleado: 'SIRIUS-PER-0007',
          cedula: cedula,
          nombre: 'Persona De Prueba',
          email: cedula,
          rolApp: 'Coordinador',
          nivelAcceso: 'Admin',
          ordenNivel: 2,
          hashBcrypt: otro,
          diasMaxOffline: 30,
        ),
        ahora: nuevo,
      );

      final c = await repo.leerCredencial(cedula);
      expect(c!.hashBcrypt, otro);
      expect(c.rolApp, 'Coordinador');
      expect(c.validoHasta, nuevo.add(const Duration(days: 30)));

      // Y la contrasena vieja deja de servir tambien sin red.
      await expectLater(
        repo.entrarOffline(cedula, password),
        throwsA(isA<ErrorLogin>()),
      );
    });
  });

  group('entrar sin senal', () {
    test('con la contrasena correcta entra', () async {
      await repo.guardarTrasLoginOnline(cedula, remota());

      final c = await repo.entrarOffline(
        cedula,
        password,
      );
      expect(c.nombre, 'Persona De Prueba');
    });

    test('con la contrasena mala no entra', () async {
      await repo.guardarTrasLoginOnline(cedula, remota());

      await expectLater(
        repo.entrarOffline(cedula, 'otra'),
        throwsA(
          isA<ErrorLogin>().having((e) => e.tipo, 'tipo', FalloLogin.credenciales),
        ),
      );
    });

    test('quien nunca entro en este telefono no puede entrar sin red', () async {
      await expectLater(
        repo.entrarOffline('9999999999', password),
        throwsA(
          isA<ErrorLogin>()
              .having((e) => e.tipo, 'tipo', FalloLogin.sinCacheOffline),
        ),
      );
    });

    test('pasado el plazo no entra AUNQUE la contrasena sea correcta', () async {
      final dia = DateTime(2026, 1, 1);
      await repo.guardarTrasLoginOnline(
        cedula,
        remota(diasMaxOffline: 30),
        ahora: dia,
      );

      // Dia 29: todavia sirve.
      final ok = await repo.entrarOffline(
        cedula,
        password,
        ahora: dia.add(const Duration(days: 29)),
      );
      expect(ok.idEmpleado, 'SIRIUS-PER-0007');

      // Dia 31: hay que buscar señal, es lo unico que puede ver si la persona
      // sigue activa en la empresa.
      await expectLater(
        repo.entrarOffline(
          cedula,
          password,
          ahora: dia.add(const Duration(days: 31)),
        ),
        throwsA(
          isA<ErrorLogin>().having((e) => e.tipo, 'tipo', FalloLogin.cacheVencido),
        ),
      );
    });
  });

  group('la sesion abierta', () {
    test('solo hay una a la vez', () async {
      await repo.guardarTrasLoginOnline('1111111111', remota());
      await repo.guardarTrasLoginOnline('2222222222', remota());

      await repo.abrirSesion('1111111111', offline: false);
      await repo.abrirSesion('2222222222', offline: true);

      final filas = await db.select(db.sesiones).get();
      expect(filas, hasLength(1));
      expect(filas.single.cedula, '2222222222');
    });

    test('marca si se valido sin internet', () async {
      await repo.guardarTrasLoginOnline(cedula, remota());
      await repo.abrirSesion(cedula, offline: true);

      final activa = await repo.observarSesion().first;
      expect(activa!.offline, isTrue);
      expect(activa.credencial.nombre, 'Persona De Prueba');
      expect(activa.esCoordinador, isFalse);
    });

    test('cerrar sesion NO borra la credencial', () async {
      // Si la borrara, cerrar sesion en una vereda dejaria el telefono
      // inservible hasta volver al pueblo.
      await repo.guardarTrasLoginOnline(cedula, remota());
      await repo.abrirSesion(cedula, offline: false);
      await repo.cerrarSesion();

      expect(await repo.observarSesion().first, isNull);
      final c = await repo.entrarOffline(
        cedula,
        password,
      );
      expect(c.idEmpleado, 'SIRIUS-PER-0007');
    });
  });

  group('la visita queda firmada por quien inicio sesion', () {
    test('la sesion se enlaza al espejo de nomina por ID Empleado', () async {
      await db.into(db.visitadores).insert(
            VisitadoresCompanion.insert(
              id: 'v-1',
              nombre: 'Persona De Prueba',
              usuarioApp: 'persona',
              idEmpleado: const Value('SIRIUS-PER-0007'),
            ),
          );
      final credencial = await repo.guardarTrasLoginOnline(
        cedula,
        remota(),
      );

      final visitador = await repo.visitadorDe(credencial);
      expect(visitador!.id, 'v-1');
    });

    test('sin espejo sembrado no revienta, devuelve null', () async {
      final credencial = await repo.guardarTrasLoginOnline(
        cedula,
        remota(),
      );
      expect(await repo.visitadorDe(credencial), isNull);
    });
  });
}
