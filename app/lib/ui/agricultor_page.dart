import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/db/app_database.dart';
import '../data/visita_repository.dart';
import '../state/providers.dart';
import 'camara_page.dart';
import 'marca.dart';
import 'theme.dart';

/// Las opciones tal como estan escritas en los selects de Airtable. No hay
/// traduccion: lo que se elige aca es lo que entra al campo.
const _tiposDocumento = ['CC', 'CE', 'TI', 'NIT', 'Pasaporte', 'Sin documento'];
const _generos = ['Femenino', 'Masculino', 'Otro', 'Prefiere no decir'];
const _nivelesEducativos = [
  'Ninguno',
  'Primaria',
  'Bachillerato',
  'Tecnico o tecnologo',
  'Universitario',
  'Posgrado',
];

/// La ficha del agricultor: quien es, como se le vuelve a hablar y su cara.
///
/// Existe porque el resto del sistema da por hecho que el agricultor tiene
/// identidad y no la tiene: la visita lo crea con un nombre suelto, y con solo
/// el nombre el backend no puede distinguir dos personas que se llaman igual
/// en la misma vereda —termina fusionandolas y mezclando sus fincas.
///
/// Lo que NO es: un cuestionario. Solo estan los datos de la PERSONA, los que
/// no salen de la conversacion porque nadie los cuenta hablando de su finca:
/// el numero de documento, el telefono, la cara. Todo lo demas —cultivos,
/// suelos, riego, insumos— sigue saliendo del audio y viviendo en `Hallazgos`.
/// Si esta pantalla crece hacia alla, el producto volvio a ser la encuesta que
/// vino a reemplazar.
///
/// Se llena una vez en la vida del productor, no en cada visita: la segunda
/// visita ya lo encuentra con ficha y esta pantalla no se abre.
class AgricultorPage extends ConsumerStatefulWidget {
  const AgricultorPage({super.key, required this.visitaId});

  final String visitaId;

  @override
  ConsumerState<AgricultorPage> createState() => _AgricultorPageState();
}

class _AgricultorPageState extends ConsumerState<AgricultorPage> {
  final _nombre = TextEditingController();
  final _documento = TextEditingController();
  final _telefono = TextEditingController();
  final _telefonoAlterno = TextEditingController();
  final _experiencia = TextEditingController();
  final _personasHogar = TextEditingController();
  final _organizacion = TextEditingController();
  final _notas = TextEditingController();

  String? _tipoDocumento;
  String? _genero;
  String? _nivelEducativo;
  DateTime? _nacimiento;

  bool _cargado = false;
  bool _guardando = false;

  @override
  void dispose() {
    _nombre.dispose();
    _documento.dispose();
    _telefono.dispose();
    _telefonoAlterno.dispose();
    _experiencia.dispose();
    _personasHogar.dispose();
    _organizacion.dispose();
    _notas.dispose();
    super.dispose();
  }

  /// Los controladores se llenan UNA vez, con lo primero que llega del stream.
  /// Volver a escribirlos en cada emision le borraria al visitador lo que esta
  /// tecleando: guardar la foto actualiza el productor y reemite.
  void _cargarUnaVez(Productor p) {
    if (_cargado) return;
    _cargado = true;
    _nombre.text = p.nombreCompleto;
    _documento.text = p.documento ?? '';
    _telefono.text = p.telefono ?? '';
    _telefonoAlterno.text = p.telefonoAlterno ?? '';
    _experiencia.text = p.aniosExperiencia?.toString() ?? '';
    _personasHogar.text = p.personasHogar?.toString() ?? '';
    _organizacion.text = p.organizacion ?? '';
    _notas.text = p.notas ?? '';
    _tipoDocumento = p.tipoDocumento;
    _genero = p.genero;
    _nivelEducativo = p.nivelEducativo;
    _nacimiento = p.fechaNacimiento;
  }

  Future<void> _guardar() async {
    if (_guardando) return;
    setState(() => _guardando = true);

    try {
      await ref.read(repoProvider).guardarDatosAgricultor(
            visitaId: widget.visitaId,
            nombreCompleto: _nombre.text,
            documento: _documento.text,
            // Un numero de documento sin tipo no se sabe leer. Si el visitador
            // escribio el numero y no toco el selector, se asume la cedula:
            // es lo que tiene el 95% de la gente en una vereda, y el
            // coordinador lo corrige en Airtable si es otra cosa.
            tipoDocumento: _documento.text.trim().isEmpty
                ? _tipoDocumento
                : (_tipoDocumento ?? 'CC'),
            telefono: _telefono.text,
            telefonoAlterno: _telefonoAlterno.text,
            genero: _genero,
            fechaNacimiento: _nacimiento,
            nivelEducativo: _nivelEducativo,
            aniosExperiencia: int.tryParse(_experiencia.text.trim()),
            personasHogar: int.tryParse(_personasHogar.text.trim()),
            organizacion: _organizacion.text,
            notas: _notas.text,
          );

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ficha del agricultor guardada.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $e')),
      );
    }
  }

  Future<void> _elegirNacimiento() async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: _nacimiento ?? DateTime(hoy.year - 45),
      // Nadie que este trabajando su finca nacio antes de 1920, y un
      // agricultor menor de 14 anios seria otra conversacion.
      firstDate: DateTime(1920),
      lastDate: DateTime(hoy.year - 14, hoy.month, hoy.day),
      helpText: 'Fecha de nacimiento',
    );
    if (elegida != null) setState(() => _nacimiento = elegida);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final productor = ref.watch(productorDeVisitaProvider(widget.visitaId));
    final visita = ref.watch(visitaProvider(widget.visitaId)).valueOrNull;

    return Scaffold(
      appBar: const AppBarMarca(titulo: 'El agricultor'),
      body: switch (productor) {
        AsyncData(value: final p?) => _formulario(p, visita, tema),
        AsyncData() => const EstadoVacio(
            icono: Icons.person_off_outlined,
            titulo: 'Esta visita no tiene agricultor',
            detalle: 'Se creo sin productor, asi que no hay ficha que llenar.',
          ),
        AsyncError(:final error) => EstadoVacio(
            icono: Icons.error_outline,
            titulo: 'No se pudo abrir la ficha',
            detalle: '$error',
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Widget _formulario(Productor p, Visita? visita, ThemeData tema) {
    _cargarUnaVez(p);
    final faltan = faltantesDeAgricultor(p);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        _Retrato(
          productor: p,
          // La camara la gobierna el mismo permiso que las fotos de la
          // conversacion: una foto de la cara de alguien es una foto.
          puedeFotografiar: visita?.consienteFotos ?? false,
          visitaId: widget.visitaId,
        ),
        const SizedBox(height: 24),
        const TituloSeccion('Quien es'),
        TextField(
          controller: _nombre,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nombre completo',
            helperText: 'Nombres y apellidos, como aparecen en el documento.',
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 118,
              child: DropdownButtonFormField<String>(
                initialValue: _tipoDocumento,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: [
                  for (final t in _tiposDocumento)
                    DropdownMenuItem(value: t, child: Text(t)),
                ],
                onChanged: (v) => setState(() => _tipoDocumento = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _documento,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Documento',
                  // El por que, dicho en campo: no es burocracia, es lo que
                  // impide que dos agricultores se conviertan en uno.
                  helperText: 'Es lo que lo distingue de otro con el mismo '
                      'nombre.',
                  helperMaxLines: 2,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _telefono,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Telefono',
            helperText: 'Para avisarle de la proxima visita.',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 24),
        // Lo de abajo es opcional y se dice: son datos de la persona que a
        // veces se sabe y a veces no, y un campo vacio aca no rompe nada.
        Card(
          child: ExpansionTile(
            leading: Icon(Icons.more_horiz, color: tema.colorScheme.primary),
            title: Text('Mas datos', style: tema.textTheme.titleMedium),
            subtitle: const Text('Opcional. Solo si ya los sabe.'),
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              TextField(
                controller: _telefonoAlterno,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Otro telefono (de un familiar, del vecino)',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _genero,
                decoration: const InputDecoration(labelText: 'Genero'),
                items: [
                  for (final g in _generos)
                    DropdownMenuItem(value: g, child: Text(g)),
                ],
                onChanged: (v) => setState(() => _genero = v),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.cake_outlined),
                title: const Text('Fecha de nacimiento'),
                subtitle: Text(
                  _nacimiento == null
                      ? 'Sin registrar'
                      : DateFormat("d 'de' MMMM 'de' y", 'es')
                          .format(_nacimiento!),
                ),
                trailing: const Icon(Icons.edit_calendar_outlined),
                onTap: _elegirNacimiento,
              ),
              DropdownButtonFormField<String>(
                initialValue: _nivelEducativo,
                decoration: const InputDecoration(labelText: 'Nivel educativo'),
                items: [
                  for (final n in _nivelesEducativos)
                    DropdownMenuItem(value: n, child: Text(n)),
                ],
                onChanged: (v) => setState(() => _nivelEducativo = v),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _experiencia,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Anios trabajando la tierra',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _personasHogar,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Personas en el hogar',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _organizacion,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Asociacion a la que pertenece',
                  helperText: 'Vacio significa que no pertenece a ninguna.',
                  helperMaxLines: 2,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notas,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notas',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // La autorizacion de tratamiento no se pide aca: se pidio en el
        // consentimiento de la visita y se copia a la persona al guardar. Se
        // muestra para que quede claro con que permiso se esta escribiendo.
        _Autorizacion(productor: p, visita: visita),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _guardando ? null : _guardar,
          icon: _guardando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: Text(_guardando ? 'Guardando...' : 'Guardar la ficha'),
        ),
        const SizedBox(height: 12),
        Text(
          faltan.isEmpty
              ? 'La ficha esta completa. Sube con la visita.'
              : 'Todavia falta ${faltan.join(', ')}. Se puede guardar igual y '
                  'completarla despues.',
          style: TextStyle(
            fontSize: 12,
            height: 1.4,
            color: tema.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// La foto de perfil, grande y arriba: es lo primero que responde «es este».
class _Retrato extends ConsumerWidget {
  const _Retrato({
    required this.productor,
    required this.puedeFotografiar,
    required this.visitaId,
  });

  final Productor productor;
  final bool puedeFotografiar;
  final String visitaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final ruta = productor.fotoPath;
    final tiene = ruta != null && File(ruta).existsSync();

    return Column(
      children: [
        GestureDetector(
          onTap: puedeFotografiar ? () => _tomar(context) : null,
          child: Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.surfaceContainerHighest,
              border: Border.all(color: scheme.outlineVariant, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: tiene
                ? Image.file(
                    File(ruta),
                    fit: BoxFit.cover,
                    // Se reconstruye cuando la ruta es la misma y el archivo
                    // cambio: la foto de perfil se llama siempre `perfil.jpg`,
                    // asi que sin esto se seguiria viendo la anterior.
                    key: ValueKey(File(ruta).lastModifiedSync()),
                    cacheWidth: 396,
                    gaplessPlayback: true,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.broken_image_outlined,
                      size: 44,
                      color: scheme.outline,
                    ),
                  )
                : Icon(
                    Icons.person_outline,
                    size: 56,
                    color: scheme.outline,
                  ),
          ),
        ),
        const SizedBox(height: 12),
        if (puedeFotografiar)
          OutlinedButton.icon(
            onPressed: () => _tomar(context),
            icon: Icon(
              tiene ? Icons.refresh : Icons.photo_camera_outlined,
              size: 18,
            ),
            label: Text(tiene ? 'Tomar de nuevo' : 'Tomarle una foto'),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'El productor no autorizo las fotos en esta visita, asi que la '
              'camara esta cerrada.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: scheme.error),
            ),
          ),
        if (tiene && productor.enlaceFoto == null)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Pildora(
              texto: 'Guardada en el telefono, sin subir',
              tono: TonoPildora.aviso,
              icono: Icons.cloud_off_outlined,
            ),
          ),
      ],
    );
  }

  Future<void> _tomar(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CamaraPage.retrato(visitaId: visitaId)),
      );
}

/// Con que permiso se esta guardando esta ficha.
class _Autorizacion extends StatelessWidget {
  const _Autorizacion({required this.productor, required this.visita});

  final Productor productor;
  final Visita? visita;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final autorizado = productor.consentimientoDatos ||
        (visita?.consienteUsoDatos ?? false);

    return Card(
      color: autorizado ? tema.marca.exitoSuave : null,
      child: ListTile(
        leading: Icon(
          autorizado ? Icons.verified_user_outlined : Icons.gpp_maybe_outlined,
          color: autorizado ? tema.marca.exito : tema.colorScheme.error,
        ),
        title: Text(
          autorizado
              ? 'Autorizo el tratamiento de sus datos'
              : 'No autorizo el tratamiento de sus datos',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          autorizado
              ? 'Ley 1581/2012. Se pidio en el consentimiento de la visita y '
                  'queda con la persona, no con la visita.'
              : 'Se puede llenar la ficha, pero conviene volver a pedirle el '
                  'permiso antes de guardar sus datos.',
          style: const TextStyle(fontSize: 12, height: 1.35),
        ),
      ),
    );
  }
}
