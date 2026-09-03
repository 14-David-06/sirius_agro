import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Servicio en primer plano que mantiene vivo el proceso mientras se graba.
///
/// La grabacion NO corre dentro del servicio: sigue en el isolate principal,
/// con el plugin `record`. Lo que hace el servicio es impedir que Android mate
/// el proceso cuando la pantalla se apaga o el visitador cambia de app, y
/// poner una notificacion permanente que el sistema exige a cambio.
///
/// Es la unica forma de que una grabacion de 30 minutos con la pantalla
/// bloqueada sobreviva en un Android moderno. Sin esto, el sistema suspende el
/// proceso a los pocos minutos y el audio se corta sin avisar.
///
/// La notificacion tambien cumple una funcion de honestidad: mientras la app
/// tiene el microfono abierto, en la barra de estado se ve. El productor puede
/// mirar el telefono y confirmar que se esta grabando lo que autorizo.
class ServicioGrabacion {
  static const _serviceId = 707;
  static const _canal = 'grabacion_visita';

  /// Se llama una sola vez al arrancar la app.
  static void configurar() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: _canal,
        channelName: 'Grabacion de visita',
        channelDescription:
            'Aparece mientras se esta grabando una visita de campo.',
        // Suena una sola vez: la conversacion no se interrumpe con un pitido
        // cada vez que la notificacion se actualiza.
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        // El servicio no necesita hacer nada periodico: el reloj y la rotacion
        // de tramos viven en el isolate principal. 30 s es solo un latido para
        // que el sistema vea el servicio activo.
        eventAction: ForegroundTaskEventAction.repeat(30000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        // Sin wake lock la CPU se duerme con la pantalla apagada y el
        // encoder de audio se detiene a media frase.
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  /// Pide el permiso de notificaciones (Android 13+) y, si hace falta, que la
  /// app quede fuera de la optimizacion de bateria.
  ///
  /// Los fabricantes chinos son agresivos matando procesos en segundo plano;
  /// sin esta exclusion, un Xiaomi o un Huawei corta la grabacion igual aunque
  /// haya servicio en primer plano. Se pide, no se exige: si el visitador
  /// la niega, la app graba de todos modos y el riesgo queda en el simulacro.
  static Future<void> pedirPermisos() async {
    if (await FlutterForegroundTask.checkNotificationPermission() !=
        NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    if (Platform.isAndroid &&
        !await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }
  }

  static Future<bool> get activo => FlutterForegroundTask.isRunningService;

  static Future<void> iniciar({
    required String titulo,
    required String texto,
  }) async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.updateService(
        notificationTitle: titulo,
        notificationText: texto,
      );
      return;
    }

    await FlutterForegroundTask.startService(
      // microphone: obligatorio desde Android 14 para un servicio que
      // mantiene el microfono abierto. Declararlo mal hace que el sistema
      // rechace el arranque del servicio.
      serviceTypes: [ForegroundServiceTypes.microphone],
      serviceId: _serviceId,
      notificationTitle: titulo,
      notificationText: texto,
      callback: iniciarTarea,
    );
  }

  /// Refresca el texto de la notificacion con el tiempo transcurrido.
  static Future<void> actualizar({
    required String titulo,
    required String texto,
  }) async {
    if (!await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.updateService(
      notificationTitle: titulo,
      notificationText: texto,
    );
  }

  static Future<void> detener() async {
    if (!await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.stopService();
  }
}

/// Punto de entrada del isolate del servicio. Tiene que ser una funcion de
/// nivel superior y llevar la anotacion, o el servicio no arranca en release.
@pragma('vm:entry-point')
void iniciarTarea() {
  FlutterForegroundTask.setTaskHandler(_TareaGrabacion());
}

/// Deliberadamente vacia. El servicio existe para que el proceso siga vivo,
/// no para hacer trabajo: si la grabacion viviera aqui, habria que registrar
/// los plugins de audio en un segundo isolate y sincronizar el estado con la
/// UI. Mas piezas, mas formas de perder un audio.
class _TareaGrabacion extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}
