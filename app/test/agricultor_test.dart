import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sirius_agro/core/api_client.dart';
import 'package:sirius_agro/data/db/app_database.dart';
import 'package:sirius_agro/data/semilla.dart';
import 'package:sirius_agro/data/visita_repository.dart';
import 'package:sirius_agro/state/sincronizador.dart';

/// El modulo de datos del agricultor.
///
/// Lo que se juega aca no es un formulario: es que el agricultor exista como
/// persona. La visita lo crea con un nombre suelto, y con solo el nombre el
/// backend no puede distinguir a dos personas que se llaman igual en la misma
/// vereda — las fusiona y les mezcla las fincas. El documento es lo que lo
/// impide, y este modulo es el unico lugar donde se puede capturar, porque es
/// el unico momento en que la persona esta enfrente.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late VisitaRepository repo;
  late Directory temp;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await Semilla(db, rootBundle).sembrarSiHaceFalta();
    repo = VisitaRepository(db);
    temp = await Directory.systemTemp.createTemp('agricultor_test');
  });

  tearDown(() async {
    await db.close();
    if (temp.existsSync()) await temp.delete(recursive: true);
  });

  Future<String> visitaBase({bool autorizaDatos = true}) async {
    final vereda = (await db.select(db.veredas).get())
        .firstWhere((v) => v.vereda == 'Guaicaramo');
    final id = await repo.crearVisitaConProductor(
      inicio: DateTime(2026, 9, 7, 8),
      nombreProductor: 'Rumil',
      nombreFinca: 'La Esperanza',
      veredaLocalId: vereda.id,
    );
    await repo.registrarConsentimiento(
      id,
      audio: true,
      fotos: true,
      usoDatos: autorizaDatos,
      segundoDelAudio: 42,
    );
    return id;
  }

  Future<File> fotoFalsa(String nombre) async {
    final f = File('${temp.path}${Platform.pathSeparator}$nombre');
    await f.writeAsBytes(List.filled(64, 9));
    return f;
  }

  group('que le falta a la ficha', () {
    test('un agricultor recien creado no tiene con que distinguirse', () async {
      final id = await visitaBase();
      final productor = await repo.productorDeVisita(id);

      // El orden importa: el documento primero, que es la llave del upsert.
      expect(
        faltantesDeAgricultor(productor),
        ['el documento', 'un telefono', 'la foto'],
      );
    });

    test('con documento, telefono y foto la ficha se calla', () async {
      final id = await visitaBase();
      await repo.guardarDatosAgricultor(
        visitaId: id,
        documento: '1234567',
        telefono: '3001234567',
      );
      await repo.registrarFotoAgricultor(
        visitaId: id,
        archivoPath: (await fotoFalsa('perfil.jpg')).path,
      );

      expect(faltantesDeAgricultor(await repo.productorDeVisita(id)), isEmpty);
    });

    test('una visita sin productor no se cae: lo dice', () {
      expect(faltantesDeAgricultor(null), ['los datos del agricultor']);
    });
  });

  group('guardar la ficha', () {
    test('escribe la identidad y el perfil de la persona', () async {
      final id = await visitaBase();

      await repo.guardarDatosAgricultor(
        visitaId: id,
        nombreCompleto: 'Rumil Antonio Perez',
        documento: '1234567',
        tipoDocumento: 'CC',
        telefono: '3001234567',
        telefonoAlterno: '3109876543',
        genero: 'Masculino',
        fechaNacimiento: DateTime(1974, 3, 12),
        nivelEducativo: 'Primaria',
        aniosExperiencia: 9,
        personasHogar: 4,
        organizacion: 'Asoproductores Barranca',
        notas: 'Vive en el lote de arriba.',
      );

      final p = (await db.select(db.productores).get()).single;
      expect(p.nombreCompleto, 'Rumil Antonio Perez');
      expect(p.documento, '1234567');
      expect(p.tipoDocumento, 'CC');
      expect(p.telefono, '3001234567');
      expect(p.aniosExperiencia, 9);
      expect(p.personasHogar, 4);
      expect(p.organizacion, 'Asoproductores Barranca');
      expect(p.datosCompletadosEn, isNotNull);
      // Vuelve a quedar pendiente de subir: lo que se acaba de teclear en la
      // finca todavia no esta en Airtable.
      expect(p.sincronizado, isFalse);
    });

    test('un campo en blanco no se guarda como espacio', () async {
      final id = await visitaBase();
      await repo.guardarDatosAgricultor(
        visitaId: id,
        documento: '   ',
        telefono: '',
      );

      final p = (await db.select(db.productores).get()).single;
      expect(p.documento, isNull);
      expect(p.telefono, isNull);
    });

    test('no borra el nombre con el que nacio la visita', () async {
      // La pantalla puede guardar sin tocar el nombre. Dejar al agricultor sin
      // como llamarlo seria peor que no guardar nada.
      final id = await visitaBase();
      await repo.guardarDatosAgricultor(visitaId: id, documento: '1234567');

      final p = (await db.select(db.productores).get()).single;
      expect(p.nombreCompleto, 'Rumil');
    });

    test('copia a la persona la autorizacion de datos de la visita', () async {
      // La Ley 1581 autoriza el tratamiento de los datos DE LA PERSONA. El
      // permiso de grabar y de fotografiar se pide en cada visita; este no.
      final id = await visitaBase();
      await repo.guardarDatosAgricultor(visitaId: id, documento: '1234567');

      final p = (await db.select(db.productores).get()).single;
      expect(p.consentimientoDatos, isTrue);
      expect(p.fechaConsentimiento, DateTime(2026, 9, 7, 8));
    });

    test('si no autorizo, no se le inventa la autorizacion', () async {
      final id = await visitaBase(autorizaDatos: false);
      await repo.guardarDatosAgricultor(visitaId: id, documento: '1234567');

      final p = (await db.select(db.productores).get()).single;
      expect(p.consentimientoDatos, isFalse);
      expect(p.fechaConsentimiento, isNull);
    });

    test('deja la visita encolada: el productor sube dentro de ella', () async {
      final id = await visitaBase();
      await repo.guardarDatosAgricultor(visitaId: id, documento: '1234567');

      final cola = await db.pendientesDeVisita(id);
      final upserts = cola.where((c) => c.operacion == 'upsert');
      // Uno, no uno por guardado: `encolar` reemplaza por id.
      expect(upserts, hasLength(1));
    });
  });

  group('la foto de perfil', () {
    test('queda en la ficha y encolada detras de las fotos', () async {
      final id = await visitaBase();
      final foto = await fotoFalsa('perfil.jpg');

      await repo.registrarFotoAgricultor(visitaId: id, archivoPath: foto.path);

      final p = (await db.select(db.productores).get()).single;
      expect(p.fotoPath, foto.path);
      expect(p.enlaceFoto, isNull);

      final item = (await db.pendientesDeVisita(id))
          .firstWhere((c) => c.operacion == 'upload_foto_agricultor');
      expect(item.archivoPath, foto.path);
      expect(item.bytesTotales, 64);
      // Detras de las fotos de la conversacion (200): una etiqueta de insumo
      // mal leida cuesta un diagnostico, el retrato se vuelve a tomar.
      expect(item.prioridad, 220);
    });

    test('tomarla de nuevo reemplaza la anterior y borra el archivo', () async {
      final id = await visitaBase();
      final vieja = await fotoFalsa('perfil-vieja.jpg');
      final nueva = await fotoFalsa('perfil-nueva.jpg');

      await repo.registrarFotoAgricultor(visitaId: id, archivoPath: vieja.path);
      await repo.registrarEnlaceFotoAgricultor(vieja.path, 'https://cdn/vieja');
      await repo.registrarFotoAgricultor(visitaId: id, archivoPath: nueva.path);

      final p = (await db.select(db.productores).get()).single;
      expect(p.fotoPath, nueva.path);
      // El enlace viejo apunta a la foto vieja: dejarlo haria que Airtable se
      // siguiera trayendo el retrato reemplazado.
      expect(p.enlaceFoto, isNull);
      expect(vieja.existsSync(), isFalse);

      // Y un solo item en la cola, no dos retratos compitiendo.
      final items = (await db.pendientesDeVisita(id))
          .where((c) => c.operacion == 'upload_foto_agricultor');
      expect(items, hasLength(1));
      expect(items.single.archivoPath, nueva.path);
    });

    test('al subir, la URL se guarda en el productor', () async {
      final id = await visitaBase();
      final foto = await fotoFalsa('perfil.jpg');
      await repo.registrarFotoAgricultor(visitaId: id, archivoPath: foto.path);

      final api = ApiClient(
        client: MockClient((req) async {
          if (req.url.path == '/v1/visitas') {
            return http.Response(
              jsonEncode({
                'codigo_visita': id,
                'record_id': 'recX',
                'url': 'https://airtable.com/x',
                'grabaciones': 0,
                'evidencias': 0,
                'hallazgos': 0,
              }),
              200,
            );
          }
          expect(req.url.path, '/v1/archivos');
          return http.Response(
            jsonEncode({
              'url': 'https://cdn/visitas/$id/fotos/perfil.jpg',
              'clave': 'x',
              'bytes': 64,
            }),
            200,
          );
        }),
      );

      await Sincronizador(db, repo, api).procesar();

      final p = (await db.select(db.productores).get()).single;
      expect(p.enlaceFoto, endsWith('perfil.jpg'));
    });

    test('borrar la visita no deja un retrato roto en la ficha', () async {
      // La foto vive bajo el prefijo de la visita donde se tomo, para que
      // borrar una visita revocada sea borrar un prefijo. El productor es
      // permanente y se queda, pero sin la referencia al archivo que ya no
      // esta.
      final id = await visitaBase();
      final foto = await fotoFalsa('perfil.jpg');
      await db.into(db.productores).insert(
            ProductoresCompanion.insert(
              id: 'otro',
              nombreCompleto: 'Otro agricultor',
              fotoPath: Value('/data/visitas/otra-visita/perfil/perfil.jpg'),
            ),
          );
      await (db.update(db.productores)
            ..where((p) => p.nombreCompleto.equals('Rumil')))
          .write(
        ProductoresCompanion(
          fotoPath: Value('/data/visitas/$id/perfil/perfil.jpg'),
          enlaceFoto: const Value('https://cdn/perfil.jpg'),
        ),
      );
      expect(foto.existsSync(), isTrue);

      await repo.eliminarVisitas([id]);

      final rumil = (await db.select(db.productores).get())
          .firstWhere((p) => p.nombreCompleto == 'Rumil');
      expect(rumil.fotoPath, isNull);
      expect(rumil.enlaceFoto, isNull);
      // Y no le toca la foto del agricultor de otra visita.
      final otro = (await db.select(db.productores).get())
          .firstWhere((p) => p.id == 'otro');
      expect(otro.fotoPath, isNotNull);
    });
  });

  group('lo que viaja a Airtable', () {
    test('el payload lleva la ficha completa', () async {
      final id = await visitaBase();
      await repo.guardarDatosAgricultor(
        visitaId: id,
        nombreCompleto: 'Rumil Antonio Perez',
        documento: '1234567',
        tipoDocumento: 'CC',
        telefono: '3001234567',
        genero: 'Masculino',
        fechaNacimiento: DateTime(1974, 3, 12),
        nivelEducativo: 'Primaria',
        aniosExperiencia: 9,
        personasHogar: 4,
        organizacion: 'Asoproductores Barranca',
      );

      final prod =
          (await repo.payloadDeVisita(id))['productor'] as Map<String, dynamic>;

      expect(prod['nombre_completo'], 'Rumil Antonio Perez');
      expect(prod['documento'], '1234567');
      expect(prod['tipo_documento'], 'CC');
      expect(prod['telefono'], '3001234567');
      // Fecha sola, sin hora: es una fecha de nacimiento, no un instante.
      expect(prod['fecha_nacimiento'], '1974-03-12');
      expect(prod['nivel_educativo'], 'Primaria');
      expect(prod['anios_experiencia'], 9);
      expect(prod['personas_hogar'], 4);
      expect(prod['organizacion'], 'Asoproductores Barranca');
      expect(prod['consentimiento_datos'], isTrue);
      expect(prod['fecha_consentimiento'], '2026-09-07');
    });

    test('el enlace de la foto va solo cuando ya subio', () async {
      final id = await visitaBase();
      final foto = await fotoFalsa('perfil.jpg');
      await repo.registrarFotoAgricultor(visitaId: id, archivoPath: foto.path);

      var prod =
          (await repo.payloadDeVisita(id))['productor'] as Map<String, dynamic>;
      expect(prod.containsKey('enlace_foto'), isFalse);

      await repo.registrarEnlaceFotoAgricultor(foto.path, 'https://cdn/p.jpg');

      prod =
          (await repo.payloadDeVisita(id))['productor'] as Map<String, dynamic>;
      expect(prod['enlace_foto'], 'https://cdn/p.jpg');
    });
  });
}
