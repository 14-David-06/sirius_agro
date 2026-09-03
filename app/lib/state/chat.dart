import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import 'providers.dart';
import 'sesion.dart';

class ChatState {
  const ChatState({
    this.mensajes = const [],
    this.esperando = false,
    this.error,
  });

  /// El hilo completo, en orden. Vive solo en memoria: el chat es una consulta
  /// de campo, no un registro de la visita. Lo que importa guardar de una
  /// visita se guarda en la visita.
  final List<MensajeChat> mensajes;

  /// Hay una pregunta en vuelo. Bloquea enviar otra: el hilo tiene que
  /// alternar visitador/modelo o el backend lo rechaza.
  final bool esperando;

  final String? error;

  ChatState copyWith({
    List<MensajeChat>? mensajes,
    bool? esperando,
    String? error,
  }) =>
      ChatState(
        mensajes: mensajes ?? this.mensajes,
        esperando: esperando ?? this.esperando,
        error: error,
      );
}

class ChatController extends StateNotifier<ChatState> {
  ChatController(this._ref) : super(const ChatState());

  final Ref _ref;

  Future<void> enviar(String texto) async {
    final pregunta = texto.trim();
    if (pregunta.isEmpty || state.esperando) return;

    final hilo = [...state.mensajes, MensajeChat(rol: 'user', contenido: pregunta)];
    state = ChatState(mensajes: hilo, esperando: true);

    try {
      // El contexto se relee en cada pregunta: si el visitador acaba de cerrar
      // una visita y vuelve al chat, tiene que poder preguntar por ella.
      final contexto = await _ref.read(repoProvider).contextoChat();
      final sesion = _ref.read(sesionProvider).valueOrNull;

      final respuesta = await _ref.read(apiProvider).chat(
            mensajes: hilo,
            visitador: sesion?.credencial.nombre,
            contexto: contexto,
          );

      state = ChatState(
        mensajes: [...hilo, MensajeChat(rol: 'assistant', contenido: respuesta)],
      );
    } on ApiException catch (e) {
      // La pregunta queda en el hilo para que se pueda reintentar sin
      // volver a escribirla.
      state = ChatState(mensajes: hilo, error: e.message);
    } catch (e) {
      state = ChatState(mensajes: hilo, error: '$e');
    }
  }

  /// Reintenta la ultima pregunta. Solo tiene sentido si el hilo termina en
  /// una pregunta sin responder, que es justo como queda tras un error.
  Future<void> reintentar() async {
    final hilo = state.mensajes;
    if (hilo.isEmpty || !hilo.last.esDelVisitador || state.esperando) return;

    final pregunta = hilo.last.contenido;
    state = ChatState(mensajes: hilo.sublist(0, hilo.length - 1));
    await enviar(pregunta);
  }

  void limpiarError() => state = state.copyWith(error: null);

  void limpiar() => state = const ChatState();
}

final chatProvider = StateNotifierProvider<ChatController, ChatState>(
  ChatController.new,
);
