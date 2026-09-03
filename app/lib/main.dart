import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/servicio_grabacion.dart';
import 'state/sesion.dart';
import 'ui/login_page.dart';
import 'ui/theme.dart';
import 'ui/visitas_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Tiene que ir antes de runApp: es el canal entre el isolate del servicio
  // en primer plano y la UI.
  FlutterForegroundTask.initCommunicationPort();
  ServicioGrabacion.configurar();

  await initializeDateFormatting('es');
  runApp(const ProviderScope(child: SiriusAgroApp()));
}

class SiriusAgroApp extends StatelessWidget {
  const SiriusAgroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sirius Agro',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      home: const _Puerta(),
    );
  }
}

/// Decide que se ve al abrir la app. Escucha la sesion en vez de navegar una
/// sola vez al arrancar, asi cerrar sesion devuelve al login sin que nadie
/// tenga que acordarse de hacer el `pop`.
class _Puerta extends ConsumerWidget {
  const _Puerta();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesion = ref.watch(sesionProvider);

    return switch (sesion) {
      AsyncData(value: final activa) =>
        activa == null ? const LoginPage() : const VisitasPage(),
      // Leer la sesion es una consulta local de milisegundos: un spinner es
      // mas honesto que mostrar el login y hacerlo desaparecer.
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }
}
