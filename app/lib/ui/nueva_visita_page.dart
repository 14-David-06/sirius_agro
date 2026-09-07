import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../core/config.dart';
import '../core/ubicacion.dart';
import '../data/db/app_database.dart';
import '../data/sesion_repository.dart';
import '../state/providers.dart';
import '../state/red.dart';
import '../state/sesion.dart';
import 'consentimiento_page.dart';
import 'marca.dart';
import 'theme.dart';

/// Lo unico que se le pide al visitador antes de empezar a conversar.
///
/// Deliberadamente corto: el resto de los datos salen de la conversacion, no
/// de un formulario. Si esta pantalla crece, el producto se convirtio en la
/// encuesta que estaba tratando de reemplazar.
class NuevaVisitaPage extends ConsumerStatefulWidget {
  const NuevaVisitaPage({super.key});

  @override
  ConsumerState<NuevaVisitaPage> createState() => _NuevaVisitaPageState();
}

class _NuevaVisitaPageState extends ConsumerState<NuevaVisitaPage> {
  final _nombreProductor = TextEditingController();
  final _nombreFinca = TextEditingController();
  final _focoProductor = FocusNode();

  String? _veredaId;
  Position? _posicion;
  String? _errorGps;
  bool _buscandoGps = false;
  bool _creando = false;

  /// El agricultor que el visitador reconocio en el directorio. Mientras sea
  /// null la visita crea una persona nueva; cuando tiene algo, se cuelga de la
  /// ficha que ya existe en vez de duplicarla.
  Productor? _elegido;

  /// Cuantos agricultores hay en el espejo local y si el ultimo intento de
  /// refrescarlo funciono. Se dice en pantalla: que no aparezca el que se
  /// busca tiene dos causas muy distintas y se arreglan distinto.
  int _conocidos = 0;
  bool _bajandoDirectorio = false;
  bool _directorioAlDia = false;

  @override
  void initState() {
    super.initState();
    _ubicar();
    _contarConocidos();
    _refrescarDirectorio();
  }

  @override
  void dispose() {
    _nombreProductor.dispose();
    _nombreFinca.dispose();
    _focoProductor.dispose();
    super.dispose();
  }

  Future<void> _contarConocidos() async {
    final cuantos = await ref.read(repoProvider).cuantosProductoresConocidos();
    if (mounted) setState(() => _conocidos = cuantos);
  }

  /// Baja de Airtable los agricultores ya registrados y los guarda en la base
  /// local.
  ///
  /// Todo lo que puede salir mal aca —sin senal, servidor caido, APK sin
  /// llave— termina igual: se sigue con lo que ya hay en el telefono. Esta
  /// pantalla existe para registrar una visita en una finca sin cobertura; un
  /// autocompletado no puede ser lo que la detenga.
  Future<void> _refrescarDirectorio() async {
    if (!AppConfig.isConfigured) return;
    if (ref.read(redProvider) == EstadoRed.sinRed) return;

    setState(() => _bajandoDirectorio = true);
    try {
      final remotos = await ref.read(apiProvider).productoresRegistrados();
      await ref.read(repoProvider).refrescarDirectorioProductores(remotos);
      if (mounted) setState(() => _directorioAlDia = true);
      await _contarConocidos();
    } catch (_) {
      // A proposito sin mensaje de error: el visitador no puede hacer nada al
      // respecto y lo unico que necesita saber —que la lista es la que tenia
      // el telefono— ya se lo dice la linea de abajo del campo.
      if (mounted) setState(() => _directorioAlDia = false);
    } finally {
      if (mounted) setState(() => _bajandoDirectorio = false);
    }
  }

  /// Deja de dar por reconocido al agricultor en cuanto el nombre deja de ser
  /// el suyo. Sin esto, corregir el nombre despues de elegirlo colgaria la
  /// visita de la persona equivocada.
  void _nombreCambio(String texto) {
    final elegido = _elegido;
    if (elegido != null && texto.trim() != elegido.nombreCompleto) {
      _elegido = null;
    }
    setState(() {});
  }

  /// El GPS se pide solo al abrir la pantalla, no con un boton: llegar a la
  /// finca ES el momento de tomar la coordenada. Si falla, la visita se crea
  /// igual — una visita sin coordenada sirve; no poder registrarla, no.
  Future<void> _ubicar() async {
    setState(() {
      _buscandoGps = true;
      _errorGps = null;
    });

    try {
      // El permiso y el timeout viven en `core/ubicacion.dart`: los comparte
      // con la captura de trazados, que pide coordenadas cada pocos segundos.
      final pos = await ubicacionActual(precision: LocationAccuracy.high);
      if (mounted) setState(() => _posicion = pos);
    } catch (e) {
      if (mounted) setState(() => _errorGps = '$e');
    } finally {
      if (mounted) setState(() => _buscandoGps = false);
    }
  }

  bool get _listo =>
      _nombreProductor.text.trim().isNotEmpty && _veredaId != null;

  Future<void> _crear() async {
    if (!_listo || _creando) return;
    setState(() => _creando = true);

    try {
      // Quien hace la visita es quien inicio sesion. Ya no se elige de una
      // lista de 18: eso era un parche por no tener login, y dejaba que una
      // visita quedara firmada por alguien que no estaba ahi.
      final visitador = await ref.read(visitadorSesionProvider.future);

      final repo = ref.read(repoProvider);
      final visitaId = await repo.crearVisitaConProductor(
        inicio: DateTime.now(),
        visitadorLocalId: visitador?.id,
        nombreProductor: _nombreProductor.text.trim(),
        // Si se reconocio en el directorio, la visita se cuelga de esa ficha:
        // es la diferencia entre la segunda visita de don Pedro y un segundo
        // don Pedro.
        productorLocalId: _elegido?.id,
        nombreFinca: _nombreFinca.text.trim().isEmpty
            ? null
            : _nombreFinca.text.trim(),
        veredaLocalId: _veredaId,
        latitud: _posicion?.latitude,
        longitud: _posicion?.longitude,
        precisionGps: _posicion?.accuracy,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ConsentimientoPage(visitaId: visitaId),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _creando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo crear la visita: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final veredas = ref.watch(veredasProvider);
    final sesion = ref.watch(sesionProvider).valueOrNull;

    return Scaffold(
      appBar: const AppBarMarca(titulo: 'Nueva visita'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          const TituloSeccion('Quien y donde'),
          // La visita queda firmada por quien inicio sesion. No se elige de
          // una lista: elegir permitia que una visita saliera a nombre de
          // alguien que no estaba en la finca.
          if (sesion != null) _QuienVisita(sesion: sesion),
          const SizedBox(height: 20),
          _TarjetaGps(
            posicion: _posicion,
            buscando: _buscandoGps,
            error: _errorGps,
            onReintentar: _ubicar,
          ),
          const SizedBox(height: 28),
          const TituloSeccion('El productor'),
          _CampoProductor(
            controller: _nombreProductor,
            foco: _focoProductor,
            buscar: (texto) =>
                ref.read(repoProvider).buscarProductores(texto),
            onElegido: (p) => setState(() {
              _elegido = p;
              _nombreProductor.text = p.nombreCompleto;
            }),
            onCambio: _nombreCambio,
          ),
          const SizedBox(height: 8),
          _EstadoDirectorio(
            conocidos: _conocidos,
            bajando: _bajandoDirectorio,
            alDia: _directorioAlDia,
            onReintentar: _refrescarDirectorio,
          ),
          if (_elegido != null) ...[
            const SizedBox(height: 12),
            _FichaReconocida(
              productor: _elegido!,
              onDescartar: () => setState(() => _elegido = null),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _nombreFinca,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nombre de la finca (opcional)',
              helperText: 'Si no lo sabe todavia, saldra en la conversacion.',
            ),
          ),
          const SizedBox(height: 16),
          switch (veredas) {
            AsyncData(value: final lista) => DropdownButtonFormField<String>(
                initialValue: _veredaId,
                decoration: const InputDecoration(labelText: 'Vereda'),
                items: [
                  for (final v in lista)
                    DropdownMenuItem(
                      value: v.id,
                      child: Text('${v.vereda} · ${v.municipio}'),
                    ),
                ],
                onChanged: (v) => setState(() => _veredaId = v),
              ),
            AsyncError(:final error) => Text('No se pudo cargar veredas: $error'),
            _ => const LinearProgressIndicator(),
          },
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _listo && !_creando ? _crear : null,
            icon: _creando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.arrow_forward),
            label: const Text('Continuar al consentimiento'),
          ),
          const SizedBox(height: 12),
          Text(
            'Antes de grabar hay que pedirle permiso al productor. '
            'Es el siguiente paso y no se puede saltar.',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaGps extends StatelessWidget {
  const _TarjetaGps({
    required this.posicion,
    required this.buscando,
    required this.error,
    required this.onReintentar,
  });

  final Position? posicion;
  final bool buscando;
  final String? error;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final (icono, titulo, detalle) = switch ((buscando, posicion, error)) {
      (true, _, _) => (
          Icons.gps_not_fixed,
          'Buscando ubicacion...',
          'Puede tardar en zona abierta.',
        ),
      (_, final Position p, _) => (
          Icons.gps_fixed,
          'Ubicacion tomada',
          '${p.latitude.toStringAsFixed(5)}, '
              '${p.longitude.toStringAsFixed(5)} '
              '(±${p.accuracy.round()} m)',
        ),
      (_, _, final String e) => (
          Icons.gps_off,
          'Sin ubicacion',
          '$e La visita se puede crear igual.',
        ),
      _ => (Icons.gps_not_fixed, 'Sin ubicacion', 'Toca para reintentar.'),
    };

    final tema = Theme.of(context);
    final color = switch ((buscando, posicion)) {
      (true, _) => scheme.onSurfaceVariant,
      (_, final Position _) => tema.marca.exito,
      _ => tema.marca.aviso,
    };

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
        leading: buscando
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Icon(icono, color: color),
        title: Text(titulo, style: tema.textTheme.titleMedium),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(detalle),
        ),
        trailing: buscando
            ? null
            : IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: onReintentar,
                tooltip: 'Reintentar',
              ),
      ),
    );
  }
}

/// Quien esta haciendo la visita. Es informativo y no se puede cambiar aca:
/// para visitar como otra persona hay que cerrar sesion y entrar como ella,
/// que es exactamente la friccion que se quiere.
class _QuienVisita extends StatelessWidget {
  const _QuienVisita({required this.sesion});

  final SesionActiva sesion;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final credencial = sesion.credencial;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          child: Text(
            _iniciales(credencial.nombre),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
        title: Text(credencial.nombre, style: tema.textTheme.titleMedium),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text('${credencial.rolApp} · ${credencial.idEmpleado}'),
        ),
      ),
    );
  }

  String _iniciales(String nombre) {
    final partes =
        nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return (partes.first[0] + partes.last[0]).toUpperCase();
  }
}


/// El nombre del productor, con los que ya estan registrados a la mano.
///
/// Es un campo de texto con sugerencias, no un selector: el 100% del tiempo
/// se puede escribir un nombre que no esta en ninguna lista y seguir. Las
/// sugerencias salen de la base local —el directorio se baja aparte cuando
/// hay senal— asi que en una vereda sin cobertura siguen apareciendo los que
/// este telefono ya visito.
class _CampoProductor extends StatelessWidget {
  const _CampoProductor({
    required this.controller,
    required this.foco,
    required this.buscar,
    required this.onElegido,
    required this.onCambio,
  });

  final TextEditingController controller;
  final FocusNode foco;
  final Future<List<Productor>> Function(String) buscar;
  final ValueChanged<Productor> onElegido;
  final ValueChanged<String> onCambio;

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<Productor>(
      textEditingController: controller,
      focusNode: foco,
      displayStringForOption: (p) => p.nombreCompleto,
      optionsBuilder: (valor) async {
        final texto = valor.text.trim();
        // Con una sola letra media vereda coincide y la lista tapa el
        // formulario sin ayudar a nadie.
        if (texto.length < 2) return const Iterable<Productor>.empty();
        return buscar(texto);
      },
      onSelected: onElegido,
      fieldViewBuilder: (context, controlador, nodo, onSubmit) => TextField(
        controller: controlador,
        focusNode: nodo,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        decoration: const InputDecoration(
          labelText: 'Nombre del productor',
          helperText: 'Como se presento. Si ya lo visitaron, aparece abajo.',
          helperMaxLines: 2,
          prefixIcon: Icon(Icons.person_search_outlined),
        ),
        onChanged: onCambio,
        onSubmitted: (_) => onSubmit(),
      ),
      optionsViewBuilder: (context, elegir, opciones) {
        final tema = Theme.of(context);
        return Align(
          alignment: Alignment.topLeft,
          child: Padding(
            // El ancho de la lista se ata al del formulario, no al de la
            // pantalla: pegada al borde se ve como si fuera otra cosa.
            padding: const EdgeInsets.only(right: 32),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: opciones.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final p = opciones.elementAt(i);
                    return ListTile(
                      leading: _CaraProductor(productor: p),
                      title: Text(p.nombreCompleto),
                      subtitle: Text(
                        _senasDe(p),
                        style: tema.textTheme.bodySmall,
                      ),
                      onTap: () => elegir(p),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Lo que distingue a este agricultor de otro con el mismo nombre.
String _senasDe(Productor p) {
  final senas = [
    if ((p.documento ?? '').trim().isNotEmpty)
      '${p.tipoDocumento ?? 'CC'} ${p.documento}',
    if ((p.telefono ?? '').trim().isNotEmpty) p.telefono!,
    if ((p.codigoProductor ?? '').trim().isNotEmpty) p.codigoProductor!,
  ];
  // Sin documento ni telefono no hay como distinguirlo, y decirlo es mas util
  // que dejar la linea vacia: es la senal de que esa ficha esta a medias.
  return senas.isEmpty ? 'Sin documento ni telefono registrados' : senas.join(' · ');
}

/// La cara del agricultor en la lista: primero la del telefono, si no la
/// miniatura de Airtable, y si no las iniciales. Nunca un hueco.
class _CaraProductor extends StatelessWidget {
  const _CaraProductor({required this.productor});

  final Productor productor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final local = productor.fotoPath;
    final remota = productor.fotoRemota;

    ImageProvider? imagen;
    if (local != null && local.isNotEmpty && File(local).existsSync()) {
      imagen = FileImage(File(local));
    } else if (remota != null && remota.isNotEmpty) {
      // Puede fallar: la URL de Airtable caduca y en la finca puede no haber
      // red. `onBackgroundImageError` deja las iniciales debajo.
      imagen = NetworkImage(remota);
    }

    return CircleAvatar(
      backgroundColor: scheme.surfaceContainerHighest,
      foregroundColor: scheme.onSurfaceVariant,
      backgroundImage: imagen,
      onBackgroundImageError: imagen == null ? null : (_, _) {},
      child: imagen == null ? Text(_iniciales(productor.nombreCompleto)) : null,
    );
  }
}

String _iniciales(String nombre) {
  final partes = nombre.trim().split(RegExp(r'\s+'));
  final letras = partes.take(2).map((p) => p.characters.first.toUpperCase());
  return letras.join();
}

/// De donde salen las sugerencias, dicho sin rodeos.
///
/// Importa porque las dos razones por las que un agricultor no aparece se
/// arreglan distinto: si el directorio esta al dia, es que no esta registrado
/// y hay que crearlo; si no se pudo bajar, puede estar registrado y este
/// telefono no lo sabe todavia.
class _EstadoDirectorio extends StatelessWidget {
  const _EstadoDirectorio({
    required this.conocidos,
    required this.bajando,
    required this.alDia,
    required this.onReintentar,
  });

  final int conocidos;
  final bool bajando;
  final bool alDia;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final estilo = tema.textTheme.bodySmall?.copyWith(
      color: tema.colorScheme.onSurfaceVariant,
      height: 1.35,
    );

    if (bajando) {
      return Row(
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Trayendo los agricultores registrados...', style: estilo),
          ),
        ],
      );
    }

    if (alDia) {
      return Text(
        conocidos == 0
            ? 'Todavia no hay agricultores registrados. Este seria el primero.'
            : '$conocidos agricultores registrados. Si el que esta al frente '
                'no aparece, se escribe el nombre y listo.',
        style: estilo,
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.cloud_off_outlined,
            size: 14, color: tema.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            conocidos == 0
                ? 'Sin conexion: no hay lista contra que comparar. Se escribe '
                    'el nombre y la visita sigue igual.'
                : 'Sin conexion: solo aparecen los $conocidos que ya estan en '
                    'este telefono. Se puede registrar uno nuevo igual.',
            style: estilo,
          ),
        ),
        TextButton(
          onPressed: onReintentar,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('Reintentar'),
        ),
      ],
    );
  }
}

/// El agricultor quedo reconocido: esta visita es su segunda, no la primera de
/// alguien que se llama igual.
class _FichaReconocida extends StatelessWidget {
  const _FichaReconocida({required this.productor, required this.onDescartar});

  final Productor productor;
  final VoidCallback onDescartar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Card(
      color: tema.marca.exitoSuave,
      child: ListTile(
        leading: _CaraProductor(productor: productor),
        title: Text(
          'Ya esta registrado',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: tema.marca.exito,
          ),
        ),
        subtitle: Text(
          '${productor.nombreCompleto} · ${_senasDe(productor)}\n'
          'La visita se guarda como seguimiento y no hay que volver a llenar '
          'su ficha.',
          style: const TextStyle(fontSize: 12, height: 1.35),
        ),
        isThreeLine: true,
        trailing: IconButton(
          tooltip: 'No es el',
          icon: const Icon(Icons.close),
          onPressed: onDescartar,
        ),
      ),
    );
  }
}
