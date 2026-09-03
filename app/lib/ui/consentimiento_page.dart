import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import 'marca.dart';
import 'theme.dart';
import 'visita_page.dart';

/// Ley 1581/2012. Los tres permisos se piden en CADA visita: autorizar una
/// grabacion en marzo no autoriza la de septiembre.
///
/// El texto esta escrito para leerse EN VOZ ALTA al productor, no para que el
/// visitador lo resuma. Por eso esta en segunda persona y sin jerga legal: un
/// consentimiento que el productor no entendio no es consentimiento.
///
/// La misma pantalla sirve para las dos veces que hace falta:
///  - al crear la visita (`ConsentimientoPage`), y
///  - a mitad de la visita (`ConsentimientoPage.revisar`), cuando el productor
///    dijo que no al principio y despues cambio de opinion.
///
/// Que se pueda volver a pedir NO es una puerta trasera: el permiso se vuelve
/// a leer completo y el productor lo vuelve a dar. Lo que se evita es tener
/// que botar la visita y empezar de cero por un "no" inicial.
class ConsentimientoPage extends ConsumerStatefulWidget {
  const ConsentimientoPage({super.key, required this.visitaId})
      : revisar = false;

  /// Se abre desde una visita que ya esta andando. Vuelve a la visita al
  /// guardar en vez de arrancarla, y respeta lo que ya estaba autorizado.
  const ConsentimientoPage.revisar({super.key, required this.visitaId})
      : revisar = true;

  final String visitaId;
  final bool revisar;

  @override
  ConsumerState<ConsentimientoPage> createState() =>
      _ConsentimientoPageState();
}

class _ConsentimientoPageState extends ConsumerState<ConsentimientoPage> {
  bool _audio = false;
  bool _fotos = false;
  bool _datos = false;
  bool _guardando = false;
  bool _prellenado = false;

  /// Guardar exige que algo cambie a favor del productor. Con los tres en no
  /// no hay nada que registrar: eso ya es el estado de la visita.
  bool get _hayAlgo => _audio || _fotos || _datos;

  Future<void> _guardar({required bool abrirVisita}) async {
    if (_guardando) return;
    setState(() => _guardando = true);

    try {
      await ref.read(repoProvider).registrarConsentimiento(
            widget.visitaId,
            audio: _audio,
            fotos: _fotos,
            usoDatos: _datos,
          );

      if (!mounted) return;
      if (abrirVisita) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => VisitaPage(visitaId: widget.visitaId),
          ),
        );
      } else {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el consentimiento: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;

    // Al revisar se parte de lo que el productor ya habia autorizado, para no
    // pisar sin querer un permiso que si estaba dado.
    if (widget.revisar && !_prellenado) {
      final visita = ref.watch(visitaProvider(widget.visitaId)).valueOrNull;
      if (visita != null) {
        _prellenado = true;
        _audio = visita.consienteAudio;
        _fotos = visita.consienteFotos;
        _datos = visita.consienteUsoDatos;
      }
    }

    return Scaffold(
      appBar: AppBarMarca(
        titulo: widget.revisar
            ? 'Volver a pedir permiso'
            : 'Permiso del productor',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (widget.revisar) ...[
            Card(
              color: tema.marca.avisoSuave,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: tema.marca.aviso.withValues(alpha: 0.3),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.replay, size: 20, color: tema.marca.aviso),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'El permiso se pide de nuevo completo: leale otra vez '
                        'el texto en voz alta antes de marcar.',
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.4,
                          color: tema.marca.aviso,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Card(
            color: scheme.primaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: scheme.primary.withValues(alpha: 0.2)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.record_voice_over,
                        size: 20,
                        color: scheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'LEALE ESTO EN VOZ ALTA',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.revisar
                        ? 'Don/Dona, ¿le parece si grabamos de aqui en '
                            'adelante? Es solo para no estar escribiendo '
                            'mientras hablamos, y con eso le armo el informe '
                            'de su finca.\n\n'
                            'Usted sigue decidiendo. Si en algun momento '
                            'quiere que pare o que borremos todo, me dice.'
                        : 'Don/Dona, yo trabajo con Sirius. Para no estar '
                            'escribiendo mientras hablamos, me gustaria grabar '
                            'la conversacion y tomar algunas fotos de los '
                            'cultivos. Con eso le armo un informe de su finca '
                            'y se lo entrego.\n\n'
                            'Usted decide. Si no quiere que grabe, conversamos '
                            'igual. Y si mas adelante cambia de opinion, me '
                            'dice y borramos todo.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const TituloSeccion('Lo que autoriza'),
          _Permiso(
            valor: _audio,
            titulo: 'Puedo grabar la conversacion',
            detalle: 'Sin esto no se habilita el boton de grabar.',
            onChanged: (v) => setState(() => _audio = v),
          ),
          _Permiso(
            valor: _fotos,
            titulo: 'Puedo tomar fotos',
            detalle: 'Cultivos, suelo y etiquetas de los productos.',
            onChanged: (v) => setState(() => _fotos = v),
          ),
          _Permiso(
            valor: _datos,
            titulo: 'Puedo usar la informacion para el diagnostico',
            detalle: 'Para armar el informe y acompanarlo en el tiempo.',
            onChanged: (v) => setState(() => _datos = v),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: _guardando || (widget.revisar && !_hayAlgo)
                ? null
                : () => _guardar(abrirVisita: !widget.revisar),
            icon: _guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(_audio ? Icons.mic : Icons.arrow_forward),
            label: Text(
              switch ((widget.revisar, _audio)) {
                (true, _) => 'Guardar el permiso',
                (false, true) => 'Continuar y grabar',
                (false, false) => 'Continuar sin grabar',
              },
            ),
          ),
          const SizedBox(height: 14),
          // El "no" no es un callejon sin salida: la visita arranca igual, se
          // toman notas, y si el productor cambia de opinion a mitad de la
          // charla el permiso se vuelve a pedir desde la misma visita.
          if (!_audio)
            Text(
              widget.revisar
                  ? 'Si sigue sin autorizar la grabacion, deja el permiso de '
                      'audio sin marcar: la visita continua con notas y fotos.'
                  : 'Si el productor no autoriza la grabacion, la visita se '
                      'hace igual y las notas se escriben a mano. Si mas '
                      'adelante cambia de opinion, en la visita hay un boton '
                      'para volver a pedirle el permiso.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: scheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'Cuando arranque la grabacion, pidale el permiso otra vez en voz '
            'alta y marca el segundo donde quedo: esa es la prueba.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Permiso extends StatelessWidget {
  const _Permiso({
    required this.valor,
    required this.titulo,
    required this.detalle,
    required this.onChanged,
  });

  final bool valor;
  final String titulo;
  final String detalle;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    // Marcado = tarjeta viva. Que se vea de lejos que permisos quedaron
    // dados, porque lo que sigue depende de eso.
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        color: valor ? tema.marca.exitoSuave : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: valor
                ? tema.marca.exito.withValues(alpha: 0.35)
                : tema.colorScheme.outlineVariant,
          ),
        ),
        child: CheckboxListTile(
          value: valor,
          onChanged: (v) => onChanged(v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
          activeColor: tema.marca.exito,
          title: Text(titulo, style: tema.textTheme.titleMedium),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(detalle),
          ),
        ),
      ),
    );
  }
}
