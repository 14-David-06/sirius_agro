import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sirius_agro/core/teselas.dart';
import 'package:sirius_agro/data/db/app_database.dart';
import 'package:sirius_agro/data/mapa_sin_senal.dart';
import 'package:sirius_agro/state/mapa_sin_senal.dart';
import 'package:sirius_agro/ui/proveedor_satelite.dart';

/// Bytes que hacen de tesela. El almacen y la busqueda no los decodifican,
/// asi que no hace falta que sean una imagen de verdad.
Uint8List _bytes(String marca) => Uint8List.fromList(marca.codeUnits);

http.Response _imagen(String marca) => http.Response.bytes(
      _bytes(marca),
      200,
      headers: {'content-type': 'image/jpeg'},
    );

void main() {
  group('teselas', () {
    test('ubica Barranca de Upia en las mismas teselas que pide Esri', () {
      // Medidas a mano contra el servidor (noviembre de 2026).
      expect(teselaDe(4.567, -72.967, 17), const Tesela(17, 38969, 63871));
      expect(teselaDe(4.567, -72.967, 19), const Tesela(19, 155878, 255485));
    });

    test('la madre de una tesela y la casilla que le toca', () {
      final a = const Tesela(18, 77939, 127742).ancestro(2);
      expect(a.madre, const Tesela(16, 19484, 31935));
      expect(a.columna, 3);
      expect(a.fila, 2);
      // La madre de la madre es la abuela.
      expect(
        const Tesela(18, 77939, 127742).ancestro(3).madre,
        a.madre.ancestro(1).madre,
      );
    });

    test('la base del municipio son las ~4.400 teselas que se midieron', () {
      expect(
        zonaBarrancaDeUpia.contar(zoomMinimoBase, zoomMaximoBase),
        2 + 6 + 20 + 63 + 216 + 828 + 3266,
      );
      expect(
        zonaBarrancaDeUpia.teselas(zoomMinimoBase, zoomMaximoBase).length,
        zonaBarrancaDeUpia.contar(zoomMinimoBase, zoomMaximoBase),
      );
    });

    test('una caja alrededor de un punto lo contiene', () {
      final c = Caja.alrededor(4.567, -72.967, 700);
      expect(c.sur, lessThan(4.567));
      expect(c.norte, greaterThan(4.567));
      expect(c.oeste, lessThan(-72.967));
      expect(c.este, greaterThan(-72.967));
      // 700 m son ~0,0063 grados de latitud.
      expect(c.norte - c.sur, closeTo(2 * 700 / 111320, 1e-9));
    });
  });

  group('plan de descarga', () {
    const finca = (latitud: 4.50, longitud: -72.95);

    test('primero lo general, luego las fincas, al final el z16 del municipio',
        () {
      final plan = planDescarga(zonaBase: zonaBarrancaDeUpia, puntos: [finca]);

      expect(plan.first.z, zoomMinimoBase);
      expect(plan.last.z, zoomMaximoBase);
      final primerDetalle = plan.indexWhere((t) => t.z == zoomMaximoDetalle);
      final primerZ16Base = plan.length -
          zonaBarrancaDeUpia.contar(zoomMaximoBase, zoomMaximoBase);
      expect(primerDetalle, lessThan(primerZ16Base));
      // El punto queda cubierto con el maximo detalle.
      expect(plan, contains(teselaDe(finca.latitud, finca.longitud, 18)));
    });

    test('no repite teselas, ni por visitas a la misma finca', () {
      final una = planDescarga(zonaBase: zonaBarrancaDeUpia, puntos: [finca]);
      final tres = planDescarga(
        zonaBase: zonaBarrancaDeUpia,
        puntos: [
          finca,
          finca,
          (latitud: finca.latitud + 0.0001, longitud: finca.longitud),
        ],
      );
      expect(tres.toSet().length, tres.length);
      expect(tres.length, una.length);
    });

    test('el detalle de una finca cuesta unas pocas centenas de teselas', () {
      final sin = planDescarga(zonaBase: zonaBarrancaDeUpia, puntos: const []);
      final con = planDescarga(zonaBase: zonaBarrancaDeUpia, puntos: [finca]);
      expect(con.length - sin.length, inInclusiveRange(100, 300));
    });
  });

  group('buscar la imagen de una tesela', () {
    late Directory dir;
    late AlmacenTeselas almacen;
    const t = Tesela(18, 77939, 127742);

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('mapas_test');
      almacen = AlmacenTeselas(dir);
    });

    tearDown(() => dir.delete(recursive: true));

    test('lo guardado se muestra sin preguntarle al servidor', () async {
      await almacen.guardar(t, _bytes('guardada'));
      var llamadas = 0;
      final servidor = ServidorSatelite(
        client: MockClient((_) async {
          llamadas++;
          return _imagen('red');
        }),
      );

      final r = await buscarImagen(t,
          almacen: almacen, servidor: servidor, intentarRed: true);

      expect(String.fromCharCodes(r!.bytes), 'guardada');
      expect(r.niveles, 0);
      expect(llamadas, 0);
    });

    test('con senal baja la tesela y la deja guardada para despues', () async {
      final servidor = ServidorSatelite(
        client: MockClient((req) async {
          expect(req.url.queryParameters['blankTile'], 'false');
          expect(req.url.path, endsWith('/tile/18/127742/77939'));
          return _imagen('red');
        }),
      );

      final r = await buscarImagen(t,
          almacen: almacen, servidor: servidor, intentarRed: true);

      expect(String.fromCharCodes(r!.bytes), 'red');
      expect(await almacen.tiene(t), isTrue);
    });

    test('sin senal estira la madre guardada mas cercana', () async {
      await almacen.guardar(t.ancestro(4).madre, _bytes('abuela lejana'));
      await almacen.guardar(t.ancestro(2).madre, _bytes('abuela'));
      final servidor = ServidorSatelite(
        client: MockClient((_) async => fail('sin senal no se pregunta')),
      );

      final r = await buscarImagen(t,
          almacen: almacen, servidor: servidor, intentarRed: false);

      expect(String.fromCharCodes(r!.bytes), 'abuela');
      expect(r.niveles, 2);
      expect((r.columna, r.fila), (3, 2));
    });

    test('si Esri no tiene imagen (404) estira, y no guarda nada', () async {
      await almacen.guardar(t.ancestro(1).madre, _bytes('madre'));
      final servidor = ServidorSatelite(
        client: MockClient((_) async => http.Response('', 404)),
      );

      final r = await buscarImagen(t,
          almacen: almacen, servidor: servidor, intentarRed: true);

      expect(r!.niveles, 1);
      expect(await almacen.tiene(t), isFalse);
    });

    test('una falla de red no deja la tesela en blanco si hay madre', () async {
      await almacen.guardar(t.ancestro(3).madre, _bytes('bisabuela'));
      final servidor = ServidorSatelite(
        client: MockClient((_) async => throw http.ClientException('sin red')),
      );

      final r = await buscarImagen(t,
          almacen: almacen, servidor: servidor, intentarRed: true);

      expect(r!.niveles, 3);
    });

    test('sin nada guardado ni senal no inventa', () async {
      final servidor = ServidorSatelite(
        client: MockClient((_) async => throw http.ClientException('sin red')),
      );
      expect(
        await buscarImagen(t,
            almacen: almacen, servidor: servidor, intentarRed: true),
        isNull,
      );
    });

    test('una pagina de error con 200 no se guarda como si fuera terreno',
        () async {
      final servidor = ServidorSatelite(
        client: MockClient((_) async => http.Response(
              '<html>portal del wifi</html>',
              200,
              headers: {'content-type': 'text/html'},
            )),
      );

      final r = await buscarImagen(t,
          almacen: almacen, servidor: servidor, intentarRed: true);

      expect(r, isNull);
      expect(await almacen.tiene(t), isFalse);
    });
  });

  group('descarga', () {
    late Directory dir;
    late AlmacenTeselas almacen;
    final teselas = [for (var y = 0; y < 10; y++) Tesela(16, 1, y)];

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('mapas_test');
      almacen = AlmacenTeselas(dir);
    });

    tearDown(() => dir.delete(recursive: true));

    test('se salta lo que ya esta y cuenta lo que Esri no tiene', () async {
      await almacen.guardar(teselas[0], _bytes('ya'));
      final pedidas = <String>[];
      final servidor = ServidorSatelite(
        client: MockClient((req) async {
          pedidas.add(req.url.path);
          return req.url.path.endsWith('/9/1') // fila 9, columna 1
              ? http.Response('', 404)
              : _imagen('ok');
        }),
      );

      final r = await descargarTeselas(teselas,
          almacen: almacen, servidor: servidor);

      expect(r.yaEstaban, 1);
      expect(r.sinImagen, 1);
      expect(r.bajadas, 8);
      expect(r.cortada, isFalse);
      expect(pedidas, hasLength(9));
      expect((await almacen.medir()).teselas, 9);
    });

    test('si se va la conexion para en vez de recorrer todo', () async {
      var pedidas = 0;
      final servidor = ServidorSatelite(
        client: MockClient((_) async {
          pedidas++;
          throw http.ClientException('sin red');
        }),
      );

      final r = await descargarTeselas(
        [for (var y = 0; y < 500; y++) Tesela(16, 2, y)],
        almacen: almacen,
        servidor: servidor,
        fallasParaCortar: 5,
      );

      expect(r.cortada, isTrue);
      expect(pedidas, lessThan(20));
    });

    test('se puede cancelar', () async {
      var pedidas = 0;
      final servidor = ServidorSatelite(
        client: MockClient((_) async {
          pedidas++;
          return _imagen('ok');
        }),
      );

      final r = await descargarTeselas(
        teselas,
        almacen: almacen,
        servidor: servidor,
        cancelada: () => pedidas >= 3,
        simultaneas: 1,
      );

      expect(r.cortada, isTrue);
      expect(r.bajadas, 3);
    });
  });

  group('puntos conocidos', () {
    test('fincas y llegadas de visitas, sin nulos ni el (0, 0) del GPS',
        () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await db.into(db.productores).insert(
            ProductoresCompanion.insert(id: 'p1', nombreCompleto: 'Ana'),
          );
      await db.into(db.fincas).insert(FincasCompanion.insert(
            id: 'f1',
            productorLocalId: 'p1',
            nombre: 'La Esperanza',
            latitud: const Value(4.50),
            longitud: const Value(-72.95),
          ));
      await db.into(db.fincas).insert(FincasCompanion.insert(
            id: 'f2',
            productorLocalId: 'p1',
            nombre: 'Sin coordenada',
          ));
      await db.into(db.visitas).insert(VisitasCompanion.insert(
            id: 'v1',
            inicio: DateTime(2026, 11, 23),
            latitud: const Value(4.60),
            longitud: const Value(-72.90),
          ));
      await db.into(db.visitas).insert(VisitasCompanion.insert(
            id: 'v2',
            inicio: DateTime(2026, 11, 23),
            latitud: const Value(0),
            longitud: const Value(0),
          ));

      final mapa = MapaSinSenal(
        db,
        ServidorSatelite(client: MockClient((_) async => _imagen('x'))),
        Future.value(AlmacenTeselas(Directory.systemTemp)),
      );
      addTearDown(mapa.dispose);

      final puntos = await mapa.puntosConocidos();
      expect(puntos, [
        (latitud: 4.50, longitud: -72.95),
        (latitud: 4.60, longitud: -72.90),
      ]);
    });
  });

  testWidgets('estirar recorta la casilla de la madre que le toca',
      (tester) async {
    await tester.runAsync(() async {
      // Una madre de 256 px con cuatro cuadrantes de colores distintos.
      const colores = [
        [Color(0xFFFF0000), Color(0xFF00FF00)], // arriba: rojo, verde
        [Color(0xFF0000FF), Color(0xFFFFFF00)], // abajo: azul, amarillo
      ];
      final grabadora = ui.PictureRecorder();
      final lienzo = Canvas(grabadora);
      for (var fila = 0; fila < 2; fila++) {
        for (var col = 0; col < 2; col++) {
          lienzo.drawRect(
            Rect.fromLTWH(col * 128.0, fila * 128.0, 128, 128),
            Paint()..color = colores[fila][col],
          );
        }
      }
      final madre = await grabadora.endRecording().toImage(256, 256);
      final png = await madre.toByteData(format: ui.ImageByteFormat.png);
      madre.dispose();

      Future<ui.Codec> decode(ui.ImmutableBuffer buffer,
              {ui.TargetImageSizeCallback? getTargetSize}) =>
          ui.instantiateImageCodecFromBuffer(buffer);

      // Casilla de arriba a la derecha (columna 1, fila 0): toda verde.
      final codec = await estirar(
        (
          bytes: Uint8List.sublistView(png!),
          niveles: 1,
          columna: 1,
          fila: 0,
        ),
        decode,
      );
      final hija = (await codec.getNextFrame()).image;
      expect((hija.width, hija.height), (256, 256));

      final pixeles =
          (await hija.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      Color pixel(int x, int y) {
        final i = (y * 256 + x) * 4;
        return Color.fromARGB(
          pixeles.getUint8(i + 3),
          pixeles.getUint8(i),
          pixeles.getUint8(i + 1),
          pixeles.getUint8(i + 2),
        );
      }

      // El centro y las esquinas, lejos del borde donde el filtro mezcla.
      for (final (x, y) in [(128, 128), (20, 20), (236, 236), (20, 236)]) {
        expect(pixel(x, y), const Color(0xFF00FF00), reason: 'pixel ($x, $y)');
      }
      hija.dispose();
    });
  });
}
