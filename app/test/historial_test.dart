import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/services.dart' show MethodChannel, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:sirius_agro/data/db/app_database.dart';
import 'package:sirius_agro/data/semilla.dart';
import 'package:sirius_agro/data/visita_repository.dart';

/// El espejo del historial: las visitas que bajan de Airtable para consultar.
///
/// Lo que se protege aca es una sola cosa, y es la que hace segura toda la
/// funcion: que traer el historial de un agricultor NO pueda costar trabajo de
/// campo. Una visita propia que se sobreescribe con la version de Airtable, o
/// un espejo que se cuela en la cola y reescribe el registro de otro
/// visitador, son perdidas sin papelera de donde rescatarlas.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late VisitaRepository repo;
  late Directory documentos;

  // Las fotos y el audio del espejo se guardan donde la app guarda los suyos, y
  // eso lo resuelve path_provider, que en un test no tiene plataforma detras.
  // Se le da una carpeta temporal para poder comprobar que el archivo queda
  // escrito de verdad: que la fila tenga ruta y en disco no haya nada es justo
  // el fallo que hay que atrapar.
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => documentos.path,
    );
  });

  setUp(() async {
    documentos = await Directory.systemTemp.createTemp('docs-historial-');
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await Semilla(db, rootBundle).sembrarSiHaceFalta();
    repo = VisitaRepository(db);
  });

  tearDown(() async {
    await db.close();
    if (documentos.existsSync()) await documentos.delete(recursive: true);
  });

  const codigo = '7f3c1a9e-0000-4000-8000-000000000001';

  Map<String, dynamic> historial({
    String codigoVisita = codigo,
    List<Map<String, dynamic>> hallazgos = const [],
    List<Map<String, dynamic>> evidencias = const [],
    List<Map<String, dynamic>> grabaciones = const [],
    List<Map<String, dynamic>> informes = const [],
  }) =>
      {
        'productor_id': 'recPEDRO',
        'productor': 'Pedro Rodriguez',
        'visitas': [
          {
            'codigo_visita': codigoVisita,
            'inicio': '2026-09-10T09:30:00.000Z',
            'fin': '2026-09-10T11:00:00.000Z',
            'estado': 'Cerrada',
            'finca': 'La Esperanza',
            'vereda': 'Guaicaramo',
            'completitud_pct': 48,
            'latitud': 4.57321,
            'longitud': -72.819044,
            'consiente_audio': true,
            'temas_pendientes': 'Falta el riego',
            'hallazgos': hallazgos,
            'evidencias': evidencias,
            'grabaciones': grabaciones,
            'informes': informes,
          },
        ],
      };

  group('lo que el espejo NO puede hacer', () {
    test('una visita propia del telefono no se toca jamas', () async {
      // La regla de oro. Airtable puede tener una version vieja o parcial de
      // una visita que este telefono todavia esta registrando; si la pisara,
      // se perderia la conversacion que no ha subido.
      final propioId = await repo.crearVisitaConProductor(
        inicio: DateTime(2026, 9, 2, 8),
        nombreProductor: 'Pedro Rodriguez',
        nombreFinca: 'La Esperanza',
      );
      await (db.update(db.visitas)..where((v) => v.id.equals(propioId))).write(
        const VisitasCompanion(
          observaciones: Value('Lo que dijo en la finca'),
        ),
      );

      final resultado = await repo.importarHistorial(
        historial(codigoVisita: propioId),
      );

      final despues = await (db.select(db.visitas)
            ..where((v) => v.id.equals(propioId)))
          .getSingle();

      expect(resultado.visitas, 0);
      expect(resultado.propiasRespetadas, 1);
      expect(despues.soloLectura, isFalse);
      expect(despues.observaciones, 'Lo que dijo en la finca');
      // No se le puso la fecha de descarga ni se marco sincronizada por la
      // cara: sigue siendo exactamente la visita que era.
      expect(despues.descargadaEn, isNull);
    });

    test('un espejo NUNCA entra a la cola de subida', () async {
      // El guardarraiil vive en `encolarVisita`, que es por donde pasan todos
      // los caminos que terminan escribiendo en Airtable.
      await repo.importarHistorial(historial());
      await repo.encolarVisita(codigo);

      final cola = await db.select(db.syncQueue).get();
      expect(cola.where((i) => i.entidadId == codigo), isEmpty);
    });

    test('la visita propia si entra a la cola', () async {
      // El contraste del test anterior: el guardarraiil bloquea los espejos,
      // no la sincronizacion.
      final propioId = await repo.crearVisitaConProductor(
        inicio: DateTime(2026, 9, 2, 8),
        nombreProductor: 'Pedro Rodriguez',
      );
      await repo.encolarVisita(propioId);

      final cola = await db.select(db.syncQueue).get();
      expect(cola.where((i) => i.entidadId == propioId), isNotEmpty);
    });
  });

  group('lo que el espejo si trae', () {
    test('la visita queda marcada de solo lectura y con su fecha', () async {
      final resultado = await repo.importarHistorial(historial());

      final v = await (db.select(db.visitas)..where((x) => x.id.equals(codigo)))
          .getSingle();

      expect(resultado.visitas, 1);
      expect(v.soloLectura, isTrue);
      expect(v.descargadaEn, isNotNull);
      expect(v.sincronizada, isTrue);
      expect(v.completitudPct, 48);
      expect(v.latitud, closeTo(4.57321, 0.000001));
      expect(v.temasPendientes, 'Falta el riego');
    });

    test('el agricultor no se duplica al traer varias visitas', () async {
      // Sin esto, bajar cinco visitas de Pedro dejaria cinco Pedro en el
      // directorio: justo el problema que el directorio existe para evitar.
      await repo.importarHistorial(historial());
      await repo.importarHistorial(
        historial(codigoVisita: '7f3c1a9e-0000-4000-8000-000000000002'),
      );

      final productores = await db.select(db.productores).get();
      expect(
        productores.where((p) => p.nombreCompleto == 'Pedro Rodriguez').length,
        1,
      );
    });

    test('los hallazgos entran con su certeza y su minuto', () async {
      final clave = (await db.select(db.catalogoCampos).get()).first.claveTecnica;

      await repo.importarHistorial(
        historial(
          hallazgos: [
            {
              'clave_tecnica': clave,
              'valor_texto': 'tres pozos',
              'certeza': 'Estimado',
              'fuente': 'Audio',
              'estado': 'Confirmado',
              'segundo_audio': 724,
            },
          ],
        ),
      );

      final h = (await db.select(db.hallazgos).get()).single;
      expect(h.valorTexto, 'tres pozos');
      expect(h.certeza, Certeza.estimado);
      expect(h.fuente, FuenteHallazgo.audio);
      expect(h.estado, EstadoHallazgo.confirmado);
      expect(h.segundoAudio, 724);
    });

    test('un campo que este telefono no conoce se cuenta, no tumba nada',
        () async {
      // El catalogo de este APK puede ser mas viejo que el de Airtable. Un
      // hallazgo con una clave desconocida romperia la clave foranea y con
      // ella la importacion entera.
      final resultado = await repo.importarHistorial(
        historial(
          hallazgos: [
            {'clave_tecnica': 'campo_que_no_existe', 'valor_texto': 'algo'},
          ],
        ),
      );

      expect(resultado.visitas, 1);
      expect(resultado.hallazgosFueraDeCatalogo, 1);
      expect(await db.select(db.hallazgos).get(), isEmpty);
    });

    test('el segundo del audio vuelve a salir de la descripcion', () async {
      // Al escribir, la sincronizacion mete `[12:04]` al frente de la
      // descripcion porque `Evidencias` no tiene columna para el segundo. Al
      // leer hay que deshacerlo, o el dato queda escondido en un texto.
      await repo.importarHistorial(
        historial(
          evidencias: [
            {
              'titulo': 'Foto 01',
              'tomada_en': '2026-09-10T10:00:00.000Z',
              'descripcion_visitador': '[12:04] Hoja con sigatoka',
            },
          ],
        ),
      );

      final e = (await db.select(db.evidencias).get()).single;
      expect(e.segundoAudio, 724);
      expect(e.descripcionVisitador, 'Hoja con sigatoka');
    });

    test('los informes bajan con su contenido y su enlace', () async {
      await repo.importarHistorial(
        historial(
          informes: [
            {
              'titulo': 'Informe La Esperanza',
              'tipo': 'Resumen para el agricultor',
              'contenido': '## Lo que conversamos',
              'version': 2,
              'enlace_pdf': 'https://bucket.test/informe-02.pdf',
            },
          ],
        ),
      );

      final i = (await db.select(db.informes).get()).single;
      expect(i.version, 2);
      expect(i.contenido, '## Lo que conversamos');
      expect(i.enlacePdf, 'https://bucket.test/informe-02.pdf');
    });

    test('volver a traerlo reemplaza, no duplica', () async {
      // El historial se vuelve a pedir cuando alguien quiere lo ultimo. Si
      // cada descarga acumulara hijos, la tercera consulta mostraria la misma
      // foto tres veces.
      final datos = historial(
        informes: [
          {'titulo': 'Informe', 'contenido': 'texto', 'version': 1},
        ],
      );

      await repo.importarHistorial(datos);
      await repo.importarHistorial(datos);

      expect((await db.select(db.informes).get()).length, 1);
      expect((await db.select(db.visitas).get()).length, 1);
    });

    test('los archivos se bajan con la funcion que se le pase', () async {
      var pedidas = 0;
      final resultado = await repo.importarHistorial(
        historial(
          evidencias: [
            {'titulo': 'Foto 01', 'url': 'https://airtable.test/foto.jpg'},
          ],
          grabaciones: [
            {'orden': 1, 'url': 'https://bucket.test/tramo-01.m4a'},
          ],
        ),
        bajar: (url) async {
          pedidas++;
          return List.filled(16, 7);
        },
      );

      expect(pedidas, 2);
      expect(resultado.fotos, 1);
      expect(resultado.audios, 1);

      final foto = (await db.select(db.evidencias).get()).single;
      expect(await File(foto.archivoPath).exists(), isTrue);
    });

    test('una foto que no se pudo bajar deja un hueco, no cancela', () async {
      // La URL de un adjunto de Airtable caduca en unas horas. Que una foto se
      // pierda no puede costar el historial entero.
      final resultado = await repo.importarHistorial(
        historial(
          evidencias: [
            {'titulo': 'Foto 01', 'url': 'https://airtable.test/vencida.jpg'},
          ],
        ),
        bajar: (url) async => null,
      );

      expect(resultado.visitas, 1);
      expect(resultado.fotos, 0);
      expect((await db.select(db.evidencias).get()).length, 1);
    });

    test('la foto que no bajo NO queda apuntando a un archivo inexistente',
        () async {
      // Es la diferencia entre un hueco y una mentira. Con la ruta escrita, la
      // galeria mostraba una miniatura rota y la visita decia tener fotos que
      // no se podian abrir; la pantalla no tenia como distinguir «no bajo» de
      // «se corrompio».
      await repo.importarHistorial(
        historial(
          evidencias: [
            {
              'titulo': 'Foto 01',
              'url': 'https://airtable.test/vencida.jpg',
              'descripcion_visitador': '[12:04] Hoja con sigatoka',
            },
          ],
        ),
        bajar: (url) async => null,
      );

      final e = (await db.select(db.evidencias).get()).single;
      expect(e.archivoPath, isEmpty);
      // Lo que se anoto de la foto sobrevive: sirve sin la imagen.
      expect(e.descripcionVisitador, 'Hoja con sigatoka');
      expect(e.segundoAudio, 724);
    });

    test('el tramo que no bajo conserva la transcripcion y no finge audio',
        () async {
      await repo.importarHistorial(
        historial(
          grabaciones: [
            {
              'orden': 1,
              'url': 'https://bucket.test/tramo-01.m4a',
              'transcripcion': 'El arriendo son 600 mil',
            },
          ],
        ),
        bajar: (url) async => null,
      );

      final g = (await db.select(db.grabaciones).get()).single;
      expect(g.archivoPath, isEmpty);
      expect(g.transcripcion, 'El arriendo son 600 mil');
    });
  });

  group('agrupar por agricultor', () {
    test('cada agricultor con sus visitas, el mas reciente primero', () async {
      await repo.crearVisitaConProductor(
        inicio: DateTime(2026, 9, 1, 8),
        nombreProductor: 'Ana Perez',
      );
      final primera = await repo.crearVisitaConProductor(
        inicio: DateTime(2026, 9, 5, 8),
        nombreProductor: 'Pedro Rodriguez',
      );
      // La segunda visita se cuelga de la MISMA ficha, como hace la pantalla
      // cuando el visitador elige al agricultor del directorio. Sin pasar el
      // id, `crearVisitaConProductor` crea una persona nueva con el mismo
      // nombre — que es el duplicado que el directorio existe para evitar.
      final pedro = (await repo.productorDeVisita(primera))!;
      await repo.crearVisitaConProductor(
        inicio: DateTime(2026, 9, 9, 8),
        nombreProductor: pedro.nombreCompleto,
        productorLocalId: pedro.id,
      );

      final grupos = await repo.observarVisitasPorAgricultor().first;

      expect(grupos.length, 2);
      expect(grupos.first.nombre, 'Pedro Rodriguez');
      expect(grupos.first.visitas.length, 2);
      // Dentro del grupo, la mas reciente arriba.
      expect(grupos.first.visitas.first.inicio, DateTime(2026, 9, 9, 8));
      expect(grupos.last.nombre, 'Ana Perez');
    });

    test('el grupo distingue lo propio de lo que se trajo', () async {
      await repo.crearVisitaConProductor(
        inicio: DateTime(2026, 9, 1, 8),
        nombreProductor: 'Pedro Rodriguez',
      );
      // El espejo reconoce al agricultor por el nombre normalizado, asi que
      // cae en la misma ficha que la visita propia de arriba.
      await repo.importarHistorial(historial());

      final grupo = (await repo.observarVisitasPorAgricultor().first).single;

      expect(grupo.visitas.length, 2);
      expect(grupo.propias, 1);
      expect(grupo.espejadas, 1);
    });

    test('las visitas sin agricultor van juntas, no una por grupo', () async {
      // Esconderlas seria tapar un pendiente; darle un encabezado a cada una
      // dejaria la pantalla peor que la lista plana.
      await repo.crearVisita(inicio: DateTime(2026, 9, 1, 8));
      await repo.crearVisita(inicio: DateTime(2026, 9, 2, 8));

      final grupos = await repo.observarVisitasPorAgricultor().first;

      expect(grupos.length, 1);
      expect(grupos.single.sinFicha, isTrue);
      expect(grupos.single.visitas.length, 2);
    });
  });

  group('el indice automatico', () {
    Map<String, dynamic> ficha({String codigo = codigo, String? productor}) => {
          'codigo_visita': codigo,
          'inicio': '2026-09-10T09:30:00.000Z',
          'estado': 'Cerrada',
          'productor': productor ?? 'Pedro Rodriguez',
          'finca': 'La Esperanza',
          'vereda': 'Guaicaramo',
          'completitud_pct': 48,
        };

    test('la visita entra como espejo y SIN detalle', () async {
      // `detalleEn` en null es lo que distingue «solo la ficha» de «visita
      // vacia». Sin esa diferencia, una visita a medio bajar se veria igual
      // que una donde no se registro nada.
      final tocadas = await repo.importarIndiceVisitas([ficha()]);

      final v = await (db.select(db.visitas)..where((x) => x.id.equals(codigo)))
          .getSingle();

      expect(tocadas, 1);
      expect(v.soloLectura, isTrue);
      expect(v.detalleEn, isNull);
      expect(await repo.faltaElDetalle(codigo), isTrue);
    });

    test('el indice NO toca una visita propia', () async {
      // La misma regla del historial, y mas importante aca: esto corre solo,
      // sin que nadie lo pida, cada vez que se abre la lista.
      final propioId = await repo.crearVisitaConProductor(
        inicio: DateTime(2026, 9, 2, 8),
        nombreProductor: 'Pedro Rodriguez',
      );

      await repo.importarIndiceVisitas([ficha(codigo: propioId)]);

      final v = await (db.select(db.visitas)
            ..where((x) => x.id.equals(propioId)))
          .getSingle();
      expect(v.soloLectura, isFalse);
      expect(await repo.faltaElDetalle(propioId), isNull);
    });

    test('refrescar el indice no borra el detalle ya bajado', () async {
      // El indice corre solo y a menudo. Si cada pasada borrara los hijos, las
      // fotos que alguien acaba de bajar desaparecerian al volver a la lista.
      await repo.importarHistorial(
        historial(
          informes: [
            {'titulo': 'Informe', 'contenido': 'texto', 'version': 1},
          ],
        ),
      );
      expect(await repo.faltaElDetalle(codigo), isFalse);

      await repo.importarIndiceVisitas([ficha()]);

      expect((await db.select(db.informes).get()).length, 1);
      expect(await repo.faltaElDetalle(codigo), isFalse);
    });

    test('el indice actualiza la ficha de un espejo que ya estaba', () async {
      await repo.importarIndiceVisitas([ficha()]);
      await repo.importarIndiceVisitas([
        {...ficha(), 'completitud_pct': 90, 'estado': 'Validada'},
      ]);

      final v = await (db.select(db.visitas)..where((x) => x.id.equals(codigo)))
          .getSingle();
      expect(v.completitudPct, 90);
      expect(v.estado, 'Validada');
      expect((await db.select(db.visitas).get()).length, 1);
    });
  });

  group('trazabilidad: la visita cuelga del agricultor', () {
    test('tecleando el mismo nombre NO se crea un agricultor nuevo', () async {
      // Era la fuga mas tonta: dos visitas a don Pedro escritas a mano
      // quedaban colgadas de dos don Pedro, cada uno con su finca y ninguno
      // con la historia del otro.
      await repo.crearVisitaConProductor(
        inicio: DateTime(2026, 9, 1, 8),
        nombreProductor: 'Pedro Rodriguez',
        nombreFinca: 'La Esperanza',
      );
      await repo.crearVisitaConProductor(
        inicio: DateTime(2026, 9, 9, 8),
        nombreProductor: 'pedro  rodriguez',
        nombreFinca: 'La Esperanza',
      );

      expect((await db.select(db.productores).get()).length, 1);
      expect((await db.select(db.fincas).get()).length, 1);

      final grupos = await repo.observarVisitasPorAgricultor().first;
      expect(grupos.length, 1);
      expect(grupos.single.visitas.length, 2);
    });

    test('con dos homonimos no se adivina: se crea uno nuevo', () async {
      // Robarle la ficha a otra persona es peor que crear una de mas. Es la
      // misma regla que sigue el directorio al mezclar.
      await db.into(db.productores).insert(
            ProductoresCompanion.insert(id: 'p1', nombreCompleto: 'Juan Perez'),
          );
      await db.into(db.productores).insert(
            ProductoresCompanion.insert(id: 'p2', nombreCompleto: 'Juan Perez'),
          );

      await repo.crearVisitaConProductor(
        inicio: DateTime(2026, 9, 9, 8),
        nombreProductor: 'Juan Perez',
      );

      final juanes = (await db.select(db.productores).get())
          .where((p) => p.nombreCompleto.toLowerCase().contains('juan'));
      expect(juanes.length, 3);
    });

    test('elegir del directorio sigue mandando sobre el nombre', () async {
      // Si el visitador eligio una ficha, esa es, aunque el nombre tecleado
      // coincida con otra.
      await db.into(db.productores).insert(
            ProductoresCompanion.insert(
              id: 'elegido',
              nombreCompleto: 'Pedro Rodriguez',
            ),
          );

      final id = await repo.crearVisitaConProductor(
        inicio: DateTime(2026, 9, 9, 8),
        nombreProductor: 'Pedro Rodriguez',
        productorLocalId: 'elegido',
      );

      final v = await (db.select(db.visitas)..where((x) => x.id.equals(id)))
          .getSingle();
      expect(v.productorLocalId, 'elegido');
      expect((await db.select(db.productores).get()).length, 1);
    });

    test('la finca reusada se queda con las coordenadas que le faltaban',
        () async {
      await repo.crearVisitaConProductor(
        inicio: DateTime(2026, 9, 1, 8),
        nombreProductor: 'Pedro Rodriguez',
        nombreFinca: 'La Esperanza',
      );
      await repo.crearVisitaConProductor(
        inicio: DateTime(2026, 9, 9, 8),
        nombreProductor: 'Pedro Rodriguez',
        nombreFinca: 'La Esperanza',
        latitud: 4.57321,
        longitud: -72.819044,
      );

      final finca = (await db.select(db.fincas).get()).single;
      expect(finca.latitud, closeTo(4.57321, 0.000001));
    });
  });
}
