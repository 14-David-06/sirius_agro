import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../data/db/app_database.dart';
import '../data/visita_repository.dart';
import 'providers.dart';

/// Vacia la cola de sincronizacion.
///
/// Hasta ahora la app encolaba y ahi se quedaba: el audio, las fotos y la
/// visita entera se registraban en `SyncQueue` y nadie los sacaba. Esto es lo
/// que los saca.
///
/// Corre de a un item por vez a proposito. Un telefono en una vereda con una
/// barra de senal no gana nada subiendo cuatro fotos en paralelo: se pisan,
/// todas fallan a la vez y el retroceso exponencial las manda a todas al mismo
/// reintento lejano. De a uno, lo que entra queda subido.
class Sincronizador {
  Sincronizador(this._db, this._repo, this._api);

  final AppDatabase _db;
  final VisitaRepository _repo;
  final ApiClient _api;

  bool _corriendo = false;

  /// Procesa lo que este vencido y devuelve cuantos items quedaron subidos.
  ///
  /// No lanza: un fallo de red no puede tumbar la pantalla del visitador. Lo
  /// que falla queda en la cola con su motivo y su proximo intento, que es
  /// justo lo que la pantalla de estado muestra.
  Future<int> procesar({int limite = 20}) async {
    if (_corriendo) return 0;
    _corriendo = true;

    var completados = 0;
    try {
      final items = await _db.proximosItems(limite: limite);
      for (final item in items) {
        try {
          await _procesarItem(item);
          await _db.marcarCompletado(item.id);
          completados++;
        } catch (e) {
          await _db.marcarFallo(item.id, e.toString());
        }
      }
    } finally {
      _corriendo = false;
    }
    return completados;
  }

  Future<void> _procesarItem(SyncItem item) async {
    switch (item.operacion) {
      case 'upload_audio':
        await _subirArchivo(item, categoria: 'audio');
      case 'upload_foto':
        await _subirArchivo(item, categoria: 'fotos');
      case 'upsert':
        await _sincronizarVisita(item);
      default:
        throw StateError('Operacion desconocida en la cola: ${item.operacion}');
    }
  }

  Future<void> _subirArchivo(SyncItem item, {required String categoria}) async {
    final ruta = item.archivoPath;
    if (ruta == null) {
      throw StateError('El item ${item.id} no trae ruta de archivo.');
    }

    final archivo = File(ruta);
    if (!await archivo.exists()) {
      // El archivo se borro: reintentar mil veces no lo va a traer de vuelta,
      // y dejar el item vivo bloquea la cola. Se deja constancia y se cierra.
      throw StateError('El archivo ya no esta en disco: $ruta');
    }

    final bytes = await archivo.readAsBytes();
    final url = await _api.subirArchivo(
      contenido: bytes,
      filename: ruta.split(Platform.pathSeparator).last,
      codigoVisita: item.entidadId,
      categoria: categoria,
      // Con la posicion, el backend lo guarda como `foto-03.jpg` en vez del
      // reloj en milisegundos de la camara.
      orden: await _repo.ordenDeArchivo(ruta),
    );

    // La URL se guarda apenas la subida termina, no al final de la visita: si
    // la app muere despues de subir, el byte ya viajo y no hay que volver a
    // gastarlo en una vereda con senal contada.
    if (categoria == 'audio') {
      await _repo.registrarEnlaceAudio(ruta, url);
    } else {
      await _repo.registrarEnlaceEvidencia(ruta, url);
    }

    await _db.registrarAvance(item.id, bytes.length);
  }

  Future<void> _sincronizarVisita(SyncItem item) async {
    final payload = await _repo.payloadDeVisita(item.entidadId);
    await _api.sincronizarVisita(payload);
    await _repo.marcarSincronizada(item.entidadId);
  }
}

final sincronizadorProvider = Provider<Sincronizador>((ref) => Sincronizador(
      ref.watch(dbProvider),
      ref.watch(repoProvider),
      ref.watch(apiProvider),
    ));

/// Estado de una corrida manual de la cola, para la pantalla de la visita.
class EstadoSincronizacion {
  const EstadoSincronizacion({
    this.trabajando = false,
    this.completados = 0,
    this.mensaje = '',
  });

  final bool trabajando;
  final int completados;
  final String mensaje;
}

class SincronizacionController extends StateNotifier<EstadoSincronizacion> {
  SincronizacionController(this._sync, this._db)
      : super(const EstadoSincronizacion());

  final Sincronizador _sync;
  final AppDatabase _db;

  /// Dispara la cola y resume el resultado en una linea.
  ///
  /// Es explicito y no automatico, igual que la transcripcion: subir consume
  /// datos moviles del visitador, y arrancar solo en medio de un potrero
  /// significa fallar y reintentar. El visitador decide cuando.
  Future<void> sincronizar(String visitaId) async {
    if (state.trabajando) return;
    state = const EstadoSincronizacion(trabajando: true, mensaje: 'Subiendo...');

    final completados = await _sync.procesar();
    final pendientes = await _db.pendientesDeVisita(visitaId);
    final fallidos =
        pendientes.where((p) => p.estado == EstadoSync.fallida).toList();

    final mensaje = switch ((pendientes.length, fallidos.length)) {
      (0, _) => 'Todo subido.',
      (_, 0) => '${pendientes.length} pendiente(s), sin errores.',
      _ => '${fallidos.length} con error: ${fallidos.first.ultimoError ?? ""}',
    };

    state = EstadoSincronizacion(completados: completados, mensaje: mensaje);
  }
}

final sincronizacionProvider = StateNotifierProvider.family<
    SincronizacionController, EstadoSincronizacion, String>(
  (ref, visitaId) => SincronizacionController(
    ref.watch(sincronizadorProvider),
    ref.watch(dbProvider),
  ),
);
