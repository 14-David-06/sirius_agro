import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import 'marca.dart';
import 'theme.dart';
import 'visita_page.dart';

/// Ley 1581/2012. Los tres permisos se piden en CADA visita: autorizar una
/// grabacion en marzo no autoriza la de septiembre.
///
/// El texto es el aviso de privacidad completo y esta escrito para leerse EN
/// VOZ ALTA al productor, no para que el visitador lo resuma. Trae lo que la
/// norma exige — quien es el responsable, para que se usa la informacion, los
/// derechos del titular y por donde ejercerlos — en frases que se pueden decir
/// de pie en un potrero: un consentimiento que el productor no entendio no es
/// consentimiento.
///
/// El canal para ejercer los derechos es el propio visitador (WhatsApp o
/// llamada) porque es el unico contacto de Sirius que el productor ya tiene
/// guardado. Lo que llegue por ahi lo escala Sirius.
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
            ? 'Solicitar autorizacion de nuevo'
            : 'Autorizacion del productor',
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
                        'La autorizacion se solicita de nuevo completa: lea '
                        'otra vez el texto en voz alta antes de marcar.',
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
                          'AVISO DE PRIVACIDAD - LEER EN VOZ ALTA',
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
                        ? 'Le solicito su autorizacion para grabar la '
                            'conversacion a partir de este momento. Sirius '
                            'Regenerative es la empresa responsable del '
                            'tratamiento de esa informacion y la finalidad '
                            'sigue siendo la misma: elaborar el informe '
                            'tecnico de su finca y hacer el seguimiento '
                            'agronomico posterior.\n\n'
                            'Usted conserva sus derechos como titular de la '
                            'informacion: conocer, actualizar y rectificar '
                            'sus datos, solicitar prueba de esta '
                            'autorizacion, revocarla y pedir que la '
                            'informacion se suprima. Para ejercerlos me '
                            'escribe o me llama a mi numero de WhatsApp y '
                            'Sirius atiende la solicitud.\n\n'
                            'Su autorizacion es voluntaria y puede retirarla '
                            'en cualquier momento.'
                        : 'Buen dia. Represento a Sirius Regenerative, la '
                            'empresa responsable del tratamiento de los '
                            'datos que se recojan en esta visita. Le '
                            'solicito su autorizacion para grabar la '
                            'conversacion y tomar fotografias de los '
                            'cultivos.\n\n'
                            'La finalidad es una sola: elaborar el informe '
                            'tecnico de su finca y hacer el seguimiento '
                            'agronomico posterior. El material no se entrega '
                            'a terceros ajenos a ese proposito.\n\n'
                            'Como titular de la informacion usted tiene '
                            'derecho a conocer, actualizar y rectificar sus '
                            'datos, a solicitar prueba de esta autorizacion, '
                            'a revocarla y a pedir que la informacion se '
                            'suprima. Para ejercer cualquiera de esos '
                            'derechos me escribe o me llama a mi numero de '
                            'WhatsApp y Sirius atiende la solicitud.\n\n'
                            'Su autorizacion es voluntaria. Si prefiere que '
                            'no grabemos, la visita se realiza igual y el '
                            'registro se hace por escrito.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // La norma citada al pie: si un dia alguien audita esta
                  // visita, el aviso que se leyo tiene nombre propio.
                  Text(
                    'Autorizacion para el tratamiento de datos personales - '
                    'Ley 1581 de 2012 y Decreto 1377 de 2013.',
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: scheme.onPrimaryContainer.withValues(alpha: 0.75),
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
            titulo: 'Autoriza grabar la conversacion',
            detalle: 'Sin esta autorizacion no se habilita la grabacion.',
            onChanged: (v) => setState(() => _audio = v),
          ),
          _Permiso(
            valor: _fotos,
            titulo: 'Autoriza tomar fotografias',
            detalle: 'Cultivos, suelo y etiquetas de los productos.',
            onChanged: (v) => setState(() => _fotos = v),
          ),
          _Permiso(
            valor: _datos,
            titulo: 'Autoriza el uso de la informacion',
            detalle: 'Para elaborar el informe tecnico y el seguimiento '
                'agronomico en el tiempo.',
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
                  ? 'Si el productor mantiene su negativa, deje la '
                      'autorizacion de audio sin marcar: la visita continua '
                      'con notas escritas y fotografias.'
                  : 'Si el productor no autoriza la grabacion, la visita se '
                      'realiza igual y el registro se hace por escrito. Si '
                      'mas adelante cambia de decision, dentro de la visita '
                      'puede volver a solicitar la autorizacion.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: scheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'Al iniciar la grabacion, solicite la autorizacion nuevamente en '
            'voz alta y registre el segundo en que quedo: ese es el soporte '
            'de la autorizacion.',
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
