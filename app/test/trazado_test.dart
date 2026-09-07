import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirius_agro/data/db/app_database.dart';
import 'package:sirius_agro/data/trazado_repository.dart';
import 'package:sirius_agro/data/visita_repository.dart';

const _lat = 4.5697;
const _lon = -72.9631;

/// ~100 m en grados a esta latitud. Alcanza para probar los filtros: lo que se
/// verifica es que se apliquen, no la precision de la conversion (eso vive en
/// `geo_test.dart`).
const _cien = 0.0008993;

void main() {
  late AppDatabase db;
  late VisitaRepository visitas;
  late TrazadoRepository repo;
  late String visitaId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    visitas = VisitaRepository(db);
    repo = TrazadoRepository(db, visitas);
    visitaId = await visitas.crearVisita(
      inicio: DateTime(2026, 9, 7, 9),
      latitud: _lat,
      longitud: _lon,
    );
  });

  tearDown(() => db.close());

  group('crear', () {
    test('el nombre se numera por tipo dentro de la visita', () async {
      // «Trazado 3» no le dice a nadie cual de los lotes es.
      final a = await repo.crearTrazado(visitaId: visitaId);
      final b = await repo.crearTrazado(visitaId: visitaId);
      final r = await repo.crearTrazado(
        visitaId: visitaId,
        tipo: TipoTrazado.ruta,
      );

      expect((await repo.porId(a))!.nombre, 'Lote 1');
      expect((await repo.porId(b))!.nombre, 'Lote 2');
      expect((await repo.porId(r))!.nombre, 'Recorrido 1');
    });

    test('una ruta nace abierta y un poligono cerrado', () async {
      final poligono = await repo.crearTrazado(visitaId: visitaId);
      final ruta = await repo.crearTrazado(
        visitaId: visitaId,
        tipo: TipoTrazado.ruta,
      );
      expect((await repo.porId(poligono))!.cerrado, isTrue);
      expect((await repo.porId(ruta))!.cerrado, isFalse);
    });
  });

  group('filtros de la captura automatica', () {
    test('un punto automatico muy cerca del anterior no entra', () async {
      final id = await repo.crearTrazado(
        visitaId: visitaId,
        distanciaMinM: 10,
      );

      final primero = await repo.agregarPunto(
        trazadoId: id,
        latitud: _lat,
        longitud: _lon,
        automatico: true,
      );
      // Un metro mas alla, con filtro de 10 m.
      final segundo = await repo.agregarPunto(
        trazadoId: id,
        latitud: _lat + _cien / 100,
        longitud: _lon,
        automatico: true,
      );

      expect(primero, ResultadoPunto.agregado);
      expect(segundo, ResultadoPunto.muyCerca);
      expect((await repo.puntosDeTrazado(id)).length, 1);
    });

    test('un punto con GPS peor que el limite se descarta', () async {
      final id = await repo.crearTrazado(visitaId: visitaId, precisionMaxM: 20);

      final r = await repo.agregarPunto(
        trazadoId: id,
        latitud: _lat,
        longitud: _lon,
        precisionM: 65,
        automatico: true,
      );

      expect(r, ResultadoPunto.precisionInsuficiente);
      expect(await repo.puntosDeTrazado(id), isEmpty);
    });

    test('sin filtros configurados entra todo', () async {
      final id = await repo.crearTrazado(visitaId: visitaId);
      for (var i = 0; i < 3; i++) {
        expect(
          await repo.agregarPunto(
            trazadoId: id,
            latitud: _lat,
            longitud: _lon,
            precisionM: 90,
            automatico: true,
          ),
          ResultadoPunto.agregado,
        );
      }
      expect((await repo.puntosDeTrazado(id)).length, 3);
    });

    test('el punto marcado a mano entra siempre, filtros o no', () async {
      // Es la regla que sostiene la funcion: quien esta parado en la esquina
      // del lote sabe algo que el filtro no.
      final id = await repo.crearTrazado(
        visitaId: visitaId,
        distanciaMinM: 50,
        precisionMaxM: 5,
      );

      await repo.agregarPunto(trazadoId: id, latitud: _lat, longitud: _lon);
      final segundo = await repo.agregarPunto(
        trazadoId: id,
        latitud: _lat,
        longitud: _lon,
        precisionM: 200,
      );

      expect(segundo, ResultadoPunto.agregado);
      expect((await repo.puntosDeTrazado(id)).length, 2);
    });
  });

  group('modo de captura', () {
    test('mezclar dedo y reloj deja el trazado en mixto', () async {
      final id = await repo.crearTrazado(visitaId: visitaId);
      await repo.agregarPunto(trazadoId: id, latitud: _lat, longitud: _lon);
      expect((await repo.porId(id))!.modoCaptura, ModoCaptura.manual);

      await repo.agregarPunto(
        trazadoId: id,
        latitud: _lat + _cien,
        longitud: _lon,
        automatico: true,
      );
      expect((await repo.porId(id))!.modoCaptura, ModoCaptura.mixto);
    });
  });

  group('geometria persistida', () {
    /// Un cuadrado de ~100 m: una hectarea.
    Future<String> cuadrado() async {
      final id = await repo.crearTrazado(visitaId: visitaId);
      final esquinas = [
        [_lat, _lon],
        [_lat, _lon + _cien],
        [_lat + _cien, _lon + _cien],
        [_lat + _cien, _lon],
      ];
      for (final e in esquinas) {
        await repo.agregarPunto(trazadoId: id, latitud: e[0], longitud: e[1]);
      }
      return id;
    }

    test('el area y el perimetro quedan guardados con los puntos', () async {
      final id = await cuadrado();
      final t = (await repo.porId(id))!;
      expect(t.areaM2! / 10000, closeTo(1.0, 0.05));
      expect(t.perimetroM, closeTo(400, 5));
    });

    test('abrir el anillo le quita el area, no la deja vieja', () async {
      // Un area guardada que no corresponde a la figura es peor que no tener
      // area: el visitador la lee en la finca y decide con ella.
      final id = await cuadrado();
      await repo.actualizarTrazado(id, cerrado: false);

      final t = (await repo.porId(id))!;
      expect(t.areaM2, isNull);
      expect(t.perimetroM, closeTo(300, 5));
    });

    test('una ruta nunca tiene area', () async {
      final id = await cuadrado();
      await repo.actualizarTrazado(id, tipo: TipoTrazado.ruta);
      expect((await repo.porId(id))!.areaM2, isNull);
    });

    test('borrar un punto malo recalcula la figura', () async {
      final id = await cuadrado();
      // El punto disparado por un salto de GPS, a un kilometro del lote y
      // fuera de la linea de los otros: un pico sobre el mismo meridiano no
      // agrega area y no probaria nada.
      await repo.agregarPunto(
        trazadoId: id,
        latitud: _lat + _cien * 10,
        longitud: _lon + _cien * 5,
      );
      final inflada = (await repo.porId(id))!.areaM2!;
      // Un pico de 1 km infla la hectarea a ~1,5: eso es un lindero movido.
      expect(inflada / 10000, greaterThan(1.4));

      final puntos = await repo.puntosDeTrazado(id);
      await repo.eliminarPunto(puntos.last.id);

      expect((await repo.porId(id))!.areaM2! / 10000, closeTo(1.0, 0.05));
    });

    test('deshacer el ultimo saca el ultimo y no otro', () async {
      final id = await cuadrado();
      final antes = await repo.puntosDeTrazado(id);
      await repo.deshacerUltimoPunto(id);
      final despues = await repo.puntosDeTrazado(id);

      expect(despues.length, antes.length - 1);
      expect(despues.map((p) => p.id), isNot(contains(antes.last.id)));
    });

    test('el orden no se reusa al borrar del medio', () async {
      // Reusar un numero pondria dos vertices en la misma posicion del anillo.
      final id = await cuadrado();
      final puntos = await repo.puntosDeTrazado(id);
      await repo.eliminarPunto(puntos[1].id);
      await repo.agregarPunto(
        trazadoId: id,
        latitud: _lat + _cien * 2,
        longitud: _lon,
      );

      final ordenes = (await repo.puntosDeTrazado(id)).map((p) => p.orden);
      expect(ordenes.toSet().length, ordenes.length);
      expect(ordenes.last, 5);
    });
  });

  group('KML', () {
    test('sin puntos no se exporta nada y se dice por que', () async {
      await repo.crearTrazado(visitaId: visitaId);
      expect(
        () => repo.exportarKml(visitaId),
        throwsA(
          isA<Exception>().having(
            (e) => '$e',
            'mensaje',
            contains('ningun punto'),
          ),
        ),
      );
    });

    test('el documento lleva la ficha de la visita, no solo coordenadas',
        () async {
      final id = await repo.crearTrazado(visitaId: visitaId, etiqueta: 'Platano');
      await repo.agregarPunto(trazadoId: id, latitud: _lat, longitud: _lon);

      final doc = await repo.documentoKml(visitaId);
      expect(doc.descripcion, contains('Codigo de visita: $visitaId'));
      expect(doc.trazados.single.etiqueta, 'Platano');
      // La coordenada de llegada a la finca entra como referencia.
      expect(doc.referencias, isNotEmpty);
    });

    test('se puede exportar un solo trazado', () async {
      final a = await repo.crearTrazado(visitaId: visitaId, nombre: 'Lote A');
      final b = await repo.crearTrazado(visitaId: visitaId, nombre: 'Lote B');
      for (final id in [a, b]) {
        await repo.agregarPunto(trazadoId: id, latitud: _lat, longitud: _lon);
      }

      final todos = await repo.documentoKml(visitaId);
      final solo = await repo.documentoKml(visitaId, soloTrazadoId: a);

      expect(todos.trazados.length, 2);
      expect(solo.trazados.single.nombre, 'Lote A');
    });

    test('los trazados vacios no llegan al documento', () async {
      final conPuntos = await repo.crearTrazado(visitaId: visitaId);
      await repo.crearTrazado(visitaId: visitaId, nombre: 'Nunca se camino');
      await repo.agregarPunto(
        trazadoId: conPuntos,
        latitud: _lat,
        longitud: _lon,
      );

      final doc = await repo.documentoKml(visitaId);
      expect(doc.trazados.length, 1);
    });
  });

  group('sincronizacion y borrado', () {
    test('los trazados viajan en el payload de la visita', () async {
      final id = await repo.crearTrazado(
        visitaId: visitaId,
        nombre: 'Lote de arriba',
        intervaloSeg: 10,
        distanciaMinM: 5,
      );
      await repo.agregarPunto(
        trazadoId: id,
        latitud: _lat,
        longitud: _lon,
        precisionM: 4.5,
      );

      final payload = await visitas.payloadDeVisita(visitaId);
      final trazados = payload['trazados'] as List;
      final primero = trazados.single as Map<String, dynamic>;

      expect(primero['nombre'], 'Lote de arriba');
      expect(primero['modo_captura'], 'Manual');
      expect(primero['intervalo_seg'], 10);
      // La huella de como se capturo viaja con el punto: sin ella el area no
      // se puede auditar seis meses despues.
      final punto = (primero['puntos'] as List).single as Map<String, dynamic>;
      expect(punto['precision_m'], 4.5);
      expect(punto['automatico'], isFalse);
    });

    test('eliminar la visita se lleva trazados y puntos', () async {
      final id = await repo.crearTrazado(visitaId: visitaId);
      await repo.agregarPunto(trazadoId: id, latitud: _lat, longitud: _lon);

      await visitas.eliminarVisitas([visitaId]);

      expect(await db.select(db.trazados).get(), isEmpty);
      expect(await db.select(db.puntosTrazado).get(), isEmpty);
    });

    test('eliminar un trazado no toca los otros', () async {
      final a = await repo.crearTrazado(visitaId: visitaId);
      final b = await repo.crearTrazado(visitaId: visitaId);
      for (final id in [a, b]) {
        await repo.agregarPunto(trazadoId: id, latitud: _lat, longitud: _lon);
      }

      await repo.eliminarTrazado(a);

      expect((await repo.trazadosDeVisita(visitaId)).single.id, b);
      expect((await repo.puntosDeTrazado(b)).length, 1);
    });
  });
}
