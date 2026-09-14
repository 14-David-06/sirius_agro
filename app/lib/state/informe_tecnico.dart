import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/informe_tecnico.dart';
import '../core/informe_tecnico_pdf.dart';
import '../data/db/app_database.dart';
import 'providers.dart';

/// El informe tecnico generado, con sus bytes listos para compartir.
class ResultadoTecnico {
  const ResultadoTecnico(this.informe, this.pdf);

  final Informe informe;
  final Uint8List pdf;
}

class InformeTecnicoState {
  const InformeTecnicoState({this.trabajando = false, this.error, this.ultimo});

  final bool trabajando;
  final String? error;
  final ResultadoTecnico? ultimo;
}

/// Arma el informe tecnico de la visita.
///
/// A diferencia del informe del productor, esto NO necesita senal y no le
/// cuesta nada: no hay llamada al modelo. Todo sale de la base del telefono —
/// coordenadas, areas caminadas, hallazgos con su certeza, evidencias,
/// consentimiento— asi que el visitador lo puede generar en la finca, aunque
/// no haya una barra de senal.
///
/// El PDF se guarda y se encola en el mismo paso que se genera, antes de
/// compartirlo. Es a proposito: el documento de la empresa tiene que quedar
/// archivado aunque el visitador nunca lo comparta con nadie.
class InformeTecnicoController extends StateNotifier<InformeTecnicoState> {
  InformeTecnicoController(this._ref, this.visitaId)
      : super(const InformeTecnicoState());

  final Ref _ref;
  final String visitaId;

  Future<ResultadoTecnico?> generar() async {
    if (state.trabajando) return null;
    state = const InformeTecnicoState(trabajando: true);

    final repo = _ref.read(repoProvider);
    try {
      final datos = await repo.datosInformeTecnico(visitaId);

      // El markdown y el PDF salen de los MISMOS datos, en el mismo instante.
      // Si se leyera la base dos veces, una foto tomada en el medio quedaria
      // en uno y no en el otro, y el texto que se archiva en Airtable no
      // describiria el PDF que lo acompana.
      final informe = await repo.guardarInforme(
        visitaId: visitaId,
        titulo: _titulo(datos),
        contenido: markdownInformeTecnico(datos),
        tipo: tipoInformeTecnico,
      );

      final pdf = await construirInformeTecnicoPdf(datos);
      await repo.guardarPdfInforme(informe.id, pdf);

      final resultado = ResultadoTecnico(informe, pdf);
      state = InformeTecnicoState(ultimo: resultado);
      return resultado;
    } catch (e) {
      state = InformeTecnicoState(error: '$e');
      return null;
    }
  }

  /// El PDF de un informe tecnico que ya existe, para volver a compartirlo o
  /// imprimirlo.
  ///
  /// Lee el archivo archivado y NO lo vuelve a armar: el documento de la
  /// version 1 es el que se genero cuando se genero, con los datos de ese
  /// momento. Rearmarlo hoy daria otro papel con el mismo numero de version —
  /// mas fotos, otra area, otro conteo de certeza— y eso es exactamente lo que
  /// un documento de archivo no puede hacer.
  ///
  /// Si el archivo ya no esta en el telefono (limpieza, cambio de equipo) se
  /// rearma desde los datos de hoy, porque es mejor que no poder entregar
  /// nada, y se devuelve [rearmado] en true para que la pantalla lo diga.
  Future<({Uint8List pdf, bool rearmado})> pdfArchivado(Informe informe) async {
    final ruta = informe.pdfPath;
    if (ruta != null) {
      final archivo = File(ruta);
      if (await archivo.exists()) {
        return (pdf: await archivo.readAsBytes(), rearmado: false);
      }
    }

    final datos = await _ref
        .read(repoProvider)
        .datosInformeTecnico(visitaId, version: informe.version);
    final pdf = await construirInformeTecnicoPdf(datos);
    // Se vuelve a guardar en la ruta del informe: la proxima vez ya esta.
    await _ref.read(repoProvider).guardarPdfInforme(informe.id, pdf);
    return (pdf: pdf, rearmado: true);
  }

  String _titulo(DatosInformeTecnico datos) {
    final quien = datos.finca?.nombre ??
        datos.productor?.nombre ??
        datos.codigoVisita.substring(0, 8);
    final fecha = datos.inicio.toIso8601String().substring(0, 10);
    return 'Informe tecnico $quien - $fecha';
  }

  void limpiarError() => state = const InformeTecnicoState();
}

final informeTecnicoProvider = StateNotifierProvider.family<
    InformeTecnicoController, InformeTecnicoState, String>(
  (ref, visitaId) => InformeTecnicoController(ref, visitaId),
);
