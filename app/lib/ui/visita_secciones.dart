import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../core/geo.dart';
import '../core/informe_tecnico.dart';
import '../core/ubicacion.dart';
import '../data/db/app_database.dart';
import '../data/nombres_archivo.dart';
import '../data/visita_repository.dart';
import '../state/informe.dart';
import '../state/informe_tecnico.dart';
import '../state/procesador.dart';
import '../state/providers.dart';
import '../state/trazado.dart';
import 'agricultor_page.dart';
import 'camara_page.dart';
import 'complemento_page.dart';
import 'galeria_fotos.dart';
import 'informe_page.dart';
import 'marca.dart';
import 'theme.dart';
import 'trazado_page.dart';
import 'visita_page.dart';

/// Quien es el agricultor, con su cara y lo que le falta a su ficha.
///
/// Aparece en la visita porque es el unico momento en que la persona esta
/// enfrente: un dato de identidad no se puede completar despues desde la
/// oficina. Y no interrumpe —igual que el resto de la pantalla, se abre a
/// proposito— pero SI avisa: mientras el agricultor no tenga documento, el
/// backend no puede distinguirlo de otro con el mismo nombre en la misma
/// vereda, y las fincas de los dos terminan en una sola ficha.
///
/// Cuando la ficha ya esta completa, la tarjeta se calla: queda como un
/// renglon con la foto y el nombre, para confirmar a quien se esta visitando.
class SeccionAgricultor extends ConsumerWidget {
  const SeccionAgricultor({
    super.key,
    required this.visitaId,
    required this.visita,
  });

  final String visitaId;
  final Visita visita;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final productor =
        ref.watch(productorDeVisitaProvider(visitaId)).valueOrNull;
    final faltan = faltantesDeAgricultor(productor);
    final completa = faltan.isEmpty;

    return Card(
      color: completa ? null : tema.marca.avisoSuave,
      shape: completa
          ? null
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: tema.marca.aviso.withValues(alpha: 0.3),
              ),
            ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AgricultorPage(visitaId: visitaId)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _Avatar(fotoPath: productor?.fotoPath),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productor?.nombreCompleto ?? 'Sin agricultor',
                      style: tema.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      completa
                          ? [
                              if (productor?.tipoDocumento != null)
                                '${productor!.tipoDocumento} ${productor.documento}'
                              else
                                productor!.documento!,
                              productor.telefono!,
                            ].join(' · ')
                          // Se nombra lo que falta, no «ficha incompleta»: el
                          // visitador tiene que saber que preguntar sin abrir
                          // la pantalla.
                          : 'Falta ${faltan.join(', ')}',
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: completa
                            ? scheme.onSurfaceVariant
                            : tema.marca.aviso,
                        fontWeight:
                            completa ? FontWeight.w400 : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (completa)
                const Icon(Icons.chevron_right)
              else
                FilledButton.tonal(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AgricultorPage(visitaId: visitaId),
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Completar'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// La cara del agricultor, o la silueta mientras no hay foto.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.fotoPath});

  final String? fotoPath;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final archivo = fotoPath == null ? null : File(fotoPath!);
    final tiene = archivo != null && archivo.existsSync();

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.surfaceContainerHighest,
        border: Border.all(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: tiene
          ? Image.file(
              archivo,
              fit: BoxFit.cover,
              // La ruta es siempre la misma (`perfil.jpg`), asi que sin la
              // marca de tiempo se seguiria viendo el retrato reemplazado.
              key: ValueKey(archivo.lastModifiedSync()),
              cacheWidth: 156,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) =>
                  Icon(Icons.person_outline, color: scheme.outline),
            )
          : Icon(Icons.person_outline, size: 26, color: scheme.outline),
    );
  }
}

/// Fotos durante la conversacion, sin detener la grabacion.
class SeccionFotos extends ConsumerWidget {
  const SeccionFotos({super.key, required this.visitaId, required this.visita});

  final String visitaId;
  final Visita visita;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final fotos = ref.watch(evidenciasProvider(visitaId)).valueOrNull ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.photo_camera_outlined, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fotos', style: tema.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        fotos.isEmpty
                            ? 'Cultivo, suelo y etiquetas'
                            : '${fotos.length} tomada(s)',
                        style: tema.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  // El consentimiento de fotos gobierna la camara, igual que
                  // el de audio gobierna el grabador. Cada permiso lo suyo.
                  onPressed: visita.consienteFotos
                      ? () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CamaraPage(visitaId: visitaId),
                            ),
                          )
                      : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Tomar'),
                ),
              ],
            ),
            // Igual que con el audio: el permiso de fotos se puede volver a
            // pedir sin abandonar la visita.
            if (!visita.consienteFotos)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'El productor no autorizo las fotos.',
                        style: TextStyle(fontSize: 12.5, color: scheme.error),
                      ),
                    ),
                    TextButton(
                      onPressed: () => pedirPermisoDeNuevo(context, visitaId),
                      child: const Text('Pedir permiso'),
                    ),
                  ],
                ),
              ),
            // Las fotos mismas, no una lista de metadatos: el visitador tiene
            // que poder confirmar que la foto salio bien sin salir de la
            // visita. Cada miniatura lleva encima el segundo del audio, que es
            // lo que permite volver a lo que se hablaba cuando se tomo.
            if (fotos.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: GrillaFotos(fotos: fotos),
              ),
          ],
        ),
      ),
    );
  }
}

/// Lo que le faltaba a la app: hacer algo con el audio.
///
/// Transcribe cada tramo y extrae los hallazgos. Cada paso se salta si ya
/// esta hecho, asi que reintentar despues de un fallo retoma donde quedo en
/// vez de volver a pagar la transcripcion de un tramo ya transcrito.
class SeccionProcesar extends ConsumerWidget {
  const SeccionProcesar({super.key, required this.visitaId});

  final String visitaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final estado = ref.watch(procesadorProvider(visitaId));
    final ctrl = ref.read(procesadorProvider(visitaId).notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              // Arriba y no al centro: el titulo puede irse a dos lineas y el
              // icono flotando en la mitad se ve accidental.
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    estado.fallo
                        ? Icons.error_outline
                        : Icons.auto_awesome_outlined,
                    color: estado.fallo ? scheme.error : scheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Procesar la conversacion',
                        style: tema.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        estado.mensaje.isEmpty
                            ? 'Transcribe el audio y extrae los datos. Necesita senal.'
                            : estado.mensaje,
                        style: tema.textTheme.bodySmall?.copyWith(
                          color: estado.fallo
                              ? scheme.error
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (estado.trabajando)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  )
                else
                  FilledButton.tonal(
                    onPressed: ctrl.procesar,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(estado.fallo ? 'Reintentar' : 'Procesar'),
                  ),
              ],
            ),
            if (estado.pasos.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              for (final paso in estado.pasos)
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        switch (paso.estado) {
                          EstadoPaso.listo => Icons.check_circle,
                          EstadoPaso.fallo => Icons.cancel,
                          EstadoPaso.enCurso => Icons.more_horiz,
                        },
                        size: 16,
                        color: switch (paso.estado) {
                          EstadoPaso.listo => tema.marca.exito,
                          EstadoPaso.fallo => scheme.error,
                          EstadoPaso.enCurso => scheme.outline,
                        },
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          paso.detalle,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            color: paso.estado == EstadoPaso.fallo
                                ? scheme.error
                                : scheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Los lotes y recorridos de la visita.
///
/// Existe porque el area dicha en la conversacion no se puede usar para nada
/// que importe: «unas diez hectareas» no calcula una dosis, no compara dos
/// visitas y no entra en un mapa. Caminar el contorno si, y el telefono ya
/// tiene el GPS.
///
/// La tarjeta lista lo capturado con su medida y abre la pantalla donde se
/// captura. Un lote o un recorrido exigen esa pantalla completa, porque se
/// hacen caminando y mirando el croquis; el punto suelto no, y por eso tiene
/// su boton aca mismo.
class SeccionTrazados extends ConsumerStatefulWidget {
  const SeccionTrazados({super.key, required this.visitaId});

  final String visitaId;

  @override
  ConsumerState<SeccionTrazados> createState() => _SeccionTrazadosState();
}

class _SeccionTrazadosState extends ConsumerState<SeccionTrazados> {
  bool _marcando = false;

  String get visitaId => widget.visitaId;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final trazados = ref.watch(trazadosProvider(visitaId)).valueOrNull ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(Icons.map_outlined, color: scheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lotes y recorridos',
                        style: tema.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        trazados.isEmpty
                            ? 'Camina el contorno del cultivo y sale un KML.'
                            : '${trazados.length} trazado(s) capturado(s)',
                        style: tema.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.tonal(
                  onPressed: () => _nuevo(context, ref),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Nuevo'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Un solo toque, sin formulario y sin cambiar de pantalla: el
            // visitador esta parado donde pasa la cosa —el foco de plaga, la
            // entrada del lote, el punto de agua— y lo que necesita es dejar
            // la marca antes de seguir caminando.
            FilledButton.icon(
              onPressed: _marcando ? null : _marcarPunto,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _marcando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: Text(
                _marcando ? 'Buscando la coordenada...' : 'Marcar punto aca',
              ),
            ),
            if (trazados.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              for (final t in trazados)
                _FilaTrazado(visitaId: visitaId, trazado: t),
            ],
          ],
        ),
      ),
    );
  }

  /// Guarda la coordenada de donde esta parado el visitador, sin preguntar
  /// nada.
  ///
  /// Cada toque deja un trazado propio de tipo punto —«Punto 1», «Punto 2»—
  /// en vez de acumular puntos dentro de uno solo. No es capricho del modelo:
  /// en el KML un trazado de tipo punto sale como UNA marca, asi que varios
  /// puntos metidos en el mismo trazado se perderian todos menos el primero.
  /// Separados, cada marca llega a Google Earth con su hora y su precision.
  Future<void> _marcarPunto() async {
    if (_marcando) return;
    setState(() => _marcando = true);

    try {
      final pos = await ubicacionActual();

      final repo = ref.read(trazadoRepoProvider);
      final id = await repo.crearTrazado(
        visitaId: visitaId,
        tipo: TipoTrazado.punto,
        cerrado: false,
      );
      await repo.agregarPunto(
        trazadoId: id,
        latitud: pos.latitude,
        longitud: pos.longitude,
        altitud: pos.altitude,
        precisionM: pos.accuracy,
      );

      final trazado = await repo.porId(id);
      if (!mounted) return;
      setState(() => _marcando = false);

      final coordenada = '${pos.latitude.toStringAsFixed(6)}, '
          '${pos.longitude.toStringAsFixed(6)}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${trazado?.nombre ?? 'Punto'} guardado · $coordenada '
            '(±${pos.accuracy.round()} m)',
          ),
          action: SnackBarAction(
            label: 'Renombrar',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TrazadoPage(visitaId: visitaId, trazadoId: id),
              ),
            ),
          ),
        ),
      );
    } on ErrorUbicacion catch (e) {
      if (!mounted) return;
      setState(() => _marcando = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.mensaje)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _marcando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo tomar la coordenada: $e')),
      );
    }
  }

  /// Crea el trazado y entra derecho a la pantalla de captura: el visitador
  /// toco «Nuevo» porque esta parado en el lote, no para administrar una lista.
  Future<void> _nuevo(BuildContext context, WidgetRef ref) async {
    final ficha = await mostrarFichaTrazado(context);
    if (ficha == null) return;

    final id = await ref.read(trazadoRepoProvider).crearTrazado(
          visitaId: visitaId,
          nombre: ficha.nombre,
          tipo: ficha.tipo,
          etiqueta: ficha.etiqueta,
          notas: ficha.notas,
          // Los valores con los que arranca el automatico si se prende. Son
          // sugerencias, no reglas: los tres chips de la pantalla los cambian.
          intervaloSeg: 10,
          distanciaMinM: 5,
        );

    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TrazadoPage(visitaId: visitaId, trazadoId: id),
      ),
    );
  }
}

class _FilaTrazado extends ConsumerWidget {
  const _FilaTrazado({required this.visitaId, required this.trazado});

  final String visitaId;
  final Trazado trazado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final puntos =
        ref.watch(puntosTrazadoProvider(trazado.id)).valueOrNull ?? [];
    // El reloj de un trazado NO se detiene al salir de su pantalla: el
    // visitador se va a la camara a fotografiar la mancha en las hojas y el
    // recorrido tiene que seguir. Pero eso hay que decirlo aca, o queda un
    // GPS corriendo que nadie ve.
    final capturando = ref.watch(capturaProvider(trazado.id)).capturando;
    final anillo = trazado.tipo.esPoligono && trazado.cerrado;
    final geos = [for (final p in puntos) PuntoGeo(p.latitud, p.longitud)];

    final medida = anillo && geos.length >= 3
        ? formatearArea(areaM2(geos))
        : geos.length > 1
            ? formatearDistancia(longitudMetros(geos, cerrado: anillo))
            : 'sin medida';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      dense: true,
      leading: Icon(
        switch (trazado.tipo) {
          TipoTrazado.poligono => Icons.crop_square,
          TipoTrazado.ruta => Icons.polyline,
          TipoTrazado.punto => Icons.place_outlined,
        },
        color: puntos.isEmpty ? scheme.outline : tema.marca.exito,
      ),
      title: Text(trazado.nombre, style: tema.textTheme.bodyLarge),
      subtitle: Text(
        [
          '${puntos.length} punto(s)',
          medida,
          if (trazado.etiqueta != null) trazado.etiqueta!,
          // Un poligono sin cerrar se avisa aca: en el KML sale como linea y
          // quien lo abra no va a ver un lote.
          if (trazado.tipo.esPoligono && !trazado.cerrado) 'sin cerrar',
        ].join(' · '),
        style: const TextStyle(fontSize: 11.5),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (capturando)
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Pildora(
                texto: 'Capturando',
                tono: TonoPildora.error,
                icono: Icons.timer_outlined,
              ),
            ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TrazadoPage(
            visitaId: visitaId,
            trazadoId: trazado.id,
          ),
        ),
      ),
    );
  }
}

/// El botón que cumple lo que se le prometió al productor en el
/// consentimiento: "con eso le armo un informe de su finca y se lo entrego".
///
/// Necesita señal y no se encola: el visitador lo pide para leérselo antes de
/// irse de la finca, y un informe que llega tres días después ya no es eso.
class SeccionInforme extends ConsumerWidget {
  const SeccionInforme({super.key, required this.visitaId});

  final String visitaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final estado = ref.watch(informeProvider(visitaId));
    // Solo los del productor: desde que existe el informe tecnico, una visita
    // tiene informes de dos tipos en la misma tabla, y cada tarjeta lista su
    // propia serie de versiones.
    final informes = [
      for (final i in ref.watch(informesProvider(visitaId)).valueOrNull ?? [])
        if (i.tipo != tipoInformeTecnico) i,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.description_outlined,
                    color: estado.error != null ? scheme.error : scheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informe para el productor',
                        style: tema.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        estado.error ??
                            (informes.isEmpty
                                ? 'Se arma con la conversacion. Necesita senal.'
                                : '${informes.length} generado(s)'),
                        style: tema.textTheme.bodySmall?.copyWith(
                          color: estado.error != null
                              ? scheme.error
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: estado.trabajando
                    ? null
                    : () async {
                        final informe = await ref
                            .read(informeProvider(visitaId).notifier)
                            .generar();
                        if (informe != null && context.mounted) {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => InformePage(informe: informe),
                            ),
                          );
                        }
                      },
                icon: estado.trabajando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(informes.isEmpty ? Icons.auto_stories : Icons.refresh),
                label: Text(
                  estado.trabajando
                      ? 'Escribiendo el informe...'
                      : informes.isEmpty
                          ? 'Generar informe'
                          : 'Generar de nuevo',
                ),
              ),
            ),
            // Los anteriores no se borran: si el nuevo sale peor, el que ya se
            // le mostro al productor sigue estando.
            if (informes.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              for (final i in informes)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  dense: true,
                  leading: Icon(
                    i.entregado ? Icons.mark_email_read_outlined : Icons.article_outlined,
                    color: i.entregado ? tema.marca.exito : scheme.onSurfaceVariant,
                  ),
                  title: Text('Version ${i.version}', style: tema.textTheme.bodyLarge),
                  subtitle: Text(
                    DateFormat("d 'de' MMMM, h:mm a", 'es').format(i.generadoEn),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => InformePage(informe: i)),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// El informe tecnico de la visita: el documento de la empresa.
///
/// Es una tarjeta aparte de la del productor y no un boton mas dentro de
/// ella, porque son dos entregables distintos con dos destinatarios distintos.
/// Y porque este no necesita senal: se arma con lo que ya esta en el telefono,
/// asi que el boton funciona igual en la finca que en la oficina — mientras el
/// del productor espera a que haya una barra para poder llamar al modelo.
class SeccionInformeTecnico extends ConsumerWidget {
  const SeccionInformeTecnico({super.key, required this.visitaId});

  final String visitaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final estado = ref.watch(informeTecnicoProvider(visitaId));
    final informes = [
      for (final i in ref.watch(informesProvider(visitaId)).valueOrNull ?? [])
        if (i.tipo == tipoInformeTecnico) i,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.fact_check_outlined,
                    color: estado.error != null ? scheme.error : scheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informe tecnico (empresa)',
                        style: tema.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        estado.error ??
                            (informes.isEmpty
                                ? 'Coordenadas, areas medidas y datos '
                                    'ordenados. No necesita senal.'
                                : '${informes.length} generado(s)'),
                        style: tema.textTheme.bodySmall?.copyWith(
                          color: estado.error != null
                              ? scheme.error
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: estado.trabajando
                    ? null
                    : () => _generar(context, ref),
                icon: estado.trabajando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(informes.isEmpty ? Icons.table_chart_outlined
                        : Icons.refresh),
                label: Text(
                  estado.trabajando
                      ? 'Armando el informe...'
                      : informes.isEmpty
                          ? 'Generar informe tecnico'
                          : 'Generar de nuevo',
                ),
              ),
            ),
            if (informes.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              for (final i in informes)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  dense: true,
                  leading: Icon(
                    Icons.description_outlined,
                    color: scheme.onSurfaceVariant,
                  ),
                  title: Text(
                    'Version ${i.version}',
                    style: tema.textTheme.bodyLarge,
                  ),
                  subtitle: Text(
                    DateFormat("d 'de' MMMM, h:mm a", 'es').format(i.generadoEn),
                  ),
                  // Compartir e imprimir, sin pantalla intermedia: el
                  // documento es una cuadricula de tablas y leerlo en el
                  // telefono no sirve de nada. Se archiva, se manda o se
                  // imprime.
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.share_outlined),
                        tooltip: 'Compartir el PDF',
                        onPressed: () => _compartir(context, ref, i),
                      ),
                      IconButton(
                        icon: const Icon(Icons.print_outlined),
                        tooltip: 'Imprimir',
                        onPressed: () => _imprimir(context, ref, i),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _generar(BuildContext context, WidgetRef ref) async {
    final mensajero = ScaffoldMessenger.of(context);
    final resultado =
        await ref.read(informeTecnicoProvider(visitaId).notifier).generar();
    if (resultado == null) return;

    mensajero.showSnackBar(
      SnackBar(
        content: Text(
          'Informe tecnico version ${resultado.informe.version} archivado. '
          'Sube cuando haya senal.',
        ),
      ),
    );
  }

  Future<void> _compartir(
    BuildContext context,
    WidgetRef ref,
    Informe informe,
  ) async {
    final mensajero = ScaffoldMessenger.of(context);
    final caja = context.findRenderObject() as RenderBox?;
    try {
      final archivado = await ref
          .read(informeTecnicoProvider(visitaId).notifier)
          .pdfArchivado(informe);

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              archivado.pdf,
              mimeType: 'application/pdf',
              name: await _nombreArchivo(ref, informe),
            ),
          ],
          subject: informe.titulo,
          sharePositionOrigin:
              caja == null ? null : caja.localToGlobal(Offset.zero) & caja.size,
        ),
      );

      if (archivado.rearmado) {
        mensajero.showSnackBar(
          const SnackBar(
            content: Text(
              'El PDF ya no estaba en el telefono: se volvio a armar con los '
              'datos de hoy.',
            ),
          ),
        );
      }
    } catch (e) {
      mensajero.showSnackBar(
        SnackBar(content: Text('No se pudo armar el PDF: $e')),
      );
    }
  }

  Future<void> _imprimir(
    BuildContext context,
    WidgetRef ref,
    Informe informe,
  ) async {
    final mensajero = ScaffoldMessenger.of(context);
    try {
      final archivado = await ref
          .read(informeTecnicoProvider(visitaId).notifier)
          .pdfArchivado(informe);
      await Printing.layoutPdf(
        onLayout: (_) async => archivado.pdf,
        name: await _nombreArchivo(ref, informe),
      );
    } catch (e) {
      mensajero.showSnackBar(
        SnackBar(content: Text('No se pudo armar el PDF: $e')),
      );
    }
  }

  /// `visita-don-pedro-2026-09-03-tecnico-v1.pdf`: con quien y cuando, no con
  /// el codigo de la visita.
  ///
  /// En el telefono y en el bucket el archivo se sigue llamando
  /// `informe-tecnico-01.pdf` —ese nombre es el contrato con el backend, que
  /// renombra por categoria y version— pero el que sale por WhatsApp o a la
  /// impresora lleva el nombre del productor: es el unico que se busca a mano.
  /// La version se conserva en el sufijo porque dos informes tecnicos de la
  /// misma visita el mismo dia son documentos distintos.
  Future<String> _nombreArchivo(WidgetRef ref, Informe informe) async {
    final ctx = await ref.read(repoProvider).contextoInforme(visitaId);
    return nombreArchivoInforme(
      productor: ctx['productor'] as String?,
      finca: ctx['finca'] as String?,
      fecha: DateTime.tryParse(ctx['fecha'] as String? ?? '') ??
          informe.generadoEn,
      sufijo: '-tecnico-v${informe.version}',
    );
  }
}

/// Las fotos de una visita traida de Airtable.
///
/// Se ven y se abren, pero no hay boton de camara: sobre un espejo no se toman
/// fotos. La tarjeta normal no sirve porque encola subidas, y un espejo no
/// sube nunca.
class SeccionFotosSoloLectura extends ConsumerWidget {
  const SeccionFotosSoloLectura({super.key, required this.visitaId});

  final String visitaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final todas = ref.watch(evidenciasProvider(visitaId)).valueOrNull ?? [];
    // Las que de verdad se pueden abrir. Una evidencia sin archivo local
    // conserva lo que se anoto de ella, pero no es una miniatura: ponerla en
    // la grilla era el icono de imagen rota que no explicaba nada.
    final fotos = [for (final f in todas) if (f.archivoPath.isNotEmpty) f];
    final sinArchivo = todas.length - fotos.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.photo_library_outlined, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    todas.isEmpty
                        ? 'Esta visita no tiene fotos'
                        : '${fotos.length} foto(s) de la visita',
                    style: tema.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            if (sinArchivo > 0) ...[
              const SizedBox(height: 10),
              Text(
                sinArchivo == 1
                    ? 'A 1 foto no se le pudo bajar la imagen. Vuelve a abrir '
                        'la visita con señal para reintentarlo.'
                    : 'A $sinArchivo fotos no se les pudo bajar la imagen. '
                        'Vuelve a abrir la visita con señal para reintentarlo.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (fotos.isNotEmpty) ...[
              const SizedBox(height: 14),
              GrillaFotos(fotos: fotos),
            ],
          ],
        ),
      ),
    );
  }
}

/// Los informes de una visita traida de Airtable.
///
/// Se leen; no se generan. Generar uno aqui encolaria la visita —
/// `guardarInforme` lo hace— y un espejo no puede subir a Airtable: se
/// reescribiria el registro de otro visitador con lo que este telefono
/// alcanzo a bajar.
class InformesSoloLectura extends ConsumerWidget {
  const InformesSoloLectura({super.key, required this.visitaId});

  final String visitaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final informes = ref.watch(informesProvider(visitaId)).valueOrNull ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.description_outlined, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    informes.isEmpty
                        ? 'Esta visita no tiene informes'
                        : 'Informes de esta visita',
                    style: tema.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            if (informes.isNotEmpty)
              for (final i in informes)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  dense: true,
                  leading: Icon(
                    Icons.article_outlined,
                    color: scheme.onSurfaceVariant,
                  ),
                  title: Text(i.tipo, style: tema.textTheme.bodyLarge),
                  subtitle: Text(
                    'Version ${i.version} · '
                    '${DateFormat("d 'de' MMMM 'de' y", 'es').format(i.generadoEn)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => InformePage(informe: i)),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// Completar la visita conversando con la IA.
///
/// Va en «Entregable» y no junto a la grabacion a proposito: se usa DESPUES,
/// cuando el visitador ya salio de la finca y se acuerda de lo que no alcanzo
/// a preguntar, o cuando el informe salio con huecos.
///
/// Es la unica tarjeta de la app que escribe datos sin pasar por el audio, y
/// la unica que lo dice en su propio subtitulo.
class SeccionComplemento extends ConsumerWidget {
  const SeccionComplemento({super.key, required this.visitaId});

  final String visitaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final faltan = ref.watch(faltantesProvider(visitaId)).valueOrNull ?? [];
    final guardada = ref.watch(conversacionComplementoProvider(visitaId));
    final hilo = guardada.valueOrNull;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ComplementoPage(visitaId: visitaId),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(Icons.edit_note, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Complementar la visita',
                      style: tema.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      // Lo que falta se nombra con numero: «faltan 12 datos»
                      // le dice al visitador si vale la pena abrirlo, y
                      // «completa» le dice que no.
                      hilo != null
                          ? 'Ya hay una conversacion guardada'
                          : faltan.isEmpty
                              ? 'Escribi lo que quedo a medias y queda registrado'
                              : 'Faltan ${faltan.length} dato(s). Escribilos y '
                                  'quedan registrados',
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
