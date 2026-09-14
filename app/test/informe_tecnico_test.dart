import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sirius_agro/core/informe_tecnico.dart';

/// El informe tecnico: el documento de la empresa.
///
/// Lo que se protege aca es la aritmetica y el formato de las coordenadas, que
/// es lo unico del documento que puede estar mal sin que se vea mal. Un area
/// equivocada en un PDF impecable es peor que un PDF feo.
void main() {
  setUpAll(() => initializeDateFormatting('es'));

  group('coordenadas', () {
    test('el decimal lleva seis cifras, coma y hemisferio', () {
      // Seis decimales son ~11 cm. Mas alla de eso se escribiria ruido: el
      // GPS de un telefono anda entre 3 y 10 m.
      expect(
        coordenadaDecimal(4.57321, -72.819044),
        '4,573210° N  ·  72,819044° W',
      );
    });

    test('el sur y el este tambien', () {
      expect(coordenadaDecimal(-4.5, 72.8).contains('S'), isTrue);
      expect(coordenadaDecimal(-4.5, 72.8).contains('E'), isTrue);
    });

    test('el sexagesimal es el de los planos del IGAC', () {
      // Va junto al decimal porque quien compare este informe con una
      // escritura o un plano lo hace en grados, minutos y segundos.
      expect(
        coordenadaSexagesimal(4.573210, -72.819044),
        '4° 34\' 23,6" N  ·  72° 49\' 8,6" W',
      );
    });

    test('la precision se escribe siempre, incluso cuando falta', () {
      // Una coordenada sin su radio de error invita a creerle mas de lo que
      // merece.
      expect(precision(6.4), '± 6 m');
      expect(precision(null), 'sin dato');
    });
  });

  group('areas y perimetros', () {
    // Un cuadrado de ~100 m de lado en Barranca de Upia. 0,0009 grados de
    // latitud son ~100 m.
    final cuadrado = [
      _punto(1, 4.5000, -72.8000),
      _punto(2, 4.5009, -72.8000),
      _punto(3, 4.5009, -72.7991),
      _punto(4, 4.5000, -72.7991),
    ];

    test('el poligono cerrado tiene area, y es la de la geometria', () {
      final t = _trazado(puntos: cuadrado);
      // ~1 ha. Se acepta un margen porque el grado de longitud se achata con
      // la latitud y el cuadrado no es exacto.
      expect(t.areaCalculadaM2, closeTo(10000, 700));
      expect(t.perimetroCalculadoM, closeTo(400, 20));
    });

    test('el poligono sin cerrar NO tiene area', () {
      // Un anillo que nadie cerro no es un lote: es un recorrido a medias, y
      // darle area seria inventarle superficie al predio.
      final t = _trazado(puntos: cuadrado, cerrado: false);
      expect(t.areaCalculadaM2, 0);
    });

    test('una ruta no tiene area, pero si largo', () {
      final t = _trazado(puntos: cuadrado, tipo: 'Ruta');
      expect(t.areaCalculadaM2, 0);
      expect(t.perimetroCalculadoM, greaterThan(0));
    });

    test('la geometria manda sobre la columna guardada', () {
      // La fila guarda el area para que la lista no recorra los puntos. Si los
      // dos numeros no coinciden, el documento que se archiva usa el que se
      // puede auditar: el de los vertices caminados.
      final t = _trazado(puntos: cuadrado, areaM2: 999999);
      expect(t.areaCalculadaM2, closeTo(10000, 700));
    });

    test('el area total suma solo los poligonos cerrados', () {
      final d = _datos(
        trazados: [
          _trazado(puntos: cuadrado),
          _trazado(puntos: cuadrado, tipo: 'Ruta'),
          _trazado(puntos: cuadrado, cerrado: false),
        ],
      );
      expect(d.areaMedidaM2, closeTo(10000, 700));
      expect(d.puntosGpsTotales, 12);
    });

    test('la precision promedio y la peor salen de los vertices', () {
      final t = _trazado(
        puntos: [
          _punto(1, 4.5, -72.8, precision: 4),
          _punto(2, 4.5009, -72.8, precision: 12),
          _punto(3, 4.5009, -72.7991),
        ],
      );
      expect(t.precisionPromedioM, 8);
      expect(t.precisionPeorM, 12);
    });

    test('sin precision reportada no se inventa un promedio', () {
      final t = _trazado(puntos: [_punto(1, 4.5, -72.8)]);
      expect(t.precisionPromedioM, isNull);
    });
  });

  group('hallazgos', () {
    test('la correccion del visitador manda sobre lo que extrajo el modelo',
        () {
      final h = _hallazgo(valor: '3', valorCorregido: '5', unidad: 'ha');
      expect(h.valorVigente, '5');
      expect(h.valorConUnidad, '5 ha');
    });

    test('los pendientes NO se filtran, al contrario del informe del productor',
        () {
      // Alla un pendiente presentado como dato seria mentirle al agricultor.
      // Aca es informacion de gestion: dice que falta preguntar.
      final d = _datos(
        hallazgos: [
          _hallazgo(certeza: 'Confirmado'),
          _hallazgo(certeza: 'Pendiente'),
        ],
      );
      expect(d.hallazgos.length, 2);
      expect(d.conteoPorCerteza['Pendiente'], 1);
    });

    test('se agrupan por modulo, en orden alfabetico', () {
      final d = _datos(
        hallazgos: [
          _hallazgo(modulo: 'Suelos'),
          _hallazgo(modulo: 'Agua'),
          _hallazgo(modulo: 'Agua'),
        ],
      );
      expect(d.porModulo.keys.toList(), ['Agua', 'Suelos']);
      expect(d.porModulo['Agua']!.length, 2);
    });
  });

  group('el markdown que se archiva en Airtable', () {
    test('trae las diez secciones numeradas', () {
      final md = markdownInformeTecnico(_datos());
      for (final seccion in [
        '## 1. Identificacion de la visita',
        '## 2. Productor y predio',
        '## 3. Georreferenciacion',
        '## 4. Lotes y recorridos medidos',
        '## 5. Datos registrados',
        '## 7. Evidencias',
        '## 8. Audio de la visita',
        '## 9. Consentimiento (Ley 1581 de 2012)',
        '## 10. Trazabilidad',
      ]) {
        expect(md, contains(seccion));
      }
    });

    test('dice que ningun numero lo escribio un modelo', () {
      // Es la propiedad que hace utilizable el documento: si las coordenadas
      // pudieran venir de un modelo, no se podrian comparar con un plano.
      final md = markdownInformeTecnico(_datos());
      expect(md, contains('Ningun numero de'));
      expect(md, contains('Base local de la app'));
    });

    test('sin trazados no finge que hay una medida', () {
      final md = markdownInformeTecnico(_datos());
      expect(md, contains('No se camino ningun lote'));
      expect(md, contains('no una medida'));
    });

    test('la visita revocada lo dice antes de cualquier dato', () {
      final md = markdownInformeTecnico(
        _datos(
          consentimiento: const ConsentimientoTecnico(
            marcadaParaEliminacion: true,
          ),
        ),
      );
      final aviso = md.indexOf('VISITA MARCADA PARA ELIMINACION');
      expect(aviso, greaterThan(-1));
      expect(aviso, lessThan(md.indexOf('## 1.')));
    });

    test('las coordenadas del predio quedan en el texto', () {
      final md = markdownInformeTecnico(
        _datos(latitud: 4.57321, longitud: -72.819044, precisionGps: 6),
      );
      expect(md, contains('4,573210° N'));
      expect(md, contains('± 6 m'));
      expect(md, contains('WGS84'));
    });

    test('sin GPS lo dice en vez de dejar el renglon vacio', () {
      final md = markdownInformeTecnico(_datos());
      expect(md, contains('Sin coordenada de la visita'));
    });

    test('la seccion de pendientes se omite cuando no hay', () {
      expect(markdownInformeTecnico(_datos()), isNot(contains('## 6.')));
      expect(
        markdownInformeTecnico(_datos(temasPendientes: 'Falta el riego')),
        contains('## 6. Temas pendientes'),
      );
    });
  });

  group('formato', () {
    test('la duracion se lee en horas y minutos', () {
      expect(duracionLegible(const Duration(minutes: 47)), '47 min');
      expect(duracionLegible(const Duration(hours: 2, minutes: 5)), '2 h 5 min');
      expect(duracionLegible(null), '—');
    });

    test('el minuto del audio se escribe como en el reproductor', () {
      // «12:04» y no «724 s»: es lo que se escribe en la barra para llegar al
      // momento exacto de la conversacion.
      expect(marcaAudio(724), '12:04');
      expect(marcaAudio(null), '—');
    });

    test('la ruta del archivo no se filtra al documento', () {
      expect(soloNombre(r'C:\datos\visita\foto-03.jpg'), 'foto-03.jpg');
      expect(soloNombre('/data/user/0/app/foto-03.jpg'), 'foto-03.jpg');
    });
  });
}

// --- Ayudas ---

PuntoTecnico _punto(
  int orden,
  double lat,
  double lon, {
  double? precision,
}) =>
    PuntoTecnico(
      orden: orden,
      latitud: lat,
      longitud: lon,
      capturadoEn: DateTime(2026, 9, 14, 10, orden),
      precisionM: precision,
    );

TrazadoTecnico _trazado({
  required List<PuntoTecnico> puntos,
  String tipo = 'Poligono',
  bool cerrado = true,
  double? areaM2,
}) =>
    TrazadoTecnico(
      nombre: 'Lote de arriba',
      tipo: tipo,
      modoCaptura: 'Manual',
      cerrado: cerrado,
      puntos: puntos,
      etiqueta: 'Plátano',
      areaM2: areaM2,
    );

HallazgoTecnico _hallazgo({
  String modulo = 'Agua',
  String valor = '3',
  String certeza = 'Confirmado',
  String? unidad,
  String? valorCorregido,
}) =>
    HallazgoTecnico(
      modulo: modulo,
      campo: 'Pozos',
      claveTecnica: 'pozos_cantidad',
      valor: valor,
      certeza: certeza,
      fuente: 'Audio',
      estado: 'Propuesto por IA',
      unidad: unidad,
      valorCorregido: valorCorregido,
    );

DatosInformeTecnico _datos({
  List<TrazadoTecnico> trazados = const [],
  List<HallazgoTecnico> hallazgos = const [],
  ConsentimientoTecnico consentimiento = const ConsentimientoTecnico(),
  double? latitud,
  double? longitud,
  double? precisionGps,
  String? temasPendientes,
}) =>
    DatosInformeTecnico(
      codigoVisita: '7f3c1a9e-0000-4000-8000-000000000001',
      inicio: DateTime(2026, 9, 14, 9, 30),
      fin: DateTime(2026, 9, 14, 11, 15),
      generadoEn: DateTime(2026, 9, 14, 11, 20),
      version: 1,
      estado: 'En curso',
      completitudPct: 48,
      visitador: 'Persona De Prueba',
      productor: const ProductorTecnico(
        nombre: 'Señora De Prueba',
        documento: '1234567890',
        tipoDocumento: 'CC',
      ),
      finca: const FincaTecnica(nombre: 'Finca de prueba', areaDeclaradaHa: 0.75),
      vereda: 'Las Moras',
      municipio: 'Barranca de Upía',
      latitud: latitud,
      longitud: longitud,
      precisionGps: precisionGps,
      temasPendientes: temasPendientes,
      trazados: trazados,
      hallazgos: hallazgos,
      consentimiento: consentimiento,
    );
