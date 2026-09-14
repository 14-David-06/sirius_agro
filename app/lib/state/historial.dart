import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../data/visita_repository.dart';
import 'providers.dart';

class HistorialState {
  const HistorialState({
    this.trabajando = false,
    this.paso = '',
    this.error,
    this.ultimo,
  });

  final bool trabajando;

  /// Lo que se esta bajando ahora mismo. Traer un historial con fotos y audio
  /// tarda, y un spinner mudo durante medio minuto parece una app colgada.
  final String paso;

  final String? error;
  final ResultadoEspejo? ultimo;
}

/// Trae de Airtable las visitas ya registradas de un agricultor.
///
/// Es la primera vez que algo baja hacia el telefono aparte del directorio.
/// Orquesta y nada mas: el backend lee Airtable, el repositorio escribe la
/// base y guarda los archivos, y esto los junta.
///
/// Las visitas entran como ESPEJO DE SOLO LECTURA. Una visita que ya esta en
/// este telefono y no es un espejo se salta entera — ahi el telefono es la
/// fuente de verdad, porque es donde se registro.
class HistorialController extends StateNotifier<HistorialState> {
  HistorialController(this._ref) : super(const HistorialState());

  final Ref _ref;

  /// [productorRemoteId] es el record id de Airtable, el que trae el
  /// directorio. Sin el no hay a quien pedirle el historial: el nombre no
  /// alcanza, porque dos homonimos de la misma vereda mezclarian sus visitas.
  Future<ResultadoEspejo?> traer(String productorRemoteId) async {
    if (state.trabajando) return null;
    state = const HistorialState(trabajando: true, paso: 'Buscando visitas...');

    final api = _ref.read(apiProvider);
    try {
      final historial = await api.historialDeProductor(productorRemoteId);

      final resultado = await _ref.read(repoProvider).importarHistorial(
            historial,
            bajar: api.descargarArchivo,
            onPaso: (paso) {
              if (mounted) {
                state = HistorialState(trabajando: true, paso: paso);
              }
            },
          );

      state = HistorialState(ultimo: resultado);
      return resultado;
    } on ApiException catch (e) {
      state = HistorialState(error: e.message);
      return null;
    } catch (e) {
      state = HistorialState(error: '$e');
      return null;
    }
  }

  void limpiar() => state = const HistorialState();
}

final historialProvider =
    StateNotifierProvider<HistorialController, HistorialState>(
  HistorialController.new,
);
