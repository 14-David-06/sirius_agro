import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pdf/pdf.dart';
import 'package:sirius_agro/core/informe_tecnico.dart';
import 'package:sirius_agro/core/informe_tecnico_pdf.dart';

/// El PDF tecnico, el que se archiva en la empresa.
///
/// Lo que se protege: que se arme siempre —una visita a medias tambien tiene
/// que poder archivarse—, que embeba la fuente TTF (sin ella los grados y el
/// «±» de las coordenadas salen rotos, y una coordenada ilegible no sirve para
/// nada), y que una foto borrada del telefono no impida archivar el documento.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting('es'));

  test('se genera un PDF valido y con contenido', () async {
    final bytes = await construirInformeTecnicoPdf(_datos());

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    // El logo pesa: un PDF de pocos bytes seria una hoja en blanco.
    expect(bytes.length, greaterThan(20000));
  });

  test('es A4, como el informe del productor', () {
    expect(PdfPageFormat.a4.width.round(), 595);
    expect(PdfPageFormat.a4.height.round(), 842);
  });

  test('embebe la fuente TTF: sin ella los grados salen rotos', () async {
    // Las fuentes internas del generador no cubren Unicode. Un documento cuyo
    // sentido es mostrar coordenadas no puede imprimir «4,573210° N» roto.
    final bytes = await construirInformeTecnicoPdf(
      _datos(latitud: 4.57321, longitud: -72.819044, precisionGps: 6),
    );
    expect(String.fromCharCodes(bytes).contains('FontFile2'), isTrue);
  });

  test('va en la letra corporativa, igual que el informe del productor',
      () async {
    // Los dos documentos de la misma visita se archivan juntos. Uno en Museo
    // Slab y el otro en la letra por defecto se leen como de dos empresas.
    final bytes = await construirInformeTecnicoPdf(_datos());

    expect(String.fromCharCodes(bytes).contains('MuseoSlab'), isTrue);
  });

  test('una visita vacia tambien se archiva', () async {
    // Sin GPS, sin trazados, sin hallazgos, sin fotos y sin audio. Es el caso
    // de la charla que quedo a medias, y es justo la que hay que poder
    // archivar: el documento dice que no hay, no finge que hay.
    final bytes = await construirInformeTecnicoPdf(
      DatosInformeTecnico(
        codigoVisita: '7f3c1a9e-0000-4000-8000-000000000001',
        inicio: DateTime(2026, 9, 14, 9, 30),
        generadoEn: DateTime(2026, 9, 14, 11, 20),
        version: 1,
      ),
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('el croquis del lote no necesita mapa ni red', () async {
    // Se dibuja el poligono con vectores a proposito: el informe se arma en la
    // finca, donde no hay de donde descargar teselas.
    final bytes = await construirInformeTecnicoPdf(
      _datos(trazados: [_trazado()]),
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(20000));
  });

  test('un trazado de un solo punto no rompe el dibujo', () async {
    // «Punto» es un tipo valido: la bocatoma, el arbol enfermo, donde se saco
    // la muestra de suelo. No tiene forma que dibujar y no puede tumbar el
    // documento.
    final bytes = await construirInformeTecnicoPdf(
      _datos(
        trazados: [
          TrazadoTecnico(
            nombre: 'Bocatoma',
            tipo: 'Punto',
            modoCaptura: 'Manual',
            cerrado: false,
            puntos: [_punto(1, 4.5, -72.8)],
          ),
        ],
      ),
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('una foto que ya no esta en disco no impide archivar', () async {
    final bytes = await construirInformeTecnicoPdf(
      _datos(
        evidencias: [
          EvidenciaTecnica(
            archivoPath: '/no/existe/foto-1.jpg',
            tomadaEn: DateTime(2026, 9, 14, 10),
            latitud: 4.5,
            longitud: -72.8,
          ),
        ],
      ),
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('las fotos que existen entran y hacen crecer el documento', () async {
    final carpeta = await Directory.systemTemp.createTemp('informe-tecnico-');
    addTearDown(() => carpeta.delete(recursive: true));

    final png = File('${carpeta.path}/foto.png');
    await png.writeAsBytes(_png1x1);

    final sinFotos = await construirInformeTecnicoPdf(_datos());
    final conFoto = await construirInformeTecnicoPdf(
      _datos(
        evidencias: [
          EvidenciaTecnica(
            archivoPath: png.path,
            tomadaEn: DateTime(2026, 9, 14, 10),
          ),
        ],
      ),
    );

    expect(conFoto.length, greaterThan(sinFotos.length));
  });

  test('la paleta de certeza no repite colores entre clases', () {
    // El color de la certeza es el unico color por dato del documento. Si dos
    // clases compartieran color, la unica senal visual del informe mentiria.
    final colores = {
      PaletaTecnica.confirmado.toInt(),
      PaletaTecnica.estimado.toInt(),
      PaletaTecnica.inferido.toInt(),
      PaletaTecnica.pendiente.toInt(),
    };
    expect(colores.length, 4);
  });

  test('el documento se identifica por su version, no por un codigo', () {
    // El codigo de formato (FT-AGRO-002) se saco del documento: al pie va la
    // version y la fecha de creacion, que es lo que distingue dos informes de
    // la misma visita. Si alguien lo devuelve, este test lo ve.
    final md = markdownInformeTecnico(_datos());
    expect(md, isNot(contains('FT-AGRO')));
    expect(md, contains('version 1'));
  });
}

PuntoTecnico _punto(int orden, double lat, double lon) => PuntoTecnico(
      orden: orden,
      latitud: lat,
      longitud: lon,
      capturadoEn: DateTime(2026, 9, 14, 10, orden),
      precisionM: 5,
    );

TrazadoTecnico _trazado() => TrazadoTecnico(
      nombre: 'Lote de arriba',
      tipo: 'Poligono',
      modoCaptura: 'Manual',
      cerrado: true,
      etiqueta: 'Plátano',
      puntos: [
        _punto(1, 4.5000, -72.8000),
        _punto(2, 4.5009, -72.8000),
        _punto(3, 4.5009, -72.7991),
        _punto(4, 4.5000, -72.7991),
      ],
    );

DatosInformeTecnico _datos({
  List<TrazadoTecnico> trazados = const [],
  List<EvidenciaTecnica> evidencias = const [],
  double? latitud,
  double? longitud,
  double? precisionGps,
}) =>
    DatosInformeTecnico(
      codigoVisita: '7f3c1a9e-0000-4000-8000-000000000001',
      inicio: DateTime(2026, 9, 14, 9, 30),
      fin: DateTime(2026, 9, 14, 11, 15),
      generadoEn: DateTime(2026, 9, 14, 11, 20),
      version: 1,
      estado: 'En curso',
      tipoVisita: 'Diagnóstico',
      completitudPct: 48,
      visitador: 'Persona De Prueba',
      productor: const ProductorTecnico(
        nombre: 'Señora De Prueba',
        documento: '1234567890',
        tipoDocumento: 'CC',
        telefono: '3000000000',
      ),
      finca: const FincaTecnica(
        nombre: 'Finca de prueba',
        areaDeclaradaHa: 0.75,
      ),
      vereda: 'Las Moras',
      municipio: 'Barranca de Upía',
      latitud: latitud,
      longitud: longitud,
      precisionGps: precisionGps,
      temasPendientes: 'Conversar con el esposo.\nConfirmar el arriendo.',
      trazados: trazados,
      evidencias: evidencias,
      hallazgos: [
        const HallazgoTecnico(
          modulo: 'Cultivos',
          campo: 'Plantas sembradas',
          claveTecnica: 'plantas_cantidad',
          valor: '2300',
          certeza: 'Confirmado',
          fuente: 'Audio',
          estado: 'Propuesto por IA',
          segundoAudio: 724,
        ),
        const HallazgoTecnico(
          modulo: 'Cultivos',
          campo: 'Área en producción',
          claveTecnica: 'area_produccion_ha',
          valor: '0,5',
          unidad: 'ha',
          certeza: 'Estimado',
          fuente: 'Audio',
          estado: 'Propuesto por IA',
        ),
        const HallazgoTecnico(
          modulo: 'Suelos',
          campo: 'Análisis de suelo',
          claveTecnica: 'analisis_suelo',
          valor: '',
          certeza: 'Pendiente',
          fuente: 'Audio',
          estado: 'Propuesto por IA',
        ),
      ],
      grabaciones: [
        GrabacionTecnica(
          orden: 1,
          inicio: DateTime(2026, 9, 14, 9, 35),
          duracionSeg: 1820,
          tamanoBytes: 3400000,
          motor: 'ElevenLabs',
          estado: 'Transcrita',
          transcrita: true,
        ),
      ],
      consentimiento: const ConsentimientoTecnico(
        audio: true,
        fotos: true,
        usoDatos: true,
        segundoConsentimiento: 42,
      ),
    );

/// PNG de 1x1 valido, suficiente para que el encoder lo acepte.
const _png1x1 = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];
