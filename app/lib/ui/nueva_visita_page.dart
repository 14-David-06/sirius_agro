import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../data/sesion_repository.dart';
import '../state/providers.dart';
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

  String? _veredaId;
  Position? _posicion;
  String? _errorGps;
  bool _buscandoGps = false;
  bool _creando = false;

  @override
  void initState() {
    super.initState();
    _ubicar();
  }

  @override
  void dispose() {
    _nombreProductor.dispose();
    _nombreFinca.dispose();
    super.dispose();
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
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        throw 'Sin permiso de ubicacion.';
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
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
          TextField(
            controller: _nombreProductor,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nombre del productor',
              helperText: 'Como se presento. Se puede corregir despues.',
            ),
            onChanged: (_) => setState(() {}),
          ),
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
