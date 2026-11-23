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
}
