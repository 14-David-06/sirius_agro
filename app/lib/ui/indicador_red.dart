import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/red.dart';
import 'marca.dart';
import 'theme.dart';

/// Como se ve cada estado de la red. Una sola fuente para el icono de la barra
/// y la pildora del login, para que no digan cosas distintas.
class _CaraRed {
  const _CaraRed(this.icono, this.color, this.tono, this.etiqueta, this.detalle);

  final IconData icono;
  final Color color;
  final TonoPildora tono;
  final String etiqueta;
  final String detalle;
}

_CaraRed _caraDe(BuildContext context, EstadoRed estado) {
  final tema = Theme.of(context);
  final scheme = tema.colorScheme;

  return switch (estado) {
    EstadoRed.enLinea => _CaraRed(
        Icons.cloud_done,
        tema.marca.exito,
        TonoPildora.exito,
        'Con conexion',
        'El servidor de Sirius responde: se puede sincronizar.',
      ),
    EstadoRed.sinServidor => _CaraRed(
        Icons.cloud_off,
        tema.marca.aviso,
        TonoPildora.aviso,
        'Sin Internet',
        'El telefono tiene senal pero no llega al servidor. La visita se '
            'sigue trabajando y queda en la cola para subir.',
      ),
    EstadoRed.sinRed => _CaraRed(
        Icons.wifi_off,
        scheme.error,
        TonoPildora.error,
        'Sin conexion',
        'No hay wifi ni datos moviles. Todo se guarda en el telefono y se '
            'sube cuando vuelva la senal.',
      ),
    EstadoRed.verificando => _CaraRed(
        Icons.cloud_sync,
        scheme.onSurfaceVariant,
        TonoPildora.neutro,
        'Revisando la conexion',
        'Un momento: se esta probando si el servidor responde.',
      ),
  };
}

/// Semaforo de conexion en la barra de todas las pantallas.
///
/// El icono cambia de forma y no solo de color: al sol, sobre una pantalla de
/// telefono sucia, el verde y el ambar se ven igual. Tocarlo dice en palabras
/// que esta pasando y fuerza una revision, que es lo que uno quiere hacer
/// cuando acaba de subir a la loma a buscar senal.
class IndicadorRed extends ConsumerWidget {
  const IndicadorRed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cara = _caraDe(context, ref.watch(redProvider));

    return IconButton(
      icon: Icon(cara.icono, size: 20, color: cara.color),
      tooltip: cara.etiqueta,
      onPressed: () {
        ref.read(redProvider.notifier).revisar();
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text('${cara.etiqueta}. ${cara.detalle}'),
            duration: const Duration(seconds: 4),
          ),
        );
      },
    );
  }
}

/// El mismo estado, con texto, para pantallas sin barra superior. En el login
/// importa mas que en ningun lado: entrar por primera vez necesita servidor.
class PildoraRed extends ConsumerWidget {
  const PildoraRed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cara = _caraDe(context, ref.watch(redProvider));

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => ref.read(redProvider.notifier).revisar(),
      child: Pildora(
        texto: cara.etiqueta,
        tono: cara.tono,
        icono: cara.icono,
      ),
    );
  }
}
