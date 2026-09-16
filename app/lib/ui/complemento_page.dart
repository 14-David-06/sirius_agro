import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/iconos_modulo.dart';
import '../state/complemento.dart';
import '../state/nota_voz.dart';
import '../state/providers.dart';
import 'marca.dart';
import 'theme.dart';

/// El chat de una visita: completar lo que falto y preguntar sobre ella.
///
/// Distinto del asistente de campo en lo unico que importa: aquel responde,
/// este ESCRIBE. Lo que el visitador cuente aca entra al registro de la visita
/// y sube a Airtable.
///
/// Por eso la pantalla dice en cada turno que quedo guardado. El dato entra
/// directo —sin confirmar— y ese aviso es la unica oportunidad que tiene el
/// visitador de notar que el modelo entendio mal un numero.
class ComplementoPage extends ConsumerStatefulWidget {
  const ComplementoPage({super.key, required this.visitaId});

  final String visitaId;

  @override
  ConsumerState<ComplementoPage> createState() => _ComplementoPageState();
}

class _ComplementoPageState extends ConsumerState<ComplementoPage> {
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
    ref.read(complementoProvider(widget.visitaId).notifier).enviar(texto);
  }

  /// Cierra la nota de voz y deja lo transcrito EN EL CAMPO, sin enviarlo.
  ///
  /// El visitador lee antes de mandar. Lo que sale de este chat entra derecho
  /// al registro de la visita, y un numero mal transcrito quedaria como dato
  /// sin que nadie lo haya visto.
  Future<void> _cerrarNota() async {
    final texto = await ref
        .read(notaVozProvider(widget.visitaId).notifier)
        .detenerYTranscribir();
    if (texto == null || !mounted) return;

    final previo = _controlador.text.trim();
    _controlador.text = previo.isEmpty ? texto : '$previo $texto';
    _controlador.selection = TextSelection.collapsed(
      offset: _controlador.text.length,
    );
  }

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
    final estado = ref.watch(complementoProvider(widget.visitaId));
    final notifier = ref.read(complementoProvider(widget.visitaId).notifier);
    final nota = ref.watch(notaVozProvider(widget.visitaId));
    final notaCtrl = ref.read(notaVozProvider(widget.visitaId).notifier);

    ref.listen(complementoProvider(widget.visitaId), (_, _) => _alFinal());

    return Scaffold(
      appBar: const AppBarMarca(titulo: 'Complementar la visita'),
      body: Column(
        children: [
          if (estado.error != null)
            Banda(
              texto: estado.error!,
              icono: Icons.cloud_off,
              tono: TonoPildora.error,
              onCerrar: notifier.limpiarError,
            ),
          // La de la nota va aparte de la del chat: que no se pueda transcribir
          // por falta de señal no dice nada del turno anterior, y pisarlas
          // haria desaparecer el error que si importa.
          if (nota.error != null)
            Banda(
              texto: nota.error!,
              icono: Icons.mic_off,
              tono: TonoPildora.error,
              onCerrar: notaCtrl.limpiarError,
            ),
          Expanded(
            child: estado.mensajes.isEmpty
                ? _Bienvenida(visitaId: widget.visitaId)
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    itemCount:
                        estado.mensajes.length + (estado.esperando ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i >= estado.mensajes.length) {
                        return const _Escribiendo();
                      }
                      final mensaje = estado.mensajes[i];
                      // El aviso de lo guardado va pegado al ultimo mensaje
                      // del asistente, no al final de la lista: asi se lee
                      // como parte de esa respuesta y no como un resumen
                      // suelto que se puede pasar por alto.
                      final ultimo = i == estado.mensajes.length - 1;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Burbuja(mensaje: mensaje),
                          if (ultimo &&
                              !mensaje.esDelVisitador &&
                              estado.ultimoTurnoEscribio > 0)
                            _Guardado(cuantos: estado.ultimoTurnoEscribio),
                        ],
                      );
                    },
                  ),
          ),
          _Redactor(
            controlador: _controlador,
            habilitado: !estado.esperando,
            onEnviar: _enviar,
            nota: nota,
            onDictar: notaCtrl.iniciar,
            onListo: _cerrarNota,
            onDescartar: notaCtrl.descartar,
          ),
        ],
      ),
    );
  }
}

/// Para que sirve esto, y que le falta a esta visita.
///
/// Un chat en blanco no dice para que sirve. Y aca hace falta mas que en el
/// asistente de campo, porque lo que se escribe queda: el visitador tiene que
/// entrar sabiendo que esto no es una consulta.
class _Bienvenida extends ConsumerWidget {
  const _Bienvenida({required this.visitaId});

  final String visitaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final faltantes = ref.watch(faltantesProvider(visitaId)).valueOrNull ?? [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      children: [
        Icon(Icons.edit_note, size: 40, color: scheme.primary),
        const SizedBox(height: 14),
        Text(
          'Completa lo que quedo a medias',
          style: tema.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'Escribi —o dicta con el microfono— lo que falto de la '
          'conversacion y queda registrado en la visita. Tambien podes '
          'preguntar por lo que ya se registro.',
          style: tema.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 17, color: scheme.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  // No es un detalle legal: es la diferencia entre un dato que
                  // dijo el agricultor grabado y uno que recuerda el
                  // visitador. El sistema la marca sola, pero quien escribe
                  // tiene que saberla.
                  'Lo que escribas aca queda como dato tuyo, no del '
                  'agricultor: se guarda como «Estimado» y con la frase con '
                  'que lo dijiste.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (faltantes.isNotEmpty) ...[
          const SizedBox(height: 22),
          Text(
            'Lo que falta de esta visita',
            style: tema.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          // Las preguntas guia TEXTUALES del catalogo, no reescritas: es la
          // misma lista que ve el visitador en la pantalla de faltantes, y dos
          // redacciones distintas de la misma pregunta confunden.
          for (final c in faltantes.take(6))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // El icono del modulo en vez de una vineta: son seis
                  // preguntas sueltas de temas distintos, y el dibujo dice de
                  // cual es cada una sin tener que escribir el modulo delante.
                  Padding(
                    padding: const EdgeInsets.only(top: 2, right: 9),
                    child: Icon(
                      iconoDeModulo(c.modulo),
                      size: 16,
                      color: scheme.primary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      c.preguntaGuia ?? c.campo,
                      style: tema.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

/// Lo que quedo escrito en el turno.
///
/// Es lo que hace honesto el guardado directo: el dato ya esta en el registro
/// cuando esto aparece, asi que decirlo es la unica forma de que el visitador
/// pueda corregirlo antes de que suba.
class _Guardado extends StatelessWidget {
  const _Guardado({required this.cuantos});

  final int cuantos;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 48, 12),
      child: Row(
        children: [
          Icon(Icons.save_outlined, size: 15, color: tema.marca.exito),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              cuantos == 1
                  ? 'Se registro 1 dato en la visita'
                  : 'Se registraron $cuantos datos en la visita',
              style: TextStyle(
                fontSize: 12,
                color: tema.marca.exito,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Burbuja extends StatelessWidget {
  const _Burbuja({required this.mensaje});

  final MensajeChat mensaje;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final mio = mensaje.esDelVisitador;

    return Align(
      alignment: mio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
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
        child: Text(
          mensaje.contenido,
          style: TextStyle(
            fontSize: 14.5,
            height: 1.45,
            color: mio ? scheme.onPrimaryContainer : scheme.onSurface,
          ),
        ),
      ),
    );
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
          borderRadius: BorderRadius.circular(16),
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
    required this.nota,
    required this.onDictar,
    required this.onListo,
    required this.onDescartar,
  });

  final TextEditingController controlador;
  final bool habilitado;
  final VoidCallback onEnviar;

  final NotaVozState nota;
  final VoidCallback onDictar;
  final VoidCallback onListo;
  final VoidCallback onDescartar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
        // Mientras se dicta, la barra REEMPLAZA al campo de escribir. Con el
        // telefono en la mano y el sol encima, un boton rojo grande que dice
        // «listo» se acierta; un icono mas en una fila de tres, no.
        child: nota.grabando
            ? _BarraNota(
                segundos: nota.segundos,
                onListo: onListo,
                onDescartar: onDescartar,
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: controlador,
                      enabled: habilitado && !nota.transcribiendo,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => onEnviar(),
                      decoration: InputDecoration(
                        hintText: nota.transcribiendo
                            ? 'Pasando la nota a texto...'
                            : 'Lo que falto de la visita...',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _BotonDictar(
                    transcribiendo: nota.transcribiendo,
                    onDictar: habilitado && !nota.transcribiendo
                        ? onDictar
                        : null,
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    onPressed:
                        habilitado && !nota.transcribiendo ? onEnviar : null,
                    icon: const Icon(Icons.send),
                    style: IconButton.styleFrom(
                      backgroundColor: scheme.primary,
                      minimumSize: const Size(48, 48),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _BotonDictar extends StatelessWidget {
  const _BotonDictar({required this.transcribiendo, required this.onDictar});

  final bool transcribiendo;
  final VoidCallback? onDictar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (transcribiendo) {
      return const SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return IconButton.filledTonal(
      onPressed: onDictar,
      icon: const Icon(Icons.mic),
      tooltip: 'Dictar',
      style: IconButton.styleFrom(
        backgroundColor: scheme.surfaceContainerHighest,
        minimumSize: const Size(48, 48),
      ),
    );
  }
}

/// Lo que se ve mientras se dicta: que se esta grabando, cuanto lleva, y las
/// dos salidas.
class _BarraNota extends StatelessWidget {
  const _BarraNota({
    required this.segundos,
    required this.onListo,
    required this.onDescartar,
  });

  final int segundos;
  final VoidCallback onListo;
  final VoidCallback onDescartar;

  String get _reloj {
    final m = (segundos ~/ 60).toString();
    final s = (segundos % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;

    return Row(
      children: [
        IconButton(
          onPressed: onDescartar,
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Descartar la nota',
          color: scheme.onSurfaceVariant,
        ),
        Expanded(
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Icon(Icons.mic, size: 18, color: scheme.error),
                const SizedBox(width: 10),
                Text(
                  _reloj,
                  style: tema.textTheme.titleSmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Grabando la nota',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: scheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: onListo,
          icon: const Icon(Icons.check),
          tooltip: 'Listo',
          style: IconButton.styleFrom(
            backgroundColor: scheme.primary,
            minimumSize: const Size(48, 48),
          ),
        ),
      ],
    );
  }
}
