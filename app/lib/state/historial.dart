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

  /// Refresca solo el INDICE de visitas de Airtable, sin archivos.
  ///
  /// Corre sola cuando el visitador abre la lista y hay senal. Puede ser
  /// automatica justamente porque no baja nada pesado: trae fichas, y los
  /// hallazgos, las fotos y el audio se bajan cuando alguien abre una visita.
  ///
  /// Falla en silencio, como el refresco del directorio. El visitador no puede
  /// hacer nada al respecto y la lista que ya tiene en el telefono sigue
  /// sirviendo: un error rojo cada vez que se entra a la pantalla principal
  /// sin senal seria ruido, no informacion.
  Future<int> refrescarIndice() async {
    if (state.trabajando) return 0;

    try {
      final remotas = await _ref.read(apiProvider).indiceDeVisitas();
      return await _ref.read(repoProvider).importarIndiceVisitas(remotas);
    } catch (_) {
      return 0;
    }
  }

  /// Baja el detalle de un espejo al que solo se le tiene la ficha.
  ///
  /// Se llama al abrir la visita. Si ya tiene detalle no hace nada, y si la
  /// visita es propia tampoco: ahi no hay nada que traer de Airtable.
  Future<bool> asegurarDetalle(String visitaId) async {
    final repo = _ref.read(repoProvider);
    final falta = await repo.faltaElDetalle(visitaId);
    if (falta != true) return false;

    state = const HistorialState(
      trabajando: true,
      paso: 'Bajando la visita completa...',
    );

    final api = _ref.read(apiProvider);
    try {
      final detalle = await api.detalleDeVisita(visitaId);
      final resultado = await repo.importarHistorial(
        {
          'visitas': [detalle],
        },
        bajar: api.descargarArchivo,
        onPaso: (paso) {
          if (mounted) {
            state = HistorialState(trabajando: true, paso: paso);
          }
        },
      );
      await repo.marcarDetalleDescargado(visitaId);
      state = HistorialState(ultimo: resultado);
      return true;
    } on ApiException catch (e) {
      state = HistorialState(error: e.message);
      return false;
    } catch (e) {
      state = HistorialState(error: '$e');
      return false;
    }
  }

  void limpiar() => state = const HistorialState();
}

final historialProvider =
    StateNotifierProvider<HistorialController, HistorialState>(
  HistorialController.new,
);
