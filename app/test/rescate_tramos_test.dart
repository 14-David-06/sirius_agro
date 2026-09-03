import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirius_agro/data/db/app_database.dart';
import 'package:sirius_agro/data/visita_repository.dart';

/// El Dia 3 promete que una grabacion larga sobrevive. Lo que se puede probar
/// sin un telefono es la mitad que importa cuando la promesa falla: que el
/// audio que quedo en disco no se pierda porque la app murio antes de
/// registrarlo.
void main() {
  late AppDatabase db;
  late VisitaRepository repo;
  late Directory carpeta;
  const visitaId = 'v-rescate-1';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = VisitaRepository(db);
    await db.into(db.visitas).insert(
          VisitasCompanion.insert(id: visitaId, inicio: DateTime(2026, 9, 5, 8)),
        );
    carpeta = await Directory.systemTemp.createTemp('visita-');
  });

  tearDown(() async {
    await db.close();
    if (await carpeta.exists()) await carpeta.delete(recursive: true);
  });

  /// Un m4a de mentiras, con el peso que se le pida.
  Future<File> tramo(String nombre, {int bytes = 4096}) async {
    final f = File('${carpeta.path}/$nombre');
    await f.writeAsBytes(List.filled(bytes, 0));
    return f;
  }

  test('sin carpeta no rescata nada y no explota', () async {
    final vacia = Directory('${carpeta.path}/no-existe');
    expect(await repo.rescatarTramosHuerfanos(visitaId, carpeta: vacia), 0);
  });

  test('registra y encola los tramos que nadie habia registrado', () async {
    await tramo('tramo-1.m4a', bytes: 1200000);
    await tramo('tramo-2.m4a', bytes: 800000);

    final rescatados =
        await repo.rescatarTramosHuerfanos(visitaId, carpeta: carpeta);
    expect(rescatados, 2);

    final grabaciones = await repo.grabacionesDeVisita(visitaId);
    expect(grabaciones.map((g) => g.orden), [1, 2]);
    expect(grabaciones.every((g) => g.estado == 'Recuperada'), isTrue);
    expect(grabaciones.map((g) => g.tamanoBytes), [1200000, 800000]);

    // Lo rescatado tiene que quedar en la cola, o se conservo un archivo que
    // nunca va a llegar al servidor.
    final cola = await db.pendientesDeVisita(visitaId);
    expect(cola.length, 2);
    expect(cola.every((i) => i.operacion == 'upload_audio'), isTrue);
    expect(cola.every((i) => i.prioridad == 0), isTrue);
  });

  test('la duracion queda en cero, no inventada', () async {
    await tramo('tramo-1.m4a', bytes: 500000);
    await repo.rescatarTramosHuerfanos(visitaId, carpeta: carpeta);

    // El reloj de la app se perdio con el proceso. Un numero inventado aqui
    // desplazaria todas las citas del tramo, que es peor que no tenerlo.
    expect((await repo.grabacionesDeVisita(visitaId)).single.duracionSeg, 0);
  });

  test('no vuelve a registrar lo que ya estaba en la base', () async {
    final f = await tramo('tramo-1.m4a', bytes: 500000);
    await repo.registrarGrabacion(
      visitaId: visitaId,
      orden: 1,
      archivoPath: f.path,
      inicio: DateTime(2026, 9, 5, 8, 10),
      duracionSeg: 300,
      tamanoBytes: 500000,
    );

    expect(await repo.rescatarTramosHuerfanos(visitaId, carpeta: carpeta), 0);
    expect((await repo.grabacionesDeVisita(visitaId)).length, 1);
  });

  test('continua la numeracion en vez de pisar el tramo existente', () async {
    final ya = await tramo('tramo-1.m4a', bytes: 500000);
    await repo.registrarGrabacion(
      visitaId: visitaId,
      orden: 1,
      archivoPath: ya.path,
      inicio: DateTime(2026, 9, 5, 8, 10),
      tamanoBytes: 500000,
    );
    await tramo('tramo-2.m4a', bytes: 600000);

    expect(await repo.rescatarTramosHuerfanos(visitaId, carpeta: carpeta), 1);
    expect(
      (await repo.grabacionesDeVisita(visitaId)).map((g) => g.orden),
      [1, 2],
    );
  });

  test('descarta y borra los archivos vacios de un microfono cortado',
      () async {
    // Un encabezado sin audio: es lo que deja el sistema cuando le quita el
    // microfono a la app de inmediato. Encolarlo solo produce un fallo de
    // transcripcion mas adelante.
    final basura = await tramo('tramo-1.m4a', bytes: 200);
    await tramo('tramo-2.m4a', bytes: 700000);

    expect(await repo.rescatarTramosHuerfanos(visitaId, carpeta: carpeta), 1);
    expect(await basura.exists(), isFalse);
    expect(
      (await repo.grabacionesDeVisita(visitaId)).single.tamanoBytes,
      700000,
    );
  });

  test('ignora lo que no sea audio', () async {
    await tramo('tramo-1.m4a', bytes: 400000);
    await File('${carpeta.path}/foto-1.jpg')
        .writeAsBytes(List.filled(90000, 0));
    await File('${carpeta.path}/notas.txt').writeAsString('lo que sea');

    expect(await repo.rescatarTramosHuerfanos(visitaId, carpeta: carpeta), 1);
  });

  test('rescatar dos veces no duplica', () async {
    await tramo('tramo-1.m4a', bytes: 400000);

    expect(await repo.rescatarTramosHuerfanos(visitaId, carpeta: carpeta), 1);
    expect(await repo.rescatarTramosHuerfanos(visitaId, carpeta: carpeta), 0);
    expect((await db.pendientesDeVisita(visitaId)).length, 1);
  });

  test('los tramos quedan en orden de nombre, no del sistema de archivos',
      () async {
    for (final n in ['tramo-3.m4a', 'tramo-1.m4a', 'tramo-2.m4a']) {
      await tramo(n, bytes: 300000);
    }
    await repo.rescatarTramosHuerfanos(visitaId, carpeta: carpeta);

    final rutas = (await repo.grabacionesDeVisita(visitaId))
        .map((g) => g.archivoPath.split(Platform.pathSeparator).last)
        .toList();
    expect(rutas, ['tramo-1.m4a', 'tramo-2.m4a', 'tramo-3.m4a']);
  });
}
