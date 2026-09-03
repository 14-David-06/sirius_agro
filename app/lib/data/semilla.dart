import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show AssetBundle;

import 'db/app_database.dart';

/// Siembra la base local desde los assets empaquetados en el APK.
///
/// Sin esto, un visitador que instala la app y se va al campo sin abrirla con
/// red no tendria ni el selector de veredas ni los obligatorios: la
/// completitud diria 0% de 0 campos y la lista de faltantes saldria vacia.
/// Es decir, la app le diria que la visita esta bien cuando no sabe nada.
///
/// Airtable sigue siendo la fuente de verdad: al primer sincronizado, lo que
/// venga del backend sobreescribe esto por clave tecnica.
class Semilla {
  const Semilla(this._db, this._assets);

  final AppDatabase _db;
  final AssetBundle _assets;

  static const rutaVeredas = 'assets/semilla/veredas.json';
  static const rutaCatalogo = 'assets/semilla/catalogo.json';
  static const rutaVisitadores = 'assets/semilla/visitadores.json';

  /// Marca de la semilla ya aplicada en este dispositivo.
  static const _claveVersion = 'semilla_version';

  /// Siembra las tablas espejo. Idempotente: se llama en cada arranque.
  ///
  /// Dos caminos:
  /// - Si el APK trae una semilla mas nueva que la ya aplicada, se re-escriben
  ///   las tres tablas completas. Sin esto, actualizar la app dejaba el
  ///   catalogo viejo: la tabla no estaba vacia, asi que el sembrador no
  ///   hacia nada y una variable nueva no aparecia nunca.
  /// - Si la semilla es la misma, solo se llenan las tablas que esten vacias.
  ///
  /// Las tres son espejos de Airtable, no datos del visitador: re-escribirlas
  /// no pierde nada. Lo que el visitador captura vive en Visitas, Grabaciones,
  /// Evidencias y Hallazgos, que esto no toca.
  Future<void> sembrarSiHaceFalta() async {
    final version = await _versionDeLaSemilla();
    final aplicada = await _db.ajuste(_claveVersion);

    if (aplicada != version) {
      await _sembrarVeredas();
      await _sembrarCatalogo();
      await _sembrarVisitadores();
      await _db.guardarAjuste(_claveVersion, version);
      return;
    }

    if ((await _db.select(_db.veredas).get()).isEmpty) {
      await _sembrarVeredas();
    }
    if ((await _db.select(_db.catalogoCampos).get()).isEmpty) {
      await _sembrarCatalogo();
    }
    if ((await _db.select(_db.visitadores).get()).isEmpty) {
      await _sembrarVisitadores();
    }
  }

  /// Identifica la semilla empaquetada por la fecha que declara cada asset.
  /// Si alguien regenera los assets y olvida cambiar la fecha, esto no lo
  /// detecta — por eso el generador la escribe solo.
  Future<String> _versionDeLaSemilla() async {
    final catalogo = jsonDecode(await _assets.loadString(rutaCatalogo))
        as Map<String, dynamic>;
    final personal = jsonDecode(await _assets.loadString(rutaVisitadores))
        as Map<String, dynamic>;

    return 'catalogo:${catalogo['generado']}'
        '|personal:${personal['generado']}'
        '|campos:${catalogo['activos']}'
        '|activos:${personal['activos']}';
  }

  /// Los empleados activos de la nomina, para que el selector de visitador
  /// funcione en el primer arranque sin red.
  Future<void> _sembrarVisitadores() async {
    final json = jsonDecode(await _assets.loadString(rutaVisitadores))
        as Map<String, dynamic>;
    final filas = (json['visitadores'] as List).cast<Map<String, dynamic>>();

    await _db.batch(
      (b) => b.insertAllOnConflictUpdate(
        _db.visitadores,
        [
          for (final v in filas)
            VisitadoresCompanion.insert(
              id: v['id'] as String,
              idEmpleado: Value(v['id_empleado'] as String?),
              nombre: v['nombre'] as String,
              usuarioApp: v['usuario_app'] as String,
              cargo: Value(v['cargo'] as String?),
              email: Value(v['email'] as String?),
              telefono: Value(v['telefono'] as String?),
              rol: Value(v['rol'] as String?),
              activo: Value(v['activo'] as bool? ?? true),
              remoteId: Value(v['remote_id'] as String?),
            ),
        ],
      ),
    );
  }

  Future<void> _sembrarVeredas() async {
    final json = jsonDecode(await _assets.loadString(rutaVeredas))
        as Map<String, dynamic>;
    final filas = (json['veredas'] as List).cast<Map<String, dynamic>>();

    await _db.batch(
      (b) => b.insertAllOnConflictUpdate(
        _db.veredas,
        [
          for (final v in filas)
            VeredasCompanion.insert(
              id: v['id'] as String,
              vereda: v['vereda'] as String,
              municipio: v['municipio'] as String,
              departamento: Value(v['departamento'] as String?),
              remoteId: Value(v['remote_id'] as String?),
            ),
        ],
      ),
    );
  }

  Future<void> _sembrarCatalogo() async {
    final json = jsonDecode(await _assets.loadString(rutaCatalogo))
        as Map<String, dynamic>;
    final filas = (json['campos'] as List).cast<Map<String, dynamic>>();

    await _db.guardarCatalogo([
      for (final c in filas)
        CatalogoCamposCompanion.insert(
          claveTecnica: c['clave_tecnica'] as String,
          campo: c['campo'] as String,
          modulo: c['modulo'] as String,
          tipoDato: Value(c['tipo_dato'] as String? ?? 'Texto'),
          unidad: Value(c['unidad'] as String?),
          opciones: Value(c['opciones'] as String?),
          preguntaGuia: Value(c['pregunta_guia'] as String?),
          obligatorioMvp: Value(c['obligatorio_mvp'] as bool? ?? false),
          prioridad: Value(c['prioridad'] as String?),
          activo: Value(c['activo'] as bool? ?? true),
          noSugerir: Value(c['no_sugerir'] as bool? ?? false),
        ),
    ]);
  }
}
