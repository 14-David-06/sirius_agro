import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/iconos_modulo.dart';
import '../core/servicio_grabacion.dart';
import '../data/db/app_database.dart';
import '../state/grabacion.dart';
import '../state/historial.dart';
import '../state/providers.dart';
import '../state/sincronizador.dart';
import 'consentimiento_page.dart';
import 'marca.dart';
import 'nueva_visita_page.dart';
import 'reproductor_audio.dart';
import 'theme.dart';
import 'visita_secciones.dart';

/// La pantalla que el visitador tiene abierta mientras conversa.
///
/// Regla de diseno: no interrumpe. No hay notificaciones, ni sonidos, ni
/// vibracion, ni preguntas que salten a mitad de la charla. El semaforo esta
/// ahi para quien quiera mirarlo, y la lista de faltantes se abre a proposito.
/// El telefono deberia poder quedar boca abajo sobre la mesa.
class VisitaPage extends ConsumerStatefulWidget {
  const VisitaPage({super.key, required this.visitaId});

  final String visitaId;

  @override
  ConsumerState<VisitaPage> createState() => _VisitaPageState();
}

class _VisitaPageState extends ConsumerState<VisitaPage> {
  @override
  void initState() {
    super.initState();
    // Los permisos se piden al abrir la visita, no al tocar grabar: pedirle
    // permiso de notificaciones al visitador justo cuando el productor ya
    // esta hablando es la peor forma de arrancar una conversacion.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ServicioGrabacion.pedirPermisos();
      // De una visita de Airtable la lista solo tiene la ficha. El detalle
      // —hallazgos, fotos, audio, informes— se baja aqui, al abrirla: es
      // cuando alguien lo va a mirar, y es lo que evita que el refresco
      // automatico de la lista arrastre cientos de megas por si acaso.
      ref.read(historialProvider.notifier).asegurarDetalle(widget.visitaId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final visitaId = widget.visitaId;
    final visita = ref.watch(visitaProvider(visitaId)).valueOrNull;
    final grabacion = ref.watch(grabacionProvider(visitaId));
    final historial = ref.watch(historialProvider);
    final bajando = historial.trabajando;
    final ctrl = ref.read(grabacionProvider(visitaId).notifier);
    final numero = ref.watch(numeroVisitaProvider(visitaId)).valueOrNull;

    return Scaffold(
      appBar: AppBarMarca(
        titulo: numero == null ? 'Visita en curso' : 'Visita $numero',
        actions: [
          if (visita != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: _Completitud(
                  pct: visita.completitudPct,
                  visitaId: visitaId,
                ),
              ),
            ),
        ],
      ),
      body: visita == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (grabacion.error != null)
                  Banda(
                    texto: grabacion.error!,
                    icono: Icons.error_outline,
                    tono: TonoPildora.error,
                  ),
                if (grabacion.aviso != null)
                  Banda(
                    texto: grabacion.aviso!,
                    icono: Icons.info_outline,
                    onCerrar: ctrl.limpiarAviso,
                  ),
                // Una visita traida de Airtable se consulta y nada mas. La
                // banda va arriba del todo porque lo primero que hay que saber
                // de esta pantalla es que aqui no se registra: quien llegue
                // creyendo que esta en una visita propia y empiece a hablar
                // sin grabar pierde la conversacion.
                if (visita.soloLectura)
                  Banda(
                    texto: bajando
                        // Sin esto, una visita recien traida del indice se ve
                        // vacia mientras baja, y vacia es indistinguible de
                        // «no se registro nada».
                        ? (historial.paso.isEmpty
                            ? 'Bajando la visita completa...'
                            : historial.paso)
                        : 'Visita de consulta, traida de Airtable. No se '
                            'puede grabar ni corregir: se ve como quedo.',
                    icono: bajando
                        ? Icons.cloud_download_outlined
                        : Icons.cloud_done_outlined,
                  ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      // Una visita de otro dia ya paso. Lo que se converse hoy
                      // con la misma persona es otra visita, con su fecha y su
                      // numero: si se grabara aqui, el audio de hoy quedaria
                      // archivado con la fecha de la vez anterior.
                      if (visita.soloLectura || !esDeHoy(visita.inicio)) ...[
                        _TarjetaSeguimiento(visita: visita),
                        const SizedBox(height: 20),
                      ],
                      if (!visita.soloLectura)
                      _PanelGrabacion(
                        visitaId: visitaId,
                        estado: grabacion,
                        puedeGrabar: visita.consienteAudio,
                        onIniciar: () =>
                            _iniciarGrabacion(context, ref, visita, ctrl),
                        onPausa: ctrl.alternarPausa,
                        onDetener: () async {
                          final ok = await ctrl.detener();
                          if (ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Grabacion cerrada y encolada.'),
                              ),
                            );
                          }
                        },
                      ),
                      if (!visita.soloLectura) const SizedBox(height: 28),
                      // Antes que la evidencia y el terreno: es la unica
                      // seccion que depende de que la persona este enfrente.
                      // Un dato de identidad no se completa desde la oficina.
                      const TituloSeccion('El agricultor'),
                      SeccionAgricultor(visitaId: visitaId, visita: visita),
                      const SizedBox(height: 28),
                      const TituloSeccion('Evidencia'),
                      // En un espejo las fotos se ven pero no se toman, y no
                      // hay nada que procesar: la conversacion ya se proceso en
                      // el telefono que la grabo.
                      if (visita.soloLectura) ...[
                        SeccionFotosSoloLectura(visitaId: visitaId),
                        const SizedBox(height: 10),
                        // La conversacion es lo que no se puede resumir: un
                        // espejo sin con que oirla deja fuera lo unico que el
                        // informe no reemplaza.
                        SeccionAudioSoloLectura(visitaId: visitaId),
                      ] else ...[
                        SeccionFotos(visitaId: visitaId, visita: visita),
                        const SizedBox(height: 10),
                        SeccionProcesar(visitaId: visitaId),
                      ],
                      // Antes del terreno y del entregable: subir es lo que
                      // cierra la visita, y el visitador lo busca apenas queda
                      // senal. Abajo del todo solo lo encontraba quien bajaba
                      // hasta el final.
                      const SizedBox(height: 28),
                      _EstadoSync(visitaId: visitaId),
                      if (!visita.soloLectura) ...[
                        const SizedBox(height: 28),
                        const TituloSeccion('El terreno'),
                        SeccionTrazados(visitaId: visitaId),
                      ],
                      const SizedBox(height: 28),
                      const TituloSeccion('Cobertura de la conversacion'),
                      _ResueltosAntes(visitaId: visitaId),
                      _Faltantes(visitaId: visitaId),
                      const SizedBox(height: 28),
                      const TituloSeccion('Entregable'),
                      // Los informes de un espejo se leen; generar uno nuevo
                      // no: `guardarInforme` encola la visita, y un espejo no
                      // sube nunca.
                      if (visita.soloLectura)
                        InformesSoloLectura(visitaId: visitaId)
                      else ...[
                        SeccionInforme(visitaId: visitaId),
                        const SizedBox(height: 10),
                        SeccionInformeTecnico(visitaId: visitaId),
                        const SizedBox(height: 10),
                        // Despues de los informes: se usa cuando el visitador
                        // ya salio de la finca y ve los huecos que quedaron.
                        SeccionComplemento(visitaId: visitaId),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

/// Abre el consentimiento otra vez sobre la visita que ya existe. Vive aca y
/// no dentro de un boton porque la piden dos pantallas: el panel de grabacion
/// y la tarjeta de fotos.
Future<void> pedirPermisoDeNuevo(BuildContext context, String visitaId) async {
  final ok = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => ConsentimientoPage.revisar(visitaId: visitaId),
    ),
  );
  if (ok == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Permiso actualizado.')),
    );
  }
}

/// Si [fecha] cae hoy, en la hora del telefono.
bool esDeHoy(DateTime fecha, {DateTime? ahora}) {
  final hoy = ahora ?? DateTime.now();
  final f = fecha.toLocal();
  return f.year == hoy.year && f.month == hoy.month && f.day == hoy.day;
}

String _fechaLarga(DateTime fecha) =>
    DateFormat("EEEE d 'de' MMMM 'de' y", 'es').format(fecha.toLocal());

/// Abre la visita de seguimiento: la pantalla de nueva visita, llena con el
/// agricultor, la finca y la vereda de [visita].
///
/// No crea nada por su cuenta. La visita nueva necesita el GPS de hoy y el
/// consentimiento de hoy, y los dos se piden en el flujo de siempre: el
/// permiso de grabar se da en cada visita, no una vez para todas.
Future<void> abrirSeguimiento(
  BuildContext context,
  WidgetRef ref,
  Visita visita,
) async {
  final repo = ref.read(repoProvider);
  final productor = await repo.productorDeVisita(visita.id);
  final finca = await repo.fincaDeVisita(visita.id);
  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => NuevaVisitaPage(
        seguimientoDe: productor,
        nombreFinca: finca?.nombre,
        veredaId: visita.veredaLocalId,
      ),
    ),
  );
}

enum _GrabarEn { seguimiento, estaVisita }

/// El boton de grabar, con una pregunta antes cuando la visita es de otro dia.
///
/// No se bloquea: puede haber una razon para seguir en la visita vieja (una
/// conversacion que cruzo la medianoche). Pero la opcion por defecto es la
/// visita de seguimiento, que es lo que casi siempre paso: el visitador volvio
/// a la finca y abrio la visita anterior para «seguir».
Future<void> _iniciarGrabacion(
  BuildContext context,
  WidgetRef ref,
  Visita visita,
  GrabacionController ctrl,
) async {
  if (!esDeHoy(visita.inicio)) {
    final fecha = _fechaLarga(visita.inicio);
    final eleccion = await showDialog<_GrabarEn>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Esta visita es de otro dia'),
        content: Text(
          'Se hizo el $fecha. Si hoy volvio a reunirse con el agricultor, '
          'registrelo como visita de seguimiento: queda con la fecha de hoy, '
          'con el numero siguiente, y solo le pide lo que falto.\n\n'
          'Si graba aqui, el audio de hoy queda dentro de la visita del '
          '$fecha.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(_GrabarEn.estaVisita),
            child: const Text('Grabar en esta'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(_GrabarEn.seguimiento),
            child: const Text('Visita de seguimiento'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    switch (eleccion) {
      case _GrabarEn.seguimiento:
        await abrirSeguimiento(context, ref, visita);
        return;
      case _GrabarEn.estaVisita:
        break;
      case null:
        // Cerro el dialogo sin elegir: no se graba nada.
        return;
    }
  }
  await ctrl.iniciar();
}

/// La salida para cuando se vuelve a ver al agricultor: una visita nueva, con
/// su fecha y su numero, en vez de seguir escribiendo sobre la anterior.
class _TarjetaSeguimiento extends ConsumerWidget {
  const _TarjetaSeguimiento({required this.visita});

  final Visita visita;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final productor =
        ref.watch(productorDeVisitaProvider(visita.id)).valueOrNull;
    final nombre = productor?.nombreCompleto ?? 'el agricultor';

    return Card(
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.event_repeat, size: 20, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Si vuelve a reunirse con $nombre',
                    style: tema.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Esta visita fue el ${_fechaLarga(visita.inicio)}. Lo de hoy '
              'va en una visita de seguimiento: queda con la fecha de hoy, '
              'con el numero siguiente, y solo pide lo que falto.',
              style: tema.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => abrirSeguimiento(context, ref, visita),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nueva visita de seguimiento'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lo que ya se sabia del agricultor antes de esta visita. Sin esta linea, un
/// seguimiento que arranca en 60% parece un error.
class _ResueltosAntes extends ConsumerWidget {
  const _ResueltosAntes({required this.visitaId});

  final String visitaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cuantos = ref.watch(resueltosAntesProvider(visitaId)).valueOrNull ?? 0;
    if (cuantos == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Text(
        cuantos == 1
            ? '1 tema ya se resolvio en visitas anteriores de este '
                'agricultor. Aqui solo sale lo que falta.'
            : '$cuantos temas ya se resolvieron en visitas anteriores de '
                'este agricultor. Aqui solo sale lo que falta.',
        style: TextStyle(
          fontSize: 12.5,
          height: 1.35,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Cuanto falta para que se cierre el tramo actual. Se muestra para que el
/// visitador sepa, si algo se cae, cuanto es lo maximo que puede perder.
String _restanteTramo(GrabacionState estado) {
  final faltan = duracionTramo.inSeconds - estado.segundosTramo;
  if (faltan <= 0) return 'un momento';
  final m = faltan ~/ 60;
  final s = faltan % 60;
  return m > 0 ? '$m:${s.toString().padLeft(2, '0')}' : '$s s';
}

/// El reloj y los controles viven en la misma tarjeta: es LA pieza de la
/// pantalla y tiene que leerse de un vistazo, con el telefono en la mano y
/// sin dejar de mirar al productor.
class _PanelGrabacion extends StatelessWidget {
  const _PanelGrabacion({
    required this.visitaId,
    required this.estado,
    required this.puedeGrabar,
    required this.onIniciar,
    required this.onPausa,
    required this.onDetener,
  });

  final String visitaId;
  final GrabacionState estado;
  final bool puedeGrabar;
  final VoidCallback onIniciar;
  final VoidCallback onPausa;
  final VoidCallback onDetener;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final activo = estado.grabando && !estado.pausada;

    return Card(
      color: activo ? scheme.primaryContainer : scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        child: Column(
          children: [
            _Estado(estado: estado),
            const SizedBox(height: 14),
            Text(
              formatDuration(estado.segundos),
              style: tema.textTheme.displaySmall?.copyWith(
                fontSize: 60,
                fontWeight: FontWeight.w300,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: activo
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              ),
            ),
            if (estado.grabando) ...[
              const SizedBox(height: 14),
              _Proteccion(estado: estado),
              const SizedBox(height: 8),
              Text(
                'El audio se guarda cada ${duracionTramo.inMinutes} min. '
                'Faltan ${_restanteTramo(estado)} para el proximo guardado.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.35,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 22),
            _Controles(
              visitaId: visitaId,
              estado: estado,
              puedeGrabar: puedeGrabar,
              onIniciar: onIniciar,
              onPausa: onPausa,
              onDetener: onDetener,
            ),
          ],
        ),
      ),
    );
  }
}

/// La linea de estado: punto rojo latiendo mientras corre, texto que dice en
/// que tramo va. Es lo que responde "¿esto esta grabando o no?".
class _Estado extends StatelessWidget {
  const _Estado({required this.estado});

  final GrabacionState estado;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activo = estado.grabando && !estado.pausada;

    final (color, texto) = switch ((estado.grabando, estado.pausada)) {
      (true, false) => (scheme.error, 'Grabando · tramo ${estado.tramo}'),
      (true, true) => (
          Theme.of(context).marca.aviso,
          'En pausa · tramo ${estado.tramo}',
        ),
      _ when estado.tramo > 0 => (
          Theme.of(context).marca.exito,
          '${estado.tramo} tramo(s) guardado(s)',
        ),
      _ => (scheme.outline, 'Sin grabar'),
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Punto(color: color, latiendo: activo),
        const SizedBox(width: 8),
        Text(
          texto,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Late solo mientras se graba. Es la unica animacion de la pantalla: todo lo
/// demas esta quieto para no robarle atencion a la conversacion.
class _Punto extends StatefulWidget {
  const _Punto({required this.color, required this.latiendo});

  final Color color;
  final bool latiendo;

  @override
  State<_Punto> createState() => _PuntoState();
}

class _PuntoState extends State<_Punto> with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    if (widget.latiendo) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_Punto viejo) {
    super.didUpdateWidget(viejo);
    if (widget.latiendo && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.latiendo && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.value = 1;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.latiendo
          ? Tween(begin: 0.25, end: 1.0).animate(_ctrl)
          : const AlwaysStoppedAnimation(1),
      child: Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}

/// El visitador tiene que poder confirmar de un vistazo que el audio va a
/// sobrevivir a la pantalla apagada. Si el servicio no arranco, se dice, no
/// se esconde.
class _Proteccion extends StatelessWidget {
  const _Proteccion({required this.estado});

  final GrabacionState estado;

  @override
  Widget build(BuildContext context) {
    return estado.servicioActivo
        ? const Pildora(
            texto: 'Sigue grabando con la pantalla apagada',
            tono: TonoPildora.exito,
            icono: Icons.shield_outlined,
          )
        : const Pildora(
            texto: 'Sin servicio: no apagues la pantalla',
            tono: TonoPildora.error,
            icono: Icons.warning_amber_rounded,
          );
  }
}

class _Controles extends StatelessWidget {
  const _Controles({
    required this.visitaId,
    required this.estado,
    required this.puedeGrabar,
    required this.onIniciar,
    required this.onPausa,
    required this.onDetener,
  });

  final String visitaId;
  final GrabacionState estado;
  final bool puedeGrabar;
  final VoidCallback onIniciar;
  final VoidCallback onPausa;
  final VoidCallback onDetener;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (!estado.grabando) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              // El candado del consentimiento: sin permiso de audio el boton
              // simplemente no funciona. La regla vive en el dato, no aqui.
              onPressed: puedeGrabar ? onIniciar : null,
              icon: const Icon(Icons.fiber_manual_record, size: 18),
              label: Text(
                estado.tramo == 0 ? 'Empezar a grabar' : 'Seguir grabando',
              ),
            ),
          ),
          // Un "no" al principio no deberia costar la visita entera: si el
          // productor cambia de opinion, el permiso se vuelve a pedir aca
          // mismo, sin salir ni crear una visita nueva.
          if (!puedeGrabar) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'El productor no autorizo la grabacion.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: scheme.error),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => pedirPermisoDeNuevo(context, visitaId),
                icon: const Icon(Icons.replay, size: 18),
                label: const Text('Volver a pedirle el permiso'),
              ),
            ),
          ],
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPausa,
            icon: Icon(estado.pausada ? Icons.play_arrow : Icons.pause),
            label: Text(estado.pausada ? 'Reanudar' : 'Pausar'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: onDetener,
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            icon: const Icon(Icons.stop),
            label: const Text('Terminar'),
          ),
        ),
      ],
    );
  }
}

/// Los obligatorios que la conversacion todavia no resolvio, con la pregunta
/// guia tal como esta escrita en el catalogo. La app no la reescribe: si el
/// visitador la lee de corrido, tiene que sonar como una pregunta de verdad.
class _Faltantes extends ConsumerWidget {
  const _Faltantes({required this.visitaId});

  final String visitaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final faltantes = ref.watch(faltantesProvider(visitaId));

    return switch (faltantes) {
      AsyncData(value: final lista) when lista.isEmpty => Card(
          color: tema.marca.exitoSuave,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: tema.marca.exito.withValues(alpha: 0.25)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: Icon(Icons.task_alt, color: tema.marca.exito),
            title: Text(
              'No queda nada obligatorio por preguntar',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: tema.marca.exito,
              ),
            ),
          ),
        ),
      AsyncData(value: final lista) => Card(
          child: ExpansionTile(
            leading: Icon(
              Icons.checklist_rtl,
              color: tema.colorScheme.primary,
            ),
            title: Text(
              'Faltan ${lista.length} temas',
              style: tema.textTheme.titleMedium,
            ),
            subtitle: const Text('Toca para ver las preguntas'),
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: const EdgeInsets.only(bottom: 8),
            children: [
              for (final grupo in _porModulo(lista).entries) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
                  // El icono delante del nombre: la lista de faltantes se lee
                  // de arriba abajo buscando un tema concreto, y el dibujo se
                  // encuentra antes que once letras en versalitas.
                  child: Row(
                    children: [
                      Icon(
                        iconoDeModulo(grupo.key),
                        size: 15,
                        color: tema.colorScheme.primary,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          grupo.key.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10.5,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w700,
                            color: tema.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                for (final campo in grupo.value)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 5, 16, 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 7, right: 10),
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: tema.colorScheme.outline,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            campo.preguntaGuia ?? campo.campo,
                            style: tema.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      AsyncError(:final error) => Card(
          child: ListTile(
            leading: Icon(
              Icons.error_outline,
              color: tema.colorScheme.error,
            ),
            title: Text('No se pudieron calcular los faltantes: $error'),
          ),
        ),
      _ => const Card(
          child: ListTile(title: Text('Calculando faltantes...')),
        ),
    };
  }

  Map<String, List<CatalogoCampo>> _porModulo(List<CatalogoCampo> lista) {
    final mapa = <String, List<CatalogoCampo>>{};
    for (final c in lista) {
      mapa.putIfAbsent(c.modulo, () => []).add(c);
    }
    return mapa;
  }
}

/// Estado de sincronizacion honesto: que falta, cuantos MB y por que fallo.
/// Un spinner indefinido no le sirve a alguien que esta a una hora del pueblo.
class _EstadoSync extends ConsumerWidget {
  const _EstadoSync({required this.visitaId});

  final String visitaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final pendientes =
        ref.watch(pendientesSyncProvider(visitaId)).valueOrNull ?? [];
    final visita = ref.watch(visitaProvider(visitaId)).valueOrNull;
    final sincronizada = visita?.sincronizada ?? false;

    // La tarjeta sigue visible cuando no queda nada por subir pero la visita
    // todavia no llego a Airtable: "sin cola" no es lo mismo que "guardada".
    if (pendientes.isEmpty && sincronizada) return const SizedBox.shrink();

    final estado = ref.watch(sincronizacionProvider(visitaId));
    final mb = pendientes.fold<int>(0, (a, i) => a + i.bytesTotales) / 1048576;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TituloSeccion('Envio a Airtable'),
        Card(
          child: ExpansionTile(
            leading: Icon(Icons.cloud_upload_outlined, color: scheme.primary),
            title: Text(
              pendientes.isEmpty
                  ? 'Sin subir'
                  : '${pendientes.length} por subir',
              style: tema.textTheme.titleMedium,
            ),
            subtitle: Text(
              estado.mensaje.isNotEmpty
                  ? estado.mensaje
                  : '${mb.toStringAsFixed(1)} MB en cola',
            ),
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            initiallyExpanded: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: estado.trabajando
                        ? null
                        : () async {
                            // Encola la visita entera antes de vaciar la cola:
                            // el audio y las fotos ya estan encolados desde que
                            // se capturaron, pero el upsert solo tiene sentido
                            // cuando el visitador decide que ya se puede
                            // mandar.
                            await ref
                                .read(repoProvider)
                                .encolarVisita(visitaId);
                            await ref
                                .read(sincronizacionProvider(visitaId).notifier)
                                .sincronizar(visitaId);
                          },
                    icon: estado.trabajando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload),
                    label: Text(
                      estado.trabajando ? 'Subiendo...' : 'Guardar en Airtable',
                    ),
                  ),
                ),
              ),
              for (final item in pendientes)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _ItemCola(item: item),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Una fila de la cola con su barra de progreso. Si fallo, el error se
/// muestra tal cual: es lo que le permite al visitador decidir si reintenta
/// ahi mismo o espera a llegar al pueblo.
class _ItemCola extends StatelessWidget {
  const _ItemCola({required this.item});

  final SyncItem item;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final fallo = item.ultimoError != null;
    final progreso = item.bytesTotales > 0
        ? item.bytesSubidos / item.bytesTotales
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.operacion,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (item.intentos > 0)
              Pildora(
                texto: '${item.intentos} intento(s)',
                tono: fallo ? TonoPildora.error : TonoPildora.neutro,
              ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progreso,
            minHeight: 5,
            color: fallo ? scheme.error : scheme.primary,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          item.ultimoError ??
              '${(item.bytesSubidos / 1024).round()} de '
                  '${(item.bytesTotales / 1024).round()} KB',
          style: TextStyle(
            fontSize: 11.5,
            height: 1.35,
            color: fallo ? scheme.error : scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Completitud extends ConsumerWidget {
  const _Completitud({required this.pct, required this.visitaId});

  final int pct;
  final String visitaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = AnilloCompletitud.colorDe(context, pct);
    final productor =
        ref.watch(productorDeVisitaProvider(visitaId)).valueOrNull;
    return Row(
      children: [
        // Un poco mas grande que antes: dentro del aro ahora va una cara, y a
        // 20 px no se distingue de una mancha.
        AnilloCompletitud(
          pct: pct,
          diametro: 30,
          grosor: 3,
          child: AvatarAgricultor(
            fotoPath: productor?.fotoPath,
            fotoRemota: productor?.fotoRemota,
            genero: productor?.genero,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$pct%',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: color,
          ),
        ),
      ],
    );
  }
}
