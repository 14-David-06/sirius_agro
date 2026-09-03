import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/servicio_grabacion.dart';
import '../data/db/app_database.dart';
import '../state/grabacion.dart';
import '../state/providers.dart';
import '../state/sincronizador.dart';
import 'consentimiento_page.dart';
import 'marca.dart';
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final visitaId = widget.visitaId;
    final visita = ref.watch(visitaProvider(visitaId)).valueOrNull;
    final grabacion = ref.watch(grabacionProvider(visitaId));
    final ctrl = ref.read(grabacionProvider(visitaId).notifier);

    return Scaffold(
      appBar: AppBarMarca(
        titulo: 'Visita en curso',
        actions: [
          if (visita != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: _Completitud(pct: visita.completitudPct),
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
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      _PanelGrabacion(
                        visitaId: visitaId,
                        estado: grabacion,
                        puedeGrabar: visita.consienteAudio,
                        onIniciar: ctrl.iniciar,
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
                      const SizedBox(height: 28),
                      const TituloSeccion('Evidencia'),
                      SeccionFotos(visitaId: visitaId, visita: visita),
                      const SizedBox(height: 10),
                      SeccionProcesar(visitaId: visitaId),
                      const SizedBox(height: 28),
                      const TituloSeccion('Entregable'),
                      SeccionInforme(visitaId: visitaId),
                      const SizedBox(height: 28),
                      const TituloSeccion('Cobertura de la conversacion'),
                      _Faltantes(visitaId: visitaId),
                      const SizedBox(height: 28),
                      _EstadoSync(visitaId: visitaId),
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

class _Completitud extends StatelessWidget {
  const _Completitud({required this.pct});

  final int pct;

  @override
  Widget build(BuildContext context) {
    final color = AnilloCompletitud.colorDe(context, pct);
    return Row(
      children: [
        AnilloCompletitud(pct: pct, diametro: 20, grosor: 3),
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
