import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../state/chat.dart';
import 'marca.dart';

/// El chat de campo: lo que el visitador consulta parado en el lote.
///
/// Necesita señal, y eso se dice antes de que falle: el resto de la app
/// funciona sin internet y seria razonable esperar que esto tambien.
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _controlador = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _controlador.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _enviar() {
    final texto = _controlador.text.trim();
    if (texto.isEmpty) return;
    _controlador.clear();
    ref.read(chatProvider.notifier).enviar(texto);
  }

  /// Despues del frame: el mensaje todavia no esta en la lista cuando esto
  /// se llama.
  void _alFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(chatProvider);
    final vacio = estado.mensajes.isEmpty;

    ref.listen(chatProvider, (_, _) => _alFinal());

    return Scaffold(
      appBar: AppBarMarca(
        titulo: 'Asistente de campo',
        actions: [
          if (!vacio)
            IconButton(
              icon: const Icon(Icons.restart_alt),
              tooltip: 'Empezar de nuevo',
              onPressed: () => ref.read(chatProvider.notifier).limpiar(),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          if (estado.error != null)
            Banda(
              texto: estado.error!,
              icono: Icons.cloud_off,
              tono: TonoPildora.error,
              onCerrar: () => ref.read(chatProvider.notifier).limpiarError(),
            ),
          Expanded(
            child: vacio
                ? const _Bienvenida()
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    itemCount:
                        estado.mensajes.length + (estado.esperando ? 1 : 0),
                    itemBuilder: (context, i) => i < estado.mensajes.length
                        ? _Burbuja(mensaje: estado.mensajes[i])
                        : const _Escribiendo(),
                  ),
          ),
          // El reintento va aca y no dentro de la banda: la pregunta que fallo
          // sigue escrita arriba, y el boton queda al lado del teclado.
          if (estado.error != null && !estado.esperando)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => ref.read(chatProvider.notifier).reintentar(),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reintentar'),
                ),
              ),
            ),
          _Redactor(
            controlador: _controlador,
            habilitado: !estado.esperando,
            onEnviar: _enviar,
          ),
        ],
      ),
    );
  }
}

/// Que puede preguntar. Un chat en blanco no dice para que sirve, y el
/// visitador no tiene tiempo de averiguarlo en la finca.
class _Bienvenida extends ConsumerWidget {
  const _Bienvenida();

  static const _ejemplos = [
    'Como reconozco compactacion en el lote',
    'Que cobertura sirve para un suelo arenoso',
    'Resumime la ultima visita',
    'Que quedo pendiente de preguntar',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
      children: [
        Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome,
              size: 32,
              color: scheme.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Preguntale al asistente',
          textAlign: TextAlign.center,
          style: tema.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Responde sobre agronomia regenerativa y sobre las visitas que ya '
          'estan en este telefono. Necesita internet.',
          textAlign: TextAlign.center,
          style: tema.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        for (final ejemplo in _ejemplos)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              onPressed: () => ref.read(chatProvider.notifier).enviar(ejemplo),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              child: SizedBox(width: double.infinity, child: Text(ejemplo)),
            ),
          ),
      ],
    );
  }
}

class _Burbuja extends StatelessWidget {
  const _Burbuja({required this.mensaje});

  final MensajeChat mensaje;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mio = mensaje.esDelVisitador;

    return Align(
      alignment: mio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        decoration: BoxDecoration(
          color: mio ? scheme.primaryContainer : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mio ? 16 : 4),
            bottomRight: Radius.circular(mio ? 4 : 16),
          ),
        ),
        // Seleccionable a proposito: lo que responde el asistente muchas veces
        // termina copiado en la nota de la visita.
        child: SelectableText.rich(
          TextSpan(children: _negritas(mensaje.contenido)),
          style: TextStyle(
            fontSize: 14.5,
            height: 1.4,
            color: mio ? scheme.onPrimaryContainer : scheme.onSurface,
          ),
        ),
      ),
    );
  }

  /// El modelo escribe `**asi**` aunque se le pida texto plano, y unos
  /// asteriscos crudos en la burbuja se leen como un error de la app. Solo
  /// negrita: es lo unico que usa de markdown en una respuesta de dos parrafos.
  static final _bold = RegExp(r'\*\*(.+?)\*\*', dotAll: true);

  List<TextSpan> _negritas(String texto) {
    final spans = <TextSpan>[];
    var desde = 0;
    for (final m in _bold.allMatches(texto)) {
      if (m.start > desde) {
        spans.add(TextSpan(text: texto.substring(desde, m.start)));
      }
      spans.add(
        TextSpan(
          text: m.group(1),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
      desde = m.end;
    }
    if (desde < texto.length) spans.add(TextSpan(text: texto.substring(desde)));
    return spans;
  }
}

class _Escribiendo extends StatelessWidget {
  const _Escribiendo();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _Redactor extends StatelessWidget {
  const _Redactor({
    required this.controlador,
    required this.habilitado,
    required this.onEnviar,
  });

  final TextEditingController controlador;
  final bool habilitado;
  final VoidCallback onEnviar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controlador,
                enabled: habilitado,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => onEnviar(),
                decoration: const InputDecoration(
                  hintText: 'Escribi tu pregunta',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: IconButton.filled(
                onPressed: habilitado ? onEnviar : null,
                icon: const Icon(Icons.arrow_upward),
                tooltip: 'Enviar',
                style: IconButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
