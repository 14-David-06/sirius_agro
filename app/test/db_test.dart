import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirius_agro/data/db/app_database.dart';
import 'package:sirius_agro/data/visita_repository.dart';

/// Catalogo minimo que imita el real: 4 obligatorios activos, 1 obligatorio
/// apagado (no debe contar) y 1 activo no obligatorio (tampoco).
final _catalogo = <CatalogoCamposCompanion>[
  CatalogoCamposCompanion.insert(
    claveTecnica: 'nombre_productor',
    campo: 'Nombre del productor',
    modulo: 'Identificacion',
    preguntaGuia: const Value('¿Con quien tengo el gusto?'),
    obligatorioMvp: const Value(true),
  ),
  CatalogoCamposCompanion.insert(
    claveTecnica: 'area_total_ha',
    campo: 'Area total de la finca',
    modulo: 'Tierra y tenencia',
    preguntaGuia: const Value('¿De que tamano es la finca?'),
    obligatorioMvp: const Value(true),
  ),
  CatalogoCamposCompanion.insert(
    claveTecnica: 'fertilizantes_usados',
    campo: 'Fertilizantes que usa',
    modulo: 'Insumos y manejo',
    preguntaGuia: const Value('¿Que le esta aplicando al cultivo?'),
    obligatorioMvp: const Value(true),
  ),
  CatalogoCamposCompanion.insert(
    claveTecnica: 'anios_experiencia',
    campo: 'Anios trabajando la tierra',
    modulo: 'Identificacion',
    preguntaGuia: const Value('¿Hace cuanto trabaja en el campo?'),
    obligatorioMvp: const Value(true),
  ),
  // Obligatorio pero apagado: no puede entrar en el denominador.
  CatalogoCamposCompanion.insert(
    claveTecnica: 'costo_jornal',
    campo: 'Costo del jornal',
    modulo: 'Mano de obra',
    obligatorioMvp: const Value(true),
    activo: const Value(false),
  ),
  // Activo pero opcional: tampoco.
  CatalogoCamposCompanion.insert(
    claveTecnica: 'area_por_cultivo',
    campo: 'Area por cultivo',
    modulo: 'Cultivos',
  ),
];

void main() {
  late AppDatabase db;
  const visitaId = 'a1b2c3d4-0000-4000-8000-000000000001';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.guardarCatalogo(_catalogo);
    await db.into(db.visitas).insert(
          VisitasCompanion.insert(id: visitaId, inicio: DateTime(2026, 9, 3, 9)),
        );
  });

  tearDown(() => db.close());

  Future<Certeza> insertar({
    required String clave,
    required Certeza certeza,
    Hablante? hablante,
    String? cita = 'una frase que respalda el dato',
    String? razonamiento,
    FuenteHallazgo fuente = FuenteHallazgo.audio,
    String? entidadLocalId,
    double? valorNumerico,
  }) =>
      db.insertarHallazgo(
        HallazgosCompanion.insert(
          id: '$clave-${entidadLocalId ?? 'x'}-${certeza.name}',
          visitaId: visitaId,
          claveTecnica: clave,
          certeza: Value(certeza),
          hablante: Value(hablante),
          citaTextual: Value(cita),
          razonamiento: Value(razonamiento),
          fuente: Value(fuente),
          entidadLocalId: Value(entidadLocalId),
          valorNumerico: Value(valorNumerico),
          creadoEn: DateTime(2026, 9, 3, 9, 30),
        ),
      );

  group('reglas duras de procedencia', () {
    test('lo que dice el visitador nunca queda Confirmado', () async {
      final quedo = await insertar(
        clave: 'area_total_ha',
        certeza: Certeza.confirmado,
        hablante: Hablante.visitador,
      );
      expect(quedo, Certeza.estimado);
    });

    test('el agricultor si puede quedar Confirmado', () async {
      final quedo = await insertar(
        clave: 'area_total_ha',
        certeza: Certeza.confirmado,
        hablante: Hablante.agricultor,
      );
      expect(quedo, Certeza.confirmado);
    });

    test('sin cita textual baja a Pendiente aunque el modelo diga Confirmado',
        () async {
      final quedo = await insertar(
        clave: 'nombre_productor',
        certeza: Certeza.confirmado,
        hablante: Hablante.agricultor,
        cita: '   ',
      );
      expect(quedo, Certeza.pendiente);
    });

    test('Inferido sin razonamiento baja a Pendiente', () async {
      final quedo = await insertar(
        clave: 'nombre_productor',
        certeza: Certeza.inferido,
        hablante: Hablante.agricultor,
      );
      expect(quedo, Certeza.pendiente);
    });

    test('Inferido con razonamiento se respeta', () async {
      final quedo = await insertar(
        clave: 'nombre_productor',
        certeza: Certeza.inferido,
        hablante: Hablante.agricultor,
        razonamiento: 'Dijo que sembro cuando nacio el hijo, que tiene 20.',
      );
      expect(quedo, Certeza.inferido);
    });

    test('el GPS no necesita cita: nadie lo dijo en voz alta', () async {
      final quedo = await insertar(
        clave: 'nombre_productor',
        certeza: Certeza.confirmado,
        cita: null,
        fuente: FuenteHallazgo.gps,
      );
      expect(quedo, Certeza.confirmado);
    });

    test('No legible se respeta y no se confunde con Pendiente', () async {
      final quedo = await insertar(
        clave: 'fertilizantes_usados',
        certeza: Certeza.noLegible,
        cita: null,
        fuente: FuenteHallazgo.ocrEtiqueta,
      );
      expect(quedo, Certeza.noLegible);
    });
  });

  group('completitud offline', () {
    test('visita vacia es 0%, no 100%', () async {
      expect(await db.calcularCompletitud(visitaId), 0);
    });

    test('cuenta sobre los obligatorios ACTIVOS, no sobre todos', () async {
      // 4 obligatorios activos en el catalogo de prueba.
      expect((await db.obligatoriosActivos()).length, 4);

      await insertar(
        clave: 'nombre_productor',
        certeza: Certeza.confirmado,
        hablante: Hablante.agricultor,
      );
      expect(await db.calcularCompletitud(visitaId), 25);
    });

    test('un hallazgo Pendiente no cuenta como resuelto', () async {
      await insertar(
        clave: 'area_total_ha',
        certeza: Certeza.confirmado,
        hablante: Hablante.agricultor,
        cita: null, // la regla 2 lo baja a Pendiente
      );
      expect(await db.calcularCompletitud(visitaId), 0);
    });

    test('un campo No legible no cuenta como resuelto', () async {
      await insertar(
        clave: 'fertilizantes_usados',
        certeza: Certeza.noLegible,
        cita: null,
        fuente: FuenteHallazgo.ocrEtiqueta,
      );
      expect(await db.calcularCompletitud(visitaId), 0);
    });

    test('Estimado si cuenta: un aproximado es un dato', () async {
      await insertar(
        clave: 'area_total_ha',
        certeza: Certeza.estimado,
        hablante: Hablante.agricultor,
      );
      expect(await db.calcularCompletitud(visitaId), 25);
    });

    test('los faltantes vienen con su pregunta guia textual', () async {
      await insertar(
        clave: 'nombre_productor',
        certeza: Certeza.confirmado,
        hablante: Hablante.agricultor,
      );
      final faltan = await db.faltantes(visitaId);

      // Agrupados por modulo y luego por campo: asi es como los lee el
      // visitador en la pantalla de faltantes, no en orden de insercion.
      expect(faltan.map((c) => c.claveTecnica), [
        'anios_experiencia', // Identificacion
        'fertilizantes_usados', // Insumos y manejo
        'area_total_ha', // Tierra y tenencia
      ]);
      expect(
        faltan.firstWhere((c) => c.claveTecnica == 'area_total_ha').preguntaGuia,
        '¿De que tamano es la finca?',
      );
    });

    test('refrescarCompletitud persiste el porcentaje en la visita', () async {
      await insertar(
        clave: 'nombre_productor',
        certeza: Certeza.confirmado,
        hablante: Hablante.agricultor,
      );
      await db.refrescarCompletitud(visitaId);

      final visita = await (db.select(db.visitas)
            ..where((v) => v.id.equals(visitaId)))
          .getSingle();
      expect(visita.completitudPct, 25);
    });
  });

  group('varios cultivos en una visita', () {
    test('tres areas distintas conviven sin pisarse', () async {
      for (final (i, area) in [4.0, 2.5, 1.0].indexed) {
        await insertar(
          clave: 'area_por_cultivo',
          certeza: Certeza.estimado,
          hablante: Hablante.agricultor,
          entidadLocalId: 'cultivo_${i + 1}',
          valorNumerico: area,
        );
      }

      final filas = await db.hallazgosDeVisita(visitaId);
      expect(filas.length, 3);
      expect(
        filas.map((h) => h.entidadLocalId).toSet(),
        {'cultivo_1', 'cultivo_2', 'cultivo_3'},
      );
      expect(filas.map((h) => h.valorNumerico).toSet(), {4.0, 2.5, 1.0});
    });
  });

  group('criterio de aceptacion del Dia 1', () {
    test('una visita con 3 cultivos y 20 hallazgos se persiste y se relee',
        () async {
      final repo = VisitaRepository(db);
      final id = await repo.crearVisita(
        inicio: DateTime(2026, 9, 3, 8, 15),
        latitud: 4.5709,
        longitud: -72.9612,
        precisionGps: 8.0,
      );

      await repo.registrarConsentimiento(
        id,
        audio: true,
        fotos: true,
        usoDatos: true,
        segundoDelAudio: 34,
      );
      expect(await repo.puedeGrabar(id), isTrue);

      await repo.registrarGrabacion(
        visitaId: id,
        orden: 1,
        archivoPath: '/data/visitas/\$id/tramo-1.m4a',
        inicio: DateTime(2026, 9, 3, 8, 16),
        duracionSeg: 1800,
        tamanoBytes: 7340032,
      );

      // 4 obligatorios + 3 cultivos + relleno hasta 20 hallazgos.
      final extraidos = <HallazgoExtraido>[
        const HallazgoExtraido(
          claveTecnica: 'nombre_productor',
          entidadDestino: EntidadDestino.productor,
          valorTexto: 'Pedro Rodriguez',
          certeza: Certeza.confirmado,
          hablante: Hablante.agricultor,
          citaTextual: 'yo soy Pedro Rodriguez, mucho gusto',
          segundoAudio: 41,
        ),
        const HallazgoExtraido(
          claveTecnica: 'area_total_ha',
          entidadDestino: EntidadDestino.finca,
          valorNumerico: 12,
          unidad: 'ha',
          certeza: Certeza.estimado,
          hablante: Hablante.agricultor,
          citaTextual: 'seran unas doce hectareas',
          segundoAudio: 120,
        ),
        // El visitador dice el dato: la regla 1 lo baja a Estimado.
        const HallazgoExtraido(
          claveTecnica: 'fertilizantes_usados',
          entidadDestino: EntidadDestino.insumo,
          valorTexto: 'DAP',
          certeza: Certeza.confirmado,
          hablante: Hablante.visitador,
          citaTextual: 'usted usa DAP, cierto?',
          segundoAudio: 300,
        ),
        // Inferido con razonamiento: se respeta.
        const HallazgoExtraido(
          claveTecnica: 'anios_experiencia',
          entidadDestino: EntidadDestino.productor,
          valorNumerico: 20,
          certeza: Certeza.inferido,
          hablante: Hablante.agricultor,
          citaTextual: 'desde que nacio el mayor',
          razonamiento: 'El hijo mayor tiene 20 anios segun el minuto 4:10.',
          segundoAudio: 250,
        ),
        for (final (i, area) in [4.0, 2.5, 1.0].indexed)
          HallazgoExtraido(
            claveTecnica: 'area_por_cultivo',
            entidadDestino: EntidadDestino.cultivo,
            entidadLocalId: 'cultivo_\${i + 1}',
            valorNumerico: area,
            unidad: 'ha',
            certeza: Certeza.estimado,
            hablante: Hablante.agricultor,
            citaTextual: 'como \$area hectareas',
            segundoAudio: 400 + i * 20,
          ),
        for (var i = 0; i < 13; i++)
          HallazgoExtraido(
            claveTecnica: 'area_por_cultivo',
            entidadDestino: EntidadDestino.cultivo,
            entidadLocalId: 'relleno_\$i',
            valorNumerico: i.toDouble(),
            certeza: Certeza.estimado,
            hablante: Hablante.agricultor,
            citaTextual: 'dato de relleno \$i',
            segundoAudio: 600 + i,
          ),
      ];
      expect(extraidos.length, 20);

      final pct = await repo.guardarExtraccion(
        visitaId: id,
        extraidos: extraidos,
        temasPendientes: ['No quedo claro a quien le vende'],
      );

      // 4 de 4 obligatorios resueltos: el que dijo el visitador quedo
      // Estimado, no descartado, asi que sigue contando como dato.
      expect(pct, 100);

      await repo.encolarVisita(id);

      // Se relee todo desde la base, como si la app se hubiera reiniciado.
      final filas = await db.hallazgosDeVisita(id);
      expect(filas.length, 20);
      expect(
        filas
            .where((h) => h.entidadLocalId?.startsWith('cultivo_') ?? false)
            .map((h) => h.valorNumerico)
            .toSet(),
        {4.0, 2.5, 1.0},
      );

      final fert =
          filas.firstWhere((h) => h.claveTecnica == 'fertilizantes_usados');
      expect(fert.certeza, Certeza.estimado);
      expect(fert.hablante, Hablante.visitador);

      final exp =
          filas.firstWhere((h) => h.claveTecnica == 'anios_experiencia');
      expect(exp.certeza, Certeza.inferido);
      expect(exp.razonamiento, contains('20 anios'));

      final visita = (await repo.visitas()).firstWhere((v) => v.id == id);
      expect(visita.completitudPct, 100);
      expect(visita.consienteAudio, isTrue);
      expect(visita.segundoConsentimiento, 34);
      expect(visita.temasPendientes, 'No quedo claro a quien le vende');

      // Audio primero, visita despues: el orden de la cola importa.
      final cola = await db.pendientesDeVisita(id);
      expect(cola.length, 2);
      expect((await db.proximosItems()).first.operacion, 'upload_audio');
    });
  });

  group('cola de sincronizacion', () {
    test('el retroceso exponencial crece y topa en una hora', () {
      expect(AppDatabase.esperaTrasFallo(1), const Duration(seconds: 2));
      expect(AppDatabase.esperaTrasFallo(3), const Duration(seconds: 8));
      expect(AppDatabase.esperaTrasFallo(99), const Duration(hours: 1));
    });

    test('un item que acaba de fallar no se vuelve a tomar de inmediato',
        () async {
      await db.encolar(
        id: 'q1',
        entidad: 'grabacion',
        entidadId: visitaId,
        operacion: 'upload_audio',
        bytesTotales: 7 * 1024 * 1024,
        prioridad: 0,
      );
      expect((await db.proximosItems()).length, 1);

      await db.marcarFallo('q1', 'SocketException: sin red');
      expect(await db.proximosItems(), isEmpty);
    });

    test('el audio se sube antes que las fotos', () async {
      await db.encolar(
        id: 'foto',
        entidad: 'evidencia',
        entidadId: visitaId,
        operacion: 'upload_foto',
        prioridad: 200,
      );
      await db.encolar(
        id: 'audio',
        entidad: 'grabacion',
        entidadId: visitaId,
        operacion: 'upload_audio',
        prioridad: 0,
      );

      final orden = (await db.proximosItems()).map((i) => i.id).toList();
      expect(orden, ['audio', 'foto']);
    });

    test('el avance parcial de una subida sobrevive para poder retomar',
        () async {
      await db.encolar(
        id: 'audio',
        entidad: 'grabacion',
        entidadId: visitaId,
        operacion: 'upload_audio',
        bytesTotales: 7340032,
      );
      await db.registrarAvance('audio', 3 * 512 * 1024);

      final item = (await db.pendientesDeVisita(visitaId)).single;
      expect(item.bytesSubidos, 1572864);
      expect(item.bytesTotales, 7340032);
    });
  });
}
