import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../data/sesion_repository.dart';
import '../state/providers.dart';
import '../state/sesion.dart';

/// La frase que hay que escribir para borrar. Se compara en minusculas y sin
/// espacios de sobra: la idea es que el visitador no pueda borrar por reflejo,
/// no ponerle una prueba de mecanografia.
const _fraseConfirmacion = 'eliminar visita';

/// Pide contrasena Y la frase, en ese orden, antes de borrar.
///
/// Son dos barreras distintas a proposito. La contrasena responde «quien sos»:
/// el telefono anda de mano en mano en la finca y el que borra tiene que ser
/// el dueno de la sesion. La frase responde «entendes que esto no se
/// deshace»: es lo unico que frena el toque automatico sobre un dialogo de
/// confirmacion que ya se vio veinte veces.
///
/// Devuelve true si se borro.
Future<bool> confirmarYEliminar(
  BuildContext context,
  WidgetRef ref,
  List<String> visitaIds,
) async {
  final sesion = ref.read(sesionProvider).valueOrNull;
  if (sesion == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hay que iniciar sesion para eliminar.')),
    );
    return false;
  }

  // El peso en disco se calcula antes de abrir el dialogo: «se liberan 84 MB»
  // le dice al visitador que ahi vive el audio de la conversacion, que es lo
  // que de verdad esta a punto de perder.
  var bytes = 0;
  for (final id in visitaIds) {
    bytes += await ref.read(repoProvider).bytesEnDisco(id);
  }

  if (!context.mounted) return false;

  final borrado = await showDialog<bool>(
    context: context,
    // No se cierra tocando afuera: en la mano, con guantes, el toque de mas es
    // la regla. Se sale por «Cancelar».
    barrierDismissible: false,
    builder: (_) => _DialogoEliminar(
      visitaIds: visitaIds,
      sesion: sesion,
      bytesEnDisco: bytes,
    ),
  );

  return borrado ?? false;
}

class _DialogoEliminar extends ConsumerStatefulWidget {
  const _DialogoEliminar({
    required this.visitaIds,
    required this.sesion,
    required this.bytesEnDisco,
  });

  final List<String> visitaIds;
  final SesionActiva sesion;
  final int bytesEnDisco;

  @override
  ConsumerState<_DialogoEliminar> createState() => _DialogoEliminarState();
}

class _DialogoEliminarState extends ConsumerState<_DialogoEliminar> {
  final _password = TextEditingController();
  final _frase = TextEditingController();
  bool _trabajando = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _frase.dispose();
    super.dispose();
  }

  bool get _fraseOk =>
      _frase.text.trim().toLowerCase() == _fraseConfirmacion;

  bool get _puedeBorrar =>
      !_trabajando && _password.text.isNotEmpty && _fraseOk;

  Future<void> _eliminar() async {
    setState(() {
      _trabajando = true;
      _error = null;
    });

    // Se verifica contra el hash bcrypt que quedo guardado en el telefono al
    // entrar, no contra el backend: el borrado tiene que poder hacerse en una
    // vereda sin senal, igual que el login offline.
    final ok = await verificarBcrypt(
      _password.text,
      widget.sesion.credencial.hashBcrypt,
    );

    if (!mounted) return;
    if (!ok) {
      setState(() {
        _trabajando = false;
        _error = 'Contrasena incorrecta.';
      });
      return;
    }

    try {
      await ref.read(repoProvider).eliminarVisitas(widget.visitaIds);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _trabajando = false;
        _error = 'No se pudo eliminar: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final n = widget.visitaIds.length;
    final cuantas = n == 1 ? 'esta visita' : 'estas $n visitas';

    return AlertDialog(
      icon: Icon(Icons.delete_forever_outlined, color: scheme.error),
      title: Text(n == 1 ? 'Eliminar la visita' : 'Eliminar $n visitas'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Se borra de este telefono todo lo de $cuantas: el audio de la '
              'conversacion, las fotos, la transcripcion, los informes y los '
              'datos extraidos. No se puede recuperar.',
              style: const TextStyle(fontSize: 13.5, height: 1.4),
            ),
            if (widget.bytesEnDisco > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Se liberan ${_peso(widget.bytesEnDisco)} de audio y fotos.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 10),
            // Distincion que importa y que nadie adivina: esto no le pide al
            // backend que borre nada. Decir "eliminado" sin aclararlo dejaria
            // creer que la visita desaparecio de Airtable tambien.
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lo que ya se sincronizo sigue guardado en la oficina. '
                      'Esto borra la copia del telefono. Si querés guardarla '
                      'antes, cancelá y usá «Descargar».',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _password,
              obscureText: true,
              autofocus: true,
              enabled: !_trabajando,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Contrasena de ${widget.sesion.credencial.nombre}',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _frase,
              enabled: !_trabajando,
              // Sin autocorrector ni mayuscula automatica: el teclado le
              // cambiaba la frase y la confirmacion no coincidia nunca.
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.none,
              inputFormatters: [LengthLimitingTextInputFormatter(40)],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Escribí «$_fraseConfirmacion»',
                prefixIcon: const Icon(Icons.keyboard_outlined),
                border: const OutlineInputBorder(),
                suffixIcon: _frase.text.isEmpty
                    ? null
                    : Icon(
                        _fraseOk ? Icons.check_circle : Icons.error_outline,
                        color: _fraseOk ? scheme.primary : scheme.error,
                      ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: scheme.error, fontSize: 12.5),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _trabajando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _puedeBorrar ? _eliminar : null,
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          child: _trabajando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Eliminar'),
        ),
      ],
    );
  }
}

/// Arma el .zip de las visitas seleccionadas y abre el menu de compartir para
/// que el visitador elija donde dejarlo: Descargas, Drive, WhatsApp o el
/// correo. No se elige por el: en el llano, a veces lo unico que hay es
/// WhatsApp, y a veces un cable y un computador en la oficina.
Future<void> descargarVisitas(
  BuildContext context,
  WidgetRef ref,
  List<String> visitaIds,
) async {
  final mensajero = ScaffoldMessenger.of(context);
  final caja = context.findRenderObject() as RenderBox?;
  final paso = ValueNotifier<String>('Preparando...');
  final navegador = Navigator.of(context);

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _DialogoProgreso(paso: paso),
  );

  // Un solo cierre para el dialogo de progreso. Sin esta bandera, un fallo del
  // menu de compartir — que ocurre DESPUES de cerrarlo — hacia un segundo pop
  // que se llevaba la pantalla de visitas.
  var abierto = true;
  void cerrarProgreso() {
    if (!abierto) return;
    abierto = false;
    navegador.pop();
  }

  try {
    final zip = await ref.read(exportadorProvider).exportar(
          visitaIds,
          onPaso: (p) => paso.value = p,
        );

    cerrarProgreso();

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(zip.path, mimeType: 'application/zip')],
        subject: visitaIds.length == 1
            ? 'Visita de campo'
            : '${visitaIds.length} visitas de campo',
        sharePositionOrigin:
            caja == null ? null : caja.localToGlobal(Offset.zero) & caja.size,
      ),
    );
  } catch (e) {
    cerrarProgreso();
    mensajero.showSnackBar(
      SnackBar(content: Text('No se pudo armar el .zip: $e')),
    );
  } finally {
    paso.dispose();
  }
}

class _DialogoProgreso extends StatelessWidget {
  const _DialogoProgreso({required this.paso});

  final ValueNotifier<String> paso;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(width: 18),
          Expanded(
            // El paso concreto y no «Cargando»: comprimir el audio de una
            // visita larga tarda, y un spinner mudo parece que se colgo.
            child: ValueListenableBuilder<String>(
              valueListenable: paso,
              builder: (_, texto, _) => Text(
                texto,
                style: const TextStyle(fontSize: 13.5, height: 1.35),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _peso(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
