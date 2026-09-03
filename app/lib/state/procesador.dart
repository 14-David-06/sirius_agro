import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../core/api_client.dart';
import '../data/visita_repository.dart';
import 'providers.dart';

enum EstadoPaso { enCurso, listo, fallo }

class Paso {
  const Paso(this.detalle, this.estado);
  final String detalle;
  final EstadoPaso estado;
}

class ProcesadorState {
  const ProcesadorState({
    this.trabajando = false,
    this.fallo = false,
    this.mensaje = '',
    this.pasos = const [],
  });

  final bool trabajando;
  final bool fallo;
  final String mensaje;

  /// Un paso por tramo, mas la extraccion. Se muestran todos porque en campo
  /// importa saber QUE fallo: que se caiga la transcripcion del tramo 3 no es
  /// lo mismo que que se caiga la extraccion con todo ya transcrito.
  final List<Paso> pasos;

  ProcesadorState copyWith({
    bool? trabajando,
    bool? fallo,
    String? mensaje,
    List<Paso>? pasos,
  }) =>
      ProcesadorState(
        trabajando: trabajando ?? this.trabajando,
        fallo: fallo ?? this.fallo,
        mensaje: mensaje ?? this.mensaje,
        pasos: pasos ?? this.pasos,
      );
}

final procesadorProvider = StateNotifierProvider.family<ProcesadorController,
    ProcesadorState, String>(
  (ref, visitaId) => ProcesadorController(
    visitaId,
    ref.watch(repoProvider),
    ref.watch(apiProvider),
  ),
);

/// Encadena audio -> transcripcion -> hallazgos.
///
/// Hasta ahora la app grababa, encolaba y ahi se quedaba: el audio no salia
/// del telefono y la completitud nunca se movia. Esto es el puente.
///
/// Es explicito y no automatico a proposito. La transcripcion y la extraccion
/// cuestan plata y necesitan senal; dispararlas solas al cerrar un tramo
/// significaria intentarlo en medio de un potrero, fallar, y reintentar. El
/// visitador decide cuando: normalmente al salir de la finca o al llegar al
/// pueblo.
class ProcesadorController extends StateNotifier<ProcesadorState> {
  ProcesadorController(this.visitaId, this._repo, this._api)
      : super(const ProcesadorState());

  final String visitaId;
  final VisitaRepository _repo;
  final ApiClient _api;

  void _paso(String detalle, EstadoPaso estado) {
    state = state.copyWith(pasos: [...state.pasos, Paso(detalle, estado)]);
  }

  void _ultimoPaso(String detalle, EstadoPaso estado) {
    final previos = state.pasos.toList();
    if (previos.isNotEmpty) previos.removeLast();
    state = state.copyWith(pasos: [...previos, Paso(detalle, estado)]);
  }

  Future<void> procesar() async {
    if (state.trabajando) return;
    state = const ProcesadorState(trabajando: true, mensaje: 'Empezando...');

    try {
      final tramos = await _repo.grabacionesDeVisita(visitaId);
      if (tramos.isEmpty) {
        state = state.copyWith(
          trabajando: false,
          fallo: true,
          mensaje: 'No hay audio grabado todavia.',
        );
        return;
      }

      final terminos = await _repo.terminosDeVisita(visitaId);
      var transcritos = 0;
      int? hablanteVisitador;

      for (final tramo in tramos) {
        // Se salta lo ya hecho: reintentar no vuelve a pagar un tramo que ya
        // se transcribio.
        if ((tramo.transcripcionMarcas ?? '').trim().isNotEmpty) {
          _paso('Tramo ${tramo.orden}: ya estaba transcrito', EstadoPaso.listo);
          transcritos++;
          continue;
        }

        final archivo = File(tramo.archivoPath);
        if (!await archivo.exists()) {
          // El archivo se borro o el rescate lo registro y luego se perdio.
          // Se dice y se sigue con los demas: un tramo perdido no invalida
          // los otros veinticinco minutos.
          _paso(
            'Tramo ${tramo.orden}: el audio ya no esta en el telefono',
            EstadoPaso.fallo,
          );
          continue;
        }

        _paso('Tramo ${tramo.orden}: transcribiendo...', EstadoPaso.enCurso);
        state = state.copyWith(mensaje: 'Transcribiendo tramo ${tramo.orden}');

        try {
          final resultado = await _api.transcribir(
            audio: await archivo.readAsBytes(),
            filename: p.basename(tramo.archivoPath),
            terminos: terminos,
          );

          await _repo.guardarTranscripcion(
            grabacionId: tramo.id,
            texto: resultado.texto,
            textoConMarcas: resultado.textoConMarcas,
            motor: resultado.motor,
            duracionSeg: resultado.duracionSegundos?.round(),
          );

          // La sugerencia del primer tramo con dos voces se usa para todos:
          // es la misma conversacion, no cambia de un tramo al siguiente.
          hablanteVisitador ??= resultado.hablanteVisitadorSugerido;

          final turnos = resultado.turnos.length;
          _ultimoPaso(
            'Tramo ${tramo.orden}: $turnos turno(s), '
            '${resultado.turnos.map((t) => t.hablante).toSet().length} voz(ces)',
            EstadoPaso.listo,
          );
          transcritos++;
        } catch (e) {
          _ultimoPaso('Tramo ${tramo.orden}: ${_corto(e)}', EstadoPaso.fallo);
        }
      }

      if (transcritos == 0) {
        state = state.copyWith(
          trabajando: false,
          fallo: true,
          mensaje: 'No se pudo transcribir ningun tramo.',
        );
        return;
      }

      // --- extraccion ---
      _paso('Extrayendo los datos...', EstadoPaso.enCurso);
      state = state.copyWith(mensaje: 'Extrayendo los datos');

      final transcripcion = await _repo.transcripcionCompleta(visitaId);
      try {
        final extraccion = await _api.extraer(
          visitaId: visitaId,
          transcripcion: transcripcion,
          campos: await _repo.camposParaExtraccion(),
          // El backend cuenta los hablantes desde 1 en el texto con marcas.
          hablanteVisitador: hablanteVisitador == null
              ? null
              : hablanteVisitador + 1,
        );

        final pct = await _repo.guardarExtraccion(
          visitaId: visitaId,
          extraidos:
              extraccion.hallazgos.map(HallazgoExtraido.fromJson).toList(),
          resumen: extraccion.resumen,
          temasPendientes: extraccion.temasPendientes,
        );

        _ultimoPaso(
          '${extraccion.hallazgos.length} dato(s) extraido(s)',
          EstadoPaso.listo,
        );
        state = state.copyWith(
          trabajando: false,
          fallo: false,
          mensaje: 'Listo. Completitud: $pct%.',
        );
      } catch (e) {
        _ultimoPaso('Extraccion: ${_corto(e)}', EstadoPaso.fallo);
        state = state.copyWith(
          trabajando: false,
          fallo: true,
          // La transcripcion NO se perdio: queda guardada y reintentar solo
          // repite la extraccion.
          mensaje: 'El audio quedo transcrito. Fallo la extraccion.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        trabajando: false,
        fallo: true,
        mensaje: _corto(e),
      );
    }
  }

  /// El error del backend tal cual, recortado. Un mensaje generico obliga a
  /// abrir los logs; el detalle dice si falta una llave o si no hay senal.
  static String _corto(Object e) {
    final texto = e.toString().replaceAll('\n', ' ');
    return texto.length > 160 ? '${texto.substring(0, 160)}...' : texto;
  }
}
