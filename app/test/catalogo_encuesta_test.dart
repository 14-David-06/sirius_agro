import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:sirius_agro/core/iconos_modulo.dart';
import 'package:sirius_agro/data/db/app_database.dart';
import 'package:sirius_agro/data/semilla.dart';
import 'package:sirius_agro/data/visita_repository.dart';
import 'package:sirius_agro/ui/visita_page.dart' show tramosPorModulo;

/// Los temas de la encuesta de caracterizacion dentro del catalogo de la visita.
///
/// No son un cuestionario aparte: son temas que se hablan en la visita, y por
/// eso viven en el mismo catalogo que alimenta «Cobertura de la conversacion»
/// y la extraccion desde la grabacion.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late List<Map<String, dynamic>> campos;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await Semilla(db, rootBundle).sembrarSiHaceFalta();
    final json = jsonDecode(File('assets/semilla/catalogo.json').readAsStringSync()) as Map;
    campos = (json['campos'] as List).cast<Map<String, dynamic>>();
  });

  tearDown(() => db.close());

  List<Map<String, dynamic>> deLaEncuesta() => campos.where((c) => c['origen'] == 'encuesta').toList();
  List<Map<String, dynamic>> reactivados() => campos.where((c) => c['origen'] == 'reactivado').toList();
  Iterable<Map<String, dynamic>> originales() => campos.where((c) => c['origen'] == null);

  test('agrega 61 temas y no toca los 55 campos que ya estaban', () {
    expect(deLaEncuesta(), hasLength(61));
    expect(originales(), hasLength(55));
    // Los originales siguen apuntando a su registro de Airtable.
    expect(originales().every((c) => (c['remote_id'] as String?)?.startsWith('rec') ?? false), isTrue);
    // De los originales solo cambia lo que se pidio ajustar, y cada ajuste
    // guarda el valor que tenia en Airtable para poder deshacerlo.
    final ajustados = {for (final c in originales().where((c) => c['valor_airtable'] != null)) c['clave_tecnica']: c};
    expect(ajustados.keys.toSet(), {'municipio_vereda', 'nombre_productor', 'telefono', 'nombre_finca'});
    expect(ajustados['municipio_vereda']!['valor_airtable'], {
      'campo': 'Municipio y vereda',
      'pregunta_guia': 'En que vereda estamos?',
    });
    expect(ajustados['nombre_productor']!['valor_airtable'], {'obligatorio_mvp': true});
    // Los nuevos solo existen en la app.
    expect(deLaEncuesta().every((c) => c['remote_id'] == null), isTrue);
    expect(campos.map((c) => c['clave_tecnica']).toSet(), hasLength(122), reason: 'claves repetidas');
  });

  test('cinco preguntas usan los seis campos que ya existian apagados en Airtable', () {
    expect(
      {for (final c in reactivados()) c['clave_tecnica']: c['pregunta_encuesta']},
      {
        'apoyos_recibidos': 40,
        'tiene_credito': 53,
        'maquinaria': 64,
        'infraestructura': 64,
        'contrata_jornaleros': 66,
        'acceso_vial': 94,
      },
    );
    for (final c in reactivados()) {
      // Son registros de Airtable, no temas que solo viven en la app.
      expect((c['remote_id'] as String).startsWith('rec'), isTrue, reason: '${c['clave_tecnica']}');
      expect(c['activo'], isTrue);
      expect((c['pregunta_guia'] as String).trim(), isNotEmpty);
    }
    // No se creo ademas el tema de la encuesta que diria lo mismo.
    final claves = campos.map((c) => c['clave_tecnica']).toSet();
    for (final repetida in ['ayudas_gobierno', 'credito', 'equipos_finca', 'contrata', 'estado_via']) {
      expect(claves, isNot(contains(repetida)), reason: repetida);
    }
    final numeros = deLaEncuesta().map((c) => c['pregunta_encuesta']).toSet();
    expect(numeros.intersection({40, 53, 64, 66, 94}), isEmpty);
  });

  test('las preguntas que se pidio quitar no estan', () {
    final numeros = deLaEncuesta().map((c) => c['pregunta_encuesta']).toSet();
    for (final quitada in [41, 42, 43, 44, 67, 76, 77, 78, 79, 87]) {
      expect(numeros, isNot(contains(quitada)), reason: 'pregunta $quitada');
    }
    final claves = campos.map((c) => c['clave_tecnica']).toSet();
    for (final clave in ['alim_preocupacion', 'alim_hambre', 'minga', 'ganado_proposito', 'leche_dia', 'vacunacion', 'certificaciones']) {
      expect(claves, isNot(contains(clave)), reason: clave);
    }
  });

  test('no repite lo que el catalogo o la visita ya preguntan', () {
    final numeros = deLaEncuesta().map((c) => c['pregunta_encuesta']).toSet();
    // Nombre, documento, celular, vereda, tamano del hogar, area, tenencia,
    // cultivos, comprador, fuente de agua, senal...
    for (final repetida in [1, 3, 4, 5, 6, 7, 57, 58, 68, 71, 91, 98, 106, 116]) {
      expect(numeros, isNot(contains(repetida)), reason: 'pregunta $repetida');
    }
  });

  test('cada tema nuevo cae en un modulo que ya existia y trae su pregunta', () {
    final modulosOriginales = originales().map((c) => c['modulo']).toSet();
    for (final c in deLaEncuesta()) {
      expect(modulosOriginales, contains(c['modulo']), reason: '${c['clave_tecnica']}');
      expect(iconoDeModulo(c['modulo'] as String), isNot(iconoModuloPorDefecto), reason: '${c['modulo']}');
      expect((c['pregunta_guia'] as String).trim(), isNotEmpty);
      if (c['tipo_dato'] == 'Lista') {
        final opciones = (c['opciones'] as String).split('\n');
        expect(opciones.length, greaterThan(1), reason: '${c['clave_tecnica']}');
        // «No sabe» y «Prefiere no responder» no son valores de un tema.
        expect(opciones, isNot(contains('No sabe')));
        expect(opciones, isNot(contains('Prefiere no responder')));
      }
    }
  });

  test('los temas sensibles no se le sugieren al visitador ni cuentan para la cobertura', () {
    final sensibles = deLaEncuesta().where((c) => c['no_sugerir'] == true).map((c) => c['clave_tecnica']).toSet();
    expect(sensibles, {'p_dificultad', 'campesino', 'etnia', 'victima', 'participacion'});
    for (final c in deLaEncuesta()) {
      expect(c['obligatorio_mvp'], c['no_sugerir'] != true, reason: '${c['clave_tecnica']}');
    }
  });

  test('aparecen en la lista de una visita nueva, por modulo, junto a los de siempre', () async {
    final repo = VisitaRepository(db);
    final vereda = (await db.select(db.veredas).get()).first;
    final id = await repo.crearVisitaConProductor(
      inicio: DateTime(2026, 11, 13, 8),
      nombreProductor: 'Ana Pérez',
      nombreFinca: 'La Esperanza',
      veredaLocalId: vereda.id,
    );

    final lista = await db.faltantesSugeribles(id);
    final claves = lista.map((c) => c.claveTecnica).toSet();

    // De los 26 de antes quedan 23 (Identificacion paso de cuatro preguntas a
    // una); se suman 56 temas nuevos y los 6 que se prendieron.
    expect(lista, hasLength(85));
    expect(claves, containsAll(['fuente_agua', 'tiene_riego', 'que_quiere_mejorar', 'comprador']));
    expect(claves, containsAll(['tenencia_vivienda', 'credito_fuente', 'documento_tierra', 'planes', 'temas_interes']));
    expect(
      claves,
      containsAll(
        ['apoyos_recibidos', 'tiene_credito', 'maquinaria', 'infraestructura', 'contrata_jornaleros', 'acceso_vial'],
      ),
    );
    // Los que se prendieron salen en su modulo de Airtable, con su pregunta.
    final creditos = lista.where((c) => c.modulo == 'Creditos y apoyos').map((c) => c.preguntaGuia).toList();
    expect(creditos, contains('¿Tiene algun credito o deuda con banco?'));
    // Ni los sensibles ni los quitados.
    expect(claves, isNot(contains('etnia')));
    expect(claves, isNot(contains('alim_hambre')));

    final agua = lista.where((c) => c.modulo == 'Agua y riego').map((c) => c.preguntaGuia).toList();
    expect(agua, contains('De donde saca el agua?'));
    expect(agua, contains('¿De dónde sacan principalmente el agua para tomar y cocinar?'));
  });

  test('la lista sigue el orden de la guia conversacional de campo', () async {
    final repo = VisitaRepository(db);
    final vereda = (await db.select(db.veredas).get()).first;
    final id = await repo.crearVisitaConProductor(
      inicio: DateTime(2026, 11, 23, 8),
      nombreProductor: 'Ana Pérez',
      nombreFinca: 'La Esperanza',
      veredaLocalId: vereda.id,
    );

    final claves = (await db.faltantesSugeribles(id)).map((c) => c.claveTecnica).toList();

    // Las 85 de la guia, etapa por etapa y tema por tema, cada una en el
    // lugar de su tabla. Solo cambia el orden: el modulo y la pregunta de
    // cada tema siguen como estaban.
    expect(claves, [
      // Etapa 1 · A. Llegada a la finca
      'municipio_vereda', 'acceso_vial',
      // Etapa 2 · B. Origen y trayectoria
      'municipio_procedencia', 'anios_en_territorio', 'como_inicio_agricultura', 'formacion_agro',
      // Etapa 3 · C. Tierra y tenencia
      'area_total_ha', 'area_produccion_ha', 'uso_tierra', 'tenencia', 'documento_tierra', 'titular_tierra',
      'vive_finca', 'dedicacion',
      // Etapa 3 · D. Cultivos y produccion
      'cultivos_principales', 'c_semilla', 'rendimiento', 'c_destino', 'c_perdida',
      // Etapa 3 · E. Manejo: suelo, agua, insumos y asistencia tecnica
      'problemas_suelo', 'fuente_agua', 'tiene_riego', 'cuidado_agua', 'tumba_monte', 'plagas_enfermedades',
      'fertilizantes_usados', 'plaguicidas_usados', 'usa_bioinsumos', 'proteccion_quimicos', 'envases',
      'asistencia', 'asistencia_quien', 'asistencia_utilidad',
      // Etapa 3 · F. Mano de obra, herramientas e infraestructura
      'contrata_jornaleros', 'maquinaria', 'infraestructura',
      // Etapa 4 · G. Venta de la produccion
      'comprador', 'precio_venta', 'acuerdo_venta', 'transporte', 'dificultades_venta', 'formalizacion',
      // Etapa 4 · H. Economia del hogar, credito y apoyos
      'rentabilidad', 'parte_finca', 'alcanza', 'tiene_credito', 'credito_fuente', 'credito_barreras',
      'productos_financieros', 'apoyos_recibidos',
      // Etapa 5 · I. La familia
      'jefatura', 'decisiones', 'cuidado', 'p_estudios', 'p_lee', 'p_estudia', 'p_ocupacion', 'p_salud',
      'pension', 'sisben', 'autoconsumo',
      // Etapa 5 · J. Vivienda y acceso a servicios
      'tenencia_vivienda', 'paredes', 'pisos', 'sanitario', 'cocina', 'energia', 'agua_consumo', 'basuras',
      'cuartos_dormir', 'tiempos_acceso',
      // Etapa 5 · K. Comunicaciones y conectividad
      'operador', 'calidad_senal', 'internet', 'aparatos', 'uso_internet', 'manejo_digital', 'usos_celular',
      // Etapa 6 · L. Riesgos, aspiraciones y acompanamiento
      'riesgo_principal', 'que_quiere_mejorar', 'planes', 'necesidades', 'interes_asociarse', 'temas_interes',
      'forma_acompanamiento',
    ]);

    // Lo que no se sugiere no lleva orden y va al final de los obligatorios.
    final obligatorios = await db.obligatoriosActivos();
    expect(obligatorios.last.claveTecnica, 'motivo_llegada');
    expect(obligatorios.last.orden, isNull);
  });

  test('los titulos de modulo de la lista no la desordenan', () async {
    final lista = (await db.obligatoriosActivos()).where((c) => !c.noSugerir).toList();
    final tramos = tramosPorModulo(lista);

    // Se lee igual que la lista: mismo orden, ningun tema movido de lugar.
    expect([for (final t in tramos) ...t.value], lista);
    for (var i = 1; i < tramos.length; i++) {
      expect(tramos[i].key, isNot(tramos[i - 1].key), reason: 'dos titulos seguidos de ${tramos[i].key}');
    }
    // El agua de la finca se habla en el recorrido y la de tomar en la casa:
    // el modulo sale dos veces en vez de juntarlas.
    expect(tramos.where((t) => t.key == 'Agua y riego').map((t) => t.value.map((c) => c.claveTecnica).toList()), [
      ['fuente_agua', 'tiene_riego', 'cuidado_agua'],
      ['agua_consumo'],
    ]);
    expect(tramos.first.key, 'Identificacion');
    expect(tramos.last.key, 'Aspiraciones y proyectos');
  });

  test('el orden del catalogo es 1..85, uno por tema que se sugiere', () {
    final sugeridos = campos.where(
      (c) => (c['activo'] ?? true) == true && c['obligatorio_mvp'] == true && c['no_sugerir'] != true,
    );
    expect(sugeridos.map((c) => c['orden']).toList()..sort(), List.generate(85, (i) => i + 1));
    final sinSugerir = campos.where((c) => !sugeridos.contains(c));
    expect(sinSugerir.where((c) => c['orden'] != null), isEmpty);
  });

  test('la extraccion recibe los temas nuevos con sus opciones', () async {
    final activos = await db.camposActivos();
    final jefatura = activos.firstWhere((c) => c.claveTecnica == 'jefatura');
    expect(jefatura.tipoDato, 'Lista');
    expect(jefatura.opciones!.split('\n'), contains('Comparten la jefatura en pareja'));
    expect(activos.firstWhere((c) => c.claveTecnica == 'cuartos_dormir').tipoDato, 'Numero');
    expect(activos.firstWhere((c) => c.claveTecnica == 'tumba_monte').tipoDato, 'Si/No');
    // Lo de cada persona del hogar va como texto: no es una sola opcion, ni
    // un solo «si» o «no» que no dice de quien se habla.
    expect(activos.firstWhere((c) => c.claveTecnica == 'p_estudios').tipoDato, 'Texto');
    expect(activos.firstWhere((c) => c.claveTecnica == 'p_estudia').tipoDato, 'Texto');
  });
}
