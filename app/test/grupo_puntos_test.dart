import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirius_agro/core/kml.dart';
import 'package:sirius_agro/data/db/app_database.dart';
import 'package:sirius_agro/data/trazado_repository.dart';
import 'package:sirius_agro/data/visita_repository.dart';

const _lat = 4.5697;
const _lon = -72.9631;

/// ~10 m en grados a esta latitud: la distancia entre dos plantas de cacao.
const _diez = 0.00009;

void main() {
  late AppDatabase db;
  late TrazadoRepository repo;
  late String visitaId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final visitas = VisitaRepository(db);
    repo = TrazadoRepository(db, visitas);
    visitaId = await visitas.crearVisita(
      inicio: DateTime(2026, 11, 23, 9),
      latitud: _lat,
      longitud: _lon,
    );
  });

  tearDown(() => db.close());

  /// Un punto suelto como lo deja el boton rapido de la visita.
  Future<String> puntoSuelto(
    int minuto, {
    String? nombre,
    String? etiqueta,
    String? nota,
  }) async {
    final id = await repo.crearTrazado(
      visitaId: visitaId,
      tipo: TipoTrazado.punto,
      nombre: nombre,
      etiqueta: etiqueta,
    );
    await repo.agregarPunto(
      trazadoId: id,
      latitud: _lat + minuto * _diez,
      longitud: _lon,
      precisionM: 4,
      nota: nota,
      capturadoEn: DateTime(2026, 11, 23, 9, minuto),
    );
    return id;
  }

  group('un grupo de puntos sueltos', () {
    test('acepta varios puntos y no les inventa largo', () async {
      final id = await repo.crearTrazado(
        visitaId: visitaId,
        tipo: TipoTrazado.punto,
        nombre: 'Plantas con monilia',
      );
      for (var i = 0; i < 4; i++) {
        await repo.agregarPunto(
          trazadoId: id,
          latitud: _lat + i * _diez,
          longitud: _lon,
        );
      }

      expect(await repo.puntosDeTrazado(id), hasLength(4));
      final t = (await repo.porId(id))!;
      expect(t.perimetroM, isNull);
      expect(t.areaM2, isNull);
      expect(TipoTrazado.punto.unePuntos, isFalse);
      expect(TipoTrazado.ruta.unePuntos, isTrue);
    });

    test('la nota de cada punto se cambia y se borra', () async {
      final id = await puntoSuelto(1);
      final punto = (await repo.puntosDeTrazado(id)).single;

      await repo.actualizarNotaPunto(punto.id, '  con monilia  ');
      expect((await repo.puntosDeTrazado(id)).single.nota, 'con monilia');

      await repo.actualizarNotaPunto(punto.id, '   ');
      expect((await repo.puntosDeTrazado(id)).single.nota, isNull);
    });
  });

  group('agrupar', () {
    test('junta los puntos en el mas antiguo, en orden de captura', () async {
      // Creados en un orden y capturados en otro: manda la hora del punto.
      final a = await puntoSuelto(5);
      final b = await puntoSuelto(1);
      final c = await puntoSuelto(3);

      final grupo = await repo.agruparPuntos([
        b,
        c,
        a,
      ], nombre: 'Cacao enfermo');

      expect(grupo, b, reason: 'el grupo es el del primer punto marcado');
      final puntos = await repo.puntosDeTrazado(grupo);
      expect([for (final p in puntos) p.capturadoEn.minute], [1, 3, 5]);
      expect([for (final p in puntos) p.orden], [1, 2, 3]);

      final t = (await repo.porId(grupo))!;
      expect(t.nombre, 'Cacao enfermo');
      expect(t.tipo, TipoTrazado.punto);
      expect(await repo.porId(a), isNull);
      expect(await repo.porId(c), isNull);
      expect(await repo.trazadosDeVisita(visitaId), hasLength(1));
    });

    test('lo que el visitador escribio pasa a la nota del punto', () async {
      final a = await puntoSuelto(1); // «Punto 1»: nombre de la app
      final b = await puntoSuelto(2, nombre: 'Bocatoma');
      final c = await puntoSuelto(3, etiqueta: 'Cacao', nota: 'muy enferma');
      final d = await puntoSuelto(4, etiqueta: 'Platano');

      final grupo = await repo.agruparPuntos([a, b, c, d]);
      final notas = [for (final p in await repo.puntosDeTrazado(grupo)) p.nota];

      expect(notas, [null, 'Bocatoma', 'Cacao · muy enferma', 'Platano']);
      // Sin nombre, el grupo dice cuantos son.
      expect((await repo.porId(grupo))!.nombre, 'Grupo de 4 puntos');
    });

    test('un cultivo comun queda como etiqueta del grupo', () async {
      final a = await puntoSuelto(1, etiqueta: 'Cacao');
      final b = await puntoSuelto(2, etiqueta: 'Cacao');

      final grupo = await repo.agruparPuntos([a, b]);

      expect((await repo.porId(grupo))!.etiqueta, 'Cacao');
      expect(
        [for (final p in await repo.puntosDeTrazado(grupo)) p.nota],
        [null, null],
      );
    });

    test('se pueden sumar puntos a un grupo que ya existe', () async {
      final g = await repo.agruparPuntos([
        await puntoSuelto(1),
        await puntoSuelto(2),
      ], nombre: 'Plantas');
      final otro = await puntoSuelto(3);

      final grupo = await repo.agruparPuntos([g, otro], nombre: 'Plantas');

      expect(await repo.puntosDeTrazado(grupo), hasLength(3));
    });

    test(
      'no agrupa lotes, ni un solo punto, ni puntos de otra visita',
      () async {
        final punto = await puntoSuelto(1);
        final lote = await repo.crearTrazado(visitaId: visitaId);

        expect(() => repo.agruparPuntos([punto]), throwsArgumentError);
        expect(() => repo.agruparPuntos([punto, punto]), throwsArgumentError);
        await expectLater(
          repo.agruparPuntos([punto, lote]),
          throwsArgumentError,
        );
        // Nada cambio por los intentos fallidos.
        expect(await repo.trazadosDeVisita(visitaId), hasLength(2));
      },
    );
  });

  group('KML de un grupo', () {
    test('sale una marca por punto, numerada y con su nota', () async {
      final id = await repo.crearTrazado(
        visitaId: visitaId,
        tipo: TipoTrazado.punto,
        nombre: 'Plantas',
        etiqueta: 'Cacao',
      );
      for (var i = 0; i < 3; i++) {
        await repo.agregarPunto(
          trazadoId: id,
          latitud: _lat + i * _diez,
          longitud: _lon,
          precisionM: 3,
          nota: i == 1 ? 'con monilia' : null,
        );
      }

      final doc = await repo.documentoKml(
        visitaId,
        soloTrazadoId: id,
        incluirFotos: false,
        incluirPuntoVisita: false,
      );
      final kml = construirKml(doc);

      expect('<Placemark>'.allMatches(kml), hasLength(3));
      expect(kml, contains('<name>Plantas 1</name>'));
      expect(kml, contains('<name>Plantas 3</name>'));
      expect(kml, contains('Nota: con monilia'));
      expect(kml, contains('<Data name="Grupo">'));
      expect(kml, isNot(contains('<LineString>')));
      // Un grupo no tiene largo: la linea de una planta a otra no existe.
      expect(kml, isNot(contains('Largo (m)')));
    });

    test('un punto solo sigue saliendo como una sola marca', () async {
      final id = await puntoSuelto(1, nombre: 'Bocatoma');
      final kml = construirKml(
        await repo.documentoKml(
          visitaId,
          soloTrazadoId: id,
          incluirFotos: false,
          incluirPuntoVisita: false,
        ),
      );

      expect('<Placemark>'.allMatches(kml), hasLength(1));
      expect(kml, contains('<name>Bocatoma</name>'));
    });
  });
}
