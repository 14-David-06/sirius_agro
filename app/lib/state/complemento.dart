import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/complemento_visita.dart';
import '../data/visita_repository.dart';
import 'providers.dart';
import 'sesion.dart';

class ComplementoState {
  const ComplementoState({
    this.mensajes = const [],
    this.esperando = false,
    this.error,
    this.escritos = const [],
    this.ultimoTurnoEscribio = 0,
  });

  final List<MensajeChat> mensajes;

  /// Hay una pregunta en vuelo. Bloquea mandar otra: el hilo tiene que
  /// alternar visitador/modelo o el backend lo rechaza.
  final bool esperando;

  final String? error;

  /// Los datos que esta conversacion ya dejo escritos, en texto legible. Se
  /// acumulan para poder decir al final que se registro, y viajan al markdown
  /// que se guarda en Airtable.
  final List<String> escritos;

  /// Cuantos datos escribio el ULTIMO turno. La pantalla lo usa para avisarlo
  /// en el momento: el dato entra directo al registro, y ese es el unico
  /// instante en que alguien puede notar que el modelo entendio mal.
  final int ultimoTurnoEscribio;
}

/// El chat de una visita. Responde sobre ella y ESCRIBE lo que el visitador
/// aporte.
///
/// Es el unico camino del sistema donde un dato entra al registro sin haber
/// pasado por el audio. Tres cosas lo hacen aceptable, y ninguna esta en el
/// prompt:
///
/// 1. El backend marca cada hallazgo `fuente = Manual`, `hablante = visitador`.
/// 2. La app los guarda por `guardarExtraccion`, que aplica las reglas duras:
///    lo dicho por el visitador nunca queda `Confirmado`.
/// 3. Cada dato lleva como cita la frase con la que el visitador lo dijo, asi
///    que meses despues se puede ver de donde salio.
///
/// La conversacion entera se guarda con la visita y sube a Airtable: es el
/// registro de procedencia de todo lo anterior.
class ComplementoController extends StateNotifier<ComplementoState> {
  ComplementoController(this._ref, this.visitaId)
      : super(const ComplementoState());

  final Ref _ref;
  final String visitaId;

  Future<void> enviar(String texto) async {
    final mensaje = texto.trim();
    if (mensaje.isEmpty || state.esperando) return;

    final hilo = [
      ...state.mensajes,
      MensajeChat(rol: 'user', contenido: mensaje),
    ];
    state = ComplementoState(
      mensajes: hilo,
      esperando: true,
      escritos: state.escritos,
    );

    final repo = _ref.read(repoProvider);
    try {
      // El contexto se relee en cada turno: el visitador puede haber
      // complementado tres datos hace un minuto, y el modelo no puede volver a
      // pedirlos como si faltaran.
      final contexto = await repo.contextoComplemento(visitaId);
      final campos = await repo.camposParaExtraccion();
      final sesion = _ref.read(sesionProvider).valueOrNull;
      final visitador = sesion?.credencial.nombre;

      final resultado = await _ref.read(apiProvider).complementar(
            codigoVisita: visitaId,
            mensajes: hilo,
            campos: campos,
            contexto: contexto,
            visitador: visitador,
          );

      final completo = [
        ...hilo,
        MensajeChat(rol: 'assistant', contenido: resultado.respuesta),
      ];

      // Se guarda lo que el turno aporto ANTES de responder en la pantalla: si
      // la app muriera entre una cosa y la otra, es mejor que el dato este
      // guardado y el visitador lo vuelva a leer, que verlo confirmado en una
      // burbuja y que no exista.
      final escritos = await _guardar(resultado, repo);

      state = ComplementoState(
        mensajes: completo,
        escritos: [...state.escritos, ...escritos],
        ultimoTurnoEscribio: escritos.length,
      );

      await _archivar(completo, visitador);
    } on ApiException catch (e) {
      state = ComplementoState(
        mensajes: hilo,
        error: e.message,
        escritos: state.escritos,
      );
    } catch (e) {
      state = ComplementoState(
        mensajes: hilo,
        error: '$e',
        escritos: state.escritos,
      );
    }
  }

  /// Escribe los hallazgos del turno y devuelve como quedaron, en texto.
  ///
  /// Va por `guardarExtraccion` —el mismo camino del audio— y no por una
  /// insercion propia: ahi viven las reglas duras y el recalculo de la
  /// completitud. Un camino paralelo seria un camino sin reglas.
  Future<List<String>> _guardar(
    ComplementoResult resultado,
    VisitaRepository repo,
  ) async {
    if (resultado.hallazgos.isEmpty && resultado.temasPendientes.isEmpty) {
      return const [];
    }

    final extraidos = [
      for (final h in resultado.hallazgos) HallazgoExtraido.fromJson(h),
    ];

    await repo.guardarExtraccion(
      visitaId: visitaId,
      extraidos: extraidos,
      // El resumen NO se toca: el de la visita lo escribio el modelo con la
      // conversacion entera delante, y este chat solo vio un mensaje suelto.
      temasPendientes: resultado.temasPendientes,
    );

    return [
      for (final h in extraidos)
        '${h.claveTecnica}: '
            '${h.valorTexto ?? h.valorNumerico ?? ''}'
            '${h.unidad == null ? '' : ' ${h.unidad}'}',
    ];
  }

  /// Guarda la conversacion con la visita y la encola para Airtable.
  ///
  /// No tumba el turno si falla: el dato ya quedo escrito y la respuesta ya
  /// esta en la pantalla. Que el registro de la conversacion no se guarde es
  /// una perdida menor comparada con mostrarle un error al visitador por algo
  /// que ya funciono.
  Future<void> _archivar(List<MensajeChat> hilo, String? visitador) async {
    try {
      await _ref.read(repoProvider).guardarConversacionComplemento(
            visitaId: visitaId,
            contenido: markdownConversacion(
              mensajes: hilo,
              generadoEn: DateTime.now(),
              visitador: visitador,
              datosEscritos: state.escritos,
            ),
          );
    } catch (_) {
      // Silencioso a proposito, ver arriba.
    }
  }

  void limpiarError() => state = ComplementoState(
        mensajes: state.mensajes,
        escritos: state.escritos,
      );
}

final complementoProvider = StateNotifierProvider.family<ComplementoController,
    ComplementoState, String>(
  (ref, visitaId) => ComplementoController(ref, visitaId),
);
