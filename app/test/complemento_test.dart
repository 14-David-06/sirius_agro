import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sirius_agro/core/api_client.dart';
import 'package:sirius_agro/core/complemento_visita.dart';
import 'package:sirius_agro/data/db/app_database.dart';
import 'package:sirius_agro/data/semilla.dart';
import 'package:sirius_agro/data/visita_repository.dart';

/// El chat que completa la visita: lo unico que escribe datos sin pasar por el
/// audio.
///
/// Lo que se protege es la diferencia entre un dato que dijo el agricultor
/// grabado y uno que el visitador recuerda despues. El sistema entero se apoya
/// en que esa diferencia quede marcada en el dato: si un complemento pudiera
/// entrar como `Confirmado`, el informe se lo leeria al productor como si el
/// lo hubiera dicho.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Las fechas del markdown van en español, como en `main()`.
  setUpAll(() => initializeDateFormatting('es'));

  late AppDatabase db;
  late VisitaRepository repo;
  late String visitaId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await Semilla(db, rootBundle).sembrarSiHaceFalta();
    repo = VisitaRepository(db);
    visitaId = await repo.crearVisitaConProductor(
      inicio: DateTime(2026, 9, 14, 9),
      nombreProductor: 'Pedro Rodriguez',
      nombreFinca: 'La Esperanza',
    );
  });

  tearDown(() async => db.close());

  /// Un hallazgo como lo devuelve `/v1/complemento`: ya marcado por el backend.
  Map<String, dynamic> delChat(
    String clave, {
    String certeza = 'Confirmado',
    String cita = 'el arriendo son 600 mil al mes',
    Object? valor = '600000',
  }) =>
      {
        'clave': clave,
        'entidad_destino': 'Finca',
        'valor_texto': valor,
        'certeza': certeza,
        'cita': cita,
        'fuente': 'Manual',
        'hablante': 'visitador',
        'segundo': null,
      };

  Future<String> algunaClave() async =>
      (await db.camposActivos()).first.claveTecnica;

  group('la procedencia del dato tecleado', () {
    test('lo que aporta el visitador NUNCA queda Confirmado', () async {
      // La regla dura del sistema. El chat manda "Confirmado" porque el
      // visitador lo afirmo sin dudar; `insertarHallazgo` lo baja igual,
      // porque quien lo afirmo no es el agricultor.
      final clave = await algunaClave();
      await repo.guardarExtraccion(
        visitaId: visitaId,
        extraidos: [HallazgoExtraido.fromJson(delChat(clave))],
      );

      final h = (await db.hallazgosDeVisita(visitaId)).single;
      expect(h.certeza, Certeza.estimado);
      expect(h.hablante, Hablante.visitador);
      expect(h.fuente, FuenteHallazgo.manual);
    });

    test('la frase del visitador queda como cita', () async {
      // Es lo que hace auditable el guardado directo: meses despues, un valor
      // que no vino del audio tiene que poder explicarse.
      final clave = await algunaClave();
      await repo.guardarExtraccion(
        visitaId: visitaId,
        extraidos: [
          HallazgoExtraido.fromJson(
            delChat(clave, cita: 'me dijo que son 600 mil mensuales'),
          ),
        ],
      );

      final h = (await db.hallazgosDeVisita(visitaId)).single;
      expect(h.citaTextual, 'me dijo que son 600 mil mensuales');
    });

    test('sin segundo del audio: no hay audio detras', () async {
      // Un segundo inventado mandaria al visitador a escuchar un minuto de la
      // grabacion donde nadie dijo nada.
      final clave = await algunaClave();
      await repo.guardarExtraccion(
        visitaId: visitaId,
        extraidos: [HallazgoExtraido.fromJson(delChat(clave))],
      );

      expect((await db.hallazgosDeVisita(visitaId)).single.segundoAudio, isNull);
    });

    test('un complemento sin cita igual entra, porque su fuente es Manual',
        () async {
      // La regla 2 (sin cita, a Pendiente) exceptua a `Manual` y `GPS`: su
      // fuente no es la conversacion, asi que no puede haber una frase de la
      // transcripcion que los respalde.
      final clave = await algunaClave();
      await repo.guardarExtraccion(
        visitaId: visitaId,
        extraidos: [
          HallazgoExtraido.fromJson(
            {...delChat(clave), 'cita': null, 'certeza': 'Estimado'},
          ),
        ],
      );

      final h = (await db.hallazgosDeVisita(visitaId)).single;
      expect(h.certeza, Certeza.estimado);
    });

    test('el complemento cuenta para la completitud', () async {
      // Es la mitad del sentido de la funcion: completar lo que falto tiene
      // que mover el semaforo, o el visitador no sabe si sirvio de algo.
      final obligatorio = (await db.obligatoriosActivos()).first.claveTecnica;
      final antes = await db.calcularCompletitud(visitaId);

      await repo.guardarExtraccion(
        visitaId: visitaId,
        extraidos: [HallazgoExtraido.fromJson(delChat(obligatorio))],
      );

      expect(await db.calcularCompletitud(visitaId), greaterThan(antes));
    });
  });

  group('la conversacion guardada', () {
    test('es una sola fila que se reescribe, no una version por mensaje',
        () async {
      // Si cada turno creara una version, una conversacion de veinte mensajes
      // dejaria veinte informes en Airtable y ninguno seria el bueno.
      await repo.guardarConversacionComplemento(
        visitaId: visitaId,
        contenido: 'primer turno',
      );
      await repo.guardarConversacionComplemento(
        visitaId: visitaId,
        contenido: 'primer turno y segundo',
      );

      final filas = await (db.select(db.informes)
            ..where((i) => i.tipo.equals(tipoComplementoVisita)))
          .get();

      expect(filas.length, 1);
      expect(filas.single.version, 1);
      expect(filas.single.contenido, 'primer turno y segundo');
    });

    test('no se mezcla con los informes del agricultor', () async {
      await repo.guardarInforme(
        visitaId: visitaId,
        titulo: 'Informe La Esperanza',
        contenido: '## Lo que conversamos',
        tipo: 'Resumen para el agricultor',
      );
      await repo.guardarConversacionComplemento(
        visitaId: visitaId,
        contenido: 'conversacion',
      );

      final guardada = await repo.conversacionComplemento(visitaId);
      expect(guardada, isNotNull);
      expect(guardada!.tipo, tipoComplementoVisita);
      expect((await repo.informesDeVisita(visitaId)).length, 2);
    });

    test('la visita queda encolada para que el hilo llegue a Airtable',
        () async {
      await repo.guardarConversacionComplemento(
        visitaId: visitaId,
        contenido: 'conversacion',
      );

      final cola = await db.select(db.syncQueue).get();
      expect(cola.where((i) => i.entidadId == visitaId), isNotEmpty);
    });
  });

  group('el markdown que se archiva', () {
    test('lleva el hilo literal, no un resumen', () async {
      // Es el registro de procedencia. Un resumen escrito por el modelo seria
      // un registro de procedencia que ya paso por un modelo.
      final md = markdownConversacion(
        mensajes: const [
          MensajeChat(rol: 'user', contenido: 'El arriendo son 600 al mes'),
          MensajeChat(rol: 'assistant', contenido: 'Anotado.'),
        ],
        generadoEn: DateTime(2026, 9, 14, 15),
        visitador: 'Persona De Prueba',
        datosEscritos: const ['arriendo_valor: 600000'],
      );

      expect(md, contains('El arriendo son 600 al mes'));
      expect(md, contains('Anotado.'));
      expect(md, contains('arriendo_valor: 600000'));
      expect(md, contains('Persona De Prueba'));
    });

    test('dice que lo de aqui no salio del audio', () async {
      // Quien lea esto en Airtable dentro de seis meses tiene que entender por
      // que ninguno de estos datos esta como «Confirmado».
      final md = markdownConversacion(
        mensajes: const [MensajeChat(rol: 'user', contenido: 'algo')],
        generadoEn: DateTime(2026, 9, 14, 15),
      );

      expect(md, contains('NO salio del audio'));
      expect(md, contains('Confirmado'));
    });
  });

  group('el contexto que ve el modelo', () {
    test('lleva lo registrado y lo que falta', () async {
      final clave = await algunaClave();
      await repo.guardarExtraccion(
        visitaId: visitaId,
        extraidos: [HallazgoExtraido.fromJson(delChat(clave))],
      );

      final contexto = await repo.contextoComplemento(visitaId);

      expect(contexto, contains('DATOS YA REGISTRADOS'));
      expect(contexto, contains(clave));
      expect(contexto, contains('OBLIGATORIOS QUE FALTAN'));
      expect(contexto, contains('Pedro Rodriguez'));
    });

    test('NO sugiere los campos marcados «no sugerir»', () async {
      // `motivo_llegada` cuenta para la completitud y no se pregunta.
      // Preguntarle a alguien por que le toco dejar su tierra, para cerrar un
      // checklist, es justo lo que no se debe hacer — y el chat no es la
      // excepcion.
      final noSugeribles = (await db.select(db.catalogoCampos).get())
          .where((c) => c.noSugerir && c.obligatorioMvp && c.activo)
          .map((c) => c.claveTecnica);

      final contexto = await repo.contextoComplemento(visitaId);
      final faltantes = contexto.split('OBLIGATORIOS QUE FALTAN').last;

      for (final clave in noSugeribles) {
        expect(faltantes, isNot(contains(clave)));
      }
    });

    test('una visita sin nada dice que no hay nada, no miente', () async {
      final contexto = await repo.contextoComplemento(visitaId);
      expect(contexto, contains('(Ninguno todavia.)'));
    });
  });
}
