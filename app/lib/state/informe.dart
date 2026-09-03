import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../data/db/app_database.dart';
import 'providers.dart';

class InformeState {
  const InformeState({this.trabajando = false, this.error, this.ultimo});

  final bool trabajando;
  final String? error;

  /// El informe recien generado, para abrirlo sin que la pantalla tenga que
  /// adivinar cual de todos es.
  final Informe? ultimo;
}

/// Genera el informe del agricultor.
///
/// Necesita señal, como procesar. La diferencia con el resto de la app es que
/// esto NO se encola para despues: el visitador lo pide cuando quiere leerselo
/// al productor antes de irse, y un informe que llega tres dias tarde ya no
/// cumple lo que se le prometio en el consentimiento.
class InformeController extends StateNotifier<InformeState> {
  InformeController(this._ref, this.visitaId) : super(const InformeState());

  final Ref _ref;
  final String visitaId;

  Future<Informe?> generar() async {
    if (state.trabajando) return null;
    state = const InformeState(trabajando: true);

    final repo = _ref.read(repoProvider);
    try {
      final contexto = await repo.contextoInforme(visitaId);
      final generado = await _ref.read(apiProvider).generarInforme(contexto);

      final informe = await repo.guardarInforme(
        visitaId: visitaId,
        titulo: generado.titulo,
        contenido: generado.contenido,
        tipo: generado.tipo,
        modelo: generado.modelo,
      );

      state = InformeState(ultimo: informe);
      return informe;
    } on ApiException catch (e) {
      state = InformeState(error: e.message);
      return null;
    } catch (e) {
      state = InformeState(error: '$e');
      return null;
    }
  }

  void limpiarError() => state = const InformeState();
}

final informeProvider =
    StateNotifierProvider.family<InformeController, InformeState, String>(
  (ref, visitaId) => InformeController(ref, visitaId),
);

/// Los informes ya generados de una visita, el mas nuevo primero.
final informesProvider = StreamProvider.family<List<Informe>, String>(
  (ref, visitaId) => ref.watch(repoProvider).observarInformes(visitaId),
);
