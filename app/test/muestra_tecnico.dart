import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sirius_agro/core/informe_tecnico.dart';
import 'package:sirius_agro/core/informe_tecnico_pdf.dart';

/// No es una prueba: genera la muestra del informe tecnico que se revisa a
/// ojo. Se corre a mano:
///   `MUESTRA_DIR=<carpeta> flutter test test/muestra_tecnico.dart`
/// Sin esa variable no hace nada, para no romper la suite.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('muestra', () async {
    await initializeDateFormatting('es');
    final base = Platform.environment['MUESTRA_DIR'];
    if (base == null) return;

    final datos = DatosInformeTecnico(
      codigoVisita: '7f3c1a9e-4d2b-4c11-9a71-0f5c8e2b9d34',
      inicio: DateTime(2026, 9, 14, 9, 30),
      fin: DateTime(2026, 9, 14, 11, 15),
      generadoEn: DateTime(2026, 9, 14, 11, 20),
      version: 1,
      estado: 'En curso',
      tipoVisita: 'Diagnóstico',
      completitudPct: 48,
      visitador: 'Joys Fernanda Moreno Firigua',
      productor: const ProductorTecnico(
        nombre: 'Señora De Prueba',
        documento: '1098765432',
        tipoDocumento: 'CC',
        telefono: '3123456789',
        consentimientoDatos: true,
      ),
      finca: const FincaTecnica(
        nombre: 'Finca de prueba',
        latitud: 4.573512,
        longitud: -72.818977,
        areaDeclaradaHa: 0.75,
      ),
      vereda: 'Las Moras',
      municipio: 'Barranca de Upía',
      latitud: 4.573210,
      longitud: -72.819044,
      precisionGps: 6.2,
      temasPendientes: 'Conversar con el esposo: él maneja el cultivo.\n'
          'Confirmar el valor del arriendo.\n'
          'Ubicar el otro predio y el predio de la isla.',
      trazados: [
        TrazadoTecnico(
          nombre: 'Lote de plátano',
          tipo: 'Poligono',
          modoCaptura: 'Automatico',
          cerrado: true,
          etiqueta: 'Plátano, 4 meses',
          notas: 'Caminado por el lindero con el vecino.',
          puntos: [
            for (var i = 0; i < 9; i++)
              PuntoTecnico(
                orden: i + 1,
                latitud: 4.5730 + 0.0006 * _seno(i),
                longitud: -72.8190 + 0.0006 * _coseno(i),
                altitud: 218 + i.toDouble(),
                precisionM: 4 + (i % 3) * 2.5,
                capturadoEn: DateTime(2026, 9, 14, 10, 12 + i),
                automatico: i != 0,
              ),
          ],
        ),
        TrazadoTecnico(
          nombre: 'Camino de acceso',
          tipo: 'Ruta',
          modoCaptura: 'Manual',
          cerrado: false,
          etiqueta: 'Entrada desde la vía',
          puntos: [
            for (var i = 0; i < 4; i++)
              PuntoTecnico(
                orden: i + 1,
                latitud: 4.5725 + 0.0004 * i,
                longitud: -72.8196 + 0.0002 * i,
                precisionM: 7,
                capturadoEn: DateTime(2026, 9, 14, 10, 40 + i),
              ),
          ],
        ),
      ],
      hallazgos: const [
        HallazgoTecnico(
          modulo: 'Cultivos',
          campo: 'Plantas sembradas',
          claveTecnica: 'plantas_cantidad',
          valor: '2300',
          certeza: 'Confirmado',
          fuente: 'Audio',
          estado: 'Propuesto por IA',
          segundoAudio: 724,
          entidad: 'cultivo_1',
        ),
        HallazgoTecnico(
          modulo: 'Cultivos',
          campo: 'Área en producción',
          claveTecnica: 'area_produccion_ha',
          valor: '0,5',
          unidad: 'ha',
          certeza: 'Estimado',
          fuente: 'Audio',
          estado: 'Propuesto por IA',
          segundoAudio: 802,
        ),
        HallazgoTecnico(
          modulo: 'Cultivos',
          campo: 'Problema sanitario',
          claveTecnica: 'plaga_principal',
          valor: 'Sigatoka',
          certeza: 'Confirmado',
          fuente: 'Audio',
          estado: 'Confirmado',
          segundoAudio: 915,
        ),
        HallazgoTecnico(
          modulo: 'Insumos',
          campo: 'Producto aplicado',
          claveTecnica: 'insumo_aplicado',
          valor: 'Cloros granulados',
          certeza: 'Inferido',
          fuente: 'Audio',
          estado: 'Requiere confirmacion',
          razonamiento: 'Lo describió la señora; quien aplica es el esposo.',
          segundoAudio: 1010,
        ),
        HallazgoTecnico(
          modulo: 'Suelos',
          campo: 'Análisis de suelo',
          claveTecnica: 'analisis_suelo',
          valor: '',
          certeza: 'Pendiente',
          fuente: 'Audio',
          estado: 'Propuesto por IA',
        ),
        HallazgoTecnico(
          modulo: 'Hogar',
          campo: 'Personas en la finca',
          claveTecnica: 'personas_hogar',
          valor: '5',
          certeza: 'Confirmado',
          fuente: 'Audio',
          estado: 'Propuesto por IA',
          segundoAudio: 300,
        ),
      ],
      evidencias: [
        EvidenciaTecnica(
          archivoPath: '$base/foto.png',
          tomadaEn: DateTime(2026, 9, 14, 10, 18),
          latitud: 4.573245,
          longitud: -72.819101,
          segundoAudio: 640,
          descripcion: 'Lote de plátano visto desde la entrada.',
        ),
        EvidenciaTecnica(
          archivoPath: '$base/foto.png',
          tomadaEn: DateTime(2026, 9, 14, 10, 31),
          segundoAudio: 890,
          descripcion: 'Hoja con sigatoka.',
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
        GrabacionTecnica(
          orden: 2,
          inicio: DateTime(2026, 9, 14, 10, 20),
          duracionSeg: 640,
          tamanoBytes: 1200000,
          motor: 'Whisper',
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
      modeloIa: 'claude-sonnet-5',
    );

    await File('$base/muestra-tecnico.pdf')
        .writeAsBytes(await construirInformeTecnicoPdf(datos));
    await File('$base/muestra-tecnico.md')
        .writeAsString(markdownInformeTecnico(datos));
  });
}

// Un poligono redondeado, para que el croquis de la muestra tenga forma de
// lote y no de cuadrado perfecto.
double _seno(int i) => [0.0, 0.6, 1.0, 0.9, 0.4, -0.2, -0.7, -0.9, -0.5][i];
double _coseno(int i) => [1.0, 0.8, 0.2, -0.4, -0.9, -1.0, -0.7, -0.1, 0.6][i];
