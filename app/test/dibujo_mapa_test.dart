import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirius_agro/core/dibujo.dart';
import 'package:sirius_agro/data/db/app_database.dart';
import 'package:sirius_agro/data/trazado_repository.dart';
import 'package:sirius_agro/data/visita_repository.dart';

const _lat = 4.5697;
const _lon = -72.9631;

/// ~100 m en grados a esta latitud.
const _cien = 0.0008993;

/// Guardar un lote dibujado sobre el mapa: lo que queda en la base tiene que
/// decir que se dibujo, no fingir que se camino.
void main() {
  late AppDatabase db;
  late TrazadoRepository repo;
  late String visitaId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final visitas = VisitaRepository(db);
    repo = TrazadoRepository(db, visitas);
    visitaId = await visitas.crearVisita(
      inicio: DateTime(2026, 9, 7, 9),
      latitud: _lat,
      longitud: _lon,
    );
  });

  tearDown(() => db.close());

  /// Un cuadrado de 100 m de lado, dibujado con [conPincel].
  List<VerticeDibujado> cuadrado({bool conPincel = true}) => [
    (latitud: _lat, longitud: _lon, conPincel: conPincel),
    (latitud: _lat, longitud: _lon + _cien, conPincel: conPincel),
    (latitud: _lat + _cien, longitud: _lon + _cien, conPincel: conPincel),
    (latitud: _lat + _cien, longitud: _lon, conPincel: conPincel),
  ];

  test('el dibujo queda en orden, sin precision y con su nota', () async {
    final id = await repo.crearTrazado(visitaId: visitaId);

    await repo.reemplazarPuntos(id, [
      ...cuadrado().take(3),
      (latitud: _lat + _cien, longitud: _lon, conPincel: false),
    ]);

    final puntos = await repo.puntosDeTrazado(id);
    expect([for (final p in puntos) p.orden], [1, 2, 3, 4]);
    // Ningun GPS midio estos puntos: inventarles precision seria mentir.
    expect(puntos.every((p) => p.precisionM == null), isTrue);
    expect(puntos.every((p) => !p.automatico), isTrue);
    expect(
      [for (final p in puntos) p.nota],
      [notaPincel, notaPincel, notaPincel, notaToque],
    );
  });

  test('reemplaza lo que habia y recalcula el area', () async {
    final id = await repo.crearTrazado(visitaId: visitaId);
    // Un lindero caminado con GPS, que despues se corrige dibujando.
    for (final v in cuadrado().take(3)) {
      await repo.agregarPunto(
        trazadoId: id,
        latitud: v.latitud,
        longitud: v.longitud,
        precisionM: 4,
        automatico: true,
      );
    }

    await repo.reemplazarPuntos(id, cuadrado());

    final puntos = await repo.puntosDeTrazado(id);
    expect(puntos, hasLength(4));
    expect(puntos.every((p) => p.precisionM == null), isTrue);

    final trazado = (await repo.porId(id))!;
    // 100 m x 100 m: una hectarea, con margen por la conversion de grados.
    expect(trazado.areaM2, closeTo(10000, 150));
    // Lo puso todo el dedo: ya no es un trazado automatico ni mixto.
    expect(trazado.modoCaptura, ModoCaptura.manual);
    expect(trazado.actualizadoEn, isNotNull);
  });

  test('una ruta dibujada no tiene area, tiene largo', () async {
    final id = await repo.crearTrazado(
      visitaId: visitaId,
      tipo: TipoTrazado.ruta,
    );

    await repo.reemplazarPuntos(id, cuadrado().take(2).toList());

    final trazado = (await repo.porId(id))!;
    expect(trazado.areaM2 == null || trazado.areaM2 == 0, isTrue);
    expect(trazado.perimetroM, closeTo(100, 3));
  });

  test('reemplazar con nada deja el trazado vacio', () async {
    final id = await repo.crearTrazado(visitaId: visitaId);
    await repo.reemplazarPuntos(id, cuadrado());

    await repo.reemplazarPuntos(id, const []);

    expect(await repo.puntosDeTrazado(id), isEmpty);
  });

  test('no toca los puntos de otro trazado', () async {
    final a = await repo.crearTrazado(visitaId: visitaId);
    final b = await repo.crearTrazado(visitaId: visitaId);
    await repo.reemplazarPuntos(b, cuadrado());

    await repo.reemplazarPuntos(a, cuadrado(conPincel: false));

    expect(await repo.puntosDeTrazado(b), hasLength(4));
  });

  group('varios lotes dibujados de una vez', () {
    /// El cuadrado corrido [lado] lados hacia el este: un lote vecino.
    List<VerticeDibujado> vecino(int lado) => [
      for (final v in cuadrado())
        (
          latitud: v.latitud,
          longitud: v.longitud + lado * _cien * 1.5,
          conPincel: true,
        ),
    ];

    LoteDibujado lote(int lado, [String? nombre]) =>
        (vertices: vecino(lado), nombre: nombre);

    test('el primero va al lote abierto y cada uno de mas es un lote '
        'nuevo', () async {
      final id = await repo.crearTrazado(visitaId: visitaId, etiqueta: 'Cacao');

      final nuevos = await repo.guardarDibujo(
        trazadoId: id,
        propios: cuadrado(),
        nuevos: [lote(1), lote(2)],
      );

      expect(nuevos, hasLength(2));
      expect(await repo.puntosDeTrazado(id), hasLength(4));

      final trazados = await repo.trazadosDeVisita(visitaId);
      expect(trazados, hasLength(3));
      // Numerados como si se hubieran creado a mano, en el orden dibujado.
      expect((await repo.porId(nuevos[0]))!.nombre, 'Lote 2');
      expect((await repo.porId(nuevos[1]))!.nombre, 'Lote 3');
      for (final nuevo in nuevos) {
        final t = (await repo.porId(nuevo))!;
        expect(t.tipo, TipoTrazado.poligono);
        expect(t.cerrado, isTrue);
        expect(t.modoCaptura, ModoCaptura.manual);
        // El cultivo es del lote que se abrio, no de sus vecinos.
        expect(t.etiqueta, isNull);
        expect(t.areaM2, closeTo(10000, 150));
        final puntos = await repo.puntosDeTrazado(nuevo);
        expect([for (final p in puntos) p.orden], [1, 2, 3, 4]);
        expect(puntos.every((p) => p.nota == notaPincel), isTrue);
      }
    });

    test('cada poligono lleva el nombre que se le puso al dibujarlo', () async {
      final id = await repo.crearTrazado(visitaId: visitaId);

      final nuevos = await repo.guardarDibujo(
        trazadoId: id,
        propios: cuadrado(),
        nombrePropio: '  Palma 2015 ',
        nuevos: [lote(1, 'Potrero'), lote(2)],
      );

      expect((await repo.porId(id))!.nombre, 'Palma 2015');
      expect((await repo.porId(nuevos[0]))!.nombre, 'Potrero');
      // El que se dejo sin nombre toma el de por defecto.
      expect((await repo.porId(nuevos[1]))!.nombre, 'Lote 3');
    });

    test('con grupo, el abierto y los nuevos quedan juntos', () async {
      final id = await repo.crearTrazado(visitaId: visitaId);
      final suelto = await repo.crearTrazado(visitaId: visitaId);

      final nuevos = await repo.guardarDibujo(
        trazadoId: id,
        propios: cuadrado(),
        nuevos: [lote(1), lote(2)],
        grupo: 'Finca El Recreo',
      );

      for (final t in [id, ...nuevos]) {
        expect((await repo.porId(t))!.grupo, 'Finca El Recreo');
      }
      // Lo que no se dibujo en esta pasada no entra al grupo.
      expect((await repo.porId(suelto))!.grupo, isNull);
    });

    test('sin grupo, el grupo que ya tenia el abierto no se pierde', () async {
      final id = await repo.crearTrazado(visitaId: visitaId, grupo: 'Cacao');

      await repo.guardarDibujo(trazadoId: id, propios: cuadrado());

      expect((await repo.porId(id))!.grupo, 'Cacao');
    });

    test('solo cambiarle el nombre no toca sus puntos', () async {
      final id = await repo.crearTrazado(visitaId: visitaId);
      await repo.reemplazarPuntos(id, cuadrado(conPincel: false));

      await repo.guardarDibujo(
        trazadoId: id,
        propios: const [],
        nombrePropio: 'Lote de arriba',
      );

      expect((await repo.porId(id))!.nombre, 'Lote de arriba');
      final puntos = await repo.puntosDeTrazado(id);
      expect(puntos, hasLength(4));
      expect(puntos.every((p) => p.nota == notaToque), isTrue);
    });

    test('si el primero viene vacio, el lote abierto no se toca', () async {
      final id = await repo.crearTrazado(visitaId: visitaId);
      // Un lindero caminado con GPS que no se quiere perder.
      for (final v in cuadrado()) {
        await repo.agregarPunto(
          trazadoId: id,
          latitud: v.latitud,
          longitud: v.longitud,
          precisionM: 3,
        );
      }

      final nuevos = await repo.guardarDibujo(
        trazadoId: id,
        propios: const [],
        nuevos: [lote(1)],
        grupo: 'Grupo 1',
      );

      expect(nuevos, hasLength(1));
      final puntos = await repo.puntosDeTrazado(id);
      expect(puntos, hasLength(4));
      expect(puntos.every((p) => p.precisionM == 3), isTrue);
      expect((await repo.porId(nuevos.single))!.nombre, 'Lote 2');
      // Pero si entra al grupo: el vecino se dibujo a partir de el.
      expect((await repo.porId(id))!.grupo, 'Grupo 1');
    });

    test('un lote de mas vacio no se crea', () async {
      final id = await repo.crearTrazado(visitaId: visitaId);

      final nuevos = await repo.guardarDibujo(
        trazadoId: id,
        propios: cuadrado(),
        nuevos: [(vertices: const [], nombre: 'Nada'), lote(1)],
      );

      expect(nuevos, hasLength(1));
      expect(await repo.trazadosDeVisita(visitaId), hasLength(2));
    });

    test('si el lote abierto ya no existe no crea nada', () async {
      await expectLater(
        repo.guardarDibujo(
          trazadoId: 'no-existe',
          propios: cuadrado(),
          nuevos: [lote(1)],
        ),
        throwsStateError,
      );
      expect(await repo.trazadosDeVisita(visitaId), isEmpty);
    });
  });

  group('grupos', () {
    test('cambiarle el nombre al grupo cambia a todos sus lotes', () async {
      final a = await repo.crearTrazado(visitaId: visitaId, grupo: 'Grupo 1');
      final b = await repo.crearTrazado(visitaId: visitaId, grupo: 'Grupo 1');
      final c = await repo.crearTrazado(visitaId: visitaId, grupo: 'Cacao');

      await repo.renombrarGrupo(visitaId, 'Grupo 1', 'Finca El Recreo');

      expect((await repo.porId(a))!.grupo, 'Finca El Recreo');
      expect((await repo.porId(b))!.grupo, 'Finca El Recreo');
      expect((await repo.porId(c))!.grupo, 'Cacao');
    });

    test('no toca el grupo del mismo nombre en otra visita', () async {
      final otraVisita = await VisitaRepository(db)
          .crearVisita(inicio: DateTime(2026, 9, 8, 9));
      final aca = await repo.crearTrazado(visitaId: visitaId, grupo: 'Lotes');
      final alla = await repo.crearTrazado(
        visitaId: otraVisita,
        grupo: 'Lotes',
      );

      await repo.renombrarGrupo(visitaId, 'Lotes', 'Palma');

      expect((await repo.porId(aca))!.grupo, 'Palma');
      expect((await repo.porId(alla))!.grupo, 'Lotes');
    });

    test('deshacer el grupo deja los lotes sueltos, con sus puntos', () async {
      final a = await repo.crearTrazado(visitaId: visitaId, grupo: 'Cacao');
      await repo.reemplazarPuntos(a, cuadrado());

      await repo.renombrarGrupo(visitaId, 'Cacao', '  ');

      expect((await repo.porId(a))!.grupo, isNull);
      expect(await repo.puntosDeTrazado(a), hasLength(4));
    });

    test('meter y sacar un lote de un grupo desde su ficha', () async {
      final a = await repo.crearTrazado(visitaId: visitaId);

      await repo.actualizarTrazado(a, grupo: 'Cacao');
      expect((await repo.porId(a))!.grupo, 'Cacao');

      // Sin tocar el grupo, editar otra cosa no lo saca.
      await repo.actualizarTrazado(a, nombre: 'Cacao viejo');
      expect((await repo.porId(a))!.grupo, 'Cacao');

      await repo.actualizarTrazado(a, grupo: '');
      expect((await repo.porId(a))!.grupo, isNull);
    });

    test('el nombre que se propone no repite uno que ya existe', () async {
      await repo.crearTrazado(visitaId: visitaId, grupo: 'Grupo 2');
      final trazados = await repo.trazadosDeVisita(visitaId);

      expect(TrazadoRepository.grupoPorDefecto(const []), 'Grupo 1');
      // Hay uno, asi que tocaria «Grupo 2», pero ese ya existe.
      expect(TrazadoRepository.grupoPorDefecto(trazados), 'Grupo 3');
      expect(TrazadoRepository.gruposDe(trazados), ['Grupo 2']);
    });
  });
}
