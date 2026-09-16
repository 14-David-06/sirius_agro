// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AjustesTable extends Ajustes with TableInfo<$AjustesTable, Ajuste> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AjustesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _claveMeta = const VerificationMeta('clave');
  @override
  late final GeneratedColumn<String> clave = GeneratedColumn<String>(
    'clave',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valorMeta = const VerificationMeta('valor');
  @override
  late final GeneratedColumn<String> valor = GeneratedColumn<String>(
    'valor',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [clave, valor];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ajustes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Ajuste> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('clave')) {
      context.handle(
        _claveMeta,
        clave.isAcceptableOrUnknown(data['clave']!, _claveMeta),
      );
    } else if (isInserting) {
      context.missing(_claveMeta);
    }
    if (data.containsKey('valor')) {
      context.handle(
        _valorMeta,
        valor.isAcceptableOrUnknown(data['valor']!, _valorMeta),
      );
    } else if (isInserting) {
      context.missing(_valorMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clave};
  @override
  Ajuste map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Ajuste(
      clave: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clave'],
      )!,
      valor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}valor'],
      )!,
    );
  }

  @override
  $AjustesTable createAlias(String alias) {
    return $AjustesTable(attachedDatabase, alias);
  }
}

class Ajuste extends DataClass implements Insertable<Ajuste> {
  final String clave;
  final String valor;
  const Ajuste({required this.clave, required this.valor});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['clave'] = Variable<String>(clave);
    map['valor'] = Variable<String>(valor);
    return map;
  }

  AjustesCompanion toCompanion(bool nullToAbsent) {
    return AjustesCompanion(clave: Value(clave), valor: Value(valor));
  }

  factory Ajuste.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Ajuste(
      clave: serializer.fromJson<String>(json['clave']),
      valor: serializer.fromJson<String>(json['valor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clave': serializer.toJson<String>(clave),
      'valor': serializer.toJson<String>(valor),
    };
  }

  Ajuste copyWith({String? clave, String? valor}) =>
      Ajuste(clave: clave ?? this.clave, valor: valor ?? this.valor);
  Ajuste copyWithCompanion(AjustesCompanion data) {
    return Ajuste(
      clave: data.clave.present ? data.clave.value : this.clave,
      valor: data.valor.present ? data.valor.value : this.valor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Ajuste(')
          ..write('clave: $clave, ')
          ..write('valor: $valor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(clave, valor);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Ajuste &&
          other.clave == this.clave &&
          other.valor == this.valor);
}

class AjustesCompanion extends UpdateCompanion<Ajuste> {
  final Value<String> clave;
  final Value<String> valor;
  final Value<int> rowid;
  const AjustesCompanion({
    this.clave = const Value.absent(),
    this.valor = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AjustesCompanion.insert({
    required String clave,
    required String valor,
    this.rowid = const Value.absent(),
  }) : clave = Value(clave),
       valor = Value(valor);
  static Insertable<Ajuste> custom({
    Expression<String>? clave,
    Expression<String>? valor,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clave != null) 'clave': clave,
      if (valor != null) 'valor': valor,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AjustesCompanion copyWith({
    Value<String>? clave,
    Value<String>? valor,
    Value<int>? rowid,
  }) {
    return AjustesCompanion(
      clave: clave ?? this.clave,
      valor: valor ?? this.valor,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clave.present) {
      map['clave'] = Variable<String>(clave.value);
    }
    if (valor.present) {
      map['valor'] = Variable<String>(valor.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AjustesCompanion(')
          ..write('clave: $clave, ')
          ..write('valor: $valor, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CatalogoCamposTable extends CatalogoCampos
    with TableInfo<$CatalogoCamposTable, CatalogoCampo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CatalogoCamposTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _claveTecnicaMeta = const VerificationMeta(
    'claveTecnica',
  );
  @override
  late final GeneratedColumn<String> claveTecnica = GeneratedColumn<String>(
    'clave_tecnica',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _campoMeta = const VerificationMeta('campo');
  @override
  late final GeneratedColumn<String> campo = GeneratedColumn<String>(
    'campo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _moduloMeta = const VerificationMeta('modulo');
  @override
  late final GeneratedColumn<String> modulo = GeneratedColumn<String>(
    'modulo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tipoDatoMeta = const VerificationMeta(
    'tipoDato',
  );
  @override
  late final GeneratedColumn<String> tipoDato = GeneratedColumn<String>(
    'tipo_dato',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Texto'),
  );
  static const VerificationMeta _unidadMeta = const VerificationMeta('unidad');
  @override
  late final GeneratedColumn<String> unidad = GeneratedColumn<String>(
    'unidad',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _opcionesMeta = const VerificationMeta(
    'opciones',
  );
  @override
  late final GeneratedColumn<String> opciones = GeneratedColumn<String>(
    'opciones',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _preguntaGuiaMeta = const VerificationMeta(
    'preguntaGuia',
  );
  @override
  late final GeneratedColumn<String> preguntaGuia = GeneratedColumn<String>(
    'pregunta_guia',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descripcionMeta = const VerificationMeta(
    'descripcion',
  );
  @override
  late final GeneratedColumn<String> descripcion = GeneratedColumn<String>(
    'descripcion',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _obligatorioMvpMeta = const VerificationMeta(
    'obligatorioMvp',
  );
  @override
  late final GeneratedColumn<bool> obligatorioMvp = GeneratedColumn<bool>(
    'obligatorio_mvp',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("obligatorio_mvp" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _prioridadMeta = const VerificationMeta(
    'prioridad',
  );
  @override
  late final GeneratedColumn<String> prioridad = GeneratedColumn<String>(
    'prioridad',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activoMeta = const VerificationMeta('activo');
  @override
  late final GeneratedColumn<bool> activo = GeneratedColumn<bool>(
    'activo',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("activo" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _noSugerirMeta = const VerificationMeta(
    'noSugerir',
  );
  @override
  late final GeneratedColumn<bool> noSugerir = GeneratedColumn<bool>(
    'no_sugerir',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("no_sugerir" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _actualizadoEnMeta = const VerificationMeta(
    'actualizadoEn',
  );
  @override
  late final GeneratedColumn<DateTime> actualizadoEn =
      GeneratedColumn<DateTime>(
        'actualizado_en',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    claveTecnica,
    campo,
    modulo,
    tipoDato,
    unidad,
    opciones,
    preguntaGuia,
    descripcion,
    obligatorioMvp,
    prioridad,
    activo,
    noSugerir,
    actualizadoEn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'catalogo_campos';
  @override
  VerificationContext validateIntegrity(
    Insertable<CatalogoCampo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('clave_tecnica')) {
      context.handle(
        _claveTecnicaMeta,
        claveTecnica.isAcceptableOrUnknown(
          data['clave_tecnica']!,
          _claveTecnicaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_claveTecnicaMeta);
    }
    if (data.containsKey('campo')) {
      context.handle(
        _campoMeta,
        campo.isAcceptableOrUnknown(data['campo']!, _campoMeta),
      );
    } else if (isInserting) {
      context.missing(_campoMeta);
    }
    if (data.containsKey('modulo')) {
      context.handle(
        _moduloMeta,
        modulo.isAcceptableOrUnknown(data['modulo']!, _moduloMeta),
      );
    } else if (isInserting) {
      context.missing(_moduloMeta);
    }
    if (data.containsKey('tipo_dato')) {
      context.handle(
        _tipoDatoMeta,
        tipoDato.isAcceptableOrUnknown(data['tipo_dato']!, _tipoDatoMeta),
      );
    }
    if (data.containsKey('unidad')) {
      context.handle(
        _unidadMeta,
        unidad.isAcceptableOrUnknown(data['unidad']!, _unidadMeta),
      );
    }
    if (data.containsKey('opciones')) {
      context.handle(
        _opcionesMeta,
        opciones.isAcceptableOrUnknown(data['opciones']!, _opcionesMeta),
      );
    }
    if (data.containsKey('pregunta_guia')) {
      context.handle(
        _preguntaGuiaMeta,
        preguntaGuia.isAcceptableOrUnknown(
          data['pregunta_guia']!,
          _preguntaGuiaMeta,
        ),
      );
    }
    if (data.containsKey('descripcion')) {
      context.handle(
        _descripcionMeta,
        descripcion.isAcceptableOrUnknown(
          data['descripcion']!,
          _descripcionMeta,
        ),
      );
    }
    if (data.containsKey('obligatorio_mvp')) {
      context.handle(
        _obligatorioMvpMeta,
        obligatorioMvp.isAcceptableOrUnknown(
          data['obligatorio_mvp']!,
          _obligatorioMvpMeta,
        ),
      );
    }
    if (data.containsKey('prioridad')) {
      context.handle(
        _prioridadMeta,
        prioridad.isAcceptableOrUnknown(data['prioridad']!, _prioridadMeta),
      );
    }
    if (data.containsKey('activo')) {
      context.handle(
        _activoMeta,
        activo.isAcceptableOrUnknown(data['activo']!, _activoMeta),
      );
    }
    if (data.containsKey('no_sugerir')) {
      context.handle(
        _noSugerirMeta,
        noSugerir.isAcceptableOrUnknown(data['no_sugerir']!, _noSugerirMeta),
      );
    }
    if (data.containsKey('actualizado_en')) {
      context.handle(
        _actualizadoEnMeta,
        actualizadoEn.isAcceptableOrUnknown(
          data['actualizado_en']!,
          _actualizadoEnMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {claveTecnica};
  @override
  CatalogoCampo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CatalogoCampo(
      claveTecnica: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clave_tecnica'],
      )!,
      campo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}campo'],
      )!,
      modulo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}modulo'],
      )!,
      tipoDato: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo_dato'],
      )!,
      unidad: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unidad'],
      ),
      opciones: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}opciones'],
      ),
      preguntaGuia: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pregunta_guia'],
      ),
      descripcion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}descripcion'],
      ),
      obligatorioMvp: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}obligatorio_mvp'],
      )!,
      prioridad: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prioridad'],
      ),
      activo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}activo'],
      )!,
      noSugerir: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}no_sugerir'],
      )!,
      actualizadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}actualizado_en'],
      ),
    );
  }

  @override
  $CatalogoCamposTable createAlias(String alias) {
    return $CatalogoCamposTable(attachedDatabase, alias);
  }
}

class CatalogoCampo extends DataClass implements Insertable<CatalogoCampo> {
  final String claveTecnica;
  final String campo;
  final String modulo;
  final String tipoDato;
  final String? unidad;

  /// Valores permitidos cuando tipoDato = Lista, uno por linea.
  final String? opciones;

  /// El motor de faltantes usa esta pregunta TEXTUALMENTE. No la reescribe.
  final String? preguntaGuia;
  final String? descripcion;
  final bool obligatorioMvp;
  final String? prioridad;

  /// Alcance de la version. activo = false significa que sigue existiendo como
  /// esquema pero no se le pide al modelo. Se prende sin tocar codigo.
  final bool activo;

  /// Cuenta para la completitud pero NUNCA se le sugiere al visitador como
  /// pregunta pendiente. Para temas sensibles que solo se registran si el
  /// productor los cuenta por su cuenta. Invertido igual que en Airtable,
  /// donde una casilla no puede venir marcada por defecto.
  final bool noSugerir;
  final DateTime? actualizadoEn;
  const CatalogoCampo({
    required this.claveTecnica,
    required this.campo,
    required this.modulo,
    required this.tipoDato,
    this.unidad,
    this.opciones,
    this.preguntaGuia,
    this.descripcion,
    required this.obligatorioMvp,
    this.prioridad,
    required this.activo,
    required this.noSugerir,
    this.actualizadoEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['clave_tecnica'] = Variable<String>(claveTecnica);
    map['campo'] = Variable<String>(campo);
    map['modulo'] = Variable<String>(modulo);
    map['tipo_dato'] = Variable<String>(tipoDato);
    if (!nullToAbsent || unidad != null) {
      map['unidad'] = Variable<String>(unidad);
    }
    if (!nullToAbsent || opciones != null) {
      map['opciones'] = Variable<String>(opciones);
    }
    if (!nullToAbsent || preguntaGuia != null) {
      map['pregunta_guia'] = Variable<String>(preguntaGuia);
    }
    if (!nullToAbsent || descripcion != null) {
      map['descripcion'] = Variable<String>(descripcion);
    }
    map['obligatorio_mvp'] = Variable<bool>(obligatorioMvp);
    if (!nullToAbsent || prioridad != null) {
      map['prioridad'] = Variable<String>(prioridad);
    }
    map['activo'] = Variable<bool>(activo);
    map['no_sugerir'] = Variable<bool>(noSugerir);
    if (!nullToAbsent || actualizadoEn != null) {
      map['actualizado_en'] = Variable<DateTime>(actualizadoEn);
    }
    return map;
  }

  CatalogoCamposCompanion toCompanion(bool nullToAbsent) {
    return CatalogoCamposCompanion(
      claveTecnica: Value(claveTecnica),
      campo: Value(campo),
      modulo: Value(modulo),
      tipoDato: Value(tipoDato),
      unidad: unidad == null && nullToAbsent
          ? const Value.absent()
          : Value(unidad),
      opciones: opciones == null && nullToAbsent
          ? const Value.absent()
          : Value(opciones),
      preguntaGuia: preguntaGuia == null && nullToAbsent
          ? const Value.absent()
          : Value(preguntaGuia),
      descripcion: descripcion == null && nullToAbsent
          ? const Value.absent()
          : Value(descripcion),
      obligatorioMvp: Value(obligatorioMvp),
      prioridad: prioridad == null && nullToAbsent
          ? const Value.absent()
          : Value(prioridad),
      activo: Value(activo),
      noSugerir: Value(noSugerir),
      actualizadoEn: actualizadoEn == null && nullToAbsent
          ? const Value.absent()
          : Value(actualizadoEn),
    );
  }

  factory CatalogoCampo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CatalogoCampo(
      claveTecnica: serializer.fromJson<String>(json['claveTecnica']),
      campo: serializer.fromJson<String>(json['campo']),
      modulo: serializer.fromJson<String>(json['modulo']),
      tipoDato: serializer.fromJson<String>(json['tipoDato']),
      unidad: serializer.fromJson<String?>(json['unidad']),
      opciones: serializer.fromJson<String?>(json['opciones']),
      preguntaGuia: serializer.fromJson<String?>(json['preguntaGuia']),
      descripcion: serializer.fromJson<String?>(json['descripcion']),
      obligatorioMvp: serializer.fromJson<bool>(json['obligatorioMvp']),
      prioridad: serializer.fromJson<String?>(json['prioridad']),
      activo: serializer.fromJson<bool>(json['activo']),
      noSugerir: serializer.fromJson<bool>(json['noSugerir']),
      actualizadoEn: serializer.fromJson<DateTime?>(json['actualizadoEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'claveTecnica': serializer.toJson<String>(claveTecnica),
      'campo': serializer.toJson<String>(campo),
      'modulo': serializer.toJson<String>(modulo),
      'tipoDato': serializer.toJson<String>(tipoDato),
      'unidad': serializer.toJson<String?>(unidad),
      'opciones': serializer.toJson<String?>(opciones),
      'preguntaGuia': serializer.toJson<String?>(preguntaGuia),
      'descripcion': serializer.toJson<String?>(descripcion),
      'obligatorioMvp': serializer.toJson<bool>(obligatorioMvp),
      'prioridad': serializer.toJson<String?>(prioridad),
      'activo': serializer.toJson<bool>(activo),
      'noSugerir': serializer.toJson<bool>(noSugerir),
      'actualizadoEn': serializer.toJson<DateTime?>(actualizadoEn),
    };
  }

  CatalogoCampo copyWith({
    String? claveTecnica,
    String? campo,
    String? modulo,
    String? tipoDato,
    Value<String?> unidad = const Value.absent(),
    Value<String?> opciones = const Value.absent(),
    Value<String?> preguntaGuia = const Value.absent(),
    Value<String?> descripcion = const Value.absent(),
    bool? obligatorioMvp,
    Value<String?> prioridad = const Value.absent(),
    bool? activo,
    bool? noSugerir,
    Value<DateTime?> actualizadoEn = const Value.absent(),
  }) => CatalogoCampo(
    claveTecnica: claveTecnica ?? this.claveTecnica,
    campo: campo ?? this.campo,
    modulo: modulo ?? this.modulo,
    tipoDato: tipoDato ?? this.tipoDato,
    unidad: unidad.present ? unidad.value : this.unidad,
    opciones: opciones.present ? opciones.value : this.opciones,
    preguntaGuia: preguntaGuia.present ? preguntaGuia.value : this.preguntaGuia,
    descripcion: descripcion.present ? descripcion.value : this.descripcion,
    obligatorioMvp: obligatorioMvp ?? this.obligatorioMvp,
    prioridad: prioridad.present ? prioridad.value : this.prioridad,
    activo: activo ?? this.activo,
    noSugerir: noSugerir ?? this.noSugerir,
    actualizadoEn: actualizadoEn.present
        ? actualizadoEn.value
        : this.actualizadoEn,
  );
  CatalogoCampo copyWithCompanion(CatalogoCamposCompanion data) {
    return CatalogoCampo(
      claveTecnica: data.claveTecnica.present
          ? data.claveTecnica.value
          : this.claveTecnica,
      campo: data.campo.present ? data.campo.value : this.campo,
      modulo: data.modulo.present ? data.modulo.value : this.modulo,
      tipoDato: data.tipoDato.present ? data.tipoDato.value : this.tipoDato,
      unidad: data.unidad.present ? data.unidad.value : this.unidad,
      opciones: data.opciones.present ? data.opciones.value : this.opciones,
      preguntaGuia: data.preguntaGuia.present
          ? data.preguntaGuia.value
          : this.preguntaGuia,
      descripcion: data.descripcion.present
          ? data.descripcion.value
          : this.descripcion,
      obligatorioMvp: data.obligatorioMvp.present
          ? data.obligatorioMvp.value
          : this.obligatorioMvp,
      prioridad: data.prioridad.present ? data.prioridad.value : this.prioridad,
      activo: data.activo.present ? data.activo.value : this.activo,
      noSugerir: data.noSugerir.present ? data.noSugerir.value : this.noSugerir,
      actualizadoEn: data.actualizadoEn.present
          ? data.actualizadoEn.value
          : this.actualizadoEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CatalogoCampo(')
          ..write('claveTecnica: $claveTecnica, ')
          ..write('campo: $campo, ')
          ..write('modulo: $modulo, ')
          ..write('tipoDato: $tipoDato, ')
          ..write('unidad: $unidad, ')
          ..write('opciones: $opciones, ')
          ..write('preguntaGuia: $preguntaGuia, ')
          ..write('descripcion: $descripcion, ')
          ..write('obligatorioMvp: $obligatorioMvp, ')
          ..write('prioridad: $prioridad, ')
          ..write('activo: $activo, ')
          ..write('noSugerir: $noSugerir, ')
          ..write('actualizadoEn: $actualizadoEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    claveTecnica,
    campo,
    modulo,
    tipoDato,
    unidad,
    opciones,
    preguntaGuia,
    descripcion,
    obligatorioMvp,
    prioridad,
    activo,
    noSugerir,
    actualizadoEn,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CatalogoCampo &&
          other.claveTecnica == this.claveTecnica &&
          other.campo == this.campo &&
          other.modulo == this.modulo &&
          other.tipoDato == this.tipoDato &&
          other.unidad == this.unidad &&
          other.opciones == this.opciones &&
          other.preguntaGuia == this.preguntaGuia &&
          other.descripcion == this.descripcion &&
          other.obligatorioMvp == this.obligatorioMvp &&
          other.prioridad == this.prioridad &&
          other.activo == this.activo &&
          other.noSugerir == this.noSugerir &&
          other.actualizadoEn == this.actualizadoEn);
}

class CatalogoCamposCompanion extends UpdateCompanion<CatalogoCampo> {
  final Value<String> claveTecnica;
  final Value<String> campo;
  final Value<String> modulo;
  final Value<String> tipoDato;
  final Value<String?> unidad;
  final Value<String?> opciones;
  final Value<String?> preguntaGuia;
  final Value<String?> descripcion;
  final Value<bool> obligatorioMvp;
  final Value<String?> prioridad;
  final Value<bool> activo;
  final Value<bool> noSugerir;
  final Value<DateTime?> actualizadoEn;
  final Value<int> rowid;
  const CatalogoCamposCompanion({
    this.claveTecnica = const Value.absent(),
    this.campo = const Value.absent(),
    this.modulo = const Value.absent(),
    this.tipoDato = const Value.absent(),
    this.unidad = const Value.absent(),
    this.opciones = const Value.absent(),
    this.preguntaGuia = const Value.absent(),
    this.descripcion = const Value.absent(),
    this.obligatorioMvp = const Value.absent(),
    this.prioridad = const Value.absent(),
    this.activo = const Value.absent(),
    this.noSugerir = const Value.absent(),
    this.actualizadoEn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CatalogoCamposCompanion.insert({
    required String claveTecnica,
    required String campo,
    required String modulo,
    this.tipoDato = const Value.absent(),
    this.unidad = const Value.absent(),
    this.opciones = const Value.absent(),
    this.preguntaGuia = const Value.absent(),
    this.descripcion = const Value.absent(),
    this.obligatorioMvp = const Value.absent(),
    this.prioridad = const Value.absent(),
    this.activo = const Value.absent(),
    this.noSugerir = const Value.absent(),
    this.actualizadoEn = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : claveTecnica = Value(claveTecnica),
       campo = Value(campo),
       modulo = Value(modulo);
  static Insertable<CatalogoCampo> custom({
    Expression<String>? claveTecnica,
    Expression<String>? campo,
    Expression<String>? modulo,
    Expression<String>? tipoDato,
    Expression<String>? unidad,
    Expression<String>? opciones,
    Expression<String>? preguntaGuia,
    Expression<String>? descripcion,
    Expression<bool>? obligatorioMvp,
    Expression<String>? prioridad,
    Expression<bool>? activo,
    Expression<bool>? noSugerir,
    Expression<DateTime>? actualizadoEn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (claveTecnica != null) 'clave_tecnica': claveTecnica,
      if (campo != null) 'campo': campo,
      if (modulo != null) 'modulo': modulo,
      if (tipoDato != null) 'tipo_dato': tipoDato,
      if (unidad != null) 'unidad': unidad,
      if (opciones != null) 'opciones': opciones,
      if (preguntaGuia != null) 'pregunta_guia': preguntaGuia,
      if (descripcion != null) 'descripcion': descripcion,
      if (obligatorioMvp != null) 'obligatorio_mvp': obligatorioMvp,
      if (prioridad != null) 'prioridad': prioridad,
      if (activo != null) 'activo': activo,
      if (noSugerir != null) 'no_sugerir': noSugerir,
      if (actualizadoEn != null) 'actualizado_en': actualizadoEn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CatalogoCamposCompanion copyWith({
    Value<String>? claveTecnica,
    Value<String>? campo,
    Value<String>? modulo,
    Value<String>? tipoDato,
    Value<String?>? unidad,
    Value<String?>? opciones,
    Value<String?>? preguntaGuia,
    Value<String?>? descripcion,
    Value<bool>? obligatorioMvp,
    Value<String?>? prioridad,
    Value<bool>? activo,
    Value<bool>? noSugerir,
    Value<DateTime?>? actualizadoEn,
    Value<int>? rowid,
  }) {
    return CatalogoCamposCompanion(
      claveTecnica: claveTecnica ?? this.claveTecnica,
      campo: campo ?? this.campo,
      modulo: modulo ?? this.modulo,
      tipoDato: tipoDato ?? this.tipoDato,
      unidad: unidad ?? this.unidad,
      opciones: opciones ?? this.opciones,
      preguntaGuia: preguntaGuia ?? this.preguntaGuia,
      descripcion: descripcion ?? this.descripcion,
      obligatorioMvp: obligatorioMvp ?? this.obligatorioMvp,
      prioridad: prioridad ?? this.prioridad,
      activo: activo ?? this.activo,
      noSugerir: noSugerir ?? this.noSugerir,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (claveTecnica.present) {
      map['clave_tecnica'] = Variable<String>(claveTecnica.value);
    }
    if (campo.present) {
      map['campo'] = Variable<String>(campo.value);
    }
    if (modulo.present) {
      map['modulo'] = Variable<String>(modulo.value);
    }
    if (tipoDato.present) {
      map['tipo_dato'] = Variable<String>(tipoDato.value);
    }
    if (unidad.present) {
      map['unidad'] = Variable<String>(unidad.value);
    }
    if (opciones.present) {
      map['opciones'] = Variable<String>(opciones.value);
    }
    if (preguntaGuia.present) {
      map['pregunta_guia'] = Variable<String>(preguntaGuia.value);
    }
    if (descripcion.present) {
      map['descripcion'] = Variable<String>(descripcion.value);
    }
    if (obligatorioMvp.present) {
      map['obligatorio_mvp'] = Variable<bool>(obligatorioMvp.value);
    }
    if (prioridad.present) {
      map['prioridad'] = Variable<String>(prioridad.value);
    }
    if (activo.present) {
      map['activo'] = Variable<bool>(activo.value);
    }
    if (noSugerir.present) {
      map['no_sugerir'] = Variable<bool>(noSugerir.value);
    }
    if (actualizadoEn.present) {
      map['actualizado_en'] = Variable<DateTime>(actualizadoEn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CatalogoCamposCompanion(')
          ..write('claveTecnica: $claveTecnica, ')
          ..write('campo: $campo, ')
          ..write('modulo: $modulo, ')
          ..write('tipoDato: $tipoDato, ')
          ..write('unidad: $unidad, ')
          ..write('opciones: $opciones, ')
          ..write('preguntaGuia: $preguntaGuia, ')
          ..write('descripcion: $descripcion, ')
          ..write('obligatorioMvp: $obligatorioMvp, ')
          ..write('prioridad: $prioridad, ')
          ..write('activo: $activo, ')
          ..write('noSugerir: $noSugerir, ')
          ..write('actualizadoEn: $actualizadoEn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VeredasTable extends Veredas with TableInfo<$VeredasTable, Vereda> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VeredasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _veredaMeta = const VerificationMeta('vereda');
  @override
  late final GeneratedColumn<String> vereda = GeneratedColumn<String>(
    'vereda',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _municipioMeta = const VerificationMeta(
    'municipio',
  );
  @override
  late final GeneratedColumn<String> municipio = GeneratedColumn<String>(
    'municipio',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _departamentoMeta = const VerificationMeta(
    'departamento',
  );
  @override
  late final GeneratedColumn<String> departamento = GeneratedColumn<String>(
    'departamento',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    vereda,
    municipio,
    departamento,
    remoteId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'veredas';
  @override
  VerificationContext validateIntegrity(
    Insertable<Vereda> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('vereda')) {
      context.handle(
        _veredaMeta,
        vereda.isAcceptableOrUnknown(data['vereda']!, _veredaMeta),
      );
    } else if (isInserting) {
      context.missing(_veredaMeta);
    }
    if (data.containsKey('municipio')) {
      context.handle(
        _municipioMeta,
        municipio.isAcceptableOrUnknown(data['municipio']!, _municipioMeta),
      );
    } else if (isInserting) {
      context.missing(_municipioMeta);
    }
    if (data.containsKey('departamento')) {
      context.handle(
        _departamentoMeta,
        departamento.isAcceptableOrUnknown(
          data['departamento']!,
          _departamentoMeta,
        ),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Vereda map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Vereda(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      vereda: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vereda'],
      )!,
      municipio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}municipio'],
      )!,
      departamento: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}departamento'],
      ),
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
    );
  }

  @override
  $VeredasTable createAlias(String alias) {
    return $VeredasTable(attachedDatabase, alias);
  }
}

class Vereda extends DataClass implements Insertable<Vereda> {
  final String id;
  final String vereda;
  final String municipio;
  final String? departamento;
  final String? remoteId;
  const Vereda({
    required this.id,
    required this.vereda,
    required this.municipio,
    this.departamento,
    this.remoteId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['vereda'] = Variable<String>(vereda);
    map['municipio'] = Variable<String>(municipio);
    if (!nullToAbsent || departamento != null) {
      map['departamento'] = Variable<String>(departamento);
    }
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    return map;
  }

  VeredasCompanion toCompanion(bool nullToAbsent) {
    return VeredasCompanion(
      id: Value(id),
      vereda: Value(vereda),
      municipio: Value(municipio),
      departamento: departamento == null && nullToAbsent
          ? const Value.absent()
          : Value(departamento),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
    );
  }

  factory Vereda.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Vereda(
      id: serializer.fromJson<String>(json['id']),
      vereda: serializer.fromJson<String>(json['vereda']),
      municipio: serializer.fromJson<String>(json['municipio']),
      departamento: serializer.fromJson<String?>(json['departamento']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'vereda': serializer.toJson<String>(vereda),
      'municipio': serializer.toJson<String>(municipio),
      'departamento': serializer.toJson<String?>(departamento),
      'remoteId': serializer.toJson<String?>(remoteId),
    };
  }

  Vereda copyWith({
    String? id,
    String? vereda,
    String? municipio,
    Value<String?> departamento = const Value.absent(),
    Value<String?> remoteId = const Value.absent(),
  }) => Vereda(
    id: id ?? this.id,
    vereda: vereda ?? this.vereda,
    municipio: municipio ?? this.municipio,
    departamento: departamento.present ? departamento.value : this.departamento,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
  );
  Vereda copyWithCompanion(VeredasCompanion data) {
    return Vereda(
      id: data.id.present ? data.id.value : this.id,
      vereda: data.vereda.present ? data.vereda.value : this.vereda,
      municipio: data.municipio.present ? data.municipio.value : this.municipio,
      departamento: data.departamento.present
          ? data.departamento.value
          : this.departamento,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Vereda(')
          ..write('id: $id, ')
          ..write('vereda: $vereda, ')
          ..write('municipio: $municipio, ')
          ..write('departamento: $departamento, ')
          ..write('remoteId: $remoteId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, vereda, municipio, departamento, remoteId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Vereda &&
          other.id == this.id &&
          other.vereda == this.vereda &&
          other.municipio == this.municipio &&
          other.departamento == this.departamento &&
          other.remoteId == this.remoteId);
}

class VeredasCompanion extends UpdateCompanion<Vereda> {
  final Value<String> id;
  final Value<String> vereda;
  final Value<String> municipio;
  final Value<String?> departamento;
  final Value<String?> remoteId;
  final Value<int> rowid;
  const VeredasCompanion({
    this.id = const Value.absent(),
    this.vereda = const Value.absent(),
    this.municipio = const Value.absent(),
    this.departamento = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VeredasCompanion.insert({
    required String id,
    required String vereda,
    required String municipio,
    this.departamento = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       vereda = Value(vereda),
       municipio = Value(municipio);
  static Insertable<Vereda> custom({
    Expression<String>? id,
    Expression<String>? vereda,
    Expression<String>? municipio,
    Expression<String>? departamento,
    Expression<String>? remoteId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vereda != null) 'vereda': vereda,
      if (municipio != null) 'municipio': municipio,
      if (departamento != null) 'departamento': departamento,
      if (remoteId != null) 'remote_id': remoteId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VeredasCompanion copyWith({
    Value<String>? id,
    Value<String>? vereda,
    Value<String>? municipio,
    Value<String?>? departamento,
    Value<String?>? remoteId,
    Value<int>? rowid,
  }) {
    return VeredasCompanion(
      id: id ?? this.id,
      vereda: vereda ?? this.vereda,
      municipio: municipio ?? this.municipio,
      departamento: departamento ?? this.departamento,
      remoteId: remoteId ?? this.remoteId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (vereda.present) {
      map['vereda'] = Variable<String>(vereda.value);
    }
    if (municipio.present) {
      map['municipio'] = Variable<String>(municipio.value);
    }
    if (departamento.present) {
      map['departamento'] = Variable<String>(departamento.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VeredasCompanion(')
          ..write('id: $id, ')
          ..write('vereda: $vereda, ')
          ..write('municipio: $municipio, ')
          ..write('departamento: $departamento, ')
          ..write('remoteId: $remoteId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VisitadoresTable extends Visitadores
    with TableInfo<$VisitadoresTable, Visitador> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VisitadoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idEmpleadoMeta = const VerificationMeta(
    'idEmpleado',
  );
  @override
  late final GeneratedColumn<String> idEmpleado = GeneratedColumn<String>(
    'id_empleado',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usuarioAppMeta = const VerificationMeta(
    'usuarioApp',
  );
  @override
  late final GeneratedColumn<String> usuarioApp = GeneratedColumn<String>(
    'usuario_app',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cargoMeta = const VerificationMeta('cargo');
  @override
  late final GeneratedColumn<String> cargo = GeneratedColumn<String>(
    'cargo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _telefonoMeta = const VerificationMeta(
    'telefono',
  );
  @override
  late final GeneratedColumn<String> telefono = GeneratedColumn<String>(
    'telefono',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rolMeta = const VerificationMeta('rol');
  @override
  late final GeneratedColumn<String> rol = GeneratedColumn<String>(
    'rol',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activoMeta = const VerificationMeta('activo');
  @override
  late final GeneratedColumn<bool> activo = GeneratedColumn<bool>(
    'activo',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("activo" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    idEmpleado,
    nombre,
    usuarioApp,
    cargo,
    email,
    telefono,
    rol,
    activo,
    remoteId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'visitadores';
  @override
  VerificationContext validateIntegrity(
    Insertable<Visitador> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('id_empleado')) {
      context.handle(
        _idEmpleadoMeta,
        idEmpleado.isAcceptableOrUnknown(data['id_empleado']!, _idEmpleadoMeta),
      );
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('usuario_app')) {
      context.handle(
        _usuarioAppMeta,
        usuarioApp.isAcceptableOrUnknown(data['usuario_app']!, _usuarioAppMeta),
      );
    } else if (isInserting) {
      context.missing(_usuarioAppMeta);
    }
    if (data.containsKey('cargo')) {
      context.handle(
        _cargoMeta,
        cargo.isAcceptableOrUnknown(data['cargo']!, _cargoMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('telefono')) {
      context.handle(
        _telefonoMeta,
        telefono.isAcceptableOrUnknown(data['telefono']!, _telefonoMeta),
      );
    }
    if (data.containsKey('rol')) {
      context.handle(
        _rolMeta,
        rol.isAcceptableOrUnknown(data['rol']!, _rolMeta),
      );
    }
    if (data.containsKey('activo')) {
      context.handle(
        _activoMeta,
        activo.isAcceptableOrUnknown(data['activo']!, _activoMeta),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Visitador map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Visitador(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      idEmpleado: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id_empleado'],
      ),
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      usuarioApp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}usuario_app'],
      )!,
      cargo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cargo'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      telefono: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}telefono'],
      ),
      rol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rol'],
      ),
      activo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}activo'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
    );
  }

  @override
  $VisitadoresTable createAlias(String alias) {
    return $VisitadoresTable(attachedDatabase, alias);
  }
}

class Visitador extends DataClass implements Insertable<Visitador> {
  final String id;

  /// SIRIUS-PER-XXXX. Llave estable hacia la nomina.
  final String? idEmpleado;
  final String nombre;
  final String usuarioApp;

  /// Cargo en la empresa, tal como esta en nomina. Distinto de [rol], que es
  /// el papel dentro de esta app.
  final String? cargo;
  final String? email;
  final String? telefono;
  final String? rol;
  final bool activo;
  final String? remoteId;
  const Visitador({
    required this.id,
    this.idEmpleado,
    required this.nombre,
    required this.usuarioApp,
    this.cargo,
    this.email,
    this.telefono,
    this.rol,
    required this.activo,
    this.remoteId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || idEmpleado != null) {
      map['id_empleado'] = Variable<String>(idEmpleado);
    }
    map['nombre'] = Variable<String>(nombre);
    map['usuario_app'] = Variable<String>(usuarioApp);
    if (!nullToAbsent || cargo != null) {
      map['cargo'] = Variable<String>(cargo);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || telefono != null) {
      map['telefono'] = Variable<String>(telefono);
    }
    if (!nullToAbsent || rol != null) {
      map['rol'] = Variable<String>(rol);
    }
    map['activo'] = Variable<bool>(activo);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    return map;
  }

  VisitadoresCompanion toCompanion(bool nullToAbsent) {
    return VisitadoresCompanion(
      id: Value(id),
      idEmpleado: idEmpleado == null && nullToAbsent
          ? const Value.absent()
          : Value(idEmpleado),
      nombre: Value(nombre),
      usuarioApp: Value(usuarioApp),
      cargo: cargo == null && nullToAbsent
          ? const Value.absent()
          : Value(cargo),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      telefono: telefono == null && nullToAbsent
          ? const Value.absent()
          : Value(telefono),
      rol: rol == null && nullToAbsent ? const Value.absent() : Value(rol),
      activo: Value(activo),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
    );
  }

  factory Visitador.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Visitador(
      id: serializer.fromJson<String>(json['id']),
      idEmpleado: serializer.fromJson<String?>(json['idEmpleado']),
      nombre: serializer.fromJson<String>(json['nombre']),
      usuarioApp: serializer.fromJson<String>(json['usuarioApp']),
      cargo: serializer.fromJson<String?>(json['cargo']),
      email: serializer.fromJson<String?>(json['email']),
      telefono: serializer.fromJson<String?>(json['telefono']),
      rol: serializer.fromJson<String?>(json['rol']),
      activo: serializer.fromJson<bool>(json['activo']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'idEmpleado': serializer.toJson<String?>(idEmpleado),
      'nombre': serializer.toJson<String>(nombre),
      'usuarioApp': serializer.toJson<String>(usuarioApp),
      'cargo': serializer.toJson<String?>(cargo),
      'email': serializer.toJson<String?>(email),
      'telefono': serializer.toJson<String?>(telefono),
      'rol': serializer.toJson<String?>(rol),
      'activo': serializer.toJson<bool>(activo),
      'remoteId': serializer.toJson<String?>(remoteId),
    };
  }

  Visitador copyWith({
    String? id,
    Value<String?> idEmpleado = const Value.absent(),
    String? nombre,
    String? usuarioApp,
    Value<String?> cargo = const Value.absent(),
    Value<String?> email = const Value.absent(),
    Value<String?> telefono = const Value.absent(),
    Value<String?> rol = const Value.absent(),
    bool? activo,
    Value<String?> remoteId = const Value.absent(),
  }) => Visitador(
    id: id ?? this.id,
    idEmpleado: idEmpleado.present ? idEmpleado.value : this.idEmpleado,
    nombre: nombre ?? this.nombre,
    usuarioApp: usuarioApp ?? this.usuarioApp,
    cargo: cargo.present ? cargo.value : this.cargo,
    email: email.present ? email.value : this.email,
    telefono: telefono.present ? telefono.value : this.telefono,
    rol: rol.present ? rol.value : this.rol,
    activo: activo ?? this.activo,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
  );
  Visitador copyWithCompanion(VisitadoresCompanion data) {
    return Visitador(
      id: data.id.present ? data.id.value : this.id,
      idEmpleado: data.idEmpleado.present
          ? data.idEmpleado.value
          : this.idEmpleado,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      usuarioApp: data.usuarioApp.present
          ? data.usuarioApp.value
          : this.usuarioApp,
      cargo: data.cargo.present ? data.cargo.value : this.cargo,
      email: data.email.present ? data.email.value : this.email,
      telefono: data.telefono.present ? data.telefono.value : this.telefono,
      rol: data.rol.present ? data.rol.value : this.rol,
      activo: data.activo.present ? data.activo.value : this.activo,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Visitador(')
          ..write('id: $id, ')
          ..write('idEmpleado: $idEmpleado, ')
          ..write('nombre: $nombre, ')
          ..write('usuarioApp: $usuarioApp, ')
          ..write('cargo: $cargo, ')
          ..write('email: $email, ')
          ..write('telefono: $telefono, ')
          ..write('rol: $rol, ')
          ..write('activo: $activo, ')
          ..write('remoteId: $remoteId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    idEmpleado,
    nombre,
    usuarioApp,
    cargo,
    email,
    telefono,
    rol,
    activo,
    remoteId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Visitador &&
          other.id == this.id &&
          other.idEmpleado == this.idEmpleado &&
          other.nombre == this.nombre &&
          other.usuarioApp == this.usuarioApp &&
          other.cargo == this.cargo &&
          other.email == this.email &&
          other.telefono == this.telefono &&
          other.rol == this.rol &&
          other.activo == this.activo &&
          other.remoteId == this.remoteId);
}

class VisitadoresCompanion extends UpdateCompanion<Visitador> {
  final Value<String> id;
  final Value<String?> idEmpleado;
  final Value<String> nombre;
  final Value<String> usuarioApp;
  final Value<String?> cargo;
  final Value<String?> email;
  final Value<String?> telefono;
  final Value<String?> rol;
  final Value<bool> activo;
  final Value<String?> remoteId;
  final Value<int> rowid;
  const VisitadoresCompanion({
    this.id = const Value.absent(),
    this.idEmpleado = const Value.absent(),
    this.nombre = const Value.absent(),
    this.usuarioApp = const Value.absent(),
    this.cargo = const Value.absent(),
    this.email = const Value.absent(),
    this.telefono = const Value.absent(),
    this.rol = const Value.absent(),
    this.activo = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VisitadoresCompanion.insert({
    required String id,
    this.idEmpleado = const Value.absent(),
    required String nombre,
    required String usuarioApp,
    this.cargo = const Value.absent(),
    this.email = const Value.absent(),
    this.telefono = const Value.absent(),
    this.rol = const Value.absent(),
    this.activo = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nombre = Value(nombre),
       usuarioApp = Value(usuarioApp);
  static Insertable<Visitador> custom({
    Expression<String>? id,
    Expression<String>? idEmpleado,
    Expression<String>? nombre,
    Expression<String>? usuarioApp,
    Expression<String>? cargo,
    Expression<String>? email,
    Expression<String>? telefono,
    Expression<String>? rol,
    Expression<bool>? activo,
    Expression<String>? remoteId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (idEmpleado != null) 'id_empleado': idEmpleado,
      if (nombre != null) 'nombre': nombre,
      if (usuarioApp != null) 'usuario_app': usuarioApp,
      if (cargo != null) 'cargo': cargo,
      if (email != null) 'email': email,
      if (telefono != null) 'telefono': telefono,
      if (rol != null) 'rol': rol,
      if (activo != null) 'activo': activo,
      if (remoteId != null) 'remote_id': remoteId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VisitadoresCompanion copyWith({
    Value<String>? id,
    Value<String?>? idEmpleado,
    Value<String>? nombre,
    Value<String>? usuarioApp,
    Value<String?>? cargo,
    Value<String?>? email,
    Value<String?>? telefono,
    Value<String?>? rol,
    Value<bool>? activo,
    Value<String?>? remoteId,
    Value<int>? rowid,
  }) {
    return VisitadoresCompanion(
      id: id ?? this.id,
      idEmpleado: idEmpleado ?? this.idEmpleado,
      nombre: nombre ?? this.nombre,
      usuarioApp: usuarioApp ?? this.usuarioApp,
      cargo: cargo ?? this.cargo,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      rol: rol ?? this.rol,
      activo: activo ?? this.activo,
      remoteId: remoteId ?? this.remoteId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (idEmpleado.present) {
      map['id_empleado'] = Variable<String>(idEmpleado.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (usuarioApp.present) {
      map['usuario_app'] = Variable<String>(usuarioApp.value);
    }
    if (cargo.present) {
      map['cargo'] = Variable<String>(cargo.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (telefono.present) {
      map['telefono'] = Variable<String>(telefono.value);
    }
    if (rol.present) {
      map['rol'] = Variable<String>(rol.value);
    }
    if (activo.present) {
      map['activo'] = Variable<bool>(activo.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VisitadoresCompanion(')
          ..write('id: $id, ')
          ..write('idEmpleado: $idEmpleado, ')
          ..write('nombre: $nombre, ')
          ..write('usuarioApp: $usuarioApp, ')
          ..write('cargo: $cargo, ')
          ..write('email: $email, ')
          ..write('telefono: $telefono, ')
          ..write('rol: $rol, ')
          ..write('activo: $activo, ')
          ..write('remoteId: $remoteId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CredencialesLocalesTable extends CredencialesLocales
    with TableInfo<$CredencialesLocalesTable, CredencialLocal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CredencialesLocalesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cedulaMeta = const VerificationMeta('cedula');
  @override
  late final GeneratedColumn<String> cedula = GeneratedColumn<String>(
    'cedula',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idEmpleadoMeta = const VerificationMeta(
    'idEmpleado',
  );
  @override
  late final GeneratedColumn<String> idEmpleado = GeneratedColumn<String>(
    'id_empleado',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hashBcryptMeta = const VerificationMeta(
    'hashBcrypt',
  );
  @override
  late final GeneratedColumn<String> hashBcrypt = GeneratedColumn<String>(
    'hash_bcrypt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rolAppMeta = const VerificationMeta('rolApp');
  @override
  late final GeneratedColumn<String> rolApp = GeneratedColumn<String>(
    'rol_app',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Visitador'),
  );
  static const VerificationMeta _nivelAccesoMeta = const VerificationMeta(
    'nivelAcceso',
  );
  @override
  late final GeneratedColumn<String> nivelAcceso = GeneratedColumn<String>(
    'nivel_acceso',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ordenNivelMeta = const VerificationMeta(
    'ordenNivel',
  );
  @override
  late final GeneratedColumn<int> ordenNivel = GeneratedColumn<int>(
    'orden_nivel',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(99),
  );
  static const VerificationMeta _ultimoLoginOnlineMeta = const VerificationMeta(
    'ultimoLoginOnline',
  );
  @override
  late final GeneratedColumn<DateTime> ultimoLoginOnline =
      GeneratedColumn<DateTime>(
        'ultimo_login_online',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _validoHastaMeta = const VerificationMeta(
    'validoHasta',
  );
  @override
  late final GeneratedColumn<DateTime> validoHasta = GeneratedColumn<DateTime>(
    'valido_hasta',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fotoUrlMeta = const VerificationMeta(
    'fotoUrl',
  );
  @override
  late final GeneratedColumn<String> fotoUrl = GeneratedColumn<String>(
    'foto_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fotoPathMeta = const VerificationMeta(
    'fotoPath',
  );
  @override
  late final GeneratedColumn<String> fotoPath = GeneratedColumn<String>(
    'foto_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    cedula,
    idEmpleado,
    nombre,
    email,
    hashBcrypt,
    rolApp,
    nivelAcceso,
    ordenNivel,
    ultimoLoginOnline,
    validoHasta,
    fotoUrl,
    fotoPath,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'credenciales_locales';
  @override
  VerificationContext validateIntegrity(
    Insertable<CredencialLocal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cedula')) {
      context.handle(
        _cedulaMeta,
        cedula.isAcceptableOrUnknown(data['cedula']!, _cedulaMeta),
      );
    } else if (isInserting) {
      context.missing(_cedulaMeta);
    }
    if (data.containsKey('id_empleado')) {
      context.handle(
        _idEmpleadoMeta,
        idEmpleado.isAcceptableOrUnknown(data['id_empleado']!, _idEmpleadoMeta),
      );
    } else if (isInserting) {
      context.missing(_idEmpleadoMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('hash_bcrypt')) {
      context.handle(
        _hashBcryptMeta,
        hashBcrypt.isAcceptableOrUnknown(data['hash_bcrypt']!, _hashBcryptMeta),
      );
    } else if (isInserting) {
      context.missing(_hashBcryptMeta);
    }
    if (data.containsKey('rol_app')) {
      context.handle(
        _rolAppMeta,
        rolApp.isAcceptableOrUnknown(data['rol_app']!, _rolAppMeta),
      );
    }
    if (data.containsKey('nivel_acceso')) {
      context.handle(
        _nivelAccesoMeta,
        nivelAcceso.isAcceptableOrUnknown(
          data['nivel_acceso']!,
          _nivelAccesoMeta,
        ),
      );
    }
    if (data.containsKey('orden_nivel')) {
      context.handle(
        _ordenNivelMeta,
        ordenNivel.isAcceptableOrUnknown(data['orden_nivel']!, _ordenNivelMeta),
      );
    }
    if (data.containsKey('ultimo_login_online')) {
      context.handle(
        _ultimoLoginOnlineMeta,
        ultimoLoginOnline.isAcceptableOrUnknown(
          data['ultimo_login_online']!,
          _ultimoLoginOnlineMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ultimoLoginOnlineMeta);
    }
    if (data.containsKey('valido_hasta')) {
      context.handle(
        _validoHastaMeta,
        validoHasta.isAcceptableOrUnknown(
          data['valido_hasta']!,
          _validoHastaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_validoHastaMeta);
    }
    if (data.containsKey('foto_url')) {
      context.handle(
        _fotoUrlMeta,
        fotoUrl.isAcceptableOrUnknown(data['foto_url']!, _fotoUrlMeta),
      );
    }
    if (data.containsKey('foto_path')) {
      context.handle(
        _fotoPathMeta,
        fotoPath.isAcceptableOrUnknown(data['foto_path']!, _fotoPathMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cedula};
  @override
  CredencialLocal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CredencialLocal(
      cedula: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cedula'],
      )!,
      idEmpleado: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id_empleado'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      hashBcrypt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hash_bcrypt'],
      )!,
      rolApp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rol_app'],
      )!,
      nivelAcceso: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nivel_acceso'],
      ),
      ordenNivel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}orden_nivel'],
      )!,
      ultimoLoginOnline: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ultimo_login_online'],
      )!,
      validoHasta: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}valido_hasta'],
      )!,
      fotoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}foto_url'],
      ),
      fotoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}foto_path'],
      ),
    );
  }

  @override
  $CredencialesLocalesTable createAlias(String alias) {
    return $CredencialesLocalesTable(attachedDatabase, alias);
  }
}

class CredencialLocal extends DataClass implements Insertable<CredencialLocal> {
  /// La cedula, normalizada a solo digitos. Es la llave porque es lo unico
  /// que el visitador tiene antes de autenticarse — y lo unico que se sabe de
  /// memoria estando en una finca.
  ///
  /// Se guarda normalizada para que entrar no dependa de si la tecleo con
  /// puntos: `1.234.567` y `1234567` tienen que ser la misma persona.
  final String cedula;
  final String idEmpleado;
  final String nombre;
  final String? email;

  /// bcrypt, tal como lo escribio la app de nomina en Next.js.
  final String hashBcrypt;

  /// Papel dentro de esta app: Visitador o Coordinador.
  final String rolApp;
  final String? nivelAcceso;
  final int ordenNivel;
  final DateTime ultimoLoginOnline;

  /// Despues de esta fecha el login offline se rechaza y hay que buscar senal.
  final DateTime validoHasta;

  /// La foto de perfil de nomina, tal como la mando el backend en el ultimo
  /// login con senal. Se guarda para saber si cambio, no para pintarla: la
  /// URL de Airtable caduca en horas y el visitador pasa dias sin red.
  final String? fotoUrl;

  /// El archivo ya bajado. Es lo que se pinta, y es lo unico que sigue
  /// existiendo en una vereda sin senal.
  final String? fotoPath;
  const CredencialLocal({
    required this.cedula,
    required this.idEmpleado,
    required this.nombre,
    this.email,
    required this.hashBcrypt,
    required this.rolApp,
    this.nivelAcceso,
    required this.ordenNivel,
    required this.ultimoLoginOnline,
    required this.validoHasta,
    this.fotoUrl,
    this.fotoPath,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cedula'] = Variable<String>(cedula);
    map['id_empleado'] = Variable<String>(idEmpleado);
    map['nombre'] = Variable<String>(nombre);
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    map['hash_bcrypt'] = Variable<String>(hashBcrypt);
    map['rol_app'] = Variable<String>(rolApp);
    if (!nullToAbsent || nivelAcceso != null) {
      map['nivel_acceso'] = Variable<String>(nivelAcceso);
    }
    map['orden_nivel'] = Variable<int>(ordenNivel);
    map['ultimo_login_online'] = Variable<DateTime>(ultimoLoginOnline);
    map['valido_hasta'] = Variable<DateTime>(validoHasta);
    if (!nullToAbsent || fotoUrl != null) {
      map['foto_url'] = Variable<String>(fotoUrl);
    }
    if (!nullToAbsent || fotoPath != null) {
      map['foto_path'] = Variable<String>(fotoPath);
    }
    return map;
  }

  CredencialesLocalesCompanion toCompanion(bool nullToAbsent) {
    return CredencialesLocalesCompanion(
      cedula: Value(cedula),
      idEmpleado: Value(idEmpleado),
      nombre: Value(nombre),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      hashBcrypt: Value(hashBcrypt),
      rolApp: Value(rolApp),
      nivelAcceso: nivelAcceso == null && nullToAbsent
          ? const Value.absent()
          : Value(nivelAcceso),
      ordenNivel: Value(ordenNivel),
      ultimoLoginOnline: Value(ultimoLoginOnline),
      validoHasta: Value(validoHasta),
      fotoUrl: fotoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(fotoUrl),
      fotoPath: fotoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(fotoPath),
    );
  }

  factory CredencialLocal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CredencialLocal(
      cedula: serializer.fromJson<String>(json['cedula']),
      idEmpleado: serializer.fromJson<String>(json['idEmpleado']),
      nombre: serializer.fromJson<String>(json['nombre']),
      email: serializer.fromJson<String?>(json['email']),
      hashBcrypt: serializer.fromJson<String>(json['hashBcrypt']),
      rolApp: serializer.fromJson<String>(json['rolApp']),
      nivelAcceso: serializer.fromJson<String?>(json['nivelAcceso']),
      ordenNivel: serializer.fromJson<int>(json['ordenNivel']),
      ultimoLoginOnline: serializer.fromJson<DateTime>(
        json['ultimoLoginOnline'],
      ),
      validoHasta: serializer.fromJson<DateTime>(json['validoHasta']),
      fotoUrl: serializer.fromJson<String?>(json['fotoUrl']),
      fotoPath: serializer.fromJson<String?>(json['fotoPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cedula': serializer.toJson<String>(cedula),
      'idEmpleado': serializer.toJson<String>(idEmpleado),
      'nombre': serializer.toJson<String>(nombre),
      'email': serializer.toJson<String?>(email),
      'hashBcrypt': serializer.toJson<String>(hashBcrypt),
      'rolApp': serializer.toJson<String>(rolApp),
      'nivelAcceso': serializer.toJson<String?>(nivelAcceso),
      'ordenNivel': serializer.toJson<int>(ordenNivel),
      'ultimoLoginOnline': serializer.toJson<DateTime>(ultimoLoginOnline),
      'validoHasta': serializer.toJson<DateTime>(validoHasta),
      'fotoUrl': serializer.toJson<String?>(fotoUrl),
      'fotoPath': serializer.toJson<String?>(fotoPath),
    };
  }

  CredencialLocal copyWith({
    String? cedula,
    String? idEmpleado,
    String? nombre,
    Value<String?> email = const Value.absent(),
    String? hashBcrypt,
    String? rolApp,
    Value<String?> nivelAcceso = const Value.absent(),
    int? ordenNivel,
    DateTime? ultimoLoginOnline,
    DateTime? validoHasta,
    Value<String?> fotoUrl = const Value.absent(),
    Value<String?> fotoPath = const Value.absent(),
  }) => CredencialLocal(
    cedula: cedula ?? this.cedula,
    idEmpleado: idEmpleado ?? this.idEmpleado,
    nombre: nombre ?? this.nombre,
    email: email.present ? email.value : this.email,
    hashBcrypt: hashBcrypt ?? this.hashBcrypt,
    rolApp: rolApp ?? this.rolApp,
    nivelAcceso: nivelAcceso.present ? nivelAcceso.value : this.nivelAcceso,
    ordenNivel: ordenNivel ?? this.ordenNivel,
    ultimoLoginOnline: ultimoLoginOnline ?? this.ultimoLoginOnline,
    validoHasta: validoHasta ?? this.validoHasta,
    fotoUrl: fotoUrl.present ? fotoUrl.value : this.fotoUrl,
    fotoPath: fotoPath.present ? fotoPath.value : this.fotoPath,
  );
  CredencialLocal copyWithCompanion(CredencialesLocalesCompanion data) {
    return CredencialLocal(
      cedula: data.cedula.present ? data.cedula.value : this.cedula,
      idEmpleado: data.idEmpleado.present
          ? data.idEmpleado.value
          : this.idEmpleado,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      email: data.email.present ? data.email.value : this.email,
      hashBcrypt: data.hashBcrypt.present
          ? data.hashBcrypt.value
          : this.hashBcrypt,
      rolApp: data.rolApp.present ? data.rolApp.value : this.rolApp,
      nivelAcceso: data.nivelAcceso.present
          ? data.nivelAcceso.value
          : this.nivelAcceso,
      ordenNivel: data.ordenNivel.present
          ? data.ordenNivel.value
          : this.ordenNivel,
      ultimoLoginOnline: data.ultimoLoginOnline.present
          ? data.ultimoLoginOnline.value
          : this.ultimoLoginOnline,
      validoHasta: data.validoHasta.present
          ? data.validoHasta.value
          : this.validoHasta,
      fotoUrl: data.fotoUrl.present ? data.fotoUrl.value : this.fotoUrl,
      fotoPath: data.fotoPath.present ? data.fotoPath.value : this.fotoPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CredencialLocal(')
          ..write('cedula: $cedula, ')
          ..write('idEmpleado: $idEmpleado, ')
          ..write('nombre: $nombre, ')
          ..write('email: $email, ')
          ..write('hashBcrypt: $hashBcrypt, ')
          ..write('rolApp: $rolApp, ')
          ..write('nivelAcceso: $nivelAcceso, ')
          ..write('ordenNivel: $ordenNivel, ')
          ..write('ultimoLoginOnline: $ultimoLoginOnline, ')
          ..write('validoHasta: $validoHasta, ')
          ..write('fotoUrl: $fotoUrl, ')
          ..write('fotoPath: $fotoPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    cedula,
    idEmpleado,
    nombre,
    email,
    hashBcrypt,
    rolApp,
    nivelAcceso,
    ordenNivel,
    ultimoLoginOnline,
    validoHasta,
    fotoUrl,
    fotoPath,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CredencialLocal &&
          other.cedula == this.cedula &&
          other.idEmpleado == this.idEmpleado &&
          other.nombre == this.nombre &&
          other.email == this.email &&
          other.hashBcrypt == this.hashBcrypt &&
          other.rolApp == this.rolApp &&
          other.nivelAcceso == this.nivelAcceso &&
          other.ordenNivel == this.ordenNivel &&
          other.ultimoLoginOnline == this.ultimoLoginOnline &&
          other.validoHasta == this.validoHasta &&
          other.fotoUrl == this.fotoUrl &&
          other.fotoPath == this.fotoPath);
}

class CredencialesLocalesCompanion extends UpdateCompanion<CredencialLocal> {
  final Value<String> cedula;
  final Value<String> idEmpleado;
  final Value<String> nombre;
  final Value<String?> email;
  final Value<String> hashBcrypt;
  final Value<String> rolApp;
  final Value<String?> nivelAcceso;
  final Value<int> ordenNivel;
  final Value<DateTime> ultimoLoginOnline;
  final Value<DateTime> validoHasta;
  final Value<String?> fotoUrl;
  final Value<String?> fotoPath;
  final Value<int> rowid;
  const CredencialesLocalesCompanion({
    this.cedula = const Value.absent(),
    this.idEmpleado = const Value.absent(),
    this.nombre = const Value.absent(),
    this.email = const Value.absent(),
    this.hashBcrypt = const Value.absent(),
    this.rolApp = const Value.absent(),
    this.nivelAcceso = const Value.absent(),
    this.ordenNivel = const Value.absent(),
    this.ultimoLoginOnline = const Value.absent(),
    this.validoHasta = const Value.absent(),
    this.fotoUrl = const Value.absent(),
    this.fotoPath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CredencialesLocalesCompanion.insert({
    required String cedula,
    required String idEmpleado,
    required String nombre,
    this.email = const Value.absent(),
    required String hashBcrypt,
    this.rolApp = const Value.absent(),
    this.nivelAcceso = const Value.absent(),
    this.ordenNivel = const Value.absent(),
    required DateTime ultimoLoginOnline,
    required DateTime validoHasta,
    this.fotoUrl = const Value.absent(),
    this.fotoPath = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : cedula = Value(cedula),
       idEmpleado = Value(idEmpleado),
       nombre = Value(nombre),
       hashBcrypt = Value(hashBcrypt),
       ultimoLoginOnline = Value(ultimoLoginOnline),
       validoHasta = Value(validoHasta);
  static Insertable<CredencialLocal> custom({
    Expression<String>? cedula,
    Expression<String>? idEmpleado,
    Expression<String>? nombre,
    Expression<String>? email,
    Expression<String>? hashBcrypt,
    Expression<String>? rolApp,
    Expression<String>? nivelAcceso,
    Expression<int>? ordenNivel,
    Expression<DateTime>? ultimoLoginOnline,
    Expression<DateTime>? validoHasta,
    Expression<String>? fotoUrl,
    Expression<String>? fotoPath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cedula != null) 'cedula': cedula,
      if (idEmpleado != null) 'id_empleado': idEmpleado,
      if (nombre != null) 'nombre': nombre,
      if (email != null) 'email': email,
      if (hashBcrypt != null) 'hash_bcrypt': hashBcrypt,
      if (rolApp != null) 'rol_app': rolApp,
      if (nivelAcceso != null) 'nivel_acceso': nivelAcceso,
      if (ordenNivel != null) 'orden_nivel': ordenNivel,
      if (ultimoLoginOnline != null) 'ultimo_login_online': ultimoLoginOnline,
      if (validoHasta != null) 'valido_hasta': validoHasta,
      if (fotoUrl != null) 'foto_url': fotoUrl,
      if (fotoPath != null) 'foto_path': fotoPath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CredencialesLocalesCompanion copyWith({
    Value<String>? cedula,
    Value<String>? idEmpleado,
    Value<String>? nombre,
    Value<String?>? email,
    Value<String>? hashBcrypt,
    Value<String>? rolApp,
    Value<String?>? nivelAcceso,
    Value<int>? ordenNivel,
    Value<DateTime>? ultimoLoginOnline,
    Value<DateTime>? validoHasta,
    Value<String?>? fotoUrl,
    Value<String?>? fotoPath,
    Value<int>? rowid,
  }) {
    return CredencialesLocalesCompanion(
      cedula: cedula ?? this.cedula,
      idEmpleado: idEmpleado ?? this.idEmpleado,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      hashBcrypt: hashBcrypt ?? this.hashBcrypt,
      rolApp: rolApp ?? this.rolApp,
      nivelAcceso: nivelAcceso ?? this.nivelAcceso,
      ordenNivel: ordenNivel ?? this.ordenNivel,
      ultimoLoginOnline: ultimoLoginOnline ?? this.ultimoLoginOnline,
      validoHasta: validoHasta ?? this.validoHasta,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      fotoPath: fotoPath ?? this.fotoPath,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cedula.present) {
      map['cedula'] = Variable<String>(cedula.value);
    }
    if (idEmpleado.present) {
      map['id_empleado'] = Variable<String>(idEmpleado.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (hashBcrypt.present) {
      map['hash_bcrypt'] = Variable<String>(hashBcrypt.value);
    }
    if (rolApp.present) {
      map['rol_app'] = Variable<String>(rolApp.value);
    }
    if (nivelAcceso.present) {
      map['nivel_acceso'] = Variable<String>(nivelAcceso.value);
    }
    if (ordenNivel.present) {
      map['orden_nivel'] = Variable<int>(ordenNivel.value);
    }
    if (ultimoLoginOnline.present) {
      map['ultimo_login_online'] = Variable<DateTime>(ultimoLoginOnline.value);
    }
    if (validoHasta.present) {
      map['valido_hasta'] = Variable<DateTime>(validoHasta.value);
    }
    if (fotoUrl.present) {
      map['foto_url'] = Variable<String>(fotoUrl.value);
    }
    if (fotoPath.present) {
      map['foto_path'] = Variable<String>(fotoPath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CredencialesLocalesCompanion(')
          ..write('cedula: $cedula, ')
          ..write('idEmpleado: $idEmpleado, ')
          ..write('nombre: $nombre, ')
          ..write('email: $email, ')
          ..write('hashBcrypt: $hashBcrypt, ')
          ..write('rolApp: $rolApp, ')
          ..write('nivelAcceso: $nivelAcceso, ')
          ..write('ordenNivel: $ordenNivel, ')
          ..write('ultimoLoginOnline: $ultimoLoginOnline, ')
          ..write('validoHasta: $validoHasta, ')
          ..write('fotoUrl: $fotoUrl, ')
          ..write('fotoPath: $fotoPath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SesionesTable extends Sesiones with TableInfo<$SesionesTable, Sesion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SesionesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _unicaMeta = const VerificationMeta('unica');
  @override
  late final GeneratedColumn<int> unica = GeneratedColumn<int>(
    'unica',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cedulaMeta = const VerificationMeta('cedula');
  @override
  late final GeneratedColumn<String> cedula = GeneratedColumn<String>(
    'cedula',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _abiertaMeta = const VerificationMeta(
    'abierta',
  );
  @override
  late final GeneratedColumn<DateTime> abierta = GeneratedColumn<DateTime>(
    'abierta',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _offlineMeta = const VerificationMeta(
    'offline',
  );
  @override
  late final GeneratedColumn<bool> offline = GeneratedColumn<bool>(
    'offline',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("offline" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [unica, cedula, abierta, offline];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sesiones';
  @override
  VerificationContext validateIntegrity(
    Insertable<Sesion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('unica')) {
      context.handle(
        _unicaMeta,
        unica.isAcceptableOrUnknown(data['unica']!, _unicaMeta),
      );
    }
    if (data.containsKey('cedula')) {
      context.handle(
        _cedulaMeta,
        cedula.isAcceptableOrUnknown(data['cedula']!, _cedulaMeta),
      );
    } else if (isInserting) {
      context.missing(_cedulaMeta);
    }
    if (data.containsKey('abierta')) {
      context.handle(
        _abiertaMeta,
        abierta.isAcceptableOrUnknown(data['abierta']!, _abiertaMeta),
      );
    } else if (isInserting) {
      context.missing(_abiertaMeta);
    }
    if (data.containsKey('offline')) {
      context.handle(
        _offlineMeta,
        offline.isAcceptableOrUnknown(data['offline']!, _offlineMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {unica};
  @override
  Sesion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Sesion(
      unica: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unica'],
      )!,
      cedula: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cedula'],
      )!,
      abierta: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}abierta'],
      )!,
      offline: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}offline'],
      )!,
    );
  }

  @override
  $SesionesTable createAlias(String alias) {
    return $SesionesTable(attachedDatabase, alias);
  }
}

class Sesion extends DataClass implements Insertable<Sesion> {
  final int unica;
  final String cedula;
  final DateTime abierta;

  /// Si el ultimo login fue offline. Se muestra en la app: el visitador tiene
  /// derecho a saber que su sesion se valido contra una copia local.
  final bool offline;
  const Sesion({
    required this.unica,
    required this.cedula,
    required this.abierta,
    required this.offline,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['unica'] = Variable<int>(unica);
    map['cedula'] = Variable<String>(cedula);
    map['abierta'] = Variable<DateTime>(abierta);
    map['offline'] = Variable<bool>(offline);
    return map;
  }

  SesionesCompanion toCompanion(bool nullToAbsent) {
    return SesionesCompanion(
      unica: Value(unica),
      cedula: Value(cedula),
      abierta: Value(abierta),
      offline: Value(offline),
    );
  }

  factory Sesion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Sesion(
      unica: serializer.fromJson<int>(json['unica']),
      cedula: serializer.fromJson<String>(json['cedula']),
      abierta: serializer.fromJson<DateTime>(json['abierta']),
      offline: serializer.fromJson<bool>(json['offline']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'unica': serializer.toJson<int>(unica),
      'cedula': serializer.toJson<String>(cedula),
      'abierta': serializer.toJson<DateTime>(abierta),
      'offline': serializer.toJson<bool>(offline),
    };
  }

  Sesion copyWith({
    int? unica,
    String? cedula,
    DateTime? abierta,
    bool? offline,
  }) => Sesion(
    unica: unica ?? this.unica,
    cedula: cedula ?? this.cedula,
    abierta: abierta ?? this.abierta,
    offline: offline ?? this.offline,
  );
  Sesion copyWithCompanion(SesionesCompanion data) {
    return Sesion(
      unica: data.unica.present ? data.unica.value : this.unica,
      cedula: data.cedula.present ? data.cedula.value : this.cedula,
      abierta: data.abierta.present ? data.abierta.value : this.abierta,
      offline: data.offline.present ? data.offline.value : this.offline,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Sesion(')
          ..write('unica: $unica, ')
          ..write('cedula: $cedula, ')
          ..write('abierta: $abierta, ')
          ..write('offline: $offline')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(unica, cedula, abierta, offline);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Sesion &&
          other.unica == this.unica &&
          other.cedula == this.cedula &&
          other.abierta == this.abierta &&
          other.offline == this.offline);
}

class SesionesCompanion extends UpdateCompanion<Sesion> {
  final Value<int> unica;
  final Value<String> cedula;
  final Value<DateTime> abierta;
  final Value<bool> offline;
  const SesionesCompanion({
    this.unica = const Value.absent(),
    this.cedula = const Value.absent(),
    this.abierta = const Value.absent(),
    this.offline = const Value.absent(),
  });
  SesionesCompanion.insert({
    this.unica = const Value.absent(),
    required String cedula,
    required DateTime abierta,
    this.offline = const Value.absent(),
  }) : cedula = Value(cedula),
       abierta = Value(abierta);
  static Insertable<Sesion> custom({
    Expression<int>? unica,
    Expression<String>? cedula,
    Expression<DateTime>? abierta,
    Expression<bool>? offline,
  }) {
    return RawValuesInsertable({
      if (unica != null) 'unica': unica,
      if (cedula != null) 'cedula': cedula,
      if (abierta != null) 'abierta': abierta,
      if (offline != null) 'offline': offline,
    });
  }

  SesionesCompanion copyWith({
    Value<int>? unica,
    Value<String>? cedula,
    Value<DateTime>? abierta,
    Value<bool>? offline,
  }) {
    return SesionesCompanion(
      unica: unica ?? this.unica,
      cedula: cedula ?? this.cedula,
      abierta: abierta ?? this.abierta,
      offline: offline ?? this.offline,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (unica.present) {
      map['unica'] = Variable<int>(unica.value);
    }
    if (cedula.present) {
      map['cedula'] = Variable<String>(cedula.value);
    }
    if (abierta.present) {
      map['abierta'] = Variable<DateTime>(abierta.value);
    }
    if (offline.present) {
      map['offline'] = Variable<bool>(offline.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SesionesCompanion(')
          ..write('unica: $unica, ')
          ..write('cedula: $cedula, ')
          ..write('abierta: $abierta, ')
          ..write('offline: $offline')
          ..write(')'))
        .toString();
  }
}

class $ProductoresTable extends Productores
    with TableInfo<$ProductoresTable, Productor> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreCompletoMeta = const VerificationMeta(
    'nombreCompleto',
  );
  @override
  late final GeneratedColumn<String> nombreCompleto = GeneratedColumn<String>(
    'nombre_completo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _documentoMeta = const VerificationMeta(
    'documento',
  );
  @override
  late final GeneratedColumn<String> documento = GeneratedColumn<String>(
    'documento',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tipoDocumentoMeta = const VerificationMeta(
    'tipoDocumento',
  );
  @override
  late final GeneratedColumn<String> tipoDocumento = GeneratedColumn<String>(
    'tipo_documento',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _telefonoMeta = const VerificationMeta(
    'telefono',
  );
  @override
  late final GeneratedColumn<String> telefono = GeneratedColumn<String>(
    'telefono',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _telefonoAlternoMeta = const VerificationMeta(
    'telefonoAlterno',
  );
  @override
  late final GeneratedColumn<String> telefonoAlterno = GeneratedColumn<String>(
    'telefono_alterno',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _generoMeta = const VerificationMeta('genero');
  @override
  late final GeneratedColumn<String> genero = GeneratedColumn<String>(
    'genero',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fechaNacimientoMeta = const VerificationMeta(
    'fechaNacimiento',
  );
  @override
  late final GeneratedColumn<DateTime> fechaNacimiento =
      GeneratedColumn<DateTime>(
        'fecha_nacimiento',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _nivelEducativoMeta = const VerificationMeta(
    'nivelEducativo',
  );
  @override
  late final GeneratedColumn<String> nivelEducativo = GeneratedColumn<String>(
    'nivel_educativo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _aniosExperienciaMeta = const VerificationMeta(
    'aniosExperiencia',
  );
  @override
  late final GeneratedColumn<int> aniosExperiencia = GeneratedColumn<int>(
    'anios_experiencia',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _personasHogarMeta = const VerificationMeta(
    'personasHogar',
  );
  @override
  late final GeneratedColumn<int> personasHogar = GeneratedColumn<int>(
    'personas_hogar',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _organizacionMeta = const VerificationMeta(
    'organizacion',
  );
  @override
  late final GeneratedColumn<String> organizacion = GeneratedColumn<String>(
    'organizacion',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notasMeta = const VerificationMeta('notas');
  @override
  late final GeneratedColumn<String> notas = GeneratedColumn<String>(
    'notas',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fotoPathMeta = const VerificationMeta(
    'fotoPath',
  );
  @override
  late final GeneratedColumn<String> fotoPath = GeneratedColumn<String>(
    'foto_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _enlaceFotoMeta = const VerificationMeta(
    'enlaceFoto',
  );
  @override
  late final GeneratedColumn<String> enlaceFoto = GeneratedColumn<String>(
    'enlace_foto',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fotoRemotaMeta = const VerificationMeta(
    'fotoRemota',
  );
  @override
  late final GeneratedColumn<String> fotoRemota = GeneratedColumn<String>(
    'foto_remota',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _consentimientoDatosMeta =
      const VerificationMeta('consentimientoDatos');
  @override
  late final GeneratedColumn<bool> consentimientoDatos = GeneratedColumn<bool>(
    'consentimiento_datos',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("consentimiento_datos" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _fechaConsentimientoMeta =
      const VerificationMeta('fechaConsentimiento');
  @override
  late final GeneratedColumn<DateTime> fechaConsentimiento =
      GeneratedColumn<DateTime>(
        'fecha_consentimiento',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _datosCompletadosEnMeta =
      const VerificationMeta('datosCompletadosEn');
  @override
  late final GeneratedColumn<DateTime> datosCompletadosEn =
      GeneratedColumn<DateTime>(
        'datos_completados_en',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _codigoProductorMeta = const VerificationMeta(
    'codigoProductor',
  );
  @override
  late final GeneratedColumn<String> codigoProductor = GeneratedColumn<String>(
    'codigo_productor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sincronizadoMeta = const VerificationMeta(
    'sincronizado',
  );
  @override
  late final GeneratedColumn<bool> sincronizado = GeneratedColumn<bool>(
    'sincronizado',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sincronizado" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nombreCompleto,
    documento,
    tipoDocumento,
    telefono,
    telefonoAlterno,
    genero,
    fechaNacimiento,
    nivelEducativo,
    aniosExperiencia,
    personasHogar,
    organizacion,
    notas,
    fotoPath,
    enlaceFoto,
    fotoRemota,
    consentimientoDatos,
    fechaConsentimiento,
    datosCompletadosEn,
    codigoProductor,
    remoteId,
    sincronizado,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'productores';
  @override
  VerificationContext validateIntegrity(
    Insertable<Productor> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nombre_completo')) {
      context.handle(
        _nombreCompletoMeta,
        nombreCompleto.isAcceptableOrUnknown(
          data['nombre_completo']!,
          _nombreCompletoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nombreCompletoMeta);
    }
    if (data.containsKey('documento')) {
      context.handle(
        _documentoMeta,
        documento.isAcceptableOrUnknown(data['documento']!, _documentoMeta),
      );
    }
    if (data.containsKey('tipo_documento')) {
      context.handle(
        _tipoDocumentoMeta,
        tipoDocumento.isAcceptableOrUnknown(
          data['tipo_documento']!,
          _tipoDocumentoMeta,
        ),
      );
    }
    if (data.containsKey('telefono')) {
      context.handle(
        _telefonoMeta,
        telefono.isAcceptableOrUnknown(data['telefono']!, _telefonoMeta),
      );
    }
    if (data.containsKey('telefono_alterno')) {
      context.handle(
        _telefonoAlternoMeta,
        telefonoAlterno.isAcceptableOrUnknown(
          data['telefono_alterno']!,
          _telefonoAlternoMeta,
        ),
      );
    }
    if (data.containsKey('genero')) {
      context.handle(
        _generoMeta,
        genero.isAcceptableOrUnknown(data['genero']!, _generoMeta),
      );
    }
    if (data.containsKey('fecha_nacimiento')) {
      context.handle(
        _fechaNacimientoMeta,
        fechaNacimiento.isAcceptableOrUnknown(
          data['fecha_nacimiento']!,
          _fechaNacimientoMeta,
        ),
      );
    }
    if (data.containsKey('nivel_educativo')) {
      context.handle(
        _nivelEducativoMeta,
        nivelEducativo.isAcceptableOrUnknown(
          data['nivel_educativo']!,
          _nivelEducativoMeta,
        ),
      );
    }
    if (data.containsKey('anios_experiencia')) {
      context.handle(
        _aniosExperienciaMeta,
        aniosExperiencia.isAcceptableOrUnknown(
          data['anios_experiencia']!,
          _aniosExperienciaMeta,
        ),
      );
    }
    if (data.containsKey('personas_hogar')) {
      context.handle(
        _personasHogarMeta,
        personasHogar.isAcceptableOrUnknown(
          data['personas_hogar']!,
          _personasHogarMeta,
        ),
      );
    }
    if (data.containsKey('organizacion')) {
      context.handle(
        _organizacionMeta,
        organizacion.isAcceptableOrUnknown(
          data['organizacion']!,
          _organizacionMeta,
        ),
      );
    }
    if (data.containsKey('notas')) {
      context.handle(
        _notasMeta,
        notas.isAcceptableOrUnknown(data['notas']!, _notasMeta),
      );
    }
    if (data.containsKey('foto_path')) {
      context.handle(
        _fotoPathMeta,
        fotoPath.isAcceptableOrUnknown(data['foto_path']!, _fotoPathMeta),
      );
    }
    if (data.containsKey('enlace_foto')) {
      context.handle(
        _enlaceFotoMeta,
        enlaceFoto.isAcceptableOrUnknown(data['enlace_foto']!, _enlaceFotoMeta),
      );
    }
    if (data.containsKey('foto_remota')) {
      context.handle(
        _fotoRemotaMeta,
        fotoRemota.isAcceptableOrUnknown(data['foto_remota']!, _fotoRemotaMeta),
      );
    }
    if (data.containsKey('consentimiento_datos')) {
      context.handle(
        _consentimientoDatosMeta,
        consentimientoDatos.isAcceptableOrUnknown(
          data['consentimiento_datos']!,
          _consentimientoDatosMeta,
        ),
      );
    }
    if (data.containsKey('fecha_consentimiento')) {
      context.handle(
        _fechaConsentimientoMeta,
        fechaConsentimiento.isAcceptableOrUnknown(
          data['fecha_consentimiento']!,
          _fechaConsentimientoMeta,
        ),
      );
    }
    if (data.containsKey('datos_completados_en')) {
      context.handle(
        _datosCompletadosEnMeta,
        datosCompletadosEn.isAcceptableOrUnknown(
          data['datos_completados_en']!,
          _datosCompletadosEnMeta,
        ),
      );
    }
    if (data.containsKey('codigo_productor')) {
      context.handle(
        _codigoProductorMeta,
        codigoProductor.isAcceptableOrUnknown(
          data['codigo_productor']!,
          _codigoProductorMeta,
        ),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('sincronizado')) {
      context.handle(
        _sincronizadoMeta,
        sincronizado.isAcceptableOrUnknown(
          data['sincronizado']!,
          _sincronizadoMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Productor map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Productor(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nombreCompleto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre_completo'],
      )!,
      documento: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}documento'],
      ),
      tipoDocumento: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo_documento'],
      ),
      telefono: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}telefono'],
      ),
      telefonoAlterno: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}telefono_alterno'],
      ),
      genero: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genero'],
      ),
      fechaNacimiento: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha_nacimiento'],
      ),
      nivelEducativo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nivel_educativo'],
      ),
      aniosExperiencia: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}anios_experiencia'],
      ),
      personasHogar: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}personas_hogar'],
      ),
      organizacion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}organizacion'],
      ),
      notas: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notas'],
      ),
      fotoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}foto_path'],
      ),
      enlaceFoto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}enlace_foto'],
      ),
      fotoRemota: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}foto_remota'],
      ),
      consentimientoDatos: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}consentimiento_datos'],
      )!,
      fechaConsentimiento: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha_consentimiento'],
      ),
      datosCompletadosEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}datos_completados_en'],
      ),
      codigoProductor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}codigo_productor'],
      ),
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      sincronizado: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sincronizado'],
      )!,
    );
  }

  @override
  $ProductoresTable createAlias(String alias) {
    return $ProductoresTable(attachedDatabase, alias);
  }
}

class Productor extends DataClass implements Insertable<Productor> {
  final String id;
  final String nombreCompleto;
  final String? documento;

  /// CC | CE | TI | NIT | Pasaporte | Sin documento. Texto y no enum porque
  /// son las opciones del select de Airtable y viajan tal cual.
  final String? tipoDocumento;
  final String? telefono;
  final String? telefonoAlterno;
  final String? genero;
  final DateTime? fechaNacimiento;
  final String? nivelEducativo;
  final int? aniosExperiencia;
  final int? personasHogar;

  /// Vacio significa que no pertenece a ninguna: el backend deriva de aqui la
  /// casilla `Pertenece a organizacion`, para no pedir dos veces lo mismo.
  final String? organizacion;
  final String? notas;

  /// La foto de perfil, en disco. Se guarda dentro de la carpeta de la visita
  /// donde se tomo: si esa visita se elimina por revocacion, la foto de la
  /// persona se va con el prefijo, que es exactamente lo que pidio.
  final String? fotoPath;

  /// URL de la foto en el bucket. Nula hasta que la cola la sube; es lo que
  /// Airtable usa para traerse el adjunto de `Productores.Foto`.
  final String? enlaceFoto;

  /// Miniatura de la foto que ya esta en Airtable, para reconocer al
  /// agricultor en el directorio antes de crearlo de nuevo.
  ///
  /// Es de Airtable y Airtable la rota cada pocas horas, asi que se muestra
  /// mientras sirva y su ausencia no significa nada: la foto de verdad es
  /// [fotoPath] en el telefono y [enlaceFoto] en el bucket.
  final String? fotoRemota;

  /// Autorizacion de tratamiento de datos (Ley 1581/2012). Va aqui y no solo
  /// en la visita porque la autorizacion es DE LA PERSONA: el permiso de
  /// grabar y de fotografiar se pide en cada visita, pero que sus datos se
  /// puedan tratar se autoriza una vez y queda con ella.
  final bool consentimientoDatos;
  final DateTime? fechaConsentimiento;

  /// Cuando alguien completo la ficha. Null = solo tiene el nombre con el que
  /// nacio, y el modulo de la visita lo va a decir.
  final DateTime? datosCompletadosEn;

  /// Consecutivo BU-0001. Lo asigna el BACKEND al sincronizar, no la app:
  /// dos telefonos offline generarian el mismo numero.
  final String? codigoProductor;
  final String? remoteId;
  final bool sincronizado;
  const Productor({
    required this.id,
    required this.nombreCompleto,
    this.documento,
    this.tipoDocumento,
    this.telefono,
    this.telefonoAlterno,
    this.genero,
    this.fechaNacimiento,
    this.nivelEducativo,
    this.aniosExperiencia,
    this.personasHogar,
    this.organizacion,
    this.notas,
    this.fotoPath,
    this.enlaceFoto,
    this.fotoRemota,
    required this.consentimientoDatos,
    this.fechaConsentimiento,
    this.datosCompletadosEn,
    this.codigoProductor,
    this.remoteId,
    required this.sincronizado,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nombre_completo'] = Variable<String>(nombreCompleto);
    if (!nullToAbsent || documento != null) {
      map['documento'] = Variable<String>(documento);
    }
    if (!nullToAbsent || tipoDocumento != null) {
      map['tipo_documento'] = Variable<String>(tipoDocumento);
    }
    if (!nullToAbsent || telefono != null) {
      map['telefono'] = Variable<String>(telefono);
    }
    if (!nullToAbsent || telefonoAlterno != null) {
      map['telefono_alterno'] = Variable<String>(telefonoAlterno);
    }
    if (!nullToAbsent || genero != null) {
      map['genero'] = Variable<String>(genero);
    }
    if (!nullToAbsent || fechaNacimiento != null) {
      map['fecha_nacimiento'] = Variable<DateTime>(fechaNacimiento);
    }
    if (!nullToAbsent || nivelEducativo != null) {
      map['nivel_educativo'] = Variable<String>(nivelEducativo);
    }
    if (!nullToAbsent || aniosExperiencia != null) {
      map['anios_experiencia'] = Variable<int>(aniosExperiencia);
    }
    if (!nullToAbsent || personasHogar != null) {
      map['personas_hogar'] = Variable<int>(personasHogar);
    }
    if (!nullToAbsent || organizacion != null) {
      map['organizacion'] = Variable<String>(organizacion);
    }
    if (!nullToAbsent || notas != null) {
      map['notas'] = Variable<String>(notas);
    }
    if (!nullToAbsent || fotoPath != null) {
      map['foto_path'] = Variable<String>(fotoPath);
    }
    if (!nullToAbsent || enlaceFoto != null) {
      map['enlace_foto'] = Variable<String>(enlaceFoto);
    }
    if (!nullToAbsent || fotoRemota != null) {
      map['foto_remota'] = Variable<String>(fotoRemota);
    }
    map['consentimiento_datos'] = Variable<bool>(consentimientoDatos);
    if (!nullToAbsent || fechaConsentimiento != null) {
      map['fecha_consentimiento'] = Variable<DateTime>(fechaConsentimiento);
    }
    if (!nullToAbsent || datosCompletadosEn != null) {
      map['datos_completados_en'] = Variable<DateTime>(datosCompletadosEn);
    }
    if (!nullToAbsent || codigoProductor != null) {
      map['codigo_productor'] = Variable<String>(codigoProductor);
    }
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['sincronizado'] = Variable<bool>(sincronizado);
    return map;
  }

  ProductoresCompanion toCompanion(bool nullToAbsent) {
    return ProductoresCompanion(
      id: Value(id),
      nombreCompleto: Value(nombreCompleto),
      documento: documento == null && nullToAbsent
          ? const Value.absent()
          : Value(documento),
      tipoDocumento: tipoDocumento == null && nullToAbsent
          ? const Value.absent()
          : Value(tipoDocumento),
      telefono: telefono == null && nullToAbsent
          ? const Value.absent()
          : Value(telefono),
      telefonoAlterno: telefonoAlterno == null && nullToAbsent
          ? const Value.absent()
          : Value(telefonoAlterno),
      genero: genero == null && nullToAbsent
          ? const Value.absent()
          : Value(genero),
      fechaNacimiento: fechaNacimiento == null && nullToAbsent
          ? const Value.absent()
          : Value(fechaNacimiento),
      nivelEducativo: nivelEducativo == null && nullToAbsent
          ? const Value.absent()
          : Value(nivelEducativo),
      aniosExperiencia: aniosExperiencia == null && nullToAbsent
          ? const Value.absent()
          : Value(aniosExperiencia),
      personasHogar: personasHogar == null && nullToAbsent
          ? const Value.absent()
          : Value(personasHogar),
      organizacion: organizacion == null && nullToAbsent
          ? const Value.absent()
          : Value(organizacion),
      notas: notas == null && nullToAbsent
          ? const Value.absent()
          : Value(notas),
      fotoPath: fotoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(fotoPath),
      enlaceFoto: enlaceFoto == null && nullToAbsent
          ? const Value.absent()
          : Value(enlaceFoto),
      fotoRemota: fotoRemota == null && nullToAbsent
          ? const Value.absent()
          : Value(fotoRemota),
      consentimientoDatos: Value(consentimientoDatos),
      fechaConsentimiento: fechaConsentimiento == null && nullToAbsent
          ? const Value.absent()
          : Value(fechaConsentimiento),
      datosCompletadosEn: datosCompletadosEn == null && nullToAbsent
          ? const Value.absent()
          : Value(datosCompletadosEn),
      codigoProductor: codigoProductor == null && nullToAbsent
          ? const Value.absent()
          : Value(codigoProductor),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      sincronizado: Value(sincronizado),
    );
  }

  factory Productor.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Productor(
      id: serializer.fromJson<String>(json['id']),
      nombreCompleto: serializer.fromJson<String>(json['nombreCompleto']),
      documento: serializer.fromJson<String?>(json['documento']),
      tipoDocumento: serializer.fromJson<String?>(json['tipoDocumento']),
      telefono: serializer.fromJson<String?>(json['telefono']),
      telefonoAlterno: serializer.fromJson<String?>(json['telefonoAlterno']),
      genero: serializer.fromJson<String?>(json['genero']),
      fechaNacimiento: serializer.fromJson<DateTime?>(json['fechaNacimiento']),
      nivelEducativo: serializer.fromJson<String?>(json['nivelEducativo']),
      aniosExperiencia: serializer.fromJson<int?>(json['aniosExperiencia']),
      personasHogar: serializer.fromJson<int?>(json['personasHogar']),
      organizacion: serializer.fromJson<String?>(json['organizacion']),
      notas: serializer.fromJson<String?>(json['notas']),
      fotoPath: serializer.fromJson<String?>(json['fotoPath']),
      enlaceFoto: serializer.fromJson<String?>(json['enlaceFoto']),
      fotoRemota: serializer.fromJson<String?>(json['fotoRemota']),
      consentimientoDatos: serializer.fromJson<bool>(
        json['consentimientoDatos'],
      ),
      fechaConsentimiento: serializer.fromJson<DateTime?>(
        json['fechaConsentimiento'],
      ),
      datosCompletadosEn: serializer.fromJson<DateTime?>(
        json['datosCompletadosEn'],
      ),
      codigoProductor: serializer.fromJson<String?>(json['codigoProductor']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      sincronizado: serializer.fromJson<bool>(json['sincronizado']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nombreCompleto': serializer.toJson<String>(nombreCompleto),
      'documento': serializer.toJson<String?>(documento),
      'tipoDocumento': serializer.toJson<String?>(tipoDocumento),
      'telefono': serializer.toJson<String?>(telefono),
      'telefonoAlterno': serializer.toJson<String?>(telefonoAlterno),
      'genero': serializer.toJson<String?>(genero),
      'fechaNacimiento': serializer.toJson<DateTime?>(fechaNacimiento),
      'nivelEducativo': serializer.toJson<String?>(nivelEducativo),
      'aniosExperiencia': serializer.toJson<int?>(aniosExperiencia),
      'personasHogar': serializer.toJson<int?>(personasHogar),
      'organizacion': serializer.toJson<String?>(organizacion),
      'notas': serializer.toJson<String?>(notas),
      'fotoPath': serializer.toJson<String?>(fotoPath),
      'enlaceFoto': serializer.toJson<String?>(enlaceFoto),
      'fotoRemota': serializer.toJson<String?>(fotoRemota),
      'consentimientoDatos': serializer.toJson<bool>(consentimientoDatos),
      'fechaConsentimiento': serializer.toJson<DateTime?>(fechaConsentimiento),
      'datosCompletadosEn': serializer.toJson<DateTime?>(datosCompletadosEn),
      'codigoProductor': serializer.toJson<String?>(codigoProductor),
      'remoteId': serializer.toJson<String?>(remoteId),
      'sincronizado': serializer.toJson<bool>(sincronizado),
    };
  }

  Productor copyWith({
    String? id,
    String? nombreCompleto,
    Value<String?> documento = const Value.absent(),
    Value<String?> tipoDocumento = const Value.absent(),
    Value<String?> telefono = const Value.absent(),
    Value<String?> telefonoAlterno = const Value.absent(),
    Value<String?> genero = const Value.absent(),
    Value<DateTime?> fechaNacimiento = const Value.absent(),
    Value<String?> nivelEducativo = const Value.absent(),
    Value<int?> aniosExperiencia = const Value.absent(),
    Value<int?> personasHogar = const Value.absent(),
    Value<String?> organizacion = const Value.absent(),
    Value<String?> notas = const Value.absent(),
    Value<String?> fotoPath = const Value.absent(),
    Value<String?> enlaceFoto = const Value.absent(),
    Value<String?> fotoRemota = const Value.absent(),
    bool? consentimientoDatos,
    Value<DateTime?> fechaConsentimiento = const Value.absent(),
    Value<DateTime?> datosCompletadosEn = const Value.absent(),
    Value<String?> codigoProductor = const Value.absent(),
    Value<String?> remoteId = const Value.absent(),
    bool? sincronizado,
  }) => Productor(
    id: id ?? this.id,
    nombreCompleto: nombreCompleto ?? this.nombreCompleto,
    documento: documento.present ? documento.value : this.documento,
    tipoDocumento: tipoDocumento.present
        ? tipoDocumento.value
        : this.tipoDocumento,
    telefono: telefono.present ? telefono.value : this.telefono,
    telefonoAlterno: telefonoAlterno.present
        ? telefonoAlterno.value
        : this.telefonoAlterno,
    genero: genero.present ? genero.value : this.genero,
    fechaNacimiento: fechaNacimiento.present
        ? fechaNacimiento.value
        : this.fechaNacimiento,
    nivelEducativo: nivelEducativo.present
        ? nivelEducativo.value
        : this.nivelEducativo,
    aniosExperiencia: aniosExperiencia.present
        ? aniosExperiencia.value
        : this.aniosExperiencia,
    personasHogar: personasHogar.present
        ? personasHogar.value
        : this.personasHogar,
    organizacion: organizacion.present ? organizacion.value : this.organizacion,
    notas: notas.present ? notas.value : this.notas,
    fotoPath: fotoPath.present ? fotoPath.value : this.fotoPath,
    enlaceFoto: enlaceFoto.present ? enlaceFoto.value : this.enlaceFoto,
    fotoRemota: fotoRemota.present ? fotoRemota.value : this.fotoRemota,
    consentimientoDatos: consentimientoDatos ?? this.consentimientoDatos,
    fechaConsentimiento: fechaConsentimiento.present
        ? fechaConsentimiento.value
        : this.fechaConsentimiento,
    datosCompletadosEn: datosCompletadosEn.present
        ? datosCompletadosEn.value
        : this.datosCompletadosEn,
    codigoProductor: codigoProductor.present
        ? codigoProductor.value
        : this.codigoProductor,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    sincronizado: sincronizado ?? this.sincronizado,
  );
  Productor copyWithCompanion(ProductoresCompanion data) {
    return Productor(
      id: data.id.present ? data.id.value : this.id,
      nombreCompleto: data.nombreCompleto.present
          ? data.nombreCompleto.value
          : this.nombreCompleto,
      documento: data.documento.present ? data.documento.value : this.documento,
      tipoDocumento: data.tipoDocumento.present
          ? data.tipoDocumento.value
          : this.tipoDocumento,
      telefono: data.telefono.present ? data.telefono.value : this.telefono,
      telefonoAlterno: data.telefonoAlterno.present
          ? data.telefonoAlterno.value
          : this.telefonoAlterno,
      genero: data.genero.present ? data.genero.value : this.genero,
      fechaNacimiento: data.fechaNacimiento.present
          ? data.fechaNacimiento.value
          : this.fechaNacimiento,
      nivelEducativo: data.nivelEducativo.present
          ? data.nivelEducativo.value
          : this.nivelEducativo,
      aniosExperiencia: data.aniosExperiencia.present
          ? data.aniosExperiencia.value
          : this.aniosExperiencia,
      personasHogar: data.personasHogar.present
          ? data.personasHogar.value
          : this.personasHogar,
      organizacion: data.organizacion.present
          ? data.organizacion.value
          : this.organizacion,
      notas: data.notas.present ? data.notas.value : this.notas,
      fotoPath: data.fotoPath.present ? data.fotoPath.value : this.fotoPath,
      enlaceFoto: data.enlaceFoto.present
          ? data.enlaceFoto.value
          : this.enlaceFoto,
      fotoRemota: data.fotoRemota.present
          ? data.fotoRemota.value
          : this.fotoRemota,
      consentimientoDatos: data.consentimientoDatos.present
          ? data.consentimientoDatos.value
          : this.consentimientoDatos,
      fechaConsentimiento: data.fechaConsentimiento.present
          ? data.fechaConsentimiento.value
          : this.fechaConsentimiento,
      datosCompletadosEn: data.datosCompletadosEn.present
          ? data.datosCompletadosEn.value
          : this.datosCompletadosEn,
      codigoProductor: data.codigoProductor.present
          ? data.codigoProductor.value
          : this.codigoProductor,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      sincronizado: data.sincronizado.present
          ? data.sincronizado.value
          : this.sincronizado,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Productor(')
          ..write('id: $id, ')
          ..write('nombreCompleto: $nombreCompleto, ')
          ..write('documento: $documento, ')
          ..write('tipoDocumento: $tipoDocumento, ')
          ..write('telefono: $telefono, ')
          ..write('telefonoAlterno: $telefonoAlterno, ')
          ..write('genero: $genero, ')
          ..write('fechaNacimiento: $fechaNacimiento, ')
          ..write('nivelEducativo: $nivelEducativo, ')
          ..write('aniosExperiencia: $aniosExperiencia, ')
          ..write('personasHogar: $personasHogar, ')
          ..write('organizacion: $organizacion, ')
          ..write('notas: $notas, ')
          ..write('fotoPath: $fotoPath, ')
          ..write('enlaceFoto: $enlaceFoto, ')
          ..write('fotoRemota: $fotoRemota, ')
          ..write('consentimientoDatos: $consentimientoDatos, ')
          ..write('fechaConsentimiento: $fechaConsentimiento, ')
          ..write('datosCompletadosEn: $datosCompletadosEn, ')
          ..write('codigoProductor: $codigoProductor, ')
          ..write('remoteId: $remoteId, ')
          ..write('sincronizado: $sincronizado')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    nombreCompleto,
    documento,
    tipoDocumento,
    telefono,
    telefonoAlterno,
    genero,
    fechaNacimiento,
    nivelEducativo,
    aniosExperiencia,
    personasHogar,
    organizacion,
    notas,
    fotoPath,
    enlaceFoto,
    fotoRemota,
    consentimientoDatos,
    fechaConsentimiento,
    datosCompletadosEn,
    codigoProductor,
    remoteId,
    sincronizado,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Productor &&
          other.id == this.id &&
          other.nombreCompleto == this.nombreCompleto &&
          other.documento == this.documento &&
          other.tipoDocumento == this.tipoDocumento &&
          other.telefono == this.telefono &&
          other.telefonoAlterno == this.telefonoAlterno &&
          other.genero == this.genero &&
          other.fechaNacimiento == this.fechaNacimiento &&
          other.nivelEducativo == this.nivelEducativo &&
          other.aniosExperiencia == this.aniosExperiencia &&
          other.personasHogar == this.personasHogar &&
          other.organizacion == this.organizacion &&
          other.notas == this.notas &&
          other.fotoPath == this.fotoPath &&
          other.enlaceFoto == this.enlaceFoto &&
          other.fotoRemota == this.fotoRemota &&
          other.consentimientoDatos == this.consentimientoDatos &&
          other.fechaConsentimiento == this.fechaConsentimiento &&
          other.datosCompletadosEn == this.datosCompletadosEn &&
          other.codigoProductor == this.codigoProductor &&
          other.remoteId == this.remoteId &&
          other.sincronizado == this.sincronizado);
}

class ProductoresCompanion extends UpdateCompanion<Productor> {
  final Value<String> id;
  final Value<String> nombreCompleto;
  final Value<String?> documento;
  final Value<String?> tipoDocumento;
  final Value<String?> telefono;
  final Value<String?> telefonoAlterno;
  final Value<String?> genero;
  final Value<DateTime?> fechaNacimiento;
  final Value<String?> nivelEducativo;
  final Value<int?> aniosExperiencia;
  final Value<int?> personasHogar;
  final Value<String?> organizacion;
  final Value<String?> notas;
  final Value<String?> fotoPath;
  final Value<String?> enlaceFoto;
  final Value<String?> fotoRemota;
  final Value<bool> consentimientoDatos;
  final Value<DateTime?> fechaConsentimiento;
  final Value<DateTime?> datosCompletadosEn;
  final Value<String?> codigoProductor;
  final Value<String?> remoteId;
  final Value<bool> sincronizado;
  final Value<int> rowid;
  const ProductoresCompanion({
    this.id = const Value.absent(),
    this.nombreCompleto = const Value.absent(),
    this.documento = const Value.absent(),
    this.tipoDocumento = const Value.absent(),
    this.telefono = const Value.absent(),
    this.telefonoAlterno = const Value.absent(),
    this.genero = const Value.absent(),
    this.fechaNacimiento = const Value.absent(),
    this.nivelEducativo = const Value.absent(),
    this.aniosExperiencia = const Value.absent(),
    this.personasHogar = const Value.absent(),
    this.organizacion = const Value.absent(),
    this.notas = const Value.absent(),
    this.fotoPath = const Value.absent(),
    this.enlaceFoto = const Value.absent(),
    this.fotoRemota = const Value.absent(),
    this.consentimientoDatos = const Value.absent(),
    this.fechaConsentimiento = const Value.absent(),
    this.datosCompletadosEn = const Value.absent(),
    this.codigoProductor = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.sincronizado = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductoresCompanion.insert({
    required String id,
    required String nombreCompleto,
    this.documento = const Value.absent(),
    this.tipoDocumento = const Value.absent(),
    this.telefono = const Value.absent(),
    this.telefonoAlterno = const Value.absent(),
    this.genero = const Value.absent(),
    this.fechaNacimiento = const Value.absent(),
    this.nivelEducativo = const Value.absent(),
    this.aniosExperiencia = const Value.absent(),
    this.personasHogar = const Value.absent(),
    this.organizacion = const Value.absent(),
    this.notas = const Value.absent(),
    this.fotoPath = const Value.absent(),
    this.enlaceFoto = const Value.absent(),
    this.fotoRemota = const Value.absent(),
    this.consentimientoDatos = const Value.absent(),
    this.fechaConsentimiento = const Value.absent(),
    this.datosCompletadosEn = const Value.absent(),
    this.codigoProductor = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.sincronizado = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nombreCompleto = Value(nombreCompleto);
  static Insertable<Productor> custom({
    Expression<String>? id,
    Expression<String>? nombreCompleto,
    Expression<String>? documento,
    Expression<String>? tipoDocumento,
    Expression<String>? telefono,
    Expression<String>? telefonoAlterno,
    Expression<String>? genero,
    Expression<DateTime>? fechaNacimiento,
    Expression<String>? nivelEducativo,
    Expression<int>? aniosExperiencia,
    Expression<int>? personasHogar,
    Expression<String>? organizacion,
    Expression<String>? notas,
    Expression<String>? fotoPath,
    Expression<String>? enlaceFoto,
    Expression<String>? fotoRemota,
    Expression<bool>? consentimientoDatos,
    Expression<DateTime>? fechaConsentimiento,
    Expression<DateTime>? datosCompletadosEn,
    Expression<String>? codigoProductor,
    Expression<String>? remoteId,
    Expression<bool>? sincronizado,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nombreCompleto != null) 'nombre_completo': nombreCompleto,
      if (documento != null) 'documento': documento,
      if (tipoDocumento != null) 'tipo_documento': tipoDocumento,
      if (telefono != null) 'telefono': telefono,
      if (telefonoAlterno != null) 'telefono_alterno': telefonoAlterno,
      if (genero != null) 'genero': genero,
      if (fechaNacimiento != null) 'fecha_nacimiento': fechaNacimiento,
      if (nivelEducativo != null) 'nivel_educativo': nivelEducativo,
      if (aniosExperiencia != null) 'anios_experiencia': aniosExperiencia,
      if (personasHogar != null) 'personas_hogar': personasHogar,
      if (organizacion != null) 'organizacion': organizacion,
      if (notas != null) 'notas': notas,
      if (fotoPath != null) 'foto_path': fotoPath,
      if (enlaceFoto != null) 'enlace_foto': enlaceFoto,
      if (fotoRemota != null) 'foto_remota': fotoRemota,
      if (consentimientoDatos != null)
        'consentimiento_datos': consentimientoDatos,
      if (fechaConsentimiento != null)
        'fecha_consentimiento': fechaConsentimiento,
      if (datosCompletadosEn != null)
        'datos_completados_en': datosCompletadosEn,
      if (codigoProductor != null) 'codigo_productor': codigoProductor,
      if (remoteId != null) 'remote_id': remoteId,
      if (sincronizado != null) 'sincronizado': sincronizado,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductoresCompanion copyWith({
    Value<String>? id,
    Value<String>? nombreCompleto,
    Value<String?>? documento,
    Value<String?>? tipoDocumento,
    Value<String?>? telefono,
    Value<String?>? telefonoAlterno,
    Value<String?>? genero,
    Value<DateTime?>? fechaNacimiento,
    Value<String?>? nivelEducativo,
    Value<int?>? aniosExperiencia,
    Value<int?>? personasHogar,
    Value<String?>? organizacion,
    Value<String?>? notas,
    Value<String?>? fotoPath,
    Value<String?>? enlaceFoto,
    Value<String?>? fotoRemota,
    Value<bool>? consentimientoDatos,
    Value<DateTime?>? fechaConsentimiento,
    Value<DateTime?>? datosCompletadosEn,
    Value<String?>? codigoProductor,
    Value<String?>? remoteId,
    Value<bool>? sincronizado,
    Value<int>? rowid,
  }) {
    return ProductoresCompanion(
      id: id ?? this.id,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      documento: documento ?? this.documento,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      telefono: telefono ?? this.telefono,
      telefonoAlterno: telefonoAlterno ?? this.telefonoAlterno,
      genero: genero ?? this.genero,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      nivelEducativo: nivelEducativo ?? this.nivelEducativo,
      aniosExperiencia: aniosExperiencia ?? this.aniosExperiencia,
      personasHogar: personasHogar ?? this.personasHogar,
      organizacion: organizacion ?? this.organizacion,
      notas: notas ?? this.notas,
      fotoPath: fotoPath ?? this.fotoPath,
      enlaceFoto: enlaceFoto ?? this.enlaceFoto,
      fotoRemota: fotoRemota ?? this.fotoRemota,
      consentimientoDatos: consentimientoDatos ?? this.consentimientoDatos,
      fechaConsentimiento: fechaConsentimiento ?? this.fechaConsentimiento,
      datosCompletadosEn: datosCompletadosEn ?? this.datosCompletadosEn,
      codigoProductor: codigoProductor ?? this.codigoProductor,
      remoteId: remoteId ?? this.remoteId,
      sincronizado: sincronizado ?? this.sincronizado,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nombreCompleto.present) {
      map['nombre_completo'] = Variable<String>(nombreCompleto.value);
    }
    if (documento.present) {
      map['documento'] = Variable<String>(documento.value);
    }
    if (tipoDocumento.present) {
      map['tipo_documento'] = Variable<String>(tipoDocumento.value);
    }
    if (telefono.present) {
      map['telefono'] = Variable<String>(telefono.value);
    }
    if (telefonoAlterno.present) {
      map['telefono_alterno'] = Variable<String>(telefonoAlterno.value);
    }
    if (genero.present) {
      map['genero'] = Variable<String>(genero.value);
    }
    if (fechaNacimiento.present) {
      map['fecha_nacimiento'] = Variable<DateTime>(fechaNacimiento.value);
    }
    if (nivelEducativo.present) {
      map['nivel_educativo'] = Variable<String>(nivelEducativo.value);
    }
    if (aniosExperiencia.present) {
      map['anios_experiencia'] = Variable<int>(aniosExperiencia.value);
    }
    if (personasHogar.present) {
      map['personas_hogar'] = Variable<int>(personasHogar.value);
    }
    if (organizacion.present) {
      map['organizacion'] = Variable<String>(organizacion.value);
    }
    if (notas.present) {
      map['notas'] = Variable<String>(notas.value);
    }
    if (fotoPath.present) {
      map['foto_path'] = Variable<String>(fotoPath.value);
    }
    if (enlaceFoto.present) {
      map['enlace_foto'] = Variable<String>(enlaceFoto.value);
    }
    if (fotoRemota.present) {
      map['foto_remota'] = Variable<String>(fotoRemota.value);
    }
    if (consentimientoDatos.present) {
      map['consentimiento_datos'] = Variable<bool>(consentimientoDatos.value);
    }
    if (fechaConsentimiento.present) {
      map['fecha_consentimiento'] = Variable<DateTime>(
        fechaConsentimiento.value,
      );
    }
    if (datosCompletadosEn.present) {
      map['datos_completados_en'] = Variable<DateTime>(
        datosCompletadosEn.value,
      );
    }
    if (codigoProductor.present) {
      map['codigo_productor'] = Variable<String>(codigoProductor.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (sincronizado.present) {
      map['sincronizado'] = Variable<bool>(sincronizado.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductoresCompanion(')
          ..write('id: $id, ')
          ..write('nombreCompleto: $nombreCompleto, ')
          ..write('documento: $documento, ')
          ..write('tipoDocumento: $tipoDocumento, ')
          ..write('telefono: $telefono, ')
          ..write('telefonoAlterno: $telefonoAlterno, ')
          ..write('genero: $genero, ')
          ..write('fechaNacimiento: $fechaNacimiento, ')
          ..write('nivelEducativo: $nivelEducativo, ')
          ..write('aniosExperiencia: $aniosExperiencia, ')
          ..write('personasHogar: $personasHogar, ')
          ..write('organizacion: $organizacion, ')
          ..write('notas: $notas, ')
          ..write('fotoPath: $fotoPath, ')
          ..write('enlaceFoto: $enlaceFoto, ')
          ..write('fotoRemota: $fotoRemota, ')
          ..write('consentimientoDatos: $consentimientoDatos, ')
          ..write('fechaConsentimiento: $fechaConsentimiento, ')
          ..write('datosCompletadosEn: $datosCompletadosEn, ')
          ..write('codigoProductor: $codigoProductor, ')
          ..write('remoteId: $remoteId, ')
          ..write('sincronizado: $sincronizado, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FincasTable extends Fincas with TableInfo<$FincasTable, Finca> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FincasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productorLocalIdMeta = const VerificationMeta(
    'productorLocalId',
  );
  @override
  late final GeneratedColumn<String> productorLocalId = GeneratedColumn<String>(
    'productor_local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _veredaLocalIdMeta = const VerificationMeta(
    'veredaLocalId',
  );
  @override
  late final GeneratedColumn<String> veredaLocalId = GeneratedColumn<String>(
    'vereda_local_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latitudMeta = const VerificationMeta(
    'latitud',
  );
  @override
  late final GeneratedColumn<double> latitud = GeneratedColumn<double>(
    'latitud',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudMeta = const VerificationMeta(
    'longitud',
  );
  @override
  late final GeneratedColumn<double> longitud = GeneratedColumn<double>(
    'longitud',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _areaTotalHaMeta = const VerificationMeta(
    'areaTotalHa',
  );
  @override
  late final GeneratedColumn<double> areaTotalHa = GeneratedColumn<double>(
    'area_total_ha',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sincronizadaMeta = const VerificationMeta(
    'sincronizada',
  );
  @override
  late final GeneratedColumn<bool> sincronizada = GeneratedColumn<bool>(
    'sincronizada',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sincronizada" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productorLocalId,
    nombre,
    veredaLocalId,
    latitud,
    longitud,
    areaTotalHa,
    remoteId,
    sincronizada,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fincas';
  @override
  VerificationContext validateIntegrity(
    Insertable<Finca> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('productor_local_id')) {
      context.handle(
        _productorLocalIdMeta,
        productorLocalId.isAcceptableOrUnknown(
          data['productor_local_id']!,
          _productorLocalIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productorLocalIdMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('vereda_local_id')) {
      context.handle(
        _veredaLocalIdMeta,
        veredaLocalId.isAcceptableOrUnknown(
          data['vereda_local_id']!,
          _veredaLocalIdMeta,
        ),
      );
    }
    if (data.containsKey('latitud')) {
      context.handle(
        _latitudMeta,
        latitud.isAcceptableOrUnknown(data['latitud']!, _latitudMeta),
      );
    }
    if (data.containsKey('longitud')) {
      context.handle(
        _longitudMeta,
        longitud.isAcceptableOrUnknown(data['longitud']!, _longitudMeta),
      );
    }
    if (data.containsKey('area_total_ha')) {
      context.handle(
        _areaTotalHaMeta,
        areaTotalHa.isAcceptableOrUnknown(
          data['area_total_ha']!,
          _areaTotalHaMeta,
        ),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('sincronizada')) {
      context.handle(
        _sincronizadaMeta,
        sincronizada.isAcceptableOrUnknown(
          data['sincronizada']!,
          _sincronizadaMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Finca map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Finca(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      productorLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}productor_local_id'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      veredaLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vereda_local_id'],
      ),
      latitud: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitud'],
      ),
      longitud: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitud'],
      ),
      areaTotalHa: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}area_total_ha'],
      ),
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      sincronizada: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sincronizada'],
      )!,
    );
  }

  @override
  $FincasTable createAlias(String alias) {
    return $FincasTable(attachedDatabase, alias);
  }
}

class Finca extends DataClass implements Insertable<Finca> {
  final String id;
  final String productorLocalId;
  final String nombre;
  final String? veredaLocalId;
  final double? latitud;
  final double? longitud;
  final double? areaTotalHa;
  final String? remoteId;
  final bool sincronizada;
  const Finca({
    required this.id,
    required this.productorLocalId,
    required this.nombre,
    this.veredaLocalId,
    this.latitud,
    this.longitud,
    this.areaTotalHa,
    this.remoteId,
    required this.sincronizada,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['productor_local_id'] = Variable<String>(productorLocalId);
    map['nombre'] = Variable<String>(nombre);
    if (!nullToAbsent || veredaLocalId != null) {
      map['vereda_local_id'] = Variable<String>(veredaLocalId);
    }
    if (!nullToAbsent || latitud != null) {
      map['latitud'] = Variable<double>(latitud);
    }
    if (!nullToAbsent || longitud != null) {
      map['longitud'] = Variable<double>(longitud);
    }
    if (!nullToAbsent || areaTotalHa != null) {
      map['area_total_ha'] = Variable<double>(areaTotalHa);
    }
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['sincronizada'] = Variable<bool>(sincronizada);
    return map;
  }

  FincasCompanion toCompanion(bool nullToAbsent) {
    return FincasCompanion(
      id: Value(id),
      productorLocalId: Value(productorLocalId),
      nombre: Value(nombre),
      veredaLocalId: veredaLocalId == null && nullToAbsent
          ? const Value.absent()
          : Value(veredaLocalId),
      latitud: latitud == null && nullToAbsent
          ? const Value.absent()
          : Value(latitud),
      longitud: longitud == null && nullToAbsent
          ? const Value.absent()
          : Value(longitud),
      areaTotalHa: areaTotalHa == null && nullToAbsent
          ? const Value.absent()
          : Value(areaTotalHa),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      sincronizada: Value(sincronizada),
    );
  }

  factory Finca.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Finca(
      id: serializer.fromJson<String>(json['id']),
      productorLocalId: serializer.fromJson<String>(json['productorLocalId']),
      nombre: serializer.fromJson<String>(json['nombre']),
      veredaLocalId: serializer.fromJson<String?>(json['veredaLocalId']),
      latitud: serializer.fromJson<double?>(json['latitud']),
      longitud: serializer.fromJson<double?>(json['longitud']),
      areaTotalHa: serializer.fromJson<double?>(json['areaTotalHa']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      sincronizada: serializer.fromJson<bool>(json['sincronizada']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'productorLocalId': serializer.toJson<String>(productorLocalId),
      'nombre': serializer.toJson<String>(nombre),
      'veredaLocalId': serializer.toJson<String?>(veredaLocalId),
      'latitud': serializer.toJson<double?>(latitud),
      'longitud': serializer.toJson<double?>(longitud),
      'areaTotalHa': serializer.toJson<double?>(areaTotalHa),
      'remoteId': serializer.toJson<String?>(remoteId),
      'sincronizada': serializer.toJson<bool>(sincronizada),
    };
  }

  Finca copyWith({
    String? id,
    String? productorLocalId,
    String? nombre,
    Value<String?> veredaLocalId = const Value.absent(),
    Value<double?> latitud = const Value.absent(),
    Value<double?> longitud = const Value.absent(),
    Value<double?> areaTotalHa = const Value.absent(),
    Value<String?> remoteId = const Value.absent(),
    bool? sincronizada,
  }) => Finca(
    id: id ?? this.id,
    productorLocalId: productorLocalId ?? this.productorLocalId,
    nombre: nombre ?? this.nombre,
    veredaLocalId: veredaLocalId.present
        ? veredaLocalId.value
        : this.veredaLocalId,
    latitud: latitud.present ? latitud.value : this.latitud,
    longitud: longitud.present ? longitud.value : this.longitud,
    areaTotalHa: areaTotalHa.present ? areaTotalHa.value : this.areaTotalHa,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    sincronizada: sincronizada ?? this.sincronizada,
  );
  Finca copyWithCompanion(FincasCompanion data) {
    return Finca(
      id: data.id.present ? data.id.value : this.id,
      productorLocalId: data.productorLocalId.present
          ? data.productorLocalId.value
          : this.productorLocalId,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      veredaLocalId: data.veredaLocalId.present
          ? data.veredaLocalId.value
          : this.veredaLocalId,
      latitud: data.latitud.present ? data.latitud.value : this.latitud,
      longitud: data.longitud.present ? data.longitud.value : this.longitud,
      areaTotalHa: data.areaTotalHa.present
          ? data.areaTotalHa.value
          : this.areaTotalHa,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      sincronizada: data.sincronizada.present
          ? data.sincronizada.value
          : this.sincronizada,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Finca(')
          ..write('id: $id, ')
          ..write('productorLocalId: $productorLocalId, ')
          ..write('nombre: $nombre, ')
          ..write('veredaLocalId: $veredaLocalId, ')
          ..write('latitud: $latitud, ')
          ..write('longitud: $longitud, ')
          ..write('areaTotalHa: $areaTotalHa, ')
          ..write('remoteId: $remoteId, ')
          ..write('sincronizada: $sincronizada')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    productorLocalId,
    nombre,
    veredaLocalId,
    latitud,
    longitud,
    areaTotalHa,
    remoteId,
    sincronizada,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Finca &&
          other.id == this.id &&
          other.productorLocalId == this.productorLocalId &&
          other.nombre == this.nombre &&
          other.veredaLocalId == this.veredaLocalId &&
          other.latitud == this.latitud &&
          other.longitud == this.longitud &&
          other.areaTotalHa == this.areaTotalHa &&
          other.remoteId == this.remoteId &&
          other.sincronizada == this.sincronizada);
}

class FincasCompanion extends UpdateCompanion<Finca> {
  final Value<String> id;
  final Value<String> productorLocalId;
  final Value<String> nombre;
  final Value<String?> veredaLocalId;
  final Value<double?> latitud;
  final Value<double?> longitud;
  final Value<double?> areaTotalHa;
  final Value<String?> remoteId;
  final Value<bool> sincronizada;
  final Value<int> rowid;
  const FincasCompanion({
    this.id = const Value.absent(),
    this.productorLocalId = const Value.absent(),
    this.nombre = const Value.absent(),
    this.veredaLocalId = const Value.absent(),
    this.latitud = const Value.absent(),
    this.longitud = const Value.absent(),
    this.areaTotalHa = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.sincronizada = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FincasCompanion.insert({
    required String id,
    required String productorLocalId,
    required String nombre,
    this.veredaLocalId = const Value.absent(),
    this.latitud = const Value.absent(),
    this.longitud = const Value.absent(),
    this.areaTotalHa = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.sincronizada = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       productorLocalId = Value(productorLocalId),
       nombre = Value(nombre);
  static Insertable<Finca> custom({
    Expression<String>? id,
    Expression<String>? productorLocalId,
    Expression<String>? nombre,
    Expression<String>? veredaLocalId,
    Expression<double>? latitud,
    Expression<double>? longitud,
    Expression<double>? areaTotalHa,
    Expression<String>? remoteId,
    Expression<bool>? sincronizada,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productorLocalId != null) 'productor_local_id': productorLocalId,
      if (nombre != null) 'nombre': nombre,
      if (veredaLocalId != null) 'vereda_local_id': veredaLocalId,
      if (latitud != null) 'latitud': latitud,
      if (longitud != null) 'longitud': longitud,
      if (areaTotalHa != null) 'area_total_ha': areaTotalHa,
      if (remoteId != null) 'remote_id': remoteId,
      if (sincronizada != null) 'sincronizada': sincronizada,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FincasCompanion copyWith({
    Value<String>? id,
    Value<String>? productorLocalId,
    Value<String>? nombre,
    Value<String?>? veredaLocalId,
    Value<double?>? latitud,
    Value<double?>? longitud,
    Value<double?>? areaTotalHa,
    Value<String?>? remoteId,
    Value<bool>? sincronizada,
    Value<int>? rowid,
  }) {
    return FincasCompanion(
      id: id ?? this.id,
      productorLocalId: productorLocalId ?? this.productorLocalId,
      nombre: nombre ?? this.nombre,
      veredaLocalId: veredaLocalId ?? this.veredaLocalId,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      areaTotalHa: areaTotalHa ?? this.areaTotalHa,
      remoteId: remoteId ?? this.remoteId,
      sincronizada: sincronizada ?? this.sincronizada,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (productorLocalId.present) {
      map['productor_local_id'] = Variable<String>(productorLocalId.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (veredaLocalId.present) {
      map['vereda_local_id'] = Variable<String>(veredaLocalId.value);
    }
    if (latitud.present) {
      map['latitud'] = Variable<double>(latitud.value);
    }
    if (longitud.present) {
      map['longitud'] = Variable<double>(longitud.value);
    }
    if (areaTotalHa.present) {
      map['area_total_ha'] = Variable<double>(areaTotalHa.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (sincronizada.present) {
      map['sincronizada'] = Variable<bool>(sincronizada.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FincasCompanion(')
          ..write('id: $id, ')
          ..write('productorLocalId: $productorLocalId, ')
          ..write('nombre: $nombre, ')
          ..write('veredaLocalId: $veredaLocalId, ')
          ..write('latitud: $latitud, ')
          ..write('longitud: $longitud, ')
          ..write('areaTotalHa: $areaTotalHa, ')
          ..write('remoteId: $remoteId, ')
          ..write('sincronizada: $sincronizada, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VisitasTable extends Visitas with TableInfo<$VisitasTable, Visita> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VisitasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inicioMeta = const VerificationMeta('inicio');
  @override
  late final GeneratedColumn<DateTime> inicio = GeneratedColumn<DateTime>(
    'inicio',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finMeta = const VerificationMeta('fin');
  @override
  late final GeneratedColumn<DateTime> fin = GeneratedColumn<DateTime>(
    'fin',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _visitadorLocalIdMeta = const VerificationMeta(
    'visitadorLocalId',
  );
  @override
  late final GeneratedColumn<String> visitadorLocalId = GeneratedColumn<String>(
    'visitador_local_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _productorLocalIdMeta = const VerificationMeta(
    'productorLocalId',
  );
  @override
  late final GeneratedColumn<String> productorLocalId = GeneratedColumn<String>(
    'productor_local_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fincaLocalIdMeta = const VerificationMeta(
    'fincaLocalId',
  );
  @override
  late final GeneratedColumn<String> fincaLocalId = GeneratedColumn<String>(
    'finca_local_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _veredaLocalIdMeta = const VerificationMeta(
    'veredaLocalId',
  );
  @override
  late final GeneratedColumn<String> veredaLocalId = GeneratedColumn<String>(
    'vereda_local_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tipoVisitaMeta = const VerificationMeta(
    'tipoVisita',
  );
  @override
  late final GeneratedColumn<String> tipoVisita = GeneratedColumn<String>(
    'tipo_visita',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latitudMeta = const VerificationMeta(
    'latitud',
  );
  @override
  late final GeneratedColumn<double> latitud = GeneratedColumn<double>(
    'latitud',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudMeta = const VerificationMeta(
    'longitud',
  );
  @override
  late final GeneratedColumn<double> longitud = GeneratedColumn<double>(
    'longitud',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _precisionGpsMeta = const VerificationMeta(
    'precisionGps',
  );
  @override
  late final GeneratedColumn<double> precisionGps = GeneratedColumn<double>(
    'precision_gps',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _estadoMeta = const VerificationMeta('estado');
  @override
  late final GeneratedColumn<String> estado = GeneratedColumn<String>(
    'estado',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('En curso'),
  );
  static const VerificationMeta _consienteAudioMeta = const VerificationMeta(
    'consienteAudio',
  );
  @override
  late final GeneratedColumn<bool> consienteAudio = GeneratedColumn<bool>(
    'consiente_audio',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("consiente_audio" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _consienteFotosMeta = const VerificationMeta(
    'consienteFotos',
  );
  @override
  late final GeneratedColumn<bool> consienteFotos = GeneratedColumn<bool>(
    'consiente_fotos',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("consiente_fotos" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _consienteUsoDatosMeta = const VerificationMeta(
    'consienteUsoDatos',
  );
  @override
  late final GeneratedColumn<bool> consienteUsoDatos = GeneratedColumn<bool>(
    'consiente_uso_datos',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("consiente_uso_datos" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _segundoConsentimientoMeta =
      const VerificationMeta('segundoConsentimiento');
  @override
  late final GeneratedColumn<int> segundoConsentimiento = GeneratedColumn<int>(
    'segundo_consentimiento',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _marcadaParaEliminacionMeta =
      const VerificationMeta('marcadaParaEliminacion');
  @override
  late final GeneratedColumn<bool> marcadaParaEliminacion =
      GeneratedColumn<bool>(
        'marcada_para_eliminacion',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("marcada_para_eliminacion" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _objetivoMeta = const VerificationMeta(
    'objetivo',
  );
  @override
  late final GeneratedColumn<String> objetivo = GeneratedColumn<String>(
    'objetivo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _observacionesMeta = const VerificationMeta(
    'observaciones',
  );
  @override
  late final GeneratedColumn<String> observaciones = GeneratedColumn<String>(
    'observaciones',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resumenMeta = const VerificationMeta(
    'resumen',
  );
  @override
  late final GeneratedColumn<String> resumen = GeneratedColumn<String>(
    'resumen',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _temasPendientesMeta = const VerificationMeta(
    'temasPendientes',
  );
  @override
  late final GeneratedColumn<String> temasPendientes = GeneratedColumn<String>(
    'temas_pendientes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notasPruebaCampoMeta = const VerificationMeta(
    'notasPruebaCampo',
  );
  @override
  late final GeneratedColumn<String> notasPruebaCampo = GeneratedColumn<String>(
    'notas_prueba_campo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completitudPctMeta = const VerificationMeta(
    'completitudPct',
  );
  @override
  late final GeneratedColumn<int> completitudPct = GeneratedColumn<int>(
    'completitud_pct',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sincronizadaMeta = const VerificationMeta(
    'sincronizada',
  );
  @override
  late final GeneratedColumn<bool> sincronizada = GeneratedColumn<bool>(
    'sincronizada',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sincronizada" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sincronizadaEnMeta = const VerificationMeta(
    'sincronizadaEn',
  );
  @override
  late final GeneratedColumn<DateTime> sincronizadaEn =
      GeneratedColumn<DateTime>(
        'sincronizada_en',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _soloLecturaMeta = const VerificationMeta(
    'soloLectura',
  );
  @override
  late final GeneratedColumn<bool> soloLectura = GeneratedColumn<bool>(
    'solo_lectura',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("solo_lectura" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _descargadaEnMeta = const VerificationMeta(
    'descargadaEn',
  );
  @override
  late final GeneratedColumn<DateTime> descargadaEn = GeneratedColumn<DateTime>(
    'descargada_en',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _detalleEnMeta = const VerificationMeta(
    'detalleEn',
  );
  @override
  late final GeneratedColumn<DateTime> detalleEn = GeneratedColumn<DateTime>(
    'detalle_en',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    inicio,
    fin,
    visitadorLocalId,
    productorLocalId,
    fincaLocalId,
    veredaLocalId,
    tipoVisita,
    latitud,
    longitud,
    precisionGps,
    estado,
    consienteAudio,
    consienteFotos,
    consienteUsoDatos,
    segundoConsentimiento,
    marcadaParaEliminacion,
    objetivo,
    observaciones,
    resumen,
    temasPendientes,
    notasPruebaCampo,
    completitudPct,
    sincronizada,
    sincronizadaEn,
    soloLectura,
    descargadaEn,
    detalleEn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'visitas';
  @override
  VerificationContext validateIntegrity(
    Insertable<Visita> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('inicio')) {
      context.handle(
        _inicioMeta,
        inicio.isAcceptableOrUnknown(data['inicio']!, _inicioMeta),
      );
    } else if (isInserting) {
      context.missing(_inicioMeta);
    }
    if (data.containsKey('fin')) {
      context.handle(
        _finMeta,
        fin.isAcceptableOrUnknown(data['fin']!, _finMeta),
      );
    }
    if (data.containsKey('visitador_local_id')) {
      context.handle(
        _visitadorLocalIdMeta,
        visitadorLocalId.isAcceptableOrUnknown(
          data['visitador_local_id']!,
          _visitadorLocalIdMeta,
        ),
      );
    }
    if (data.containsKey('productor_local_id')) {
      context.handle(
        _productorLocalIdMeta,
        productorLocalId.isAcceptableOrUnknown(
          data['productor_local_id']!,
          _productorLocalIdMeta,
        ),
      );
    }
    if (data.containsKey('finca_local_id')) {
      context.handle(
        _fincaLocalIdMeta,
        fincaLocalId.isAcceptableOrUnknown(
          data['finca_local_id']!,
          _fincaLocalIdMeta,
        ),
      );
    }
    if (data.containsKey('vereda_local_id')) {
      context.handle(
        _veredaLocalIdMeta,
        veredaLocalId.isAcceptableOrUnknown(
          data['vereda_local_id']!,
          _veredaLocalIdMeta,
        ),
      );
    }
    if (data.containsKey('tipo_visita')) {
      context.handle(
        _tipoVisitaMeta,
        tipoVisita.isAcceptableOrUnknown(data['tipo_visita']!, _tipoVisitaMeta),
      );
    }
    if (data.containsKey('latitud')) {
      context.handle(
        _latitudMeta,
        latitud.isAcceptableOrUnknown(data['latitud']!, _latitudMeta),
      );
    }
    if (data.containsKey('longitud')) {
      context.handle(
        _longitudMeta,
        longitud.isAcceptableOrUnknown(data['longitud']!, _longitudMeta),
      );
    }
    if (data.containsKey('precision_gps')) {
      context.handle(
        _precisionGpsMeta,
        precisionGps.isAcceptableOrUnknown(
          data['precision_gps']!,
          _precisionGpsMeta,
        ),
      );
    }
    if (data.containsKey('estado')) {
      context.handle(
        _estadoMeta,
        estado.isAcceptableOrUnknown(data['estado']!, _estadoMeta),
      );
    }
    if (data.containsKey('consiente_audio')) {
      context.handle(
        _consienteAudioMeta,
        consienteAudio.isAcceptableOrUnknown(
          data['consiente_audio']!,
          _consienteAudioMeta,
        ),
      );
    }
    if (data.containsKey('consiente_fotos')) {
      context.handle(
        _consienteFotosMeta,
        consienteFotos.isAcceptableOrUnknown(
          data['consiente_fotos']!,
          _consienteFotosMeta,
        ),
      );
    }
    if (data.containsKey('consiente_uso_datos')) {
      context.handle(
        _consienteUsoDatosMeta,
        consienteUsoDatos.isAcceptableOrUnknown(
          data['consiente_uso_datos']!,
          _consienteUsoDatosMeta,
        ),
      );
    }
    if (data.containsKey('segundo_consentimiento')) {
      context.handle(
        _segundoConsentimientoMeta,
        segundoConsentimiento.isAcceptableOrUnknown(
          data['segundo_consentimiento']!,
          _segundoConsentimientoMeta,
        ),
      );
    }
    if (data.containsKey('marcada_para_eliminacion')) {
      context.handle(
        _marcadaParaEliminacionMeta,
        marcadaParaEliminacion.isAcceptableOrUnknown(
          data['marcada_para_eliminacion']!,
          _marcadaParaEliminacionMeta,
        ),
      );
    }
    if (data.containsKey('objetivo')) {
      context.handle(
        _objetivoMeta,
        objetivo.isAcceptableOrUnknown(data['objetivo']!, _objetivoMeta),
      );
    }
    if (data.containsKey('observaciones')) {
      context.handle(
        _observacionesMeta,
        observaciones.isAcceptableOrUnknown(
          data['observaciones']!,
          _observacionesMeta,
        ),
      );
    }
    if (data.containsKey('resumen')) {
      context.handle(
        _resumenMeta,
        resumen.isAcceptableOrUnknown(data['resumen']!, _resumenMeta),
      );
    }
    if (data.containsKey('temas_pendientes')) {
      context.handle(
        _temasPendientesMeta,
        temasPendientes.isAcceptableOrUnknown(
          data['temas_pendientes']!,
          _temasPendientesMeta,
        ),
      );
    }
    if (data.containsKey('notas_prueba_campo')) {
      context.handle(
        _notasPruebaCampoMeta,
        notasPruebaCampo.isAcceptableOrUnknown(
          data['notas_prueba_campo']!,
          _notasPruebaCampoMeta,
        ),
      );
    }
    if (data.containsKey('completitud_pct')) {
      context.handle(
        _completitudPctMeta,
        completitudPct.isAcceptableOrUnknown(
          data['completitud_pct']!,
          _completitudPctMeta,
        ),
      );
    }
    if (data.containsKey('sincronizada')) {
      context.handle(
        _sincronizadaMeta,
        sincronizada.isAcceptableOrUnknown(
          data['sincronizada']!,
          _sincronizadaMeta,
        ),
      );
    }
    if (data.containsKey('sincronizada_en')) {
      context.handle(
        _sincronizadaEnMeta,
        sincronizadaEn.isAcceptableOrUnknown(
          data['sincronizada_en']!,
          _sincronizadaEnMeta,
        ),
      );
    }
    if (data.containsKey('solo_lectura')) {
      context.handle(
        _soloLecturaMeta,
        soloLectura.isAcceptableOrUnknown(
          data['solo_lectura']!,
          _soloLecturaMeta,
        ),
      );
    }
    if (data.containsKey('descargada_en')) {
      context.handle(
        _descargadaEnMeta,
        descargadaEn.isAcceptableOrUnknown(
          data['descargada_en']!,
          _descargadaEnMeta,
        ),
      );
    }
    if (data.containsKey('detalle_en')) {
      context.handle(
        _detalleEnMeta,
        detalleEn.isAcceptableOrUnknown(data['detalle_en']!, _detalleEnMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Visita map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Visita(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      inicio: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}inicio'],
      )!,
      fin: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fin'],
      ),
      visitadorLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visitador_local_id'],
      ),
      productorLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}productor_local_id'],
      ),
      fincaLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}finca_local_id'],
      ),
      veredaLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vereda_local_id'],
      ),
      tipoVisita: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo_visita'],
      ),
      latitud: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitud'],
      ),
      longitud: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitud'],
      ),
      precisionGps: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}precision_gps'],
      ),
      estado: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}estado'],
      )!,
      consienteAudio: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}consiente_audio'],
      )!,
      consienteFotos: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}consiente_fotos'],
      )!,
      consienteUsoDatos: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}consiente_uso_datos'],
      )!,
      segundoConsentimiento: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}segundo_consentimiento'],
      ),
      marcadaParaEliminacion: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}marcada_para_eliminacion'],
      )!,
      objetivo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}objetivo'],
      ),
      observaciones: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}observaciones'],
      ),
      resumen: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resumen'],
      ),
      temasPendientes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}temas_pendientes'],
      ),
      notasPruebaCampo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notas_prueba_campo'],
      ),
      completitudPct: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completitud_pct'],
      )!,
      sincronizada: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sincronizada'],
      )!,
      sincronizadaEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sincronizada_en'],
      ),
      soloLectura: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}solo_lectura'],
      )!,
      descargadaEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}descargada_en'],
      ),
      detalleEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}detalle_en'],
      ),
    );
  }

  @override
  $VisitasTable createAlias(String alias) {
    return $VisitasTable(attachedDatabase, alias);
  }
}

class Visita extends DataClass implements Insertable<Visita> {
  /// UUID v4 del dispositivo. Es tambien `Visitas.Codigo de visita` en Airtable.
  final String id;
  final DateTime inicio;
  final DateTime? fin;
  final String? visitadorLocalId;
  final String? productorLocalId;
  final String? fincaLocalId;
  final String? veredaLocalId;
  final String? tipoVisita;
  final double? latitud;
  final double? longitud;
  final double? precisionGps;
  final String estado;

  /// El boton de grabar esta deshabilitado mientras esto sea false.
  final bool consienteAudio;
  final bool consienteFotos;
  final bool consienteUsoDatos;

  /// Segundo del audio donde consta verbalmente. Prueba auditable.
  final int? segundoConsentimiento;

  /// El productor revoco. Al sincronizar, el backend borra audio, fotos y hallazgos.
  final bool marcadaParaEliminacion;
  final String? objetivo;
  final String? observaciones;
  final String? resumen;
  final String? temasPendientes;
  final String? notasPruebaCampo;

  /// Recalculada localmente en cada cambio de hallazgos. El backend la recalcula
  /// al sincronizar y su valor manda: este es para el semaforo en campo.
  final int completitudPct;
  final bool sincronizada;
  final DateTime? sincronizadaEn;

  /// Esta visita se bajo de Airtable para consultarla, no se registro aqui.
  ///
  /// Es la marca que la vuelve intocable: no se graba, no se le toman fotos,
  /// no se edita y NUNCA se vuelve a encolar. Sin esto, espejar el historial
  /// de un agricultor podria terminar reescribiendo en Airtable una visita que
  /// hizo otro visitador con datos a medio bajar.
  ///
  /// Que sea una columna y no un estado es a proposito: `estado` viaja a
  /// Airtable, y el hecho de que una copia viva en este telefono no es asunto
  /// del registro central.
  final bool soloLectura;

  /// Cuando se bajo el espejo. Es lo que permite decir en la pantalla «traido
  /// el martes» y saber si vale la pena volver a pedirlo.
  final DateTime? descargadaEn;

  /// Cuando se bajo el DETALLE de este espejo: hallazgos, fotos, audio,
  /// informes.
  ///
  /// Null significa que del espejo solo esta la ficha, que es como llega desde
  /// el indice automatico. Esa diferencia es lo que permite que la lista se
  /// refresque sola sin bajar cientos de megas: doscientas fichas son unos KB,
  /// y las mismas con sus fotos no caben en un telefono de campo.
  ///
  /// Sin esta columna habria que adivinar si una visita sin hallazgos es una
  /// visita vacia o una que no se ha terminado de bajar — y son cosas
  /// distintas que se ven igual.
  final DateTime? detalleEn;
  const Visita({
    required this.id,
    required this.inicio,
    this.fin,
    this.visitadorLocalId,
    this.productorLocalId,
    this.fincaLocalId,
    this.veredaLocalId,
    this.tipoVisita,
    this.latitud,
    this.longitud,
    this.precisionGps,
    required this.estado,
    required this.consienteAudio,
    required this.consienteFotos,
    required this.consienteUsoDatos,
    this.segundoConsentimiento,
    required this.marcadaParaEliminacion,
    this.objetivo,
    this.observaciones,
    this.resumen,
    this.temasPendientes,
    this.notasPruebaCampo,
    required this.completitudPct,
    required this.sincronizada,
    this.sincronizadaEn,
    required this.soloLectura,
    this.descargadaEn,
    this.detalleEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['inicio'] = Variable<DateTime>(inicio);
    if (!nullToAbsent || fin != null) {
      map['fin'] = Variable<DateTime>(fin);
    }
    if (!nullToAbsent || visitadorLocalId != null) {
      map['visitador_local_id'] = Variable<String>(visitadorLocalId);
    }
    if (!nullToAbsent || productorLocalId != null) {
      map['productor_local_id'] = Variable<String>(productorLocalId);
    }
    if (!nullToAbsent || fincaLocalId != null) {
      map['finca_local_id'] = Variable<String>(fincaLocalId);
    }
    if (!nullToAbsent || veredaLocalId != null) {
      map['vereda_local_id'] = Variable<String>(veredaLocalId);
    }
    if (!nullToAbsent || tipoVisita != null) {
      map['tipo_visita'] = Variable<String>(tipoVisita);
    }
    if (!nullToAbsent || latitud != null) {
      map['latitud'] = Variable<double>(latitud);
    }
    if (!nullToAbsent || longitud != null) {
      map['longitud'] = Variable<double>(longitud);
    }
    if (!nullToAbsent || precisionGps != null) {
      map['precision_gps'] = Variable<double>(precisionGps);
    }
    map['estado'] = Variable<String>(estado);
    map['consiente_audio'] = Variable<bool>(consienteAudio);
    map['consiente_fotos'] = Variable<bool>(consienteFotos);
    map['consiente_uso_datos'] = Variable<bool>(consienteUsoDatos);
    if (!nullToAbsent || segundoConsentimiento != null) {
      map['segundo_consentimiento'] = Variable<int>(segundoConsentimiento);
    }
    map['marcada_para_eliminacion'] = Variable<bool>(marcadaParaEliminacion);
    if (!nullToAbsent || objetivo != null) {
      map['objetivo'] = Variable<String>(objetivo);
    }
    if (!nullToAbsent || observaciones != null) {
      map['observaciones'] = Variable<String>(observaciones);
    }
    if (!nullToAbsent || resumen != null) {
      map['resumen'] = Variable<String>(resumen);
    }
    if (!nullToAbsent || temasPendientes != null) {
      map['temas_pendientes'] = Variable<String>(temasPendientes);
    }
    if (!nullToAbsent || notasPruebaCampo != null) {
      map['notas_prueba_campo'] = Variable<String>(notasPruebaCampo);
    }
    map['completitud_pct'] = Variable<int>(completitudPct);
    map['sincronizada'] = Variable<bool>(sincronizada);
    if (!nullToAbsent || sincronizadaEn != null) {
      map['sincronizada_en'] = Variable<DateTime>(sincronizadaEn);
    }
    map['solo_lectura'] = Variable<bool>(soloLectura);
    if (!nullToAbsent || descargadaEn != null) {
      map['descargada_en'] = Variable<DateTime>(descargadaEn);
    }
    if (!nullToAbsent || detalleEn != null) {
      map['detalle_en'] = Variable<DateTime>(detalleEn);
    }
    return map;
  }

  VisitasCompanion toCompanion(bool nullToAbsent) {
    return VisitasCompanion(
      id: Value(id),
      inicio: Value(inicio),
      fin: fin == null && nullToAbsent ? const Value.absent() : Value(fin),
      visitadorLocalId: visitadorLocalId == null && nullToAbsent
          ? const Value.absent()
          : Value(visitadorLocalId),
      productorLocalId: productorLocalId == null && nullToAbsent
          ? const Value.absent()
          : Value(productorLocalId),
      fincaLocalId: fincaLocalId == null && nullToAbsent
          ? const Value.absent()
          : Value(fincaLocalId),
      veredaLocalId: veredaLocalId == null && nullToAbsent
          ? const Value.absent()
          : Value(veredaLocalId),
      tipoVisita: tipoVisita == null && nullToAbsent
          ? const Value.absent()
          : Value(tipoVisita),
      latitud: latitud == null && nullToAbsent
          ? const Value.absent()
          : Value(latitud),
      longitud: longitud == null && nullToAbsent
          ? const Value.absent()
          : Value(longitud),
      precisionGps: precisionGps == null && nullToAbsent
          ? const Value.absent()
          : Value(precisionGps),
      estado: Value(estado),
      consienteAudio: Value(consienteAudio),
      consienteFotos: Value(consienteFotos),
      consienteUsoDatos: Value(consienteUsoDatos),
      segundoConsentimiento: segundoConsentimiento == null && nullToAbsent
          ? const Value.absent()
          : Value(segundoConsentimiento),
      marcadaParaEliminacion: Value(marcadaParaEliminacion),
      objetivo: objetivo == null && nullToAbsent
          ? const Value.absent()
          : Value(objetivo),
      observaciones: observaciones == null && nullToAbsent
          ? const Value.absent()
          : Value(observaciones),
      resumen: resumen == null && nullToAbsent
          ? const Value.absent()
          : Value(resumen),
      temasPendientes: temasPendientes == null && nullToAbsent
          ? const Value.absent()
          : Value(temasPendientes),
      notasPruebaCampo: notasPruebaCampo == null && nullToAbsent
          ? const Value.absent()
          : Value(notasPruebaCampo),
      completitudPct: Value(completitudPct),
      sincronizada: Value(sincronizada),
      sincronizadaEn: sincronizadaEn == null && nullToAbsent
          ? const Value.absent()
          : Value(sincronizadaEn),
      soloLectura: Value(soloLectura),
      descargadaEn: descargadaEn == null && nullToAbsent
          ? const Value.absent()
          : Value(descargadaEn),
      detalleEn: detalleEn == null && nullToAbsent
          ? const Value.absent()
          : Value(detalleEn),
    );
  }

  factory Visita.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Visita(
      id: serializer.fromJson<String>(json['id']),
      inicio: serializer.fromJson<DateTime>(json['inicio']),
      fin: serializer.fromJson<DateTime?>(json['fin']),
      visitadorLocalId: serializer.fromJson<String?>(json['visitadorLocalId']),
      productorLocalId: serializer.fromJson<String?>(json['productorLocalId']),
      fincaLocalId: serializer.fromJson<String?>(json['fincaLocalId']),
      veredaLocalId: serializer.fromJson<String?>(json['veredaLocalId']),
      tipoVisita: serializer.fromJson<String?>(json['tipoVisita']),
      latitud: serializer.fromJson<double?>(json['latitud']),
      longitud: serializer.fromJson<double?>(json['longitud']),
      precisionGps: serializer.fromJson<double?>(json['precisionGps']),
      estado: serializer.fromJson<String>(json['estado']),
      consienteAudio: serializer.fromJson<bool>(json['consienteAudio']),
      consienteFotos: serializer.fromJson<bool>(json['consienteFotos']),
      consienteUsoDatos: serializer.fromJson<bool>(json['consienteUsoDatos']),
      segundoConsentimiento: serializer.fromJson<int?>(
        json['segundoConsentimiento'],
      ),
      marcadaParaEliminacion: serializer.fromJson<bool>(
        json['marcadaParaEliminacion'],
      ),
      objetivo: serializer.fromJson<String?>(json['objetivo']),
      observaciones: serializer.fromJson<String?>(json['observaciones']),
      resumen: serializer.fromJson<String?>(json['resumen']),
      temasPendientes: serializer.fromJson<String?>(json['temasPendientes']),
      notasPruebaCampo: serializer.fromJson<String?>(json['notasPruebaCampo']),
      completitudPct: serializer.fromJson<int>(json['completitudPct']),
      sincronizada: serializer.fromJson<bool>(json['sincronizada']),
      sincronizadaEn: serializer.fromJson<DateTime?>(json['sincronizadaEn']),
      soloLectura: serializer.fromJson<bool>(json['soloLectura']),
      descargadaEn: serializer.fromJson<DateTime?>(json['descargadaEn']),
      detalleEn: serializer.fromJson<DateTime?>(json['detalleEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'inicio': serializer.toJson<DateTime>(inicio),
      'fin': serializer.toJson<DateTime?>(fin),
      'visitadorLocalId': serializer.toJson<String?>(visitadorLocalId),
      'productorLocalId': serializer.toJson<String?>(productorLocalId),
      'fincaLocalId': serializer.toJson<String?>(fincaLocalId),
      'veredaLocalId': serializer.toJson<String?>(veredaLocalId),
      'tipoVisita': serializer.toJson<String?>(tipoVisita),
      'latitud': serializer.toJson<double?>(latitud),
      'longitud': serializer.toJson<double?>(longitud),
      'precisionGps': serializer.toJson<double?>(precisionGps),
      'estado': serializer.toJson<String>(estado),
      'consienteAudio': serializer.toJson<bool>(consienteAudio),
      'consienteFotos': serializer.toJson<bool>(consienteFotos),
      'consienteUsoDatos': serializer.toJson<bool>(consienteUsoDatos),
      'segundoConsentimiento': serializer.toJson<int?>(segundoConsentimiento),
      'marcadaParaEliminacion': serializer.toJson<bool>(marcadaParaEliminacion),
      'objetivo': serializer.toJson<String?>(objetivo),
      'observaciones': serializer.toJson<String?>(observaciones),
      'resumen': serializer.toJson<String?>(resumen),
      'temasPendientes': serializer.toJson<String?>(temasPendientes),
      'notasPruebaCampo': serializer.toJson<String?>(notasPruebaCampo),
      'completitudPct': serializer.toJson<int>(completitudPct),
      'sincronizada': serializer.toJson<bool>(sincronizada),
      'sincronizadaEn': serializer.toJson<DateTime?>(sincronizadaEn),
      'soloLectura': serializer.toJson<bool>(soloLectura),
      'descargadaEn': serializer.toJson<DateTime?>(descargadaEn),
      'detalleEn': serializer.toJson<DateTime?>(detalleEn),
    };
  }

  Visita copyWith({
    String? id,
    DateTime? inicio,
    Value<DateTime?> fin = const Value.absent(),
    Value<String?> visitadorLocalId = const Value.absent(),
    Value<String?> productorLocalId = const Value.absent(),
    Value<String?> fincaLocalId = const Value.absent(),
    Value<String?> veredaLocalId = const Value.absent(),
    Value<String?> tipoVisita = const Value.absent(),
    Value<double?> latitud = const Value.absent(),
    Value<double?> longitud = const Value.absent(),
    Value<double?> precisionGps = const Value.absent(),
    String? estado,
    bool? consienteAudio,
    bool? consienteFotos,
    bool? consienteUsoDatos,
    Value<int?> segundoConsentimiento = const Value.absent(),
    bool? marcadaParaEliminacion,
    Value<String?> objetivo = const Value.absent(),
    Value<String?> observaciones = const Value.absent(),
    Value<String?> resumen = const Value.absent(),
    Value<String?> temasPendientes = const Value.absent(),
    Value<String?> notasPruebaCampo = const Value.absent(),
    int? completitudPct,
    bool? sincronizada,
    Value<DateTime?> sincronizadaEn = const Value.absent(),
    bool? soloLectura,
    Value<DateTime?> descargadaEn = const Value.absent(),
    Value<DateTime?> detalleEn = const Value.absent(),
  }) => Visita(
    id: id ?? this.id,
    inicio: inicio ?? this.inicio,
    fin: fin.present ? fin.value : this.fin,
    visitadorLocalId: visitadorLocalId.present
        ? visitadorLocalId.value
        : this.visitadorLocalId,
    productorLocalId: productorLocalId.present
        ? productorLocalId.value
        : this.productorLocalId,
    fincaLocalId: fincaLocalId.present ? fincaLocalId.value : this.fincaLocalId,
    veredaLocalId: veredaLocalId.present
        ? veredaLocalId.value
        : this.veredaLocalId,
    tipoVisita: tipoVisita.present ? tipoVisita.value : this.tipoVisita,
    latitud: latitud.present ? latitud.value : this.latitud,
    longitud: longitud.present ? longitud.value : this.longitud,
    precisionGps: precisionGps.present ? precisionGps.value : this.precisionGps,
    estado: estado ?? this.estado,
    consienteAudio: consienteAudio ?? this.consienteAudio,
    consienteFotos: consienteFotos ?? this.consienteFotos,
    consienteUsoDatos: consienteUsoDatos ?? this.consienteUsoDatos,
    segundoConsentimiento: segundoConsentimiento.present
        ? segundoConsentimiento.value
        : this.segundoConsentimiento,
    marcadaParaEliminacion:
        marcadaParaEliminacion ?? this.marcadaParaEliminacion,
    objetivo: objetivo.present ? objetivo.value : this.objetivo,
    observaciones: observaciones.present
        ? observaciones.value
        : this.observaciones,
    resumen: resumen.present ? resumen.value : this.resumen,
    temasPendientes: temasPendientes.present
        ? temasPendientes.value
        : this.temasPendientes,
    notasPruebaCampo: notasPruebaCampo.present
        ? notasPruebaCampo.value
        : this.notasPruebaCampo,
    completitudPct: completitudPct ?? this.completitudPct,
    sincronizada: sincronizada ?? this.sincronizada,
    sincronizadaEn: sincronizadaEn.present
        ? sincronizadaEn.value
        : this.sincronizadaEn,
    soloLectura: soloLectura ?? this.soloLectura,
    descargadaEn: descargadaEn.present ? descargadaEn.value : this.descargadaEn,
    detalleEn: detalleEn.present ? detalleEn.value : this.detalleEn,
  );
  Visita copyWithCompanion(VisitasCompanion data) {
    return Visita(
      id: data.id.present ? data.id.value : this.id,
      inicio: data.inicio.present ? data.inicio.value : this.inicio,
      fin: data.fin.present ? data.fin.value : this.fin,
      visitadorLocalId: data.visitadorLocalId.present
          ? data.visitadorLocalId.value
          : this.visitadorLocalId,
      productorLocalId: data.productorLocalId.present
          ? data.productorLocalId.value
          : this.productorLocalId,
      fincaLocalId: data.fincaLocalId.present
          ? data.fincaLocalId.value
          : this.fincaLocalId,
      veredaLocalId: data.veredaLocalId.present
          ? data.veredaLocalId.value
          : this.veredaLocalId,
      tipoVisita: data.tipoVisita.present
          ? data.tipoVisita.value
          : this.tipoVisita,
      latitud: data.latitud.present ? data.latitud.value : this.latitud,
      longitud: data.longitud.present ? data.longitud.value : this.longitud,
      precisionGps: data.precisionGps.present
          ? data.precisionGps.value
          : this.precisionGps,
      estado: data.estado.present ? data.estado.value : this.estado,
      consienteAudio: data.consienteAudio.present
          ? data.consienteAudio.value
          : this.consienteAudio,
      consienteFotos: data.consienteFotos.present
          ? data.consienteFotos.value
          : this.consienteFotos,
      consienteUsoDatos: data.consienteUsoDatos.present
          ? data.consienteUsoDatos.value
          : this.consienteUsoDatos,
      segundoConsentimiento: data.segundoConsentimiento.present
          ? data.segundoConsentimiento.value
          : this.segundoConsentimiento,
      marcadaParaEliminacion: data.marcadaParaEliminacion.present
          ? data.marcadaParaEliminacion.value
          : this.marcadaParaEliminacion,
      objetivo: data.objetivo.present ? data.objetivo.value : this.objetivo,
      observaciones: data.observaciones.present
          ? data.observaciones.value
          : this.observaciones,
      resumen: data.resumen.present ? data.resumen.value : this.resumen,
      temasPendientes: data.temasPendientes.present
          ? data.temasPendientes.value
          : this.temasPendientes,
      notasPruebaCampo: data.notasPruebaCampo.present
          ? data.notasPruebaCampo.value
          : this.notasPruebaCampo,
      completitudPct: data.completitudPct.present
          ? data.completitudPct.value
          : this.completitudPct,
      sincronizada: data.sincronizada.present
          ? data.sincronizada.value
          : this.sincronizada,
      sincronizadaEn: data.sincronizadaEn.present
          ? data.sincronizadaEn.value
          : this.sincronizadaEn,
      soloLectura: data.soloLectura.present
          ? data.soloLectura.value
          : this.soloLectura,
      descargadaEn: data.descargadaEn.present
          ? data.descargadaEn.value
          : this.descargadaEn,
      detalleEn: data.detalleEn.present ? data.detalleEn.value : this.detalleEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Visita(')
          ..write('id: $id, ')
          ..write('inicio: $inicio, ')
          ..write('fin: $fin, ')
          ..write('visitadorLocalId: $visitadorLocalId, ')
          ..write('productorLocalId: $productorLocalId, ')
          ..write('fincaLocalId: $fincaLocalId, ')
          ..write('veredaLocalId: $veredaLocalId, ')
          ..write('tipoVisita: $tipoVisita, ')
          ..write('latitud: $latitud, ')
          ..write('longitud: $longitud, ')
          ..write('precisionGps: $precisionGps, ')
          ..write('estado: $estado, ')
          ..write('consienteAudio: $consienteAudio, ')
          ..write('consienteFotos: $consienteFotos, ')
          ..write('consienteUsoDatos: $consienteUsoDatos, ')
          ..write('segundoConsentimiento: $segundoConsentimiento, ')
          ..write('marcadaParaEliminacion: $marcadaParaEliminacion, ')
          ..write('objetivo: $objetivo, ')
          ..write('observaciones: $observaciones, ')
          ..write('resumen: $resumen, ')
          ..write('temasPendientes: $temasPendientes, ')
          ..write('notasPruebaCampo: $notasPruebaCampo, ')
          ..write('completitudPct: $completitudPct, ')
          ..write('sincronizada: $sincronizada, ')
          ..write('sincronizadaEn: $sincronizadaEn, ')
          ..write('soloLectura: $soloLectura, ')
          ..write('descargadaEn: $descargadaEn, ')
          ..write('detalleEn: $detalleEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    inicio,
    fin,
    visitadorLocalId,
    productorLocalId,
    fincaLocalId,
    veredaLocalId,
    tipoVisita,
    latitud,
    longitud,
    precisionGps,
    estado,
    consienteAudio,
    consienteFotos,
    consienteUsoDatos,
    segundoConsentimiento,
    marcadaParaEliminacion,
    objetivo,
    observaciones,
    resumen,
    temasPendientes,
    notasPruebaCampo,
    completitudPct,
    sincronizada,
    sincronizadaEn,
    soloLectura,
    descargadaEn,
    detalleEn,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Visita &&
          other.id == this.id &&
          other.inicio == this.inicio &&
          other.fin == this.fin &&
          other.visitadorLocalId == this.visitadorLocalId &&
          other.productorLocalId == this.productorLocalId &&
          other.fincaLocalId == this.fincaLocalId &&
          other.veredaLocalId == this.veredaLocalId &&
          other.tipoVisita == this.tipoVisita &&
          other.latitud == this.latitud &&
          other.longitud == this.longitud &&
          other.precisionGps == this.precisionGps &&
          other.estado == this.estado &&
          other.consienteAudio == this.consienteAudio &&
          other.consienteFotos == this.consienteFotos &&
          other.consienteUsoDatos == this.consienteUsoDatos &&
          other.segundoConsentimiento == this.segundoConsentimiento &&
          other.marcadaParaEliminacion == this.marcadaParaEliminacion &&
          other.objetivo == this.objetivo &&
          other.observaciones == this.observaciones &&
          other.resumen == this.resumen &&
          other.temasPendientes == this.temasPendientes &&
          other.notasPruebaCampo == this.notasPruebaCampo &&
          other.completitudPct == this.completitudPct &&
          other.sincronizada == this.sincronizada &&
          other.sincronizadaEn == this.sincronizadaEn &&
          other.soloLectura == this.soloLectura &&
          other.descargadaEn == this.descargadaEn &&
          other.detalleEn == this.detalleEn);
}

class VisitasCompanion extends UpdateCompanion<Visita> {
  final Value<String> id;
  final Value<DateTime> inicio;
  final Value<DateTime?> fin;
  final Value<String?> visitadorLocalId;
  final Value<String?> productorLocalId;
  final Value<String?> fincaLocalId;
  final Value<String?> veredaLocalId;
  final Value<String?> tipoVisita;
  final Value<double?> latitud;
  final Value<double?> longitud;
  final Value<double?> precisionGps;
  final Value<String> estado;
  final Value<bool> consienteAudio;
  final Value<bool> consienteFotos;
  final Value<bool> consienteUsoDatos;
  final Value<int?> segundoConsentimiento;
  final Value<bool> marcadaParaEliminacion;
  final Value<String?> objetivo;
  final Value<String?> observaciones;
  final Value<String?> resumen;
  final Value<String?> temasPendientes;
  final Value<String?> notasPruebaCampo;
  final Value<int> completitudPct;
  final Value<bool> sincronizada;
  final Value<DateTime?> sincronizadaEn;
  final Value<bool> soloLectura;
  final Value<DateTime?> descargadaEn;
  final Value<DateTime?> detalleEn;
  final Value<int> rowid;
  const VisitasCompanion({
    this.id = const Value.absent(),
    this.inicio = const Value.absent(),
    this.fin = const Value.absent(),
    this.visitadorLocalId = const Value.absent(),
    this.productorLocalId = const Value.absent(),
    this.fincaLocalId = const Value.absent(),
    this.veredaLocalId = const Value.absent(),
    this.tipoVisita = const Value.absent(),
    this.latitud = const Value.absent(),
    this.longitud = const Value.absent(),
    this.precisionGps = const Value.absent(),
    this.estado = const Value.absent(),
    this.consienteAudio = const Value.absent(),
    this.consienteFotos = const Value.absent(),
    this.consienteUsoDatos = const Value.absent(),
    this.segundoConsentimiento = const Value.absent(),
    this.marcadaParaEliminacion = const Value.absent(),
    this.objetivo = const Value.absent(),
    this.observaciones = const Value.absent(),
    this.resumen = const Value.absent(),
    this.temasPendientes = const Value.absent(),
    this.notasPruebaCampo = const Value.absent(),
    this.completitudPct = const Value.absent(),
    this.sincronizada = const Value.absent(),
    this.sincronizadaEn = const Value.absent(),
    this.soloLectura = const Value.absent(),
    this.descargadaEn = const Value.absent(),
    this.detalleEn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VisitasCompanion.insert({
    required String id,
    required DateTime inicio,
    this.fin = const Value.absent(),
    this.visitadorLocalId = const Value.absent(),
    this.productorLocalId = const Value.absent(),
    this.fincaLocalId = const Value.absent(),
    this.veredaLocalId = const Value.absent(),
    this.tipoVisita = const Value.absent(),
    this.latitud = const Value.absent(),
    this.longitud = const Value.absent(),
    this.precisionGps = const Value.absent(),
    this.estado = const Value.absent(),
    this.consienteAudio = const Value.absent(),
    this.consienteFotos = const Value.absent(),
    this.consienteUsoDatos = const Value.absent(),
    this.segundoConsentimiento = const Value.absent(),
    this.marcadaParaEliminacion = const Value.absent(),
    this.objetivo = const Value.absent(),
    this.observaciones = const Value.absent(),
    this.resumen = const Value.absent(),
    this.temasPendientes = const Value.absent(),
    this.notasPruebaCampo = const Value.absent(),
    this.completitudPct = const Value.absent(),
    this.sincronizada = const Value.absent(),
    this.sincronizadaEn = const Value.absent(),
    this.soloLectura = const Value.absent(),
    this.descargadaEn = const Value.absent(),
    this.detalleEn = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       inicio = Value(inicio);
  static Insertable<Visita> custom({
    Expression<String>? id,
    Expression<DateTime>? inicio,
    Expression<DateTime>? fin,
    Expression<String>? visitadorLocalId,
    Expression<String>? productorLocalId,
    Expression<String>? fincaLocalId,
    Expression<String>? veredaLocalId,
    Expression<String>? tipoVisita,
    Expression<double>? latitud,
    Expression<double>? longitud,
    Expression<double>? precisionGps,
    Expression<String>? estado,
    Expression<bool>? consienteAudio,
    Expression<bool>? consienteFotos,
    Expression<bool>? consienteUsoDatos,
    Expression<int>? segundoConsentimiento,
    Expression<bool>? marcadaParaEliminacion,
    Expression<String>? objetivo,
    Expression<String>? observaciones,
    Expression<String>? resumen,
    Expression<String>? temasPendientes,
    Expression<String>? notasPruebaCampo,
    Expression<int>? completitudPct,
    Expression<bool>? sincronizada,
    Expression<DateTime>? sincronizadaEn,
    Expression<bool>? soloLectura,
    Expression<DateTime>? descargadaEn,
    Expression<DateTime>? detalleEn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (inicio != null) 'inicio': inicio,
      if (fin != null) 'fin': fin,
      if (visitadorLocalId != null) 'visitador_local_id': visitadorLocalId,
      if (productorLocalId != null) 'productor_local_id': productorLocalId,
      if (fincaLocalId != null) 'finca_local_id': fincaLocalId,
      if (veredaLocalId != null) 'vereda_local_id': veredaLocalId,
      if (tipoVisita != null) 'tipo_visita': tipoVisita,
      if (latitud != null) 'latitud': latitud,
      if (longitud != null) 'longitud': longitud,
      if (precisionGps != null) 'precision_gps': precisionGps,
      if (estado != null) 'estado': estado,
      if (consienteAudio != null) 'consiente_audio': consienteAudio,
      if (consienteFotos != null) 'consiente_fotos': consienteFotos,
      if (consienteUsoDatos != null) 'consiente_uso_datos': consienteUsoDatos,
      if (segundoConsentimiento != null)
        'segundo_consentimiento': segundoConsentimiento,
      if (marcadaParaEliminacion != null)
        'marcada_para_eliminacion': marcadaParaEliminacion,
      if (objetivo != null) 'objetivo': objetivo,
      if (observaciones != null) 'observaciones': observaciones,
      if (resumen != null) 'resumen': resumen,
      if (temasPendientes != null) 'temas_pendientes': temasPendientes,
      if (notasPruebaCampo != null) 'notas_prueba_campo': notasPruebaCampo,
      if (completitudPct != null) 'completitud_pct': completitudPct,
      if (sincronizada != null) 'sincronizada': sincronizada,
      if (sincronizadaEn != null) 'sincronizada_en': sincronizadaEn,
      if (soloLectura != null) 'solo_lectura': soloLectura,
      if (descargadaEn != null) 'descargada_en': descargadaEn,
      if (detalleEn != null) 'detalle_en': detalleEn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VisitasCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? inicio,
    Value<DateTime?>? fin,
    Value<String?>? visitadorLocalId,
    Value<String?>? productorLocalId,
    Value<String?>? fincaLocalId,
    Value<String?>? veredaLocalId,
    Value<String?>? tipoVisita,
    Value<double?>? latitud,
    Value<double?>? longitud,
    Value<double?>? precisionGps,
    Value<String>? estado,
    Value<bool>? consienteAudio,
    Value<bool>? consienteFotos,
    Value<bool>? consienteUsoDatos,
    Value<int?>? segundoConsentimiento,
    Value<bool>? marcadaParaEliminacion,
    Value<String?>? objetivo,
    Value<String?>? observaciones,
    Value<String?>? resumen,
    Value<String?>? temasPendientes,
    Value<String?>? notasPruebaCampo,
    Value<int>? completitudPct,
    Value<bool>? sincronizada,
    Value<DateTime?>? sincronizadaEn,
    Value<bool>? soloLectura,
    Value<DateTime?>? descargadaEn,
    Value<DateTime?>? detalleEn,
    Value<int>? rowid,
  }) {
    return VisitasCompanion(
      id: id ?? this.id,
      inicio: inicio ?? this.inicio,
      fin: fin ?? this.fin,
      visitadorLocalId: visitadorLocalId ?? this.visitadorLocalId,
      productorLocalId: productorLocalId ?? this.productorLocalId,
      fincaLocalId: fincaLocalId ?? this.fincaLocalId,
      veredaLocalId: veredaLocalId ?? this.veredaLocalId,
      tipoVisita: tipoVisita ?? this.tipoVisita,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      precisionGps: precisionGps ?? this.precisionGps,
      estado: estado ?? this.estado,
      consienteAudio: consienteAudio ?? this.consienteAudio,
      consienteFotos: consienteFotos ?? this.consienteFotos,
      consienteUsoDatos: consienteUsoDatos ?? this.consienteUsoDatos,
      segundoConsentimiento:
          segundoConsentimiento ?? this.segundoConsentimiento,
      marcadaParaEliminacion:
          marcadaParaEliminacion ?? this.marcadaParaEliminacion,
      objetivo: objetivo ?? this.objetivo,
      observaciones: observaciones ?? this.observaciones,
      resumen: resumen ?? this.resumen,
      temasPendientes: temasPendientes ?? this.temasPendientes,
      notasPruebaCampo: notasPruebaCampo ?? this.notasPruebaCampo,
      completitudPct: completitudPct ?? this.completitudPct,
      sincronizada: sincronizada ?? this.sincronizada,
      sincronizadaEn: sincronizadaEn ?? this.sincronizadaEn,
      soloLectura: soloLectura ?? this.soloLectura,
      descargadaEn: descargadaEn ?? this.descargadaEn,
      detalleEn: detalleEn ?? this.detalleEn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (inicio.present) {
      map['inicio'] = Variable<DateTime>(inicio.value);
    }
    if (fin.present) {
      map['fin'] = Variable<DateTime>(fin.value);
    }
    if (visitadorLocalId.present) {
      map['visitador_local_id'] = Variable<String>(visitadorLocalId.value);
    }
    if (productorLocalId.present) {
      map['productor_local_id'] = Variable<String>(productorLocalId.value);
    }
    if (fincaLocalId.present) {
      map['finca_local_id'] = Variable<String>(fincaLocalId.value);
    }
    if (veredaLocalId.present) {
      map['vereda_local_id'] = Variable<String>(veredaLocalId.value);
    }
    if (tipoVisita.present) {
      map['tipo_visita'] = Variable<String>(tipoVisita.value);
    }
    if (latitud.present) {
      map['latitud'] = Variable<double>(latitud.value);
    }
    if (longitud.present) {
      map['longitud'] = Variable<double>(longitud.value);
    }
    if (precisionGps.present) {
      map['precision_gps'] = Variable<double>(precisionGps.value);
    }
    if (estado.present) {
      map['estado'] = Variable<String>(estado.value);
    }
    if (consienteAudio.present) {
      map['consiente_audio'] = Variable<bool>(consienteAudio.value);
    }
    if (consienteFotos.present) {
      map['consiente_fotos'] = Variable<bool>(consienteFotos.value);
    }
    if (consienteUsoDatos.present) {
      map['consiente_uso_datos'] = Variable<bool>(consienteUsoDatos.value);
    }
    if (segundoConsentimiento.present) {
      map['segundo_consentimiento'] = Variable<int>(
        segundoConsentimiento.value,
      );
    }
    if (marcadaParaEliminacion.present) {
      map['marcada_para_eliminacion'] = Variable<bool>(
        marcadaParaEliminacion.value,
      );
    }
    if (objetivo.present) {
      map['objetivo'] = Variable<String>(objetivo.value);
    }
    if (observaciones.present) {
      map['observaciones'] = Variable<String>(observaciones.value);
    }
    if (resumen.present) {
      map['resumen'] = Variable<String>(resumen.value);
    }
    if (temasPendientes.present) {
      map['temas_pendientes'] = Variable<String>(temasPendientes.value);
    }
    if (notasPruebaCampo.present) {
      map['notas_prueba_campo'] = Variable<String>(notasPruebaCampo.value);
    }
    if (completitudPct.present) {
      map['completitud_pct'] = Variable<int>(completitudPct.value);
    }
    if (sincronizada.present) {
      map['sincronizada'] = Variable<bool>(sincronizada.value);
    }
    if (sincronizadaEn.present) {
      map['sincronizada_en'] = Variable<DateTime>(sincronizadaEn.value);
    }
    if (soloLectura.present) {
      map['solo_lectura'] = Variable<bool>(soloLectura.value);
    }
    if (descargadaEn.present) {
      map['descargada_en'] = Variable<DateTime>(descargadaEn.value);
    }
    if (detalleEn.present) {
      map['detalle_en'] = Variable<DateTime>(detalleEn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VisitasCompanion(')
          ..write('id: $id, ')
          ..write('inicio: $inicio, ')
          ..write('fin: $fin, ')
          ..write('visitadorLocalId: $visitadorLocalId, ')
          ..write('productorLocalId: $productorLocalId, ')
          ..write('fincaLocalId: $fincaLocalId, ')
          ..write('veredaLocalId: $veredaLocalId, ')
          ..write('tipoVisita: $tipoVisita, ')
          ..write('latitud: $latitud, ')
          ..write('longitud: $longitud, ')
          ..write('precisionGps: $precisionGps, ')
          ..write('estado: $estado, ')
          ..write('consienteAudio: $consienteAudio, ')
          ..write('consienteFotos: $consienteFotos, ')
          ..write('consienteUsoDatos: $consienteUsoDatos, ')
          ..write('segundoConsentimiento: $segundoConsentimiento, ')
          ..write('marcadaParaEliminacion: $marcadaParaEliminacion, ')
          ..write('objetivo: $objetivo, ')
          ..write('observaciones: $observaciones, ')
          ..write('resumen: $resumen, ')
          ..write('temasPendientes: $temasPendientes, ')
          ..write('notasPruebaCampo: $notasPruebaCampo, ')
          ..write('completitudPct: $completitudPct, ')
          ..write('sincronizada: $sincronizada, ')
          ..write('sincronizadaEn: $sincronizadaEn, ')
          ..write('soloLectura: $soloLectura, ')
          ..write('descargadaEn: $descargadaEn, ')
          ..write('detalleEn: $detalleEn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GrabacionesTable extends Grabaciones
    with TableInfo<$GrabacionesTable, Grabacion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GrabacionesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _visitaIdMeta = const VerificationMeta(
    'visitaId',
  );
  @override
  late final GeneratedColumn<String> visitaId = GeneratedColumn<String>(
    'visita_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ordenMeta = const VerificationMeta('orden');
  @override
  late final GeneratedColumn<int> orden = GeneratedColumn<int>(
    'orden',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivoPathMeta = const VerificationMeta(
    'archivoPath',
  );
  @override
  late final GeneratedColumn<String> archivoPath = GeneratedColumn<String>(
    'archivo_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inicioMeta = const VerificationMeta('inicio');
  @override
  late final GeneratedColumn<DateTime> inicio = GeneratedColumn<DateTime>(
    'inicio',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _duracionSegMeta = const VerificationMeta(
    'duracionSeg',
  );
  @override
  late final GeneratedColumn<int> duracionSeg = GeneratedColumn<int>(
    'duracion_seg',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _tamanoBytesMeta = const VerificationMeta(
    'tamanoBytes',
  );
  @override
  late final GeneratedColumn<int> tamanoBytes = GeneratedColumn<int>(
    'tamano_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _enlaceAudioMeta = const VerificationMeta(
    'enlaceAudio',
  );
  @override
  late final GeneratedColumn<String> enlaceAudio = GeneratedColumn<String>(
    'enlace_audio',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transcripcionMeta = const VerificationMeta(
    'transcripcion',
  );
  @override
  late final GeneratedColumn<String> transcripcion = GeneratedColumn<String>(
    'transcripcion',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transcripcionMarcasMeta =
      const VerificationMeta('transcripcionMarcas');
  @override
  late final GeneratedColumn<String> transcripcionMarcas =
      GeneratedColumn<String>(
        'transcripcion_marcas',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _motorTranscripcionMeta =
      const VerificationMeta('motorTranscripcion');
  @override
  late final GeneratedColumn<String> motorTranscripcion =
      GeneratedColumn<String>(
        'motor_transcripcion',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _estadoMeta = const VerificationMeta('estado');
  @override
  late final GeneratedColumn<String> estado = GeneratedColumn<String>(
    'estado',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Grabada'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    visitaId,
    orden,
    archivoPath,
    inicio,
    duracionSeg,
    tamanoBytes,
    enlaceAudio,
    transcripcion,
    transcripcionMarcas,
    motorTranscripcion,
    estado,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'grabaciones';
  @override
  VerificationContext validateIntegrity(
    Insertable<Grabacion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('visita_id')) {
      context.handle(
        _visitaIdMeta,
        visitaId.isAcceptableOrUnknown(data['visita_id']!, _visitaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_visitaIdMeta);
    }
    if (data.containsKey('orden')) {
      context.handle(
        _ordenMeta,
        orden.isAcceptableOrUnknown(data['orden']!, _ordenMeta),
      );
    } else if (isInserting) {
      context.missing(_ordenMeta);
    }
    if (data.containsKey('archivo_path')) {
      context.handle(
        _archivoPathMeta,
        archivoPath.isAcceptableOrUnknown(
          data['archivo_path']!,
          _archivoPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_archivoPathMeta);
    }
    if (data.containsKey('inicio')) {
      context.handle(
        _inicioMeta,
        inicio.isAcceptableOrUnknown(data['inicio']!, _inicioMeta),
      );
    } else if (isInserting) {
      context.missing(_inicioMeta);
    }
    if (data.containsKey('duracion_seg')) {
      context.handle(
        _duracionSegMeta,
        duracionSeg.isAcceptableOrUnknown(
          data['duracion_seg']!,
          _duracionSegMeta,
        ),
      );
    }
    if (data.containsKey('tamano_bytes')) {
      context.handle(
        _tamanoBytesMeta,
        tamanoBytes.isAcceptableOrUnknown(
          data['tamano_bytes']!,
          _tamanoBytesMeta,
        ),
      );
    }
    if (data.containsKey('enlace_audio')) {
      context.handle(
        _enlaceAudioMeta,
        enlaceAudio.isAcceptableOrUnknown(
          data['enlace_audio']!,
          _enlaceAudioMeta,
        ),
      );
    }
    if (data.containsKey('transcripcion')) {
      context.handle(
        _transcripcionMeta,
        transcripcion.isAcceptableOrUnknown(
          data['transcripcion']!,
          _transcripcionMeta,
        ),
      );
    }
    if (data.containsKey('transcripcion_marcas')) {
      context.handle(
        _transcripcionMarcasMeta,
        transcripcionMarcas.isAcceptableOrUnknown(
          data['transcripcion_marcas']!,
          _transcripcionMarcasMeta,
        ),
      );
    }
    if (data.containsKey('motor_transcripcion')) {
      context.handle(
        _motorTranscripcionMeta,
        motorTranscripcion.isAcceptableOrUnknown(
          data['motor_transcripcion']!,
          _motorTranscripcionMeta,
        ),
      );
    }
    if (data.containsKey('estado')) {
      context.handle(
        _estadoMeta,
        estado.isAcceptableOrUnknown(data['estado']!, _estadoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Grabacion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Grabacion(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      visitaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visita_id'],
      )!,
      orden: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}orden'],
      )!,
      archivoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}archivo_path'],
      )!,
      inicio: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}inicio'],
      )!,
      duracionSeg: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duracion_seg'],
      )!,
      tamanoBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tamano_bytes'],
      )!,
      enlaceAudio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}enlace_audio'],
      ),
      transcripcion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transcripcion'],
      ),
      transcripcionMarcas: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transcripcion_marcas'],
      ),
      motorTranscripcion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}motor_transcripcion'],
      ),
      estado: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}estado'],
      )!,
    );
  }

  @override
  $GrabacionesTable createAlias(String alias) {
    return $GrabacionesTable(attachedDatabase, alias);
  }
}

class Grabacion extends DataClass implements Insertable<Grabacion> {
  final String id;
  final String visitaId;

  /// Secuencia dentro de la visita. Una visita tiene varias grabaciones:
  /// pausas, llamadas entrantes, y el boton "Seguir grabando" del Dia 11.
  final int orden;

  /// Ruta en disco. El audio se escribe POR TRAMOS mientras se graba, no al
  /// final: si la app muere a los 28 minutos, se conservan los 28 minutos.
  final String archivoPath;
  final DateTime inicio;
  final int duracionSeg;
  final int tamanoBytes;

  /// URL en el bucket. Fuente de verdad del audio; el adjunto de Airtable no.
  final String? enlaceAudio;
  final String? transcripcion;

  /// Segmentos con segundo de inicio y hablante. Sin esto no hay citas, y sin
  /// citas no hay procedencia.
  final String? transcripcionMarcas;
  final String? motorTranscripcion;
  final String estado;
  const Grabacion({
    required this.id,
    required this.visitaId,
    required this.orden,
    required this.archivoPath,
    required this.inicio,
    required this.duracionSeg,
    required this.tamanoBytes,
    this.enlaceAudio,
    this.transcripcion,
    this.transcripcionMarcas,
    this.motorTranscripcion,
    required this.estado,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['visita_id'] = Variable<String>(visitaId);
    map['orden'] = Variable<int>(orden);
    map['archivo_path'] = Variable<String>(archivoPath);
    map['inicio'] = Variable<DateTime>(inicio);
    map['duracion_seg'] = Variable<int>(duracionSeg);
    map['tamano_bytes'] = Variable<int>(tamanoBytes);
    if (!nullToAbsent || enlaceAudio != null) {
      map['enlace_audio'] = Variable<String>(enlaceAudio);
    }
    if (!nullToAbsent || transcripcion != null) {
      map['transcripcion'] = Variable<String>(transcripcion);
    }
    if (!nullToAbsent || transcripcionMarcas != null) {
      map['transcripcion_marcas'] = Variable<String>(transcripcionMarcas);
    }
    if (!nullToAbsent || motorTranscripcion != null) {
      map['motor_transcripcion'] = Variable<String>(motorTranscripcion);
    }
    map['estado'] = Variable<String>(estado);
    return map;
  }

  GrabacionesCompanion toCompanion(bool nullToAbsent) {
    return GrabacionesCompanion(
      id: Value(id),
      visitaId: Value(visitaId),
      orden: Value(orden),
      archivoPath: Value(archivoPath),
      inicio: Value(inicio),
      duracionSeg: Value(duracionSeg),
      tamanoBytes: Value(tamanoBytes),
      enlaceAudio: enlaceAudio == null && nullToAbsent
          ? const Value.absent()
          : Value(enlaceAudio),
      transcripcion: transcripcion == null && nullToAbsent
          ? const Value.absent()
          : Value(transcripcion),
      transcripcionMarcas: transcripcionMarcas == null && nullToAbsent
          ? const Value.absent()
          : Value(transcripcionMarcas),
      motorTranscripcion: motorTranscripcion == null && nullToAbsent
          ? const Value.absent()
          : Value(motorTranscripcion),
      estado: Value(estado),
    );
  }

  factory Grabacion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Grabacion(
      id: serializer.fromJson<String>(json['id']),
      visitaId: serializer.fromJson<String>(json['visitaId']),
      orden: serializer.fromJson<int>(json['orden']),
      archivoPath: serializer.fromJson<String>(json['archivoPath']),
      inicio: serializer.fromJson<DateTime>(json['inicio']),
      duracionSeg: serializer.fromJson<int>(json['duracionSeg']),
      tamanoBytes: serializer.fromJson<int>(json['tamanoBytes']),
      enlaceAudio: serializer.fromJson<String?>(json['enlaceAudio']),
      transcripcion: serializer.fromJson<String?>(json['transcripcion']),
      transcripcionMarcas: serializer.fromJson<String?>(
        json['transcripcionMarcas'],
      ),
      motorTranscripcion: serializer.fromJson<String?>(
        json['motorTranscripcion'],
      ),
      estado: serializer.fromJson<String>(json['estado']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'visitaId': serializer.toJson<String>(visitaId),
      'orden': serializer.toJson<int>(orden),
      'archivoPath': serializer.toJson<String>(archivoPath),
      'inicio': serializer.toJson<DateTime>(inicio),
      'duracionSeg': serializer.toJson<int>(duracionSeg),
      'tamanoBytes': serializer.toJson<int>(tamanoBytes),
      'enlaceAudio': serializer.toJson<String?>(enlaceAudio),
      'transcripcion': serializer.toJson<String?>(transcripcion),
      'transcripcionMarcas': serializer.toJson<String?>(transcripcionMarcas),
      'motorTranscripcion': serializer.toJson<String?>(motorTranscripcion),
      'estado': serializer.toJson<String>(estado),
    };
  }

  Grabacion copyWith({
    String? id,
    String? visitaId,
    int? orden,
    String? archivoPath,
    DateTime? inicio,
    int? duracionSeg,
    int? tamanoBytes,
    Value<String?> enlaceAudio = const Value.absent(),
    Value<String?> transcripcion = const Value.absent(),
    Value<String?> transcripcionMarcas = const Value.absent(),
    Value<String?> motorTranscripcion = const Value.absent(),
    String? estado,
  }) => Grabacion(
    id: id ?? this.id,
    visitaId: visitaId ?? this.visitaId,
    orden: orden ?? this.orden,
    archivoPath: archivoPath ?? this.archivoPath,
    inicio: inicio ?? this.inicio,
    duracionSeg: duracionSeg ?? this.duracionSeg,
    tamanoBytes: tamanoBytes ?? this.tamanoBytes,
    enlaceAudio: enlaceAudio.present ? enlaceAudio.value : this.enlaceAudio,
    transcripcion: transcripcion.present
        ? transcripcion.value
        : this.transcripcion,
    transcripcionMarcas: transcripcionMarcas.present
        ? transcripcionMarcas.value
        : this.transcripcionMarcas,
    motorTranscripcion: motorTranscripcion.present
        ? motorTranscripcion.value
        : this.motorTranscripcion,
    estado: estado ?? this.estado,
  );
  Grabacion copyWithCompanion(GrabacionesCompanion data) {
    return Grabacion(
      id: data.id.present ? data.id.value : this.id,
      visitaId: data.visitaId.present ? data.visitaId.value : this.visitaId,
      orden: data.orden.present ? data.orden.value : this.orden,
      archivoPath: data.archivoPath.present
          ? data.archivoPath.value
          : this.archivoPath,
      inicio: data.inicio.present ? data.inicio.value : this.inicio,
      duracionSeg: data.duracionSeg.present
          ? data.duracionSeg.value
          : this.duracionSeg,
      tamanoBytes: data.tamanoBytes.present
          ? data.tamanoBytes.value
          : this.tamanoBytes,
      enlaceAudio: data.enlaceAudio.present
          ? data.enlaceAudio.value
          : this.enlaceAudio,
      transcripcion: data.transcripcion.present
          ? data.transcripcion.value
          : this.transcripcion,
      transcripcionMarcas: data.transcripcionMarcas.present
          ? data.transcripcionMarcas.value
          : this.transcripcionMarcas,
      motorTranscripcion: data.motorTranscripcion.present
          ? data.motorTranscripcion.value
          : this.motorTranscripcion,
      estado: data.estado.present ? data.estado.value : this.estado,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Grabacion(')
          ..write('id: $id, ')
          ..write('visitaId: $visitaId, ')
          ..write('orden: $orden, ')
          ..write('archivoPath: $archivoPath, ')
          ..write('inicio: $inicio, ')
          ..write('duracionSeg: $duracionSeg, ')
          ..write('tamanoBytes: $tamanoBytes, ')
          ..write('enlaceAudio: $enlaceAudio, ')
          ..write('transcripcion: $transcripcion, ')
          ..write('transcripcionMarcas: $transcripcionMarcas, ')
          ..write('motorTranscripcion: $motorTranscripcion, ')
          ..write('estado: $estado')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    visitaId,
    orden,
    archivoPath,
    inicio,
    duracionSeg,
    tamanoBytes,
    enlaceAudio,
    transcripcion,
    transcripcionMarcas,
    motorTranscripcion,
    estado,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Grabacion &&
          other.id == this.id &&
          other.visitaId == this.visitaId &&
          other.orden == this.orden &&
          other.archivoPath == this.archivoPath &&
          other.inicio == this.inicio &&
          other.duracionSeg == this.duracionSeg &&
          other.tamanoBytes == this.tamanoBytes &&
          other.enlaceAudio == this.enlaceAudio &&
          other.transcripcion == this.transcripcion &&
          other.transcripcionMarcas == this.transcripcionMarcas &&
          other.motorTranscripcion == this.motorTranscripcion &&
          other.estado == this.estado);
}

class GrabacionesCompanion extends UpdateCompanion<Grabacion> {
  final Value<String> id;
  final Value<String> visitaId;
  final Value<int> orden;
  final Value<String> archivoPath;
  final Value<DateTime> inicio;
  final Value<int> duracionSeg;
  final Value<int> tamanoBytes;
  final Value<String?> enlaceAudio;
  final Value<String?> transcripcion;
  final Value<String?> transcripcionMarcas;
  final Value<String?> motorTranscripcion;
  final Value<String> estado;
  final Value<int> rowid;
  const GrabacionesCompanion({
    this.id = const Value.absent(),
    this.visitaId = const Value.absent(),
    this.orden = const Value.absent(),
    this.archivoPath = const Value.absent(),
    this.inicio = const Value.absent(),
    this.duracionSeg = const Value.absent(),
    this.tamanoBytes = const Value.absent(),
    this.enlaceAudio = const Value.absent(),
    this.transcripcion = const Value.absent(),
    this.transcripcionMarcas = const Value.absent(),
    this.motorTranscripcion = const Value.absent(),
    this.estado = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GrabacionesCompanion.insert({
    required String id,
    required String visitaId,
    required int orden,
    required String archivoPath,
    required DateTime inicio,
    this.duracionSeg = const Value.absent(),
    this.tamanoBytes = const Value.absent(),
    this.enlaceAudio = const Value.absent(),
    this.transcripcion = const Value.absent(),
    this.transcripcionMarcas = const Value.absent(),
    this.motorTranscripcion = const Value.absent(),
    this.estado = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       visitaId = Value(visitaId),
       orden = Value(orden),
       archivoPath = Value(archivoPath),
       inicio = Value(inicio);
  static Insertable<Grabacion> custom({
    Expression<String>? id,
    Expression<String>? visitaId,
    Expression<int>? orden,
    Expression<String>? archivoPath,
    Expression<DateTime>? inicio,
    Expression<int>? duracionSeg,
    Expression<int>? tamanoBytes,
    Expression<String>? enlaceAudio,
    Expression<String>? transcripcion,
    Expression<String>? transcripcionMarcas,
    Expression<String>? motorTranscripcion,
    Expression<String>? estado,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (visitaId != null) 'visita_id': visitaId,
      if (orden != null) 'orden': orden,
      if (archivoPath != null) 'archivo_path': archivoPath,
      if (inicio != null) 'inicio': inicio,
      if (duracionSeg != null) 'duracion_seg': duracionSeg,
      if (tamanoBytes != null) 'tamano_bytes': tamanoBytes,
      if (enlaceAudio != null) 'enlace_audio': enlaceAudio,
      if (transcripcion != null) 'transcripcion': transcripcion,
      if (transcripcionMarcas != null)
        'transcripcion_marcas': transcripcionMarcas,
      if (motorTranscripcion != null) 'motor_transcripcion': motorTranscripcion,
      if (estado != null) 'estado': estado,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GrabacionesCompanion copyWith({
    Value<String>? id,
    Value<String>? visitaId,
    Value<int>? orden,
    Value<String>? archivoPath,
    Value<DateTime>? inicio,
    Value<int>? duracionSeg,
    Value<int>? tamanoBytes,
    Value<String?>? enlaceAudio,
    Value<String?>? transcripcion,
    Value<String?>? transcripcionMarcas,
    Value<String?>? motorTranscripcion,
    Value<String>? estado,
    Value<int>? rowid,
  }) {
    return GrabacionesCompanion(
      id: id ?? this.id,
      visitaId: visitaId ?? this.visitaId,
      orden: orden ?? this.orden,
      archivoPath: archivoPath ?? this.archivoPath,
      inicio: inicio ?? this.inicio,
      duracionSeg: duracionSeg ?? this.duracionSeg,
      tamanoBytes: tamanoBytes ?? this.tamanoBytes,
      enlaceAudio: enlaceAudio ?? this.enlaceAudio,
      transcripcion: transcripcion ?? this.transcripcion,
      transcripcionMarcas: transcripcionMarcas ?? this.transcripcionMarcas,
      motorTranscripcion: motorTranscripcion ?? this.motorTranscripcion,
      estado: estado ?? this.estado,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (visitaId.present) {
      map['visita_id'] = Variable<String>(visitaId.value);
    }
    if (orden.present) {
      map['orden'] = Variable<int>(orden.value);
    }
    if (archivoPath.present) {
      map['archivo_path'] = Variable<String>(archivoPath.value);
    }
    if (inicio.present) {
      map['inicio'] = Variable<DateTime>(inicio.value);
    }
    if (duracionSeg.present) {
      map['duracion_seg'] = Variable<int>(duracionSeg.value);
    }
    if (tamanoBytes.present) {
      map['tamano_bytes'] = Variable<int>(tamanoBytes.value);
    }
    if (enlaceAudio.present) {
      map['enlace_audio'] = Variable<String>(enlaceAudio.value);
    }
    if (transcripcion.present) {
      map['transcripcion'] = Variable<String>(transcripcion.value);
    }
    if (transcripcionMarcas.present) {
      map['transcripcion_marcas'] = Variable<String>(transcripcionMarcas.value);
    }
    if (motorTranscripcion.present) {
      map['motor_transcripcion'] = Variable<String>(motorTranscripcion.value);
    }
    if (estado.present) {
      map['estado'] = Variable<String>(estado.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GrabacionesCompanion(')
          ..write('id: $id, ')
          ..write('visitaId: $visitaId, ')
          ..write('orden: $orden, ')
          ..write('archivoPath: $archivoPath, ')
          ..write('inicio: $inicio, ')
          ..write('duracionSeg: $duracionSeg, ')
          ..write('tamanoBytes: $tamanoBytes, ')
          ..write('enlaceAudio: $enlaceAudio, ')
          ..write('transcripcion: $transcripcion, ')
          ..write('transcripcionMarcas: $transcripcionMarcas, ')
          ..write('motorTranscripcion: $motorTranscripcion, ')
          ..write('estado: $estado, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EvidenciasTable extends Evidencias
    with TableInfo<$EvidenciasTable, Evidencia> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EvidenciasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _visitaIdMeta = const VerificationMeta(
    'visitaId',
  );
  @override
  late final GeneratedColumn<String> visitaId = GeneratedColumn<String>(
    'visita_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivoPathMeta = const VerificationMeta(
    'archivoPath',
  );
  @override
  late final GeneratedColumn<String> archivoPath = GeneratedColumn<String>(
    'archivo_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tomadaEnMeta = const VerificationMeta(
    'tomadaEn',
  );
  @override
  late final GeneratedColumn<DateTime> tomadaEn = GeneratedColumn<DateTime>(
    'tomada_en',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudMeta = const VerificationMeta(
    'latitud',
  );
  @override
  late final GeneratedColumn<double> latitud = GeneratedColumn<double>(
    'latitud',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudMeta = const VerificationMeta(
    'longitud',
  );
  @override
  late final GeneratedColumn<double> longitud = GeneratedColumn<double>(
    'longitud',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _segundoAudioMeta = const VerificationMeta(
    'segundoAudio',
  );
  @override
  late final GeneratedColumn<int> segundoAudio = GeneratedColumn<int>(
    'segundo_audio',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descripcionVisitadorMeta =
      const VerificationMeta('descripcionVisitador');
  @override
  late final GeneratedColumn<String> descripcionVisitador =
      GeneratedColumn<String>(
        'descripcion_visitador',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _descripcionIaMeta = const VerificationMeta(
    'descripcionIa',
  );
  @override
  late final GeneratedColumn<String> descripcionIa = GeneratedColumn<String>(
    'descripcion_ia',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _textoOcrMeta = const VerificationMeta(
    'textoOcr',
  );
  @override
  late final GeneratedColumn<String> textoOcr = GeneratedColumn<String>(
    'texto_ocr',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _enlaceArchivoMeta = const VerificationMeta(
    'enlaceArchivo',
  );
  @override
  late final GeneratedColumn<String> enlaceArchivo = GeneratedColumn<String>(
    'enlace_archivo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _estadoValidacionMeta = const VerificationMeta(
    'estadoValidacion',
  );
  @override
  late final GeneratedColumn<String> estadoValidacion = GeneratedColumn<String>(
    'estado_validacion',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Sin revisar'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    visitaId,
    tipo,
    archivoPath,
    tomadaEn,
    latitud,
    longitud,
    segundoAudio,
    descripcionVisitador,
    descripcionIa,
    textoOcr,
    enlaceArchivo,
    estadoValidacion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'evidencias';
  @override
  VerificationContext validateIntegrity(
    Insertable<Evidencia> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('visita_id')) {
      context.handle(
        _visitaIdMeta,
        visitaId.isAcceptableOrUnknown(data['visita_id']!, _visitaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_visitaIdMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    }
    if (data.containsKey('archivo_path')) {
      context.handle(
        _archivoPathMeta,
        archivoPath.isAcceptableOrUnknown(
          data['archivo_path']!,
          _archivoPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_archivoPathMeta);
    }
    if (data.containsKey('tomada_en')) {
      context.handle(
        _tomadaEnMeta,
        tomadaEn.isAcceptableOrUnknown(data['tomada_en']!, _tomadaEnMeta),
      );
    } else if (isInserting) {
      context.missing(_tomadaEnMeta);
    }
    if (data.containsKey('latitud')) {
      context.handle(
        _latitudMeta,
        latitud.isAcceptableOrUnknown(data['latitud']!, _latitudMeta),
      );
    }
    if (data.containsKey('longitud')) {
      context.handle(
        _longitudMeta,
        longitud.isAcceptableOrUnknown(data['longitud']!, _longitudMeta),
      );
    }
    if (data.containsKey('segundo_audio')) {
      context.handle(
        _segundoAudioMeta,
        segundoAudio.isAcceptableOrUnknown(
          data['segundo_audio']!,
          _segundoAudioMeta,
        ),
      );
    }
    if (data.containsKey('descripcion_visitador')) {
      context.handle(
        _descripcionVisitadorMeta,
        descripcionVisitador.isAcceptableOrUnknown(
          data['descripcion_visitador']!,
          _descripcionVisitadorMeta,
        ),
      );
    }
    if (data.containsKey('descripcion_ia')) {
      context.handle(
        _descripcionIaMeta,
        descripcionIa.isAcceptableOrUnknown(
          data['descripcion_ia']!,
          _descripcionIaMeta,
        ),
      );
    }
    if (data.containsKey('texto_ocr')) {
      context.handle(
        _textoOcrMeta,
        textoOcr.isAcceptableOrUnknown(data['texto_ocr']!, _textoOcrMeta),
      );
    }
    if (data.containsKey('enlace_archivo')) {
      context.handle(
        _enlaceArchivoMeta,
        enlaceArchivo.isAcceptableOrUnknown(
          data['enlace_archivo']!,
          _enlaceArchivoMeta,
        ),
      );
    }
    if (data.containsKey('estado_validacion')) {
      context.handle(
        _estadoValidacionMeta,
        estadoValidacion.isAcceptableOrUnknown(
          data['estado_validacion']!,
          _estadoValidacionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Evidencia map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Evidencia(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      visitaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visita_id'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      ),
      archivoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}archivo_path'],
      )!,
      tomadaEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}tomada_en'],
      )!,
      latitud: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitud'],
      ),
      longitud: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitud'],
      ),
      segundoAudio: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}segundo_audio'],
      ),
      descripcionVisitador: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}descripcion_visitador'],
      ),
      descripcionIa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}descripcion_ia'],
      ),
      textoOcr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}texto_ocr'],
      ),
      enlaceArchivo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}enlace_archivo'],
      ),
      estadoValidacion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}estado_validacion'],
      )!,
    );
  }

  @override
  $EvidenciasTable createAlias(String alias) {
    return $EvidenciasTable(attachedDatabase, alias);
  }
}

class Evidencia extends DataClass implements Insertable<Evidencia> {
  final String id;
  final String visitaId;
  final String? tipo;
  final String archivoPath;
  final DateTime tomadaEn;
  final double? latitud;
  final double? longitud;

  /// Segundo de la grabacion en curso cuando se tomo la foto. Permite volver a
  /// lo que se estaba hablando mientras se fotografiaba.
  final int? segundoAudio;
  final String? descripcionVisitador;
  final String? descripcionIa;
  final String? textoOcr;
  final String? enlaceArchivo;
  final String estadoValidacion;
  const Evidencia({
    required this.id,
    required this.visitaId,
    this.tipo,
    required this.archivoPath,
    required this.tomadaEn,
    this.latitud,
    this.longitud,
    this.segundoAudio,
    this.descripcionVisitador,
    this.descripcionIa,
    this.textoOcr,
    this.enlaceArchivo,
    required this.estadoValidacion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['visita_id'] = Variable<String>(visitaId);
    if (!nullToAbsent || tipo != null) {
      map['tipo'] = Variable<String>(tipo);
    }
    map['archivo_path'] = Variable<String>(archivoPath);
    map['tomada_en'] = Variable<DateTime>(tomadaEn);
    if (!nullToAbsent || latitud != null) {
      map['latitud'] = Variable<double>(latitud);
    }
    if (!nullToAbsent || longitud != null) {
      map['longitud'] = Variable<double>(longitud);
    }
    if (!nullToAbsent || segundoAudio != null) {
      map['segundo_audio'] = Variable<int>(segundoAudio);
    }
    if (!nullToAbsent || descripcionVisitador != null) {
      map['descripcion_visitador'] = Variable<String>(descripcionVisitador);
    }
    if (!nullToAbsent || descripcionIa != null) {
      map['descripcion_ia'] = Variable<String>(descripcionIa);
    }
    if (!nullToAbsent || textoOcr != null) {
      map['texto_ocr'] = Variable<String>(textoOcr);
    }
    if (!nullToAbsent || enlaceArchivo != null) {
      map['enlace_archivo'] = Variable<String>(enlaceArchivo);
    }
    map['estado_validacion'] = Variable<String>(estadoValidacion);
    return map;
  }

  EvidenciasCompanion toCompanion(bool nullToAbsent) {
    return EvidenciasCompanion(
      id: Value(id),
      visitaId: Value(visitaId),
      tipo: tipo == null && nullToAbsent ? const Value.absent() : Value(tipo),
      archivoPath: Value(archivoPath),
      tomadaEn: Value(tomadaEn),
      latitud: latitud == null && nullToAbsent
          ? const Value.absent()
          : Value(latitud),
      longitud: longitud == null && nullToAbsent
          ? const Value.absent()
          : Value(longitud),
      segundoAudio: segundoAudio == null && nullToAbsent
          ? const Value.absent()
          : Value(segundoAudio),
      descripcionVisitador: descripcionVisitador == null && nullToAbsent
          ? const Value.absent()
          : Value(descripcionVisitador),
      descripcionIa: descripcionIa == null && nullToAbsent
          ? const Value.absent()
          : Value(descripcionIa),
      textoOcr: textoOcr == null && nullToAbsent
          ? const Value.absent()
          : Value(textoOcr),
      enlaceArchivo: enlaceArchivo == null && nullToAbsent
          ? const Value.absent()
          : Value(enlaceArchivo),
      estadoValidacion: Value(estadoValidacion),
    );
  }

  factory Evidencia.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Evidencia(
      id: serializer.fromJson<String>(json['id']),
      visitaId: serializer.fromJson<String>(json['visitaId']),
      tipo: serializer.fromJson<String?>(json['tipo']),
      archivoPath: serializer.fromJson<String>(json['archivoPath']),
      tomadaEn: serializer.fromJson<DateTime>(json['tomadaEn']),
      latitud: serializer.fromJson<double?>(json['latitud']),
      longitud: serializer.fromJson<double?>(json['longitud']),
      segundoAudio: serializer.fromJson<int?>(json['segundoAudio']),
      descripcionVisitador: serializer.fromJson<String?>(
        json['descripcionVisitador'],
      ),
      descripcionIa: serializer.fromJson<String?>(json['descripcionIa']),
      textoOcr: serializer.fromJson<String?>(json['textoOcr']),
      enlaceArchivo: serializer.fromJson<String?>(json['enlaceArchivo']),
      estadoValidacion: serializer.fromJson<String>(json['estadoValidacion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'visitaId': serializer.toJson<String>(visitaId),
      'tipo': serializer.toJson<String?>(tipo),
      'archivoPath': serializer.toJson<String>(archivoPath),
      'tomadaEn': serializer.toJson<DateTime>(tomadaEn),
      'latitud': serializer.toJson<double?>(latitud),
      'longitud': serializer.toJson<double?>(longitud),
      'segundoAudio': serializer.toJson<int?>(segundoAudio),
      'descripcionVisitador': serializer.toJson<String?>(descripcionVisitador),
      'descripcionIa': serializer.toJson<String?>(descripcionIa),
      'textoOcr': serializer.toJson<String?>(textoOcr),
      'enlaceArchivo': serializer.toJson<String?>(enlaceArchivo),
      'estadoValidacion': serializer.toJson<String>(estadoValidacion),
    };
  }

  Evidencia copyWith({
    String? id,
    String? visitaId,
    Value<String?> tipo = const Value.absent(),
    String? archivoPath,
    DateTime? tomadaEn,
    Value<double?> latitud = const Value.absent(),
    Value<double?> longitud = const Value.absent(),
    Value<int?> segundoAudio = const Value.absent(),
    Value<String?> descripcionVisitador = const Value.absent(),
    Value<String?> descripcionIa = const Value.absent(),
    Value<String?> textoOcr = const Value.absent(),
    Value<String?> enlaceArchivo = const Value.absent(),
    String? estadoValidacion,
  }) => Evidencia(
    id: id ?? this.id,
    visitaId: visitaId ?? this.visitaId,
    tipo: tipo.present ? tipo.value : this.tipo,
    archivoPath: archivoPath ?? this.archivoPath,
    tomadaEn: tomadaEn ?? this.tomadaEn,
    latitud: latitud.present ? latitud.value : this.latitud,
    longitud: longitud.present ? longitud.value : this.longitud,
    segundoAudio: segundoAudio.present ? segundoAudio.value : this.segundoAudio,
    descripcionVisitador: descripcionVisitador.present
        ? descripcionVisitador.value
        : this.descripcionVisitador,
    descripcionIa: descripcionIa.present
        ? descripcionIa.value
        : this.descripcionIa,
    textoOcr: textoOcr.present ? textoOcr.value : this.textoOcr,
    enlaceArchivo: enlaceArchivo.present
        ? enlaceArchivo.value
        : this.enlaceArchivo,
    estadoValidacion: estadoValidacion ?? this.estadoValidacion,
  );
  Evidencia copyWithCompanion(EvidenciasCompanion data) {
    return Evidencia(
      id: data.id.present ? data.id.value : this.id,
      visitaId: data.visitaId.present ? data.visitaId.value : this.visitaId,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      archivoPath: data.archivoPath.present
          ? data.archivoPath.value
          : this.archivoPath,
      tomadaEn: data.tomadaEn.present ? data.tomadaEn.value : this.tomadaEn,
      latitud: data.latitud.present ? data.latitud.value : this.latitud,
      longitud: data.longitud.present ? data.longitud.value : this.longitud,
      segundoAudio: data.segundoAudio.present
          ? data.segundoAudio.value
          : this.segundoAudio,
      descripcionVisitador: data.descripcionVisitador.present
          ? data.descripcionVisitador.value
          : this.descripcionVisitador,
      descripcionIa: data.descripcionIa.present
          ? data.descripcionIa.value
          : this.descripcionIa,
      textoOcr: data.textoOcr.present ? data.textoOcr.value : this.textoOcr,
      enlaceArchivo: data.enlaceArchivo.present
          ? data.enlaceArchivo.value
          : this.enlaceArchivo,
      estadoValidacion: data.estadoValidacion.present
          ? data.estadoValidacion.value
          : this.estadoValidacion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Evidencia(')
          ..write('id: $id, ')
          ..write('visitaId: $visitaId, ')
          ..write('tipo: $tipo, ')
          ..write('archivoPath: $archivoPath, ')
          ..write('tomadaEn: $tomadaEn, ')
          ..write('latitud: $latitud, ')
          ..write('longitud: $longitud, ')
          ..write('segundoAudio: $segundoAudio, ')
          ..write('descripcionVisitador: $descripcionVisitador, ')
          ..write('descripcionIa: $descripcionIa, ')
          ..write('textoOcr: $textoOcr, ')
          ..write('enlaceArchivo: $enlaceArchivo, ')
          ..write('estadoValidacion: $estadoValidacion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    visitaId,
    tipo,
    archivoPath,
    tomadaEn,
    latitud,
    longitud,
    segundoAudio,
    descripcionVisitador,
    descripcionIa,
    textoOcr,
    enlaceArchivo,
    estadoValidacion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Evidencia &&
          other.id == this.id &&
          other.visitaId == this.visitaId &&
          other.tipo == this.tipo &&
          other.archivoPath == this.archivoPath &&
          other.tomadaEn == this.tomadaEn &&
          other.latitud == this.latitud &&
          other.longitud == this.longitud &&
          other.segundoAudio == this.segundoAudio &&
          other.descripcionVisitador == this.descripcionVisitador &&
          other.descripcionIa == this.descripcionIa &&
          other.textoOcr == this.textoOcr &&
          other.enlaceArchivo == this.enlaceArchivo &&
          other.estadoValidacion == this.estadoValidacion);
}

class EvidenciasCompanion extends UpdateCompanion<Evidencia> {
  final Value<String> id;
  final Value<String> visitaId;
  final Value<String?> tipo;
  final Value<String> archivoPath;
  final Value<DateTime> tomadaEn;
  final Value<double?> latitud;
  final Value<double?> longitud;
  final Value<int?> segundoAudio;
  final Value<String?> descripcionVisitador;
  final Value<String?> descripcionIa;
  final Value<String?> textoOcr;
  final Value<String?> enlaceArchivo;
  final Value<String> estadoValidacion;
  final Value<int> rowid;
  const EvidenciasCompanion({
    this.id = const Value.absent(),
    this.visitaId = const Value.absent(),
    this.tipo = const Value.absent(),
    this.archivoPath = const Value.absent(),
    this.tomadaEn = const Value.absent(),
    this.latitud = const Value.absent(),
    this.longitud = const Value.absent(),
    this.segundoAudio = const Value.absent(),
    this.descripcionVisitador = const Value.absent(),
    this.descripcionIa = const Value.absent(),
    this.textoOcr = const Value.absent(),
    this.enlaceArchivo = const Value.absent(),
    this.estadoValidacion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EvidenciasCompanion.insert({
    required String id,
    required String visitaId,
    this.tipo = const Value.absent(),
    required String archivoPath,
    required DateTime tomadaEn,
    this.latitud = const Value.absent(),
    this.longitud = const Value.absent(),
    this.segundoAudio = const Value.absent(),
    this.descripcionVisitador = const Value.absent(),
    this.descripcionIa = const Value.absent(),
    this.textoOcr = const Value.absent(),
    this.enlaceArchivo = const Value.absent(),
    this.estadoValidacion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       visitaId = Value(visitaId),
       archivoPath = Value(archivoPath),
       tomadaEn = Value(tomadaEn);
  static Insertable<Evidencia> custom({
    Expression<String>? id,
    Expression<String>? visitaId,
    Expression<String>? tipo,
    Expression<String>? archivoPath,
    Expression<DateTime>? tomadaEn,
    Expression<double>? latitud,
    Expression<double>? longitud,
    Expression<int>? segundoAudio,
    Expression<String>? descripcionVisitador,
    Expression<String>? descripcionIa,
    Expression<String>? textoOcr,
    Expression<String>? enlaceArchivo,
    Expression<String>? estadoValidacion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (visitaId != null) 'visita_id': visitaId,
      if (tipo != null) 'tipo': tipo,
      if (archivoPath != null) 'archivo_path': archivoPath,
      if (tomadaEn != null) 'tomada_en': tomadaEn,
      if (latitud != null) 'latitud': latitud,
      if (longitud != null) 'longitud': longitud,
      if (segundoAudio != null) 'segundo_audio': segundoAudio,
      if (descripcionVisitador != null)
        'descripcion_visitador': descripcionVisitador,
      if (descripcionIa != null) 'descripcion_ia': descripcionIa,
      if (textoOcr != null) 'texto_ocr': textoOcr,
      if (enlaceArchivo != null) 'enlace_archivo': enlaceArchivo,
      if (estadoValidacion != null) 'estado_validacion': estadoValidacion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EvidenciasCompanion copyWith({
    Value<String>? id,
    Value<String>? visitaId,
    Value<String?>? tipo,
    Value<String>? archivoPath,
    Value<DateTime>? tomadaEn,
    Value<double?>? latitud,
    Value<double?>? longitud,
    Value<int?>? segundoAudio,
    Value<String?>? descripcionVisitador,
    Value<String?>? descripcionIa,
    Value<String?>? textoOcr,
    Value<String?>? enlaceArchivo,
    Value<String>? estadoValidacion,
    Value<int>? rowid,
  }) {
    return EvidenciasCompanion(
      id: id ?? this.id,
      visitaId: visitaId ?? this.visitaId,
      tipo: tipo ?? this.tipo,
      archivoPath: archivoPath ?? this.archivoPath,
      tomadaEn: tomadaEn ?? this.tomadaEn,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      segundoAudio: segundoAudio ?? this.segundoAudio,
      descripcionVisitador: descripcionVisitador ?? this.descripcionVisitador,
      descripcionIa: descripcionIa ?? this.descripcionIa,
      textoOcr: textoOcr ?? this.textoOcr,
      enlaceArchivo: enlaceArchivo ?? this.enlaceArchivo,
      estadoValidacion: estadoValidacion ?? this.estadoValidacion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (visitaId.present) {
      map['visita_id'] = Variable<String>(visitaId.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (archivoPath.present) {
      map['archivo_path'] = Variable<String>(archivoPath.value);
    }
    if (tomadaEn.present) {
      map['tomada_en'] = Variable<DateTime>(tomadaEn.value);
    }
    if (latitud.present) {
      map['latitud'] = Variable<double>(latitud.value);
    }
    if (longitud.present) {
      map['longitud'] = Variable<double>(longitud.value);
    }
    if (segundoAudio.present) {
      map['segundo_audio'] = Variable<int>(segundoAudio.value);
    }
    if (descripcionVisitador.present) {
      map['descripcion_visitador'] = Variable<String>(
        descripcionVisitador.value,
      );
    }
    if (descripcionIa.present) {
      map['descripcion_ia'] = Variable<String>(descripcionIa.value);
    }
    if (textoOcr.present) {
      map['texto_ocr'] = Variable<String>(textoOcr.value);
    }
    if (enlaceArchivo.present) {
      map['enlace_archivo'] = Variable<String>(enlaceArchivo.value);
    }
    if (estadoValidacion.present) {
      map['estado_validacion'] = Variable<String>(estadoValidacion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EvidenciasCompanion(')
          ..write('id: $id, ')
          ..write('visitaId: $visitaId, ')
          ..write('tipo: $tipo, ')
          ..write('archivoPath: $archivoPath, ')
          ..write('tomadaEn: $tomadaEn, ')
          ..write('latitud: $latitud, ')
          ..write('longitud: $longitud, ')
          ..write('segundoAudio: $segundoAudio, ')
          ..write('descripcionVisitador: $descripcionVisitador, ')
          ..write('descripcionIa: $descripcionIa, ')
          ..write('textoOcr: $textoOcr, ')
          ..write('enlaceArchivo: $enlaceArchivo, ')
          ..write('estadoValidacion: $estadoValidacion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HallazgosTable extends Hallazgos
    with TableInfo<$HallazgosTable, Hallazgo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HallazgosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _visitaIdMeta = const VerificationMeta(
    'visitaId',
  );
  @override
  late final GeneratedColumn<String> visitaId = GeneratedColumn<String>(
    'visita_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _claveTecnicaMeta = const VerificationMeta(
    'claveTecnica',
  );
  @override
  late final GeneratedColumn<String> claveTecnica = GeneratedColumn<String>(
    'clave_tecnica',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<EntidadDestino?, String>
  entidadDestino = GeneratedColumn<String>(
    'entidad_destino',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<EntidadDestino?>($HallazgosTable.$converterentidadDestinon);
  static const VerificationMeta _entidadLocalIdMeta = const VerificationMeta(
    'entidadLocalId',
  );
  @override
  late final GeneratedColumn<String> entidadLocalId = GeneratedColumn<String>(
    'entidad_local_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _valorTextoMeta = const VerificationMeta(
    'valorTexto',
  );
  @override
  late final GeneratedColumn<String> valorTexto = GeneratedColumn<String>(
    'valor_texto',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _valorNumericoMeta = const VerificationMeta(
    'valorNumerico',
  );
  @override
  late final GeneratedColumn<double> valorNumerico = GeneratedColumn<double>(
    'valor_numerico',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unidadMeta = const VerificationMeta('unidad');
  @override
  late final GeneratedColumn<String> unidad = GeneratedColumn<String>(
    'unidad',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<FuenteHallazgo, String> fuente =
      GeneratedColumn<String>(
        'fuente',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('Audio'),
      ).withConverter<FuenteHallazgo>($HallazgosTable.$converterfuente);
  static const VerificationMeta _citaTextualMeta = const VerificationMeta(
    'citaTextual',
  );
  @override
  late final GeneratedColumn<String> citaTextual = GeneratedColumn<String>(
    'cita_textual',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _segundoAudioMeta = const VerificationMeta(
    'segundoAudio',
  );
  @override
  late final GeneratedColumn<int> segundoAudio = GeneratedColumn<int>(
    'segundo_audio',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Hablante?, String> hablante =
      GeneratedColumn<String>(
        'hablante',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<Hablante?>($HallazgosTable.$converterhablanten);
  @override
  late final GeneratedColumnWithTypeConverter<Certeza, String> certeza =
      GeneratedColumn<String>(
        'certeza',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('Pendiente'),
      ).withConverter<Certeza>($HallazgosTable.$convertercerteza);
  static const VerificationMeta _razonamientoMeta = const VerificationMeta(
    'razonamiento',
  );
  @override
  late final GeneratedColumn<String> razonamiento = GeneratedColumn<String>(
    'razonamiento',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _confianzaMeta = const VerificationMeta(
    'confianza',
  );
  @override
  late final GeneratedColumn<double> confianza = GeneratedColumn<double>(
    'confianza',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<EstadoHallazgo, String> estado =
      GeneratedColumn<String>(
        'estado',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('Propuesto por IA'),
      ).withConverter<EstadoHallazgo>($HallazgosTable.$converterestado);
  static const VerificationMeta _valorCorregidoMeta = const VerificationMeta(
    'valorCorregido',
  );
  @override
  late final GeneratedColumn<String> valorCorregido = GeneratedColumn<String>(
    'valor_corregido',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _validadoPorLocalIdMeta =
      const VerificationMeta('validadoPorLocalId');
  @override
  late final GeneratedColumn<String> validadoPorLocalId =
      GeneratedColumn<String>(
        'validado_por_local_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _validadoEnMeta = const VerificationMeta(
    'validadoEn',
  );
  @override
  late final GeneratedColumn<DateTime> validadoEn = GeneratedColumn<DateTime>(
    'validado_en',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _creadoEnMeta = const VerificationMeta(
    'creadoEn',
  );
  @override
  late final GeneratedColumn<DateTime> creadoEn = GeneratedColumn<DateTime>(
    'creado_en',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    visitaId,
    claveTecnica,
    entidadDestino,
    entidadLocalId,
    valorTexto,
    valorNumerico,
    unidad,
    fuente,
    citaTextual,
    segundoAudio,
    hablante,
    certeza,
    razonamiento,
    confianza,
    estado,
    valorCorregido,
    validadoPorLocalId,
    validadoEn,
    creadoEn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hallazgos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Hallazgo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('visita_id')) {
      context.handle(
        _visitaIdMeta,
        visitaId.isAcceptableOrUnknown(data['visita_id']!, _visitaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_visitaIdMeta);
    }
    if (data.containsKey('clave_tecnica')) {
      context.handle(
        _claveTecnicaMeta,
        claveTecnica.isAcceptableOrUnknown(
          data['clave_tecnica']!,
          _claveTecnicaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_claveTecnicaMeta);
    }
    if (data.containsKey('entidad_local_id')) {
      context.handle(
        _entidadLocalIdMeta,
        entidadLocalId.isAcceptableOrUnknown(
          data['entidad_local_id']!,
          _entidadLocalIdMeta,
        ),
      );
    }
    if (data.containsKey('valor_texto')) {
      context.handle(
        _valorTextoMeta,
        valorTexto.isAcceptableOrUnknown(data['valor_texto']!, _valorTextoMeta),
      );
    }
    if (data.containsKey('valor_numerico')) {
      context.handle(
        _valorNumericoMeta,
        valorNumerico.isAcceptableOrUnknown(
          data['valor_numerico']!,
          _valorNumericoMeta,
        ),
      );
    }
    if (data.containsKey('unidad')) {
      context.handle(
        _unidadMeta,
        unidad.isAcceptableOrUnknown(data['unidad']!, _unidadMeta),
      );
    }
    if (data.containsKey('cita_textual')) {
      context.handle(
        _citaTextualMeta,
        citaTextual.isAcceptableOrUnknown(
          data['cita_textual']!,
          _citaTextualMeta,
        ),
      );
    }
    if (data.containsKey('segundo_audio')) {
      context.handle(
        _segundoAudioMeta,
        segundoAudio.isAcceptableOrUnknown(
          data['segundo_audio']!,
          _segundoAudioMeta,
        ),
      );
    }
    if (data.containsKey('razonamiento')) {
      context.handle(
        _razonamientoMeta,
        razonamiento.isAcceptableOrUnknown(
          data['razonamiento']!,
          _razonamientoMeta,
        ),
      );
    }
    if (data.containsKey('confianza')) {
      context.handle(
        _confianzaMeta,
        confianza.isAcceptableOrUnknown(data['confianza']!, _confianzaMeta),
      );
    }
    if (data.containsKey('valor_corregido')) {
      context.handle(
        _valorCorregidoMeta,
        valorCorregido.isAcceptableOrUnknown(
          data['valor_corregido']!,
          _valorCorregidoMeta,
        ),
      );
    }
    if (data.containsKey('validado_por_local_id')) {
      context.handle(
        _validadoPorLocalIdMeta,
        validadoPorLocalId.isAcceptableOrUnknown(
          data['validado_por_local_id']!,
          _validadoPorLocalIdMeta,
        ),
      );
    }
    if (data.containsKey('validado_en')) {
      context.handle(
        _validadoEnMeta,
        validadoEn.isAcceptableOrUnknown(data['validado_en']!, _validadoEnMeta),
      );
    }
    if (data.containsKey('creado_en')) {
      context.handle(
        _creadoEnMeta,
        creadoEn.isAcceptableOrUnknown(data['creado_en']!, _creadoEnMeta),
      );
    } else if (isInserting) {
      context.missing(_creadoEnMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Hallazgo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Hallazgo(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      visitaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visita_id'],
      )!,
      claveTecnica: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clave_tecnica'],
      )!,
      entidadDestino: $HallazgosTable.$converterentidadDestinon.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}entidad_destino'],
        ),
      ),
      entidadLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entidad_local_id'],
      ),
      valorTexto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}valor_texto'],
      ),
      valorNumerico: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}valor_numerico'],
      ),
      unidad: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unidad'],
      ),
      fuente: $HallazgosTable.$converterfuente.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}fuente'],
        )!,
      ),
      citaTextual: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cita_textual'],
      ),
      segundoAudio: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}segundo_audio'],
      ),
      hablante: $HallazgosTable.$converterhablanten.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}hablante'],
        ),
      ),
      certeza: $HallazgosTable.$convertercerteza.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}certeza'],
        )!,
      ),
      razonamiento: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}razonamiento'],
      ),
      confianza: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confianza'],
      ),
      estado: $HallazgosTable.$converterestado.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}estado'],
        )!,
      ),
      valorCorregido: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}valor_corregido'],
      ),
      validadoPorLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}validado_por_local_id'],
      ),
      validadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}validado_en'],
      ),
      creadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}creado_en'],
      )!,
    );
  }

  @override
  $HallazgosTable createAlias(String alias) {
    return $HallazgosTable(attachedDatabase, alias);
  }

  static TypeConverter<EntidadDestino, String> $converterentidadDestino =
      const EntidadDestinoConverter();
  static TypeConverter<EntidadDestino?, String?> $converterentidadDestinon =
      NullAwareTypeConverter.wrap($converterentidadDestino);
  static TypeConverter<FuenteHallazgo, String> $converterfuente =
      const FuenteHallazgoConverter();
  static TypeConverter<Hablante, String> $converterhablante =
      const HablanteConverter();
  static TypeConverter<Hablante?, String?> $converterhablanten =
      NullAwareTypeConverter.wrap($converterhablante);
  static TypeConverter<Certeza, String> $convertercerteza =
      const CertezaConverter();
  static TypeConverter<EstadoHallazgo, String> $converterestado =
      const EstadoHallazgoConverter();
}

class Hallazgo extends DataClass implements Insertable<Hallazgo> {
  final String id;
  final String visitaId;

  /// Clave tecnica del catalogo. No es texto libre: si el modelo devuelve una
  /// clave que no esta en el catalogo, el hallazgo se rechaza y va a
  /// `Visitas.temasPendientes`.
  final String claveTecnica;

  /// A cual de los tres cultivos se refiere.
  final EntidadDestino? entidadDestino;

  /// Instancia local dentro de la visita: cultivo_1, cultivo_2. La asigna el
  /// modelo; el backend la resuelve a un Lote real al sincronizar.
  final String? entidadLocalId;
  final String? valorTexto;
  final double? valorNumerico;
  final String? unidad;
  final FuenteHallazgo fuente;

  /// Fragmento textual que respalda el dato. Sin esto, certeza baja a Pendiente.
  final String? citaTextual;
  final int? segundoAudio;

  /// Quien lo dijo. hablante = visitador implica que NUNCA es Confirmado.
  final Hablante? hablante;
  final Certeza certeza;

  /// Obligatorio cuando certeza = Inferido. Sin el, baja a Pendiente.
  final String? razonamiento;
  final double? confianza;
  final EstadoHallazgo estado;

  /// Lo que el visitador dejo como verdad final. El valor original NUNCA se
  /// borra: sin los dos no se puede medir la precision del modelo en el piloto.
  final String? valorCorregido;
  final String? validadoPorLocalId;
  final DateTime? validadoEn;
  final DateTime creadoEn;
  const Hallazgo({
    required this.id,
    required this.visitaId,
    required this.claveTecnica,
    this.entidadDestino,
    this.entidadLocalId,
    this.valorTexto,
    this.valorNumerico,
    this.unidad,
    required this.fuente,
    this.citaTextual,
    this.segundoAudio,
    this.hablante,
    required this.certeza,
    this.razonamiento,
    this.confianza,
    required this.estado,
    this.valorCorregido,
    this.validadoPorLocalId,
    this.validadoEn,
    required this.creadoEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['visita_id'] = Variable<String>(visitaId);
    map['clave_tecnica'] = Variable<String>(claveTecnica);
    if (!nullToAbsent || entidadDestino != null) {
      map['entidad_destino'] = Variable<String>(
        $HallazgosTable.$converterentidadDestinon.toSql(entidadDestino),
      );
    }
    if (!nullToAbsent || entidadLocalId != null) {
      map['entidad_local_id'] = Variable<String>(entidadLocalId);
    }
    if (!nullToAbsent || valorTexto != null) {
      map['valor_texto'] = Variable<String>(valorTexto);
    }
    if (!nullToAbsent || valorNumerico != null) {
      map['valor_numerico'] = Variable<double>(valorNumerico);
    }
    if (!nullToAbsent || unidad != null) {
      map['unidad'] = Variable<String>(unidad);
    }
    {
      map['fuente'] = Variable<String>(
        $HallazgosTable.$converterfuente.toSql(fuente),
      );
    }
    if (!nullToAbsent || citaTextual != null) {
      map['cita_textual'] = Variable<String>(citaTextual);
    }
    if (!nullToAbsent || segundoAudio != null) {
      map['segundo_audio'] = Variable<int>(segundoAudio);
    }
    if (!nullToAbsent || hablante != null) {
      map['hablante'] = Variable<String>(
        $HallazgosTable.$converterhablanten.toSql(hablante),
      );
    }
    {
      map['certeza'] = Variable<String>(
        $HallazgosTable.$convertercerteza.toSql(certeza),
      );
    }
    if (!nullToAbsent || razonamiento != null) {
      map['razonamiento'] = Variable<String>(razonamiento);
    }
    if (!nullToAbsent || confianza != null) {
      map['confianza'] = Variable<double>(confianza);
    }
    {
      map['estado'] = Variable<String>(
        $HallazgosTable.$converterestado.toSql(estado),
      );
    }
    if (!nullToAbsent || valorCorregido != null) {
      map['valor_corregido'] = Variable<String>(valorCorregido);
    }
    if (!nullToAbsent || validadoPorLocalId != null) {
      map['validado_por_local_id'] = Variable<String>(validadoPorLocalId);
    }
    if (!nullToAbsent || validadoEn != null) {
      map['validado_en'] = Variable<DateTime>(validadoEn);
    }
    map['creado_en'] = Variable<DateTime>(creadoEn);
    return map;
  }

  HallazgosCompanion toCompanion(bool nullToAbsent) {
    return HallazgosCompanion(
      id: Value(id),
      visitaId: Value(visitaId),
      claveTecnica: Value(claveTecnica),
      entidadDestino: entidadDestino == null && nullToAbsent
          ? const Value.absent()
          : Value(entidadDestino),
      entidadLocalId: entidadLocalId == null && nullToAbsent
          ? const Value.absent()
          : Value(entidadLocalId),
      valorTexto: valorTexto == null && nullToAbsent
          ? const Value.absent()
          : Value(valorTexto),
      valorNumerico: valorNumerico == null && nullToAbsent
          ? const Value.absent()
          : Value(valorNumerico),
      unidad: unidad == null && nullToAbsent
          ? const Value.absent()
          : Value(unidad),
      fuente: Value(fuente),
      citaTextual: citaTextual == null && nullToAbsent
          ? const Value.absent()
          : Value(citaTextual),
      segundoAudio: segundoAudio == null && nullToAbsent
          ? const Value.absent()
          : Value(segundoAudio),
      hablante: hablante == null && nullToAbsent
          ? const Value.absent()
          : Value(hablante),
      certeza: Value(certeza),
      razonamiento: razonamiento == null && nullToAbsent
          ? const Value.absent()
          : Value(razonamiento),
      confianza: confianza == null && nullToAbsent
          ? const Value.absent()
          : Value(confianza),
      estado: Value(estado),
      valorCorregido: valorCorregido == null && nullToAbsent
          ? const Value.absent()
          : Value(valorCorregido),
      validadoPorLocalId: validadoPorLocalId == null && nullToAbsent
          ? const Value.absent()
          : Value(validadoPorLocalId),
      validadoEn: validadoEn == null && nullToAbsent
          ? const Value.absent()
          : Value(validadoEn),
      creadoEn: Value(creadoEn),
    );
  }

  factory Hallazgo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Hallazgo(
      id: serializer.fromJson<String>(json['id']),
      visitaId: serializer.fromJson<String>(json['visitaId']),
      claveTecnica: serializer.fromJson<String>(json['claveTecnica']),
      entidadDestino: serializer.fromJson<EntidadDestino?>(
        json['entidadDestino'],
      ),
      entidadLocalId: serializer.fromJson<String?>(json['entidadLocalId']),
      valorTexto: serializer.fromJson<String?>(json['valorTexto']),
      valorNumerico: serializer.fromJson<double?>(json['valorNumerico']),
      unidad: serializer.fromJson<String?>(json['unidad']),
      fuente: serializer.fromJson<FuenteHallazgo>(json['fuente']),
      citaTextual: serializer.fromJson<String?>(json['citaTextual']),
      segundoAudio: serializer.fromJson<int?>(json['segundoAudio']),
      hablante: serializer.fromJson<Hablante?>(json['hablante']),
      certeza: serializer.fromJson<Certeza>(json['certeza']),
      razonamiento: serializer.fromJson<String?>(json['razonamiento']),
      confianza: serializer.fromJson<double?>(json['confianza']),
      estado: serializer.fromJson<EstadoHallazgo>(json['estado']),
      valorCorregido: serializer.fromJson<String?>(json['valorCorregido']),
      validadoPorLocalId: serializer.fromJson<String?>(
        json['validadoPorLocalId'],
      ),
      validadoEn: serializer.fromJson<DateTime?>(json['validadoEn']),
      creadoEn: serializer.fromJson<DateTime>(json['creadoEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'visitaId': serializer.toJson<String>(visitaId),
      'claveTecnica': serializer.toJson<String>(claveTecnica),
      'entidadDestino': serializer.toJson<EntidadDestino?>(entidadDestino),
      'entidadLocalId': serializer.toJson<String?>(entidadLocalId),
      'valorTexto': serializer.toJson<String?>(valorTexto),
      'valorNumerico': serializer.toJson<double?>(valorNumerico),
      'unidad': serializer.toJson<String?>(unidad),
      'fuente': serializer.toJson<FuenteHallazgo>(fuente),
      'citaTextual': serializer.toJson<String?>(citaTextual),
      'segundoAudio': serializer.toJson<int?>(segundoAudio),
      'hablante': serializer.toJson<Hablante?>(hablante),
      'certeza': serializer.toJson<Certeza>(certeza),
      'razonamiento': serializer.toJson<String?>(razonamiento),
      'confianza': serializer.toJson<double?>(confianza),
      'estado': serializer.toJson<EstadoHallazgo>(estado),
      'valorCorregido': serializer.toJson<String?>(valorCorregido),
      'validadoPorLocalId': serializer.toJson<String?>(validadoPorLocalId),
      'validadoEn': serializer.toJson<DateTime?>(validadoEn),
      'creadoEn': serializer.toJson<DateTime>(creadoEn),
    };
  }

  Hallazgo copyWith({
    String? id,
    String? visitaId,
    String? claveTecnica,
    Value<EntidadDestino?> entidadDestino = const Value.absent(),
    Value<String?> entidadLocalId = const Value.absent(),
    Value<String?> valorTexto = const Value.absent(),
    Value<double?> valorNumerico = const Value.absent(),
    Value<String?> unidad = const Value.absent(),
    FuenteHallazgo? fuente,
    Value<String?> citaTextual = const Value.absent(),
    Value<int?> segundoAudio = const Value.absent(),
    Value<Hablante?> hablante = const Value.absent(),
    Certeza? certeza,
    Value<String?> razonamiento = const Value.absent(),
    Value<double?> confianza = const Value.absent(),
    EstadoHallazgo? estado,
    Value<String?> valorCorregido = const Value.absent(),
    Value<String?> validadoPorLocalId = const Value.absent(),
    Value<DateTime?> validadoEn = const Value.absent(),
    DateTime? creadoEn,
  }) => Hallazgo(
    id: id ?? this.id,
    visitaId: visitaId ?? this.visitaId,
    claveTecnica: claveTecnica ?? this.claveTecnica,
    entidadDestino: entidadDestino.present
        ? entidadDestino.value
        : this.entidadDestino,
    entidadLocalId: entidadLocalId.present
        ? entidadLocalId.value
        : this.entidadLocalId,
    valorTexto: valorTexto.present ? valorTexto.value : this.valorTexto,
    valorNumerico: valorNumerico.present
        ? valorNumerico.value
        : this.valorNumerico,
    unidad: unidad.present ? unidad.value : this.unidad,
    fuente: fuente ?? this.fuente,
    citaTextual: citaTextual.present ? citaTextual.value : this.citaTextual,
    segundoAudio: segundoAudio.present ? segundoAudio.value : this.segundoAudio,
    hablante: hablante.present ? hablante.value : this.hablante,
    certeza: certeza ?? this.certeza,
    razonamiento: razonamiento.present ? razonamiento.value : this.razonamiento,
    confianza: confianza.present ? confianza.value : this.confianza,
    estado: estado ?? this.estado,
    valorCorregido: valorCorregido.present
        ? valorCorregido.value
        : this.valorCorregido,
    validadoPorLocalId: validadoPorLocalId.present
        ? validadoPorLocalId.value
        : this.validadoPorLocalId,
    validadoEn: validadoEn.present ? validadoEn.value : this.validadoEn,
    creadoEn: creadoEn ?? this.creadoEn,
  );
  Hallazgo copyWithCompanion(HallazgosCompanion data) {
    return Hallazgo(
      id: data.id.present ? data.id.value : this.id,
      visitaId: data.visitaId.present ? data.visitaId.value : this.visitaId,
      claveTecnica: data.claveTecnica.present
          ? data.claveTecnica.value
          : this.claveTecnica,
      entidadDestino: data.entidadDestino.present
          ? data.entidadDestino.value
          : this.entidadDestino,
      entidadLocalId: data.entidadLocalId.present
          ? data.entidadLocalId.value
          : this.entidadLocalId,
      valorTexto: data.valorTexto.present
          ? data.valorTexto.value
          : this.valorTexto,
      valorNumerico: data.valorNumerico.present
          ? data.valorNumerico.value
          : this.valorNumerico,
      unidad: data.unidad.present ? data.unidad.value : this.unidad,
      fuente: data.fuente.present ? data.fuente.value : this.fuente,
      citaTextual: data.citaTextual.present
          ? data.citaTextual.value
          : this.citaTextual,
      segundoAudio: data.segundoAudio.present
          ? data.segundoAudio.value
          : this.segundoAudio,
      hablante: data.hablante.present ? data.hablante.value : this.hablante,
      certeza: data.certeza.present ? data.certeza.value : this.certeza,
      razonamiento: data.razonamiento.present
          ? data.razonamiento.value
          : this.razonamiento,
      confianza: data.confianza.present ? data.confianza.value : this.confianza,
      estado: data.estado.present ? data.estado.value : this.estado,
      valorCorregido: data.valorCorregido.present
          ? data.valorCorregido.value
          : this.valorCorregido,
      validadoPorLocalId: data.validadoPorLocalId.present
          ? data.validadoPorLocalId.value
          : this.validadoPorLocalId,
      validadoEn: data.validadoEn.present
          ? data.validadoEn.value
          : this.validadoEn,
      creadoEn: data.creadoEn.present ? data.creadoEn.value : this.creadoEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Hallazgo(')
          ..write('id: $id, ')
          ..write('visitaId: $visitaId, ')
          ..write('claveTecnica: $claveTecnica, ')
          ..write('entidadDestino: $entidadDestino, ')
          ..write('entidadLocalId: $entidadLocalId, ')
          ..write('valorTexto: $valorTexto, ')
          ..write('valorNumerico: $valorNumerico, ')
          ..write('unidad: $unidad, ')
          ..write('fuente: $fuente, ')
          ..write('citaTextual: $citaTextual, ')
          ..write('segundoAudio: $segundoAudio, ')
          ..write('hablante: $hablante, ')
          ..write('certeza: $certeza, ')
          ..write('razonamiento: $razonamiento, ')
          ..write('confianza: $confianza, ')
          ..write('estado: $estado, ')
          ..write('valorCorregido: $valorCorregido, ')
          ..write('validadoPorLocalId: $validadoPorLocalId, ')
          ..write('validadoEn: $validadoEn, ')
          ..write('creadoEn: $creadoEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    visitaId,
    claveTecnica,
    entidadDestino,
    entidadLocalId,
    valorTexto,
    valorNumerico,
    unidad,
    fuente,
    citaTextual,
    segundoAudio,
    hablante,
    certeza,
    razonamiento,
    confianza,
    estado,
    valorCorregido,
    validadoPorLocalId,
    validadoEn,
    creadoEn,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Hallazgo &&
          other.id == this.id &&
          other.visitaId == this.visitaId &&
          other.claveTecnica == this.claveTecnica &&
          other.entidadDestino == this.entidadDestino &&
          other.entidadLocalId == this.entidadLocalId &&
          other.valorTexto == this.valorTexto &&
          other.valorNumerico == this.valorNumerico &&
          other.unidad == this.unidad &&
          other.fuente == this.fuente &&
          other.citaTextual == this.citaTextual &&
          other.segundoAudio == this.segundoAudio &&
          other.hablante == this.hablante &&
          other.certeza == this.certeza &&
          other.razonamiento == this.razonamiento &&
          other.confianza == this.confianza &&
          other.estado == this.estado &&
          other.valorCorregido == this.valorCorregido &&
          other.validadoPorLocalId == this.validadoPorLocalId &&
          other.validadoEn == this.validadoEn &&
          other.creadoEn == this.creadoEn);
}

class HallazgosCompanion extends UpdateCompanion<Hallazgo> {
  final Value<String> id;
  final Value<String> visitaId;
  final Value<String> claveTecnica;
  final Value<EntidadDestino?> entidadDestino;
  final Value<String?> entidadLocalId;
  final Value<String?> valorTexto;
  final Value<double?> valorNumerico;
  final Value<String?> unidad;
  final Value<FuenteHallazgo> fuente;
  final Value<String?> citaTextual;
  final Value<int?> segundoAudio;
  final Value<Hablante?> hablante;
  final Value<Certeza> certeza;
  final Value<String?> razonamiento;
  final Value<double?> confianza;
  final Value<EstadoHallazgo> estado;
  final Value<String?> valorCorregido;
  final Value<String?> validadoPorLocalId;
  final Value<DateTime?> validadoEn;
  final Value<DateTime> creadoEn;
  final Value<int> rowid;
  const HallazgosCompanion({
    this.id = const Value.absent(),
    this.visitaId = const Value.absent(),
    this.claveTecnica = const Value.absent(),
    this.entidadDestino = const Value.absent(),
    this.entidadLocalId = const Value.absent(),
    this.valorTexto = const Value.absent(),
    this.valorNumerico = const Value.absent(),
    this.unidad = const Value.absent(),
    this.fuente = const Value.absent(),
    this.citaTextual = const Value.absent(),
    this.segundoAudio = const Value.absent(),
    this.hablante = const Value.absent(),
    this.certeza = const Value.absent(),
    this.razonamiento = const Value.absent(),
    this.confianza = const Value.absent(),
    this.estado = const Value.absent(),
    this.valorCorregido = const Value.absent(),
    this.validadoPorLocalId = const Value.absent(),
    this.validadoEn = const Value.absent(),
    this.creadoEn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HallazgosCompanion.insert({
    required String id,
    required String visitaId,
    required String claveTecnica,
    this.entidadDestino = const Value.absent(),
    this.entidadLocalId = const Value.absent(),
    this.valorTexto = const Value.absent(),
    this.valorNumerico = const Value.absent(),
    this.unidad = const Value.absent(),
    this.fuente = const Value.absent(),
    this.citaTextual = const Value.absent(),
    this.segundoAudio = const Value.absent(),
    this.hablante = const Value.absent(),
    this.certeza = const Value.absent(),
    this.razonamiento = const Value.absent(),
    this.confianza = const Value.absent(),
    this.estado = const Value.absent(),
    this.valorCorregido = const Value.absent(),
    this.validadoPorLocalId = const Value.absent(),
    this.validadoEn = const Value.absent(),
    required DateTime creadoEn,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       visitaId = Value(visitaId),
       claveTecnica = Value(claveTecnica),
       creadoEn = Value(creadoEn);
  static Insertable<Hallazgo> custom({
    Expression<String>? id,
    Expression<String>? visitaId,
    Expression<String>? claveTecnica,
    Expression<String>? entidadDestino,
    Expression<String>? entidadLocalId,
    Expression<String>? valorTexto,
    Expression<double>? valorNumerico,
    Expression<String>? unidad,
    Expression<String>? fuente,
    Expression<String>? citaTextual,
    Expression<int>? segundoAudio,
    Expression<String>? hablante,
    Expression<String>? certeza,
    Expression<String>? razonamiento,
    Expression<double>? confianza,
    Expression<String>? estado,
    Expression<String>? valorCorregido,
    Expression<String>? validadoPorLocalId,
    Expression<DateTime>? validadoEn,
    Expression<DateTime>? creadoEn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (visitaId != null) 'visita_id': visitaId,
      if (claveTecnica != null) 'clave_tecnica': claveTecnica,
      if (entidadDestino != null) 'entidad_destino': entidadDestino,
      if (entidadLocalId != null) 'entidad_local_id': entidadLocalId,
      if (valorTexto != null) 'valor_texto': valorTexto,
      if (valorNumerico != null) 'valor_numerico': valorNumerico,
      if (unidad != null) 'unidad': unidad,
      if (fuente != null) 'fuente': fuente,
      if (citaTextual != null) 'cita_textual': citaTextual,
      if (segundoAudio != null) 'segundo_audio': segundoAudio,
      if (hablante != null) 'hablante': hablante,
      if (certeza != null) 'certeza': certeza,
      if (razonamiento != null) 'razonamiento': razonamiento,
      if (confianza != null) 'confianza': confianza,
      if (estado != null) 'estado': estado,
      if (valorCorregido != null) 'valor_corregido': valorCorregido,
      if (validadoPorLocalId != null)
        'validado_por_local_id': validadoPorLocalId,
      if (validadoEn != null) 'validado_en': validadoEn,
      if (creadoEn != null) 'creado_en': creadoEn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HallazgosCompanion copyWith({
    Value<String>? id,
    Value<String>? visitaId,
    Value<String>? claveTecnica,
    Value<EntidadDestino?>? entidadDestino,
    Value<String?>? entidadLocalId,
    Value<String?>? valorTexto,
    Value<double?>? valorNumerico,
    Value<String?>? unidad,
    Value<FuenteHallazgo>? fuente,
    Value<String?>? citaTextual,
    Value<int?>? segundoAudio,
    Value<Hablante?>? hablante,
    Value<Certeza>? certeza,
    Value<String?>? razonamiento,
    Value<double?>? confianza,
    Value<EstadoHallazgo>? estado,
    Value<String?>? valorCorregido,
    Value<String?>? validadoPorLocalId,
    Value<DateTime?>? validadoEn,
    Value<DateTime>? creadoEn,
    Value<int>? rowid,
  }) {
    return HallazgosCompanion(
      id: id ?? this.id,
      visitaId: visitaId ?? this.visitaId,
      claveTecnica: claveTecnica ?? this.claveTecnica,
      entidadDestino: entidadDestino ?? this.entidadDestino,
      entidadLocalId: entidadLocalId ?? this.entidadLocalId,
      valorTexto: valorTexto ?? this.valorTexto,
      valorNumerico: valorNumerico ?? this.valorNumerico,
      unidad: unidad ?? this.unidad,
      fuente: fuente ?? this.fuente,
      citaTextual: citaTextual ?? this.citaTextual,
      segundoAudio: segundoAudio ?? this.segundoAudio,
      hablante: hablante ?? this.hablante,
      certeza: certeza ?? this.certeza,
      razonamiento: razonamiento ?? this.razonamiento,
      confianza: confianza ?? this.confianza,
      estado: estado ?? this.estado,
      valorCorregido: valorCorregido ?? this.valorCorregido,
      validadoPorLocalId: validadoPorLocalId ?? this.validadoPorLocalId,
      validadoEn: validadoEn ?? this.validadoEn,
      creadoEn: creadoEn ?? this.creadoEn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (visitaId.present) {
      map['visita_id'] = Variable<String>(visitaId.value);
    }
    if (claveTecnica.present) {
      map['clave_tecnica'] = Variable<String>(claveTecnica.value);
    }
    if (entidadDestino.present) {
      map['entidad_destino'] = Variable<String>(
        $HallazgosTable.$converterentidadDestinon.toSql(entidadDestino.value),
      );
    }
    if (entidadLocalId.present) {
      map['entidad_local_id'] = Variable<String>(entidadLocalId.value);
    }
    if (valorTexto.present) {
      map['valor_texto'] = Variable<String>(valorTexto.value);
    }
    if (valorNumerico.present) {
      map['valor_numerico'] = Variable<double>(valorNumerico.value);
    }
    if (unidad.present) {
      map['unidad'] = Variable<String>(unidad.value);
    }
    if (fuente.present) {
      map['fuente'] = Variable<String>(
        $HallazgosTable.$converterfuente.toSql(fuente.value),
      );
    }
    if (citaTextual.present) {
      map['cita_textual'] = Variable<String>(citaTextual.value);
    }
    if (segundoAudio.present) {
      map['segundo_audio'] = Variable<int>(segundoAudio.value);
    }
    if (hablante.present) {
      map['hablante'] = Variable<String>(
        $HallazgosTable.$converterhablanten.toSql(hablante.value),
      );
    }
    if (certeza.present) {
      map['certeza'] = Variable<String>(
        $HallazgosTable.$convertercerteza.toSql(certeza.value),
      );
    }
    if (razonamiento.present) {
      map['razonamiento'] = Variable<String>(razonamiento.value);
    }
    if (confianza.present) {
      map['confianza'] = Variable<double>(confianza.value);
    }
    if (estado.present) {
      map['estado'] = Variable<String>(
        $HallazgosTable.$converterestado.toSql(estado.value),
      );
    }
    if (valorCorregido.present) {
      map['valor_corregido'] = Variable<String>(valorCorregido.value);
    }
    if (validadoPorLocalId.present) {
      map['validado_por_local_id'] = Variable<String>(validadoPorLocalId.value);
    }
    if (validadoEn.present) {
      map['validado_en'] = Variable<DateTime>(validadoEn.value);
    }
    if (creadoEn.present) {
      map['creado_en'] = Variable<DateTime>(creadoEn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HallazgosCompanion(')
          ..write('id: $id, ')
          ..write('visitaId: $visitaId, ')
          ..write('claveTecnica: $claveTecnica, ')
          ..write('entidadDestino: $entidadDestino, ')
          ..write('entidadLocalId: $entidadLocalId, ')
          ..write('valorTexto: $valorTexto, ')
          ..write('valorNumerico: $valorNumerico, ')
          ..write('unidad: $unidad, ')
          ..write('fuente: $fuente, ')
          ..write('citaTextual: $citaTextual, ')
          ..write('segundoAudio: $segundoAudio, ')
          ..write('hablante: $hablante, ')
          ..write('certeza: $certeza, ')
          ..write('razonamiento: $razonamiento, ')
          ..write('confianza: $confianza, ')
          ..write('estado: $estado, ')
          ..write('valorCorregido: $valorCorregido, ')
          ..write('validadoPorLocalId: $validadoPorLocalId, ')
          ..write('validadoEn: $validadoEn, ')
          ..write('creadoEn: $creadoEn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InformesTable extends Informes with TableInfo<$InformesTable, Informe> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InformesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _visitaIdMeta = const VerificationMeta(
    'visitaId',
  );
  @override
  late final GeneratedColumn<String> visitaId = GeneratedColumn<String>(
    'visita_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tituloMeta = const VerificationMeta('titulo');
  @override
  late final GeneratedColumn<String> titulo = GeneratedColumn<String>(
    'titulo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Resumen para el agricultor'),
  );
  static const VerificationMeta _contenidoMeta = const VerificationMeta(
    'contenido',
  );
  @override
  late final GeneratedColumn<String> contenido = GeneratedColumn<String>(
    'contenido',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _generadoEnMeta = const VerificationMeta(
    'generadoEn',
  );
  @override
  late final GeneratedColumn<DateTime> generadoEn = GeneratedColumn<DateTime>(
    'generado_en',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modeloMeta = const VerificationMeta('modelo');
  @override
  late final GeneratedColumn<String> modelo = GeneratedColumn<String>(
    'modelo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _entregadoMeta = const VerificationMeta(
    'entregado',
  );
  @override
  late final GeneratedColumn<bool> entregado = GeneratedColumn<bool>(
    'entregado',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("entregado" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _medioEntregaMeta = const VerificationMeta(
    'medioEntrega',
  );
  @override
  late final GeneratedColumn<String> medioEntrega = GeneratedColumn<String>(
    'medio_entrega',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pdfPathMeta = const VerificationMeta(
    'pdfPath',
  );
  @override
  late final GeneratedColumn<String> pdfPath = GeneratedColumn<String>(
    'pdf_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _enlacePdfMeta = const VerificationMeta(
    'enlacePdf',
  );
  @override
  late final GeneratedColumn<String> enlacePdf = GeneratedColumn<String>(
    'enlace_pdf',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sincronizadoMeta = const VerificationMeta(
    'sincronizado',
  );
  @override
  late final GeneratedColumn<bool> sincronizado = GeneratedColumn<bool>(
    'sincronizado',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sincronizado" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    visitaId,
    titulo,
    tipo,
    contenido,
    version,
    generadoEn,
    modelo,
    entregado,
    medioEntrega,
    pdfPath,
    enlacePdf,
    remoteId,
    sincronizado,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'informes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Informe> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('visita_id')) {
      context.handle(
        _visitaIdMeta,
        visitaId.isAcceptableOrUnknown(data['visita_id']!, _visitaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_visitaIdMeta);
    }
    if (data.containsKey('titulo')) {
      context.handle(
        _tituloMeta,
        titulo.isAcceptableOrUnknown(data['titulo']!, _tituloMeta),
      );
    } else if (isInserting) {
      context.missing(_tituloMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    }
    if (data.containsKey('contenido')) {
      context.handle(
        _contenidoMeta,
        contenido.isAcceptableOrUnknown(data['contenido']!, _contenidoMeta),
      );
    } else if (isInserting) {
      context.missing(_contenidoMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('generado_en')) {
      context.handle(
        _generadoEnMeta,
        generadoEn.isAcceptableOrUnknown(data['generado_en']!, _generadoEnMeta),
      );
    } else if (isInserting) {
      context.missing(_generadoEnMeta);
    }
    if (data.containsKey('modelo')) {
      context.handle(
        _modeloMeta,
        modelo.isAcceptableOrUnknown(data['modelo']!, _modeloMeta),
      );
    }
    if (data.containsKey('entregado')) {
      context.handle(
        _entregadoMeta,
        entregado.isAcceptableOrUnknown(data['entregado']!, _entregadoMeta),
      );
    }
    if (data.containsKey('medio_entrega')) {
      context.handle(
        _medioEntregaMeta,
        medioEntrega.isAcceptableOrUnknown(
          data['medio_entrega']!,
          _medioEntregaMeta,
        ),
      );
    }
    if (data.containsKey('pdf_path')) {
      context.handle(
        _pdfPathMeta,
        pdfPath.isAcceptableOrUnknown(data['pdf_path']!, _pdfPathMeta),
      );
    }
    if (data.containsKey('enlace_pdf')) {
      context.handle(
        _enlacePdfMeta,
        enlacePdf.isAcceptableOrUnknown(data['enlace_pdf']!, _enlacePdfMeta),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('sincronizado')) {
      context.handle(
        _sincronizadoMeta,
        sincronizado.isAcceptableOrUnknown(
          data['sincronizado']!,
          _sincronizadoMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Informe map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Informe(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      visitaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visita_id'],
      )!,
      titulo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}titulo'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
      contenido: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contenido'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      generadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}generado_en'],
      )!,
      modelo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}modelo'],
      ),
      entregado: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}entregado'],
      )!,
      medioEntrega: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medio_entrega'],
      ),
      pdfPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pdf_path'],
      ),
      enlacePdf: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}enlace_pdf'],
      ),
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      sincronizado: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sincronizado'],
      )!,
    );
  }

  @override
  $InformesTable createAlias(String alias) {
    return $InformesTable(attachedDatabase, alias);
  }
}

class Informe extends DataClass implements Insertable<Informe> {
  final String id;
  final String visitaId;
  final String titulo;
  final String tipo;

  /// Markdown. Se guarda el texto y no un PDF: desde aqui se regenera el
  /// documento sin volver a pagarle al modelo.
  final String contenido;

  /// Sube en cada regeneracion. El anterior no se borra: si el visitador
  /// regenera y el nuevo sale peor, el que ya le mostro al productor sigue ahi.
  final int version;
  final DateTime generadoEn;
  final String? modelo;
  final bool entregado;
  final String? medioEntrega;

  /// El PDF armado, en disco. Se guarda el archivo y no solo el markdown
  /// porque es el documento que el productor tiene en la mano: regenerarlo
  /// meses despues con otra version del renderizador daria otro papel, y el
  /// que respalda lo acordado es este.
  final String? pdfPath;

  /// URL del PDF en el bucket. Nula hasta que la cola lo sube: el PDF va por
  /// su propio item y puede quedar pendiente cuando la visita ya subio.
  final String? enlacePdf;
  final String? remoteId;
  final bool sincronizado;
  const Informe({
    required this.id,
    required this.visitaId,
    required this.titulo,
    required this.tipo,
    required this.contenido,
    required this.version,
    required this.generadoEn,
    this.modelo,
    required this.entregado,
    this.medioEntrega,
    this.pdfPath,
    this.enlacePdf,
    this.remoteId,
    required this.sincronizado,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['visita_id'] = Variable<String>(visitaId);
    map['titulo'] = Variable<String>(titulo);
    map['tipo'] = Variable<String>(tipo);
    map['contenido'] = Variable<String>(contenido);
    map['version'] = Variable<int>(version);
    map['generado_en'] = Variable<DateTime>(generadoEn);
    if (!nullToAbsent || modelo != null) {
      map['modelo'] = Variable<String>(modelo);
    }
    map['entregado'] = Variable<bool>(entregado);
    if (!nullToAbsent || medioEntrega != null) {
      map['medio_entrega'] = Variable<String>(medioEntrega);
    }
    if (!nullToAbsent || pdfPath != null) {
      map['pdf_path'] = Variable<String>(pdfPath);
    }
    if (!nullToAbsent || enlacePdf != null) {
      map['enlace_pdf'] = Variable<String>(enlacePdf);
    }
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['sincronizado'] = Variable<bool>(sincronizado);
    return map;
  }

  InformesCompanion toCompanion(bool nullToAbsent) {
    return InformesCompanion(
      id: Value(id),
      visitaId: Value(visitaId),
      titulo: Value(titulo),
      tipo: Value(tipo),
      contenido: Value(contenido),
      version: Value(version),
      generadoEn: Value(generadoEn),
      modelo: modelo == null && nullToAbsent
          ? const Value.absent()
          : Value(modelo),
      entregado: Value(entregado),
      medioEntrega: medioEntrega == null && nullToAbsent
          ? const Value.absent()
          : Value(medioEntrega),
      pdfPath: pdfPath == null && nullToAbsent
          ? const Value.absent()
          : Value(pdfPath),
      enlacePdf: enlacePdf == null && nullToAbsent
          ? const Value.absent()
          : Value(enlacePdf),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      sincronizado: Value(sincronizado),
    );
  }

  factory Informe.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Informe(
      id: serializer.fromJson<String>(json['id']),
      visitaId: serializer.fromJson<String>(json['visitaId']),
      titulo: serializer.fromJson<String>(json['titulo']),
      tipo: serializer.fromJson<String>(json['tipo']),
      contenido: serializer.fromJson<String>(json['contenido']),
      version: serializer.fromJson<int>(json['version']),
      generadoEn: serializer.fromJson<DateTime>(json['generadoEn']),
      modelo: serializer.fromJson<String?>(json['modelo']),
      entregado: serializer.fromJson<bool>(json['entregado']),
      medioEntrega: serializer.fromJson<String?>(json['medioEntrega']),
      pdfPath: serializer.fromJson<String?>(json['pdfPath']),
      enlacePdf: serializer.fromJson<String?>(json['enlacePdf']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      sincronizado: serializer.fromJson<bool>(json['sincronizado']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'visitaId': serializer.toJson<String>(visitaId),
      'titulo': serializer.toJson<String>(titulo),
      'tipo': serializer.toJson<String>(tipo),
      'contenido': serializer.toJson<String>(contenido),
      'version': serializer.toJson<int>(version),
      'generadoEn': serializer.toJson<DateTime>(generadoEn),
      'modelo': serializer.toJson<String?>(modelo),
      'entregado': serializer.toJson<bool>(entregado),
      'medioEntrega': serializer.toJson<String?>(medioEntrega),
      'pdfPath': serializer.toJson<String?>(pdfPath),
      'enlacePdf': serializer.toJson<String?>(enlacePdf),
      'remoteId': serializer.toJson<String?>(remoteId),
      'sincronizado': serializer.toJson<bool>(sincronizado),
    };
  }

  Informe copyWith({
    String? id,
    String? visitaId,
    String? titulo,
    String? tipo,
    String? contenido,
    int? version,
    DateTime? generadoEn,
    Value<String?> modelo = const Value.absent(),
    bool? entregado,
    Value<String?> medioEntrega = const Value.absent(),
    Value<String?> pdfPath = const Value.absent(),
    Value<String?> enlacePdf = const Value.absent(),
    Value<String?> remoteId = const Value.absent(),
    bool? sincronizado,
  }) => Informe(
    id: id ?? this.id,
    visitaId: visitaId ?? this.visitaId,
    titulo: titulo ?? this.titulo,
    tipo: tipo ?? this.tipo,
    contenido: contenido ?? this.contenido,
    version: version ?? this.version,
    generadoEn: generadoEn ?? this.generadoEn,
    modelo: modelo.present ? modelo.value : this.modelo,
    entregado: entregado ?? this.entregado,
    medioEntrega: medioEntrega.present ? medioEntrega.value : this.medioEntrega,
    pdfPath: pdfPath.present ? pdfPath.value : this.pdfPath,
    enlacePdf: enlacePdf.present ? enlacePdf.value : this.enlacePdf,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    sincronizado: sincronizado ?? this.sincronizado,
  );
  Informe copyWithCompanion(InformesCompanion data) {
    return Informe(
      id: data.id.present ? data.id.value : this.id,
      visitaId: data.visitaId.present ? data.visitaId.value : this.visitaId,
      titulo: data.titulo.present ? data.titulo.value : this.titulo,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      contenido: data.contenido.present ? data.contenido.value : this.contenido,
      version: data.version.present ? data.version.value : this.version,
      generadoEn: data.generadoEn.present
          ? data.generadoEn.value
          : this.generadoEn,
      modelo: data.modelo.present ? data.modelo.value : this.modelo,
      entregado: data.entregado.present ? data.entregado.value : this.entregado,
      medioEntrega: data.medioEntrega.present
          ? data.medioEntrega.value
          : this.medioEntrega,
      pdfPath: data.pdfPath.present ? data.pdfPath.value : this.pdfPath,
      enlacePdf: data.enlacePdf.present ? data.enlacePdf.value : this.enlacePdf,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      sincronizado: data.sincronizado.present
          ? data.sincronizado.value
          : this.sincronizado,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Informe(')
          ..write('id: $id, ')
          ..write('visitaId: $visitaId, ')
          ..write('titulo: $titulo, ')
          ..write('tipo: $tipo, ')
          ..write('contenido: $contenido, ')
          ..write('version: $version, ')
          ..write('generadoEn: $generadoEn, ')
          ..write('modelo: $modelo, ')
          ..write('entregado: $entregado, ')
          ..write('medioEntrega: $medioEntrega, ')
          ..write('pdfPath: $pdfPath, ')
          ..write('enlacePdf: $enlacePdf, ')
          ..write('remoteId: $remoteId, ')
          ..write('sincronizado: $sincronizado')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    visitaId,
    titulo,
    tipo,
    contenido,
    version,
    generadoEn,
    modelo,
    entregado,
    medioEntrega,
    pdfPath,
    enlacePdf,
    remoteId,
    sincronizado,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Informe &&
          other.id == this.id &&
          other.visitaId == this.visitaId &&
          other.titulo == this.titulo &&
          other.tipo == this.tipo &&
          other.contenido == this.contenido &&
          other.version == this.version &&
          other.generadoEn == this.generadoEn &&
          other.modelo == this.modelo &&
          other.entregado == this.entregado &&
          other.medioEntrega == this.medioEntrega &&
          other.pdfPath == this.pdfPath &&
          other.enlacePdf == this.enlacePdf &&
          other.remoteId == this.remoteId &&
          other.sincronizado == this.sincronizado);
}

class InformesCompanion extends UpdateCompanion<Informe> {
  final Value<String> id;
  final Value<String> visitaId;
  final Value<String> titulo;
  final Value<String> tipo;
  final Value<String> contenido;
  final Value<int> version;
  final Value<DateTime> generadoEn;
  final Value<String?> modelo;
  final Value<bool> entregado;
  final Value<String?> medioEntrega;
  final Value<String?> pdfPath;
  final Value<String?> enlacePdf;
  final Value<String?> remoteId;
  final Value<bool> sincronizado;
  final Value<int> rowid;
  const InformesCompanion({
    this.id = const Value.absent(),
    this.visitaId = const Value.absent(),
    this.titulo = const Value.absent(),
    this.tipo = const Value.absent(),
    this.contenido = const Value.absent(),
    this.version = const Value.absent(),
    this.generadoEn = const Value.absent(),
    this.modelo = const Value.absent(),
    this.entregado = const Value.absent(),
    this.medioEntrega = const Value.absent(),
    this.pdfPath = const Value.absent(),
    this.enlacePdf = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.sincronizado = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InformesCompanion.insert({
    required String id,
    required String visitaId,
    required String titulo,
    this.tipo = const Value.absent(),
    required String contenido,
    this.version = const Value.absent(),
    required DateTime generadoEn,
    this.modelo = const Value.absent(),
    this.entregado = const Value.absent(),
    this.medioEntrega = const Value.absent(),
    this.pdfPath = const Value.absent(),
    this.enlacePdf = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.sincronizado = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       visitaId = Value(visitaId),
       titulo = Value(titulo),
       contenido = Value(contenido),
       generadoEn = Value(generadoEn);
  static Insertable<Informe> custom({
    Expression<String>? id,
    Expression<String>? visitaId,
    Expression<String>? titulo,
    Expression<String>? tipo,
    Expression<String>? contenido,
    Expression<int>? version,
    Expression<DateTime>? generadoEn,
    Expression<String>? modelo,
    Expression<bool>? entregado,
    Expression<String>? medioEntrega,
    Expression<String>? pdfPath,
    Expression<String>? enlacePdf,
    Expression<String>? remoteId,
    Expression<bool>? sincronizado,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (visitaId != null) 'visita_id': visitaId,
      if (titulo != null) 'titulo': titulo,
      if (tipo != null) 'tipo': tipo,
      if (contenido != null) 'contenido': contenido,
      if (version != null) 'version': version,
      if (generadoEn != null) 'generado_en': generadoEn,
      if (modelo != null) 'modelo': modelo,
      if (entregado != null) 'entregado': entregado,
      if (medioEntrega != null) 'medio_entrega': medioEntrega,
      if (pdfPath != null) 'pdf_path': pdfPath,
      if (enlacePdf != null) 'enlace_pdf': enlacePdf,
      if (remoteId != null) 'remote_id': remoteId,
      if (sincronizado != null) 'sincronizado': sincronizado,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InformesCompanion copyWith({
    Value<String>? id,
    Value<String>? visitaId,
    Value<String>? titulo,
    Value<String>? tipo,
    Value<String>? contenido,
    Value<int>? version,
    Value<DateTime>? generadoEn,
    Value<String?>? modelo,
    Value<bool>? entregado,
    Value<String?>? medioEntrega,
    Value<String?>? pdfPath,
    Value<String?>? enlacePdf,
    Value<String?>? remoteId,
    Value<bool>? sincronizado,
    Value<int>? rowid,
  }) {
    return InformesCompanion(
      id: id ?? this.id,
      visitaId: visitaId ?? this.visitaId,
      titulo: titulo ?? this.titulo,
      tipo: tipo ?? this.tipo,
      contenido: contenido ?? this.contenido,
      version: version ?? this.version,
      generadoEn: generadoEn ?? this.generadoEn,
      modelo: modelo ?? this.modelo,
      entregado: entregado ?? this.entregado,
      medioEntrega: medioEntrega ?? this.medioEntrega,
      pdfPath: pdfPath ?? this.pdfPath,
      enlacePdf: enlacePdf ?? this.enlacePdf,
      remoteId: remoteId ?? this.remoteId,
      sincronizado: sincronizado ?? this.sincronizado,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (visitaId.present) {
      map['visita_id'] = Variable<String>(visitaId.value);
    }
    if (titulo.present) {
      map['titulo'] = Variable<String>(titulo.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (contenido.present) {
      map['contenido'] = Variable<String>(contenido.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (generadoEn.present) {
      map['generado_en'] = Variable<DateTime>(generadoEn.value);
    }
    if (modelo.present) {
      map['modelo'] = Variable<String>(modelo.value);
    }
    if (entregado.present) {
      map['entregado'] = Variable<bool>(entregado.value);
    }
    if (medioEntrega.present) {
      map['medio_entrega'] = Variable<String>(medioEntrega.value);
    }
    if (pdfPath.present) {
      map['pdf_path'] = Variable<String>(pdfPath.value);
    }
    if (enlacePdf.present) {
      map['enlace_pdf'] = Variable<String>(enlacePdf.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (sincronizado.present) {
      map['sincronizado'] = Variable<bool>(sincronizado.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InformesCompanion(')
          ..write('id: $id, ')
          ..write('visitaId: $visitaId, ')
          ..write('titulo: $titulo, ')
          ..write('tipo: $tipo, ')
          ..write('contenido: $contenido, ')
          ..write('version: $version, ')
          ..write('generadoEn: $generadoEn, ')
          ..write('modelo: $modelo, ')
          ..write('entregado: $entregado, ')
          ..write('medioEntrega: $medioEntrega, ')
          ..write('pdfPath: $pdfPath, ')
          ..write('enlacePdf: $enlacePdf, ')
          ..write('remoteId: $remoteId, ')
          ..write('sincronizado: $sincronizado, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TrazadosTable extends Trazados with TableInfo<$TrazadosTable, Trazado> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrazadosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _visitaIdMeta = const VerificationMeta(
    'visitaId',
  );
  @override
  late final GeneratedColumn<String> visitaId = GeneratedColumn<String>(
    'visita_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TipoTrazado, String> tipo =
      GeneratedColumn<String>(
        'tipo',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('Poligono'),
      ).withConverter<TipoTrazado>($TrazadosTable.$convertertipo);
  @override
  late final GeneratedColumnWithTypeConverter<ModoCaptura, String> modoCaptura =
      GeneratedColumn<String>(
        'modo_captura',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('Manual'),
      ).withConverter<ModoCaptura>($TrazadosTable.$convertermodoCaptura);
  static const VerificationMeta _etiquetaMeta = const VerificationMeta(
    'etiqueta',
  );
  @override
  late final GeneratedColumn<String> etiqueta = GeneratedColumn<String>(
    'etiqueta',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notasMeta = const VerificationMeta('notas');
  @override
  late final GeneratedColumn<String> notas = GeneratedColumn<String>(
    'notas',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _intervaloSegMeta = const VerificationMeta(
    'intervaloSeg',
  );
  @override
  late final GeneratedColumn<int> intervaloSeg = GeneratedColumn<int>(
    'intervalo_seg',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _distanciaMinMMeta = const VerificationMeta(
    'distanciaMinM',
  );
  @override
  late final GeneratedColumn<double> distanciaMinM = GeneratedColumn<double>(
    'distancia_min_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _precisionMaxMMeta = const VerificationMeta(
    'precisionMaxM',
  );
  @override
  late final GeneratedColumn<double> precisionMaxM = GeneratedColumn<double>(
    'precision_max_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cerradoMeta = const VerificationMeta(
    'cerrado',
  );
  @override
  late final GeneratedColumn<bool> cerrado = GeneratedColumn<bool>(
    'cerrado',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("cerrado" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _areaM2Meta = const VerificationMeta('areaM2');
  @override
  late final GeneratedColumn<double> areaM2 = GeneratedColumn<double>(
    'area_m2',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _perimetroMMeta = const VerificationMeta(
    'perimetroM',
  );
  @override
  late final GeneratedColumn<double> perimetroM = GeneratedColumn<double>(
    'perimetro_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _creadoEnMeta = const VerificationMeta(
    'creadoEn',
  );
  @override
  late final GeneratedColumn<DateTime> creadoEn = GeneratedColumn<DateTime>(
    'creado_en',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actualizadoEnMeta = const VerificationMeta(
    'actualizadoEn',
  );
  @override
  late final GeneratedColumn<DateTime> actualizadoEn =
      GeneratedColumn<DateTime>(
        'actualizado_en',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sincronizadoMeta = const VerificationMeta(
    'sincronizado',
  );
  @override
  late final GeneratedColumn<bool> sincronizado = GeneratedColumn<bool>(
    'sincronizado',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sincronizado" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    visitaId,
    nombre,
    tipo,
    modoCaptura,
    etiqueta,
    notas,
    intervaloSeg,
    distanciaMinM,
    precisionMaxM,
    cerrado,
    areaM2,
    perimetroM,
    creadoEn,
    actualizadoEn,
    remoteId,
    sincronizado,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trazados';
  @override
  VerificationContext validateIntegrity(
    Insertable<Trazado> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('visita_id')) {
      context.handle(
        _visitaIdMeta,
        visitaId.isAcceptableOrUnknown(data['visita_id']!, _visitaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_visitaIdMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('etiqueta')) {
      context.handle(
        _etiquetaMeta,
        etiqueta.isAcceptableOrUnknown(data['etiqueta']!, _etiquetaMeta),
      );
    }
    if (data.containsKey('notas')) {
      context.handle(
        _notasMeta,
        notas.isAcceptableOrUnknown(data['notas']!, _notasMeta),
      );
    }
    if (data.containsKey('intervalo_seg')) {
      context.handle(
        _intervaloSegMeta,
        intervaloSeg.isAcceptableOrUnknown(
          data['intervalo_seg']!,
          _intervaloSegMeta,
        ),
      );
    }
    if (data.containsKey('distancia_min_m')) {
      context.handle(
        _distanciaMinMMeta,
        distanciaMinM.isAcceptableOrUnknown(
          data['distancia_min_m']!,
          _distanciaMinMMeta,
        ),
      );
    }
    if (data.containsKey('precision_max_m')) {
      context.handle(
        _precisionMaxMMeta,
        precisionMaxM.isAcceptableOrUnknown(
          data['precision_max_m']!,
          _precisionMaxMMeta,
        ),
      );
    }
    if (data.containsKey('cerrado')) {
      context.handle(
        _cerradoMeta,
        cerrado.isAcceptableOrUnknown(data['cerrado']!, _cerradoMeta),
      );
    }
    if (data.containsKey('area_m2')) {
      context.handle(
        _areaM2Meta,
        areaM2.isAcceptableOrUnknown(data['area_m2']!, _areaM2Meta),
      );
    }
    if (data.containsKey('perimetro_m')) {
      context.handle(
        _perimetroMMeta,
        perimetroM.isAcceptableOrUnknown(data['perimetro_m']!, _perimetroMMeta),
      );
    }
    if (data.containsKey('creado_en')) {
      context.handle(
        _creadoEnMeta,
        creadoEn.isAcceptableOrUnknown(data['creado_en']!, _creadoEnMeta),
      );
    } else if (isInserting) {
      context.missing(_creadoEnMeta);
    }
    if (data.containsKey('actualizado_en')) {
      context.handle(
        _actualizadoEnMeta,
        actualizadoEn.isAcceptableOrUnknown(
          data['actualizado_en']!,
          _actualizadoEnMeta,
        ),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('sincronizado')) {
      context.handle(
        _sincronizadoMeta,
        sincronizado.isAcceptableOrUnknown(
          data['sincronizado']!,
          _sincronizadoMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Trazado map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Trazado(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      visitaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visita_id'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      tipo: $TrazadosTable.$convertertipo.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}tipo'],
        )!,
      ),
      modoCaptura: $TrazadosTable.$convertermodoCaptura.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}modo_captura'],
        )!,
      ),
      etiqueta: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etiqueta'],
      ),
      notas: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notas'],
      ),
      intervaloSeg: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}intervalo_seg'],
      ),
      distanciaMinM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distancia_min_m'],
      ),
      precisionMaxM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}precision_max_m'],
      ),
      cerrado: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}cerrado'],
      )!,
      areaM2: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}area_m2'],
      ),
      perimetroM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}perimetro_m'],
      ),
      creadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}creado_en'],
      )!,
      actualizadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}actualizado_en'],
      ),
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      sincronizado: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sincronizado'],
      )!,
    );
  }

  @override
  $TrazadosTable createAlias(String alias) {
    return $TrazadosTable(attachedDatabase, alias);
  }

  static TypeConverter<TipoTrazado, String> $convertertipo =
      const TipoTrazadoConverter();
  static TypeConverter<ModoCaptura, String> $convertermodoCaptura =
      const ModoCapturaConverter();
}

class Trazado extends DataClass implements Insertable<Trazado> {
  final String id;
  final String visitaId;

  /// Como lo llama el visitador: «Lote de arriba», «lindero con el vecino».
  final String nombre;
  final TipoTrazado tipo;
  final ModoCaptura modoCaptura;

  /// Que hay sembrado ahi. Texto libre a proposito: el cultivo tambien sale de
  /// la conversacion, y obligar a elegir de una lista en el potrero es como
  /// volver a la encuesta.
  final String? etiqueta;
  final String? notas;

  /// Cada cuantos segundos se pone un punto en modo automatico. null o 0
  /// significa que este trazado no captura solo.
  final int? intervaloSeg;

  /// Si el punto nuevo esta a menos de esto del anterior, no se guarda. Es lo
  /// que evita que estar parado hablando dos minutos deje cuarenta puntos
  /// encimados que le inventan forma al lote.
  final double? distanciaMinM;

  /// Se rechaza el punto cuya precision reportada sea peor que esto. Un punto
  /// con 60 m de error mueve un lindero mas de lo que mide el lote.
  final double? precisionMaxM;

  /// El anillo se cierra. Lo decide el visitador: mientras sea false, el
  /// trazado sale al KML como linea, porque un poligono que nadie cerro no es
  /// un lote — es un recorrido a medias.
  final bool cerrado;

  /// Recalculadas en cada cambio de puntos. Se persisten para que la lista de
  /// trazados no tenga que recorrer todos los puntos de todos los lotes para
  /// mostrar un area.
  final double? areaM2;
  final double? perimetroM;
  final DateTime creadoEn;
  final DateTime? actualizadoEn;
  final String? remoteId;
  final bool sincronizado;
  const Trazado({
    required this.id,
    required this.visitaId,
    required this.nombre,
    required this.tipo,
    required this.modoCaptura,
    this.etiqueta,
    this.notas,
    this.intervaloSeg,
    this.distanciaMinM,
    this.precisionMaxM,
    required this.cerrado,
    this.areaM2,
    this.perimetroM,
    required this.creadoEn,
    this.actualizadoEn,
    this.remoteId,
    required this.sincronizado,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['visita_id'] = Variable<String>(visitaId);
    map['nombre'] = Variable<String>(nombre);
    {
      map['tipo'] = Variable<String>($TrazadosTable.$convertertipo.toSql(tipo));
    }
    {
      map['modo_captura'] = Variable<String>(
        $TrazadosTable.$convertermodoCaptura.toSql(modoCaptura),
      );
    }
    if (!nullToAbsent || etiqueta != null) {
      map['etiqueta'] = Variable<String>(etiqueta);
    }
    if (!nullToAbsent || notas != null) {
      map['notas'] = Variable<String>(notas);
    }
    if (!nullToAbsent || intervaloSeg != null) {
      map['intervalo_seg'] = Variable<int>(intervaloSeg);
    }
    if (!nullToAbsent || distanciaMinM != null) {
      map['distancia_min_m'] = Variable<double>(distanciaMinM);
    }
    if (!nullToAbsent || precisionMaxM != null) {
      map['precision_max_m'] = Variable<double>(precisionMaxM);
    }
    map['cerrado'] = Variable<bool>(cerrado);
    if (!nullToAbsent || areaM2 != null) {
      map['area_m2'] = Variable<double>(areaM2);
    }
    if (!nullToAbsent || perimetroM != null) {
      map['perimetro_m'] = Variable<double>(perimetroM);
    }
    map['creado_en'] = Variable<DateTime>(creadoEn);
    if (!nullToAbsent || actualizadoEn != null) {
      map['actualizado_en'] = Variable<DateTime>(actualizadoEn);
    }
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['sincronizado'] = Variable<bool>(sincronizado);
    return map;
  }

  TrazadosCompanion toCompanion(bool nullToAbsent) {
    return TrazadosCompanion(
      id: Value(id),
      visitaId: Value(visitaId),
      nombre: Value(nombre),
      tipo: Value(tipo),
      modoCaptura: Value(modoCaptura),
      etiqueta: etiqueta == null && nullToAbsent
          ? const Value.absent()
          : Value(etiqueta),
      notas: notas == null && nullToAbsent
          ? const Value.absent()
          : Value(notas),
      intervaloSeg: intervaloSeg == null && nullToAbsent
          ? const Value.absent()
          : Value(intervaloSeg),
      distanciaMinM: distanciaMinM == null && nullToAbsent
          ? const Value.absent()
          : Value(distanciaMinM),
      precisionMaxM: precisionMaxM == null && nullToAbsent
          ? const Value.absent()
          : Value(precisionMaxM),
      cerrado: Value(cerrado),
      areaM2: areaM2 == null && nullToAbsent
          ? const Value.absent()
          : Value(areaM2),
      perimetroM: perimetroM == null && nullToAbsent
          ? const Value.absent()
          : Value(perimetroM),
      creadoEn: Value(creadoEn),
      actualizadoEn: actualizadoEn == null && nullToAbsent
          ? const Value.absent()
          : Value(actualizadoEn),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      sincronizado: Value(sincronizado),
    );
  }

  factory Trazado.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Trazado(
      id: serializer.fromJson<String>(json['id']),
      visitaId: serializer.fromJson<String>(json['visitaId']),
      nombre: serializer.fromJson<String>(json['nombre']),
      tipo: serializer.fromJson<TipoTrazado>(json['tipo']),
      modoCaptura: serializer.fromJson<ModoCaptura>(json['modoCaptura']),
      etiqueta: serializer.fromJson<String?>(json['etiqueta']),
      notas: serializer.fromJson<String?>(json['notas']),
      intervaloSeg: serializer.fromJson<int?>(json['intervaloSeg']),
      distanciaMinM: serializer.fromJson<double?>(json['distanciaMinM']),
      precisionMaxM: serializer.fromJson<double?>(json['precisionMaxM']),
      cerrado: serializer.fromJson<bool>(json['cerrado']),
      areaM2: serializer.fromJson<double?>(json['areaM2']),
      perimetroM: serializer.fromJson<double?>(json['perimetroM']),
      creadoEn: serializer.fromJson<DateTime>(json['creadoEn']),
      actualizadoEn: serializer.fromJson<DateTime?>(json['actualizadoEn']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      sincronizado: serializer.fromJson<bool>(json['sincronizado']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'visitaId': serializer.toJson<String>(visitaId),
      'nombre': serializer.toJson<String>(nombre),
      'tipo': serializer.toJson<TipoTrazado>(tipo),
      'modoCaptura': serializer.toJson<ModoCaptura>(modoCaptura),
      'etiqueta': serializer.toJson<String?>(etiqueta),
      'notas': serializer.toJson<String?>(notas),
      'intervaloSeg': serializer.toJson<int?>(intervaloSeg),
      'distanciaMinM': serializer.toJson<double?>(distanciaMinM),
      'precisionMaxM': serializer.toJson<double?>(precisionMaxM),
      'cerrado': serializer.toJson<bool>(cerrado),
      'areaM2': serializer.toJson<double?>(areaM2),
      'perimetroM': serializer.toJson<double?>(perimetroM),
      'creadoEn': serializer.toJson<DateTime>(creadoEn),
      'actualizadoEn': serializer.toJson<DateTime?>(actualizadoEn),
      'remoteId': serializer.toJson<String?>(remoteId),
      'sincronizado': serializer.toJson<bool>(sincronizado),
    };
  }

  Trazado copyWith({
    String? id,
    String? visitaId,
    String? nombre,
    TipoTrazado? tipo,
    ModoCaptura? modoCaptura,
    Value<String?> etiqueta = const Value.absent(),
    Value<String?> notas = const Value.absent(),
    Value<int?> intervaloSeg = const Value.absent(),
    Value<double?> distanciaMinM = const Value.absent(),
    Value<double?> precisionMaxM = const Value.absent(),
    bool? cerrado,
    Value<double?> areaM2 = const Value.absent(),
    Value<double?> perimetroM = const Value.absent(),
    DateTime? creadoEn,
    Value<DateTime?> actualizadoEn = const Value.absent(),
    Value<String?> remoteId = const Value.absent(),
    bool? sincronizado,
  }) => Trazado(
    id: id ?? this.id,
    visitaId: visitaId ?? this.visitaId,
    nombre: nombre ?? this.nombre,
    tipo: tipo ?? this.tipo,
    modoCaptura: modoCaptura ?? this.modoCaptura,
    etiqueta: etiqueta.present ? etiqueta.value : this.etiqueta,
    notas: notas.present ? notas.value : this.notas,
    intervaloSeg: intervaloSeg.present ? intervaloSeg.value : this.intervaloSeg,
    distanciaMinM: distanciaMinM.present
        ? distanciaMinM.value
        : this.distanciaMinM,
    precisionMaxM: precisionMaxM.present
        ? precisionMaxM.value
        : this.precisionMaxM,
    cerrado: cerrado ?? this.cerrado,
    areaM2: areaM2.present ? areaM2.value : this.areaM2,
    perimetroM: perimetroM.present ? perimetroM.value : this.perimetroM,
    creadoEn: creadoEn ?? this.creadoEn,
    actualizadoEn: actualizadoEn.present
        ? actualizadoEn.value
        : this.actualizadoEn,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    sincronizado: sincronizado ?? this.sincronizado,
  );
  Trazado copyWithCompanion(TrazadosCompanion data) {
    return Trazado(
      id: data.id.present ? data.id.value : this.id,
      visitaId: data.visitaId.present ? data.visitaId.value : this.visitaId,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      modoCaptura: data.modoCaptura.present
          ? data.modoCaptura.value
          : this.modoCaptura,
      etiqueta: data.etiqueta.present ? data.etiqueta.value : this.etiqueta,
      notas: data.notas.present ? data.notas.value : this.notas,
      intervaloSeg: data.intervaloSeg.present
          ? data.intervaloSeg.value
          : this.intervaloSeg,
      distanciaMinM: data.distanciaMinM.present
          ? data.distanciaMinM.value
          : this.distanciaMinM,
      precisionMaxM: data.precisionMaxM.present
          ? data.precisionMaxM.value
          : this.precisionMaxM,
      cerrado: data.cerrado.present ? data.cerrado.value : this.cerrado,
      areaM2: data.areaM2.present ? data.areaM2.value : this.areaM2,
      perimetroM: data.perimetroM.present
          ? data.perimetroM.value
          : this.perimetroM,
      creadoEn: data.creadoEn.present ? data.creadoEn.value : this.creadoEn,
      actualizadoEn: data.actualizadoEn.present
          ? data.actualizadoEn.value
          : this.actualizadoEn,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      sincronizado: data.sincronizado.present
          ? data.sincronizado.value
          : this.sincronizado,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Trazado(')
          ..write('id: $id, ')
          ..write('visitaId: $visitaId, ')
          ..write('nombre: $nombre, ')
          ..write('tipo: $tipo, ')
          ..write('modoCaptura: $modoCaptura, ')
          ..write('etiqueta: $etiqueta, ')
          ..write('notas: $notas, ')
          ..write('intervaloSeg: $intervaloSeg, ')
          ..write('distanciaMinM: $distanciaMinM, ')
          ..write('precisionMaxM: $precisionMaxM, ')
          ..write('cerrado: $cerrado, ')
          ..write('areaM2: $areaM2, ')
          ..write('perimetroM: $perimetroM, ')
          ..write('creadoEn: $creadoEn, ')
          ..write('actualizadoEn: $actualizadoEn, ')
          ..write('remoteId: $remoteId, ')
          ..write('sincronizado: $sincronizado')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    visitaId,
    nombre,
    tipo,
    modoCaptura,
    etiqueta,
    notas,
    intervaloSeg,
    distanciaMinM,
    precisionMaxM,
    cerrado,
    areaM2,
    perimetroM,
    creadoEn,
    actualizadoEn,
    remoteId,
    sincronizado,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Trazado &&
          other.id == this.id &&
          other.visitaId == this.visitaId &&
          other.nombre == this.nombre &&
          other.tipo == this.tipo &&
          other.modoCaptura == this.modoCaptura &&
          other.etiqueta == this.etiqueta &&
          other.notas == this.notas &&
          other.intervaloSeg == this.intervaloSeg &&
          other.distanciaMinM == this.distanciaMinM &&
          other.precisionMaxM == this.precisionMaxM &&
          other.cerrado == this.cerrado &&
          other.areaM2 == this.areaM2 &&
          other.perimetroM == this.perimetroM &&
          other.creadoEn == this.creadoEn &&
          other.actualizadoEn == this.actualizadoEn &&
          other.remoteId == this.remoteId &&
          other.sincronizado == this.sincronizado);
}

class TrazadosCompanion extends UpdateCompanion<Trazado> {
  final Value<String> id;
  final Value<String> visitaId;
  final Value<String> nombre;
  final Value<TipoTrazado> tipo;
  final Value<ModoCaptura> modoCaptura;
  final Value<String?> etiqueta;
  final Value<String?> notas;
  final Value<int?> intervaloSeg;
  final Value<double?> distanciaMinM;
  final Value<double?> precisionMaxM;
  final Value<bool> cerrado;
  final Value<double?> areaM2;
  final Value<double?> perimetroM;
  final Value<DateTime> creadoEn;
  final Value<DateTime?> actualizadoEn;
  final Value<String?> remoteId;
  final Value<bool> sincronizado;
  final Value<int> rowid;
  const TrazadosCompanion({
    this.id = const Value.absent(),
    this.visitaId = const Value.absent(),
    this.nombre = const Value.absent(),
    this.tipo = const Value.absent(),
    this.modoCaptura = const Value.absent(),
    this.etiqueta = const Value.absent(),
    this.notas = const Value.absent(),
    this.intervaloSeg = const Value.absent(),
    this.distanciaMinM = const Value.absent(),
    this.precisionMaxM = const Value.absent(),
    this.cerrado = const Value.absent(),
    this.areaM2 = const Value.absent(),
    this.perimetroM = const Value.absent(),
    this.creadoEn = const Value.absent(),
    this.actualizadoEn = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.sincronizado = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrazadosCompanion.insert({
    required String id,
    required String visitaId,
    required String nombre,
    this.tipo = const Value.absent(),
    this.modoCaptura = const Value.absent(),
    this.etiqueta = const Value.absent(),
    this.notas = const Value.absent(),
    this.intervaloSeg = const Value.absent(),
    this.distanciaMinM = const Value.absent(),
    this.precisionMaxM = const Value.absent(),
    this.cerrado = const Value.absent(),
    this.areaM2 = const Value.absent(),
    this.perimetroM = const Value.absent(),
    required DateTime creadoEn,
    this.actualizadoEn = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.sincronizado = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       visitaId = Value(visitaId),
       nombre = Value(nombre),
       creadoEn = Value(creadoEn);
  static Insertable<Trazado> custom({
    Expression<String>? id,
    Expression<String>? visitaId,
    Expression<String>? nombre,
    Expression<String>? tipo,
    Expression<String>? modoCaptura,
    Expression<String>? etiqueta,
    Expression<String>? notas,
    Expression<int>? intervaloSeg,
    Expression<double>? distanciaMinM,
    Expression<double>? precisionMaxM,
    Expression<bool>? cerrado,
    Expression<double>? areaM2,
    Expression<double>? perimetroM,
    Expression<DateTime>? creadoEn,
    Expression<DateTime>? actualizadoEn,
    Expression<String>? remoteId,
    Expression<bool>? sincronizado,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (visitaId != null) 'visita_id': visitaId,
      if (nombre != null) 'nombre': nombre,
      if (tipo != null) 'tipo': tipo,
      if (modoCaptura != null) 'modo_captura': modoCaptura,
      if (etiqueta != null) 'etiqueta': etiqueta,
      if (notas != null) 'notas': notas,
      if (intervaloSeg != null) 'intervalo_seg': intervaloSeg,
      if (distanciaMinM != null) 'distancia_min_m': distanciaMinM,
      if (precisionMaxM != null) 'precision_max_m': precisionMaxM,
      if (cerrado != null) 'cerrado': cerrado,
      if (areaM2 != null) 'area_m2': areaM2,
      if (perimetroM != null) 'perimetro_m': perimetroM,
      if (creadoEn != null) 'creado_en': creadoEn,
      if (actualizadoEn != null) 'actualizado_en': actualizadoEn,
      if (remoteId != null) 'remote_id': remoteId,
      if (sincronizado != null) 'sincronizado': sincronizado,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrazadosCompanion copyWith({
    Value<String>? id,
    Value<String>? visitaId,
    Value<String>? nombre,
    Value<TipoTrazado>? tipo,
    Value<ModoCaptura>? modoCaptura,
    Value<String?>? etiqueta,
    Value<String?>? notas,
    Value<int?>? intervaloSeg,
    Value<double?>? distanciaMinM,
    Value<double?>? precisionMaxM,
    Value<bool>? cerrado,
    Value<double?>? areaM2,
    Value<double?>? perimetroM,
    Value<DateTime>? creadoEn,
    Value<DateTime?>? actualizadoEn,
    Value<String?>? remoteId,
    Value<bool>? sincronizado,
    Value<int>? rowid,
  }) {
    return TrazadosCompanion(
      id: id ?? this.id,
      visitaId: visitaId ?? this.visitaId,
      nombre: nombre ?? this.nombre,
      tipo: tipo ?? this.tipo,
      modoCaptura: modoCaptura ?? this.modoCaptura,
      etiqueta: etiqueta ?? this.etiqueta,
      notas: notas ?? this.notas,
      intervaloSeg: intervaloSeg ?? this.intervaloSeg,
      distanciaMinM: distanciaMinM ?? this.distanciaMinM,
      precisionMaxM: precisionMaxM ?? this.precisionMaxM,
      cerrado: cerrado ?? this.cerrado,
      areaM2: areaM2 ?? this.areaM2,
      perimetroM: perimetroM ?? this.perimetroM,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
      remoteId: remoteId ?? this.remoteId,
      sincronizado: sincronizado ?? this.sincronizado,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (visitaId.present) {
      map['visita_id'] = Variable<String>(visitaId.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(
        $TrazadosTable.$convertertipo.toSql(tipo.value),
      );
    }
    if (modoCaptura.present) {
      map['modo_captura'] = Variable<String>(
        $TrazadosTable.$convertermodoCaptura.toSql(modoCaptura.value),
      );
    }
    if (etiqueta.present) {
      map['etiqueta'] = Variable<String>(etiqueta.value);
    }
    if (notas.present) {
      map['notas'] = Variable<String>(notas.value);
    }
    if (intervaloSeg.present) {
      map['intervalo_seg'] = Variable<int>(intervaloSeg.value);
    }
    if (distanciaMinM.present) {
      map['distancia_min_m'] = Variable<double>(distanciaMinM.value);
    }
    if (precisionMaxM.present) {
      map['precision_max_m'] = Variable<double>(precisionMaxM.value);
    }
    if (cerrado.present) {
      map['cerrado'] = Variable<bool>(cerrado.value);
    }
    if (areaM2.present) {
      map['area_m2'] = Variable<double>(areaM2.value);
    }
    if (perimetroM.present) {
      map['perimetro_m'] = Variable<double>(perimetroM.value);
    }
    if (creadoEn.present) {
      map['creado_en'] = Variable<DateTime>(creadoEn.value);
    }
    if (actualizadoEn.present) {
      map['actualizado_en'] = Variable<DateTime>(actualizadoEn.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (sincronizado.present) {
      map['sincronizado'] = Variable<bool>(sincronizado.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrazadosCompanion(')
          ..write('id: $id, ')
          ..write('visitaId: $visitaId, ')
          ..write('nombre: $nombre, ')
          ..write('tipo: $tipo, ')
          ..write('modoCaptura: $modoCaptura, ')
          ..write('etiqueta: $etiqueta, ')
          ..write('notas: $notas, ')
          ..write('intervaloSeg: $intervaloSeg, ')
          ..write('distanciaMinM: $distanciaMinM, ')
          ..write('precisionMaxM: $precisionMaxM, ')
          ..write('cerrado: $cerrado, ')
          ..write('areaM2: $areaM2, ')
          ..write('perimetroM: $perimetroM, ')
          ..write('creadoEn: $creadoEn, ')
          ..write('actualizadoEn: $actualizadoEn, ')
          ..write('remoteId: $remoteId, ')
          ..write('sincronizado: $sincronizado, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PuntosTrazadoTable extends PuntosTrazado
    with TableInfo<$PuntosTrazadoTable, PuntoTrazado> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PuntosTrazadoTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trazadoIdMeta = const VerificationMeta(
    'trazadoId',
  );
  @override
  late final GeneratedColumn<String> trazadoId = GeneratedColumn<String>(
    'trazado_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ordenMeta = const VerificationMeta('orden');
  @override
  late final GeneratedColumn<int> orden = GeneratedColumn<int>(
    'orden',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudMeta = const VerificationMeta(
    'latitud',
  );
  @override
  late final GeneratedColumn<double> latitud = GeneratedColumn<double>(
    'latitud',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudMeta = const VerificationMeta(
    'longitud',
  );
  @override
  late final GeneratedColumn<double> longitud = GeneratedColumn<double>(
    'longitud',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _altitudMeta = const VerificationMeta(
    'altitud',
  );
  @override
  late final GeneratedColumn<double> altitud = GeneratedColumn<double>(
    'altitud',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _precisionMMeta = const VerificationMeta(
    'precisionM',
  );
  @override
  late final GeneratedColumn<double> precisionM = GeneratedColumn<double>(
    'precision_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _capturadoEnMeta = const VerificationMeta(
    'capturadoEn',
  );
  @override
  late final GeneratedColumn<DateTime> capturadoEn = GeneratedColumn<DateTime>(
    'capturado_en',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _automaticoMeta = const VerificationMeta(
    'automatico',
  );
  @override
  late final GeneratedColumn<bool> automatico = GeneratedColumn<bool>(
    'automatico',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("automatico" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _notaMeta = const VerificationMeta('nota');
  @override
  late final GeneratedColumn<String> nota = GeneratedColumn<String>(
    'nota',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    trazadoId,
    orden,
    latitud,
    longitud,
    altitud,
    precisionM,
    capturadoEn,
    automatico,
    nota,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'puntos_trazado';
  @override
  VerificationContext validateIntegrity(
    Insertable<PuntoTrazado> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('trazado_id')) {
      context.handle(
        _trazadoIdMeta,
        trazadoId.isAcceptableOrUnknown(data['trazado_id']!, _trazadoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trazadoIdMeta);
    }
    if (data.containsKey('orden')) {
      context.handle(
        _ordenMeta,
        orden.isAcceptableOrUnknown(data['orden']!, _ordenMeta),
      );
    } else if (isInserting) {
      context.missing(_ordenMeta);
    }
    if (data.containsKey('latitud')) {
      context.handle(
        _latitudMeta,
        latitud.isAcceptableOrUnknown(data['latitud']!, _latitudMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudMeta);
    }
    if (data.containsKey('longitud')) {
      context.handle(
        _longitudMeta,
        longitud.isAcceptableOrUnknown(data['longitud']!, _longitudMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudMeta);
    }
    if (data.containsKey('altitud')) {
      context.handle(
        _altitudMeta,
        altitud.isAcceptableOrUnknown(data['altitud']!, _altitudMeta),
      );
    }
    if (data.containsKey('precision_m')) {
      context.handle(
        _precisionMMeta,
        precisionM.isAcceptableOrUnknown(data['precision_m']!, _precisionMMeta),
      );
    }
    if (data.containsKey('capturado_en')) {
      context.handle(
        _capturadoEnMeta,
        capturadoEn.isAcceptableOrUnknown(
          data['capturado_en']!,
          _capturadoEnMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_capturadoEnMeta);
    }
    if (data.containsKey('automatico')) {
      context.handle(
        _automaticoMeta,
        automatico.isAcceptableOrUnknown(data['automatico']!, _automaticoMeta),
      );
    }
    if (data.containsKey('nota')) {
      context.handle(
        _notaMeta,
        nota.isAcceptableOrUnknown(data['nota']!, _notaMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PuntoTrazado map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PuntoTrazado(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      trazadoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trazado_id'],
      )!,
      orden: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}orden'],
      )!,
      latitud: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitud'],
      )!,
      longitud: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitud'],
      )!,
      altitud: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}altitud'],
      ),
      precisionM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}precision_m'],
      ),
      capturadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}capturado_en'],
      )!,
      automatico: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}automatico'],
      )!,
      nota: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nota'],
      ),
    );
  }

  @override
  $PuntosTrazadoTable createAlias(String alias) {
    return $PuntosTrazadoTable(attachedDatabase, alias);
  }
}

class PuntoTrazado extends DataClass implements Insertable<PuntoTrazado> {
  final String id;
  final String trazadoId;

  /// Posicion en el anillo. El orden ES la geometria: dos puntos intercambiados
  /// convierten un lote en un ocho.
  final int orden;
  final double latitud;
  final double longitud;
  final double? altitud;

  /// Radio de error que reporto el GPS, en metros.
  final double? precisionM;
  final DateTime capturadoEn;

  /// false = lo marco el visitador con el boton. true = lo puso el reloj.
  final bool automatico;
  final String? nota;
  const PuntoTrazado({
    required this.id,
    required this.trazadoId,
    required this.orden,
    required this.latitud,
    required this.longitud,
    this.altitud,
    this.precisionM,
    required this.capturadoEn,
    required this.automatico,
    this.nota,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['trazado_id'] = Variable<String>(trazadoId);
    map['orden'] = Variable<int>(orden);
    map['latitud'] = Variable<double>(latitud);
    map['longitud'] = Variable<double>(longitud);
    if (!nullToAbsent || altitud != null) {
      map['altitud'] = Variable<double>(altitud);
    }
    if (!nullToAbsent || precisionM != null) {
      map['precision_m'] = Variable<double>(precisionM);
    }
    map['capturado_en'] = Variable<DateTime>(capturadoEn);
    map['automatico'] = Variable<bool>(automatico);
    if (!nullToAbsent || nota != null) {
      map['nota'] = Variable<String>(nota);
    }
    return map;
  }

  PuntosTrazadoCompanion toCompanion(bool nullToAbsent) {
    return PuntosTrazadoCompanion(
      id: Value(id),
      trazadoId: Value(trazadoId),
      orden: Value(orden),
      latitud: Value(latitud),
      longitud: Value(longitud),
      altitud: altitud == null && nullToAbsent
          ? const Value.absent()
          : Value(altitud),
      precisionM: precisionM == null && nullToAbsent
          ? const Value.absent()
          : Value(precisionM),
      capturadoEn: Value(capturadoEn),
      automatico: Value(automatico),
      nota: nota == null && nullToAbsent ? const Value.absent() : Value(nota),
    );
  }

  factory PuntoTrazado.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PuntoTrazado(
      id: serializer.fromJson<String>(json['id']),
      trazadoId: serializer.fromJson<String>(json['trazadoId']),
      orden: serializer.fromJson<int>(json['orden']),
      latitud: serializer.fromJson<double>(json['latitud']),
      longitud: serializer.fromJson<double>(json['longitud']),
      altitud: serializer.fromJson<double?>(json['altitud']),
      precisionM: serializer.fromJson<double?>(json['precisionM']),
      capturadoEn: serializer.fromJson<DateTime>(json['capturadoEn']),
      automatico: serializer.fromJson<bool>(json['automatico']),
      nota: serializer.fromJson<String?>(json['nota']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'trazadoId': serializer.toJson<String>(trazadoId),
      'orden': serializer.toJson<int>(orden),
      'latitud': serializer.toJson<double>(latitud),
      'longitud': serializer.toJson<double>(longitud),
      'altitud': serializer.toJson<double?>(altitud),
      'precisionM': serializer.toJson<double?>(precisionM),
      'capturadoEn': serializer.toJson<DateTime>(capturadoEn),
      'automatico': serializer.toJson<bool>(automatico),
      'nota': serializer.toJson<String?>(nota),
    };
  }

  PuntoTrazado copyWith({
    String? id,
    String? trazadoId,
    int? orden,
    double? latitud,
    double? longitud,
    Value<double?> altitud = const Value.absent(),
    Value<double?> precisionM = const Value.absent(),
    DateTime? capturadoEn,
    bool? automatico,
    Value<String?> nota = const Value.absent(),
  }) => PuntoTrazado(
    id: id ?? this.id,
    trazadoId: trazadoId ?? this.trazadoId,
    orden: orden ?? this.orden,
    latitud: latitud ?? this.latitud,
    longitud: longitud ?? this.longitud,
    altitud: altitud.present ? altitud.value : this.altitud,
    precisionM: precisionM.present ? precisionM.value : this.precisionM,
    capturadoEn: capturadoEn ?? this.capturadoEn,
    automatico: automatico ?? this.automatico,
    nota: nota.present ? nota.value : this.nota,
  );
  PuntoTrazado copyWithCompanion(PuntosTrazadoCompanion data) {
    return PuntoTrazado(
      id: data.id.present ? data.id.value : this.id,
      trazadoId: data.trazadoId.present ? data.trazadoId.value : this.trazadoId,
      orden: data.orden.present ? data.orden.value : this.orden,
      latitud: data.latitud.present ? data.latitud.value : this.latitud,
      longitud: data.longitud.present ? data.longitud.value : this.longitud,
      altitud: data.altitud.present ? data.altitud.value : this.altitud,
      precisionM: data.precisionM.present
          ? data.precisionM.value
          : this.precisionM,
      capturadoEn: data.capturadoEn.present
          ? data.capturadoEn.value
          : this.capturadoEn,
      automatico: data.automatico.present
          ? data.automatico.value
          : this.automatico,
      nota: data.nota.present ? data.nota.value : this.nota,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PuntoTrazado(')
          ..write('id: $id, ')
          ..write('trazadoId: $trazadoId, ')
          ..write('orden: $orden, ')
          ..write('latitud: $latitud, ')
          ..write('longitud: $longitud, ')
          ..write('altitud: $altitud, ')
          ..write('precisionM: $precisionM, ')
          ..write('capturadoEn: $capturadoEn, ')
          ..write('automatico: $automatico, ')
          ..write('nota: $nota')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    trazadoId,
    orden,
    latitud,
    longitud,
    altitud,
    precisionM,
    capturadoEn,
    automatico,
    nota,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PuntoTrazado &&
          other.id == this.id &&
          other.trazadoId == this.trazadoId &&
          other.orden == this.orden &&
          other.latitud == this.latitud &&
          other.longitud == this.longitud &&
          other.altitud == this.altitud &&
          other.precisionM == this.precisionM &&
          other.capturadoEn == this.capturadoEn &&
          other.automatico == this.automatico &&
          other.nota == this.nota);
}

class PuntosTrazadoCompanion extends UpdateCompanion<PuntoTrazado> {
  final Value<String> id;
  final Value<String> trazadoId;
  final Value<int> orden;
  final Value<double> latitud;
  final Value<double> longitud;
  final Value<double?> altitud;
  final Value<double?> precisionM;
  final Value<DateTime> capturadoEn;
  final Value<bool> automatico;
  final Value<String?> nota;
  final Value<int> rowid;
  const PuntosTrazadoCompanion({
    this.id = const Value.absent(),
    this.trazadoId = const Value.absent(),
    this.orden = const Value.absent(),
    this.latitud = const Value.absent(),
    this.longitud = const Value.absent(),
    this.altitud = const Value.absent(),
    this.precisionM = const Value.absent(),
    this.capturadoEn = const Value.absent(),
    this.automatico = const Value.absent(),
    this.nota = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PuntosTrazadoCompanion.insert({
    required String id,
    required String trazadoId,
    required int orden,
    required double latitud,
    required double longitud,
    this.altitud = const Value.absent(),
    this.precisionM = const Value.absent(),
    required DateTime capturadoEn,
    this.automatico = const Value.absent(),
    this.nota = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       trazadoId = Value(trazadoId),
       orden = Value(orden),
       latitud = Value(latitud),
       longitud = Value(longitud),
       capturadoEn = Value(capturadoEn);
  static Insertable<PuntoTrazado> custom({
    Expression<String>? id,
    Expression<String>? trazadoId,
    Expression<int>? orden,
    Expression<double>? latitud,
    Expression<double>? longitud,
    Expression<double>? altitud,
    Expression<double>? precisionM,
    Expression<DateTime>? capturadoEn,
    Expression<bool>? automatico,
    Expression<String>? nota,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trazadoId != null) 'trazado_id': trazadoId,
      if (orden != null) 'orden': orden,
      if (latitud != null) 'latitud': latitud,
      if (longitud != null) 'longitud': longitud,
      if (altitud != null) 'altitud': altitud,
      if (precisionM != null) 'precision_m': precisionM,
      if (capturadoEn != null) 'capturado_en': capturadoEn,
      if (automatico != null) 'automatico': automatico,
      if (nota != null) 'nota': nota,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PuntosTrazadoCompanion copyWith({
    Value<String>? id,
    Value<String>? trazadoId,
    Value<int>? orden,
    Value<double>? latitud,
    Value<double>? longitud,
    Value<double?>? altitud,
    Value<double?>? precisionM,
    Value<DateTime>? capturadoEn,
    Value<bool>? automatico,
    Value<String?>? nota,
    Value<int>? rowid,
  }) {
    return PuntosTrazadoCompanion(
      id: id ?? this.id,
      trazadoId: trazadoId ?? this.trazadoId,
      orden: orden ?? this.orden,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      altitud: altitud ?? this.altitud,
      precisionM: precisionM ?? this.precisionM,
      capturadoEn: capturadoEn ?? this.capturadoEn,
      automatico: automatico ?? this.automatico,
      nota: nota ?? this.nota,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (trazadoId.present) {
      map['trazado_id'] = Variable<String>(trazadoId.value);
    }
    if (orden.present) {
      map['orden'] = Variable<int>(orden.value);
    }
    if (latitud.present) {
      map['latitud'] = Variable<double>(latitud.value);
    }
    if (longitud.present) {
      map['longitud'] = Variable<double>(longitud.value);
    }
    if (altitud.present) {
      map['altitud'] = Variable<double>(altitud.value);
    }
    if (precisionM.present) {
      map['precision_m'] = Variable<double>(precisionM.value);
    }
    if (capturadoEn.present) {
      map['capturado_en'] = Variable<DateTime>(capturadoEn.value);
    }
    if (automatico.present) {
      map['automatico'] = Variable<bool>(automatico.value);
    }
    if (nota.present) {
      map['nota'] = Variable<String>(nota.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PuntosTrazadoCompanion(')
          ..write('id: $id, ')
          ..write('trazadoId: $trazadoId, ')
          ..write('orden: $orden, ')
          ..write('latitud: $latitud, ')
          ..write('longitud: $longitud, ')
          ..write('altitud: $altitud, ')
          ..write('precisionM: $precisionM, ')
          ..write('capturadoEn: $capturadoEn, ')
          ..write('automatico: $automatico, ')
          ..write('nota: $nota, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entidadMeta = const VerificationMeta(
    'entidad',
  );
  @override
  late final GeneratedColumn<String> entidad = GeneratedColumn<String>(
    'entidad',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entidadIdMeta = const VerificationMeta(
    'entidadId',
  );
  @override
  late final GeneratedColumn<String> entidadId = GeneratedColumn<String>(
    'entidad_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operacionMeta = const VerificationMeta(
    'operacion',
  );
  @override
  late final GeneratedColumn<String> operacion = GeneratedColumn<String>(
    'operacion',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivoPathMeta = const VerificationMeta(
    'archivoPath',
  );
  @override
  late final GeneratedColumn<String> archivoPath = GeneratedColumn<String>(
    'archivo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<EstadoSync, String> estado =
      GeneratedColumn<String>(
        'estado',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('Pendiente'),
      ).withConverter<EstadoSync>($SyncQueueTable.$converterestado);
  static const VerificationMeta _intentosMeta = const VerificationMeta(
    'intentos',
  );
  @override
  late final GeneratedColumn<int> intentos = GeneratedColumn<int>(
    'intentos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _proximoIntentoEnMeta = const VerificationMeta(
    'proximoIntentoEn',
  );
  @override
  late final GeneratedColumn<DateTime> proximoIntentoEn =
      GeneratedColumn<DateTime>(
        'proximo_intento_en',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _bytesSubidosMeta = const VerificationMeta(
    'bytesSubidos',
  );
  @override
  late final GeneratedColumn<int> bytesSubidos = GeneratedColumn<int>(
    'bytes_subidos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _bytesTotalesMeta = const VerificationMeta(
    'bytesTotales',
  );
  @override
  late final GeneratedColumn<int> bytesTotales = GeneratedColumn<int>(
    'bytes_totales',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _ultimoErrorMeta = const VerificationMeta(
    'ultimoError',
  );
  @override
  late final GeneratedColumn<String> ultimoError = GeneratedColumn<String>(
    'ultimo_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _prioridadMeta = const VerificationMeta(
    'prioridad',
  );
  @override
  late final GeneratedColumn<int> prioridad = GeneratedColumn<int>(
    'prioridad',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(100),
  );
  static const VerificationMeta _creadoEnMeta = const VerificationMeta(
    'creadoEn',
  );
  @override
  late final GeneratedColumn<DateTime> creadoEn = GeneratedColumn<DateTime>(
    'creado_en',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entidad,
    entidadId,
    operacion,
    payload,
    archivoPath,
    estado,
    intentos,
    proximoIntentoEn,
    bytesSubidos,
    bytesTotales,
    ultimoError,
    prioridad,
    creadoEn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entidad')) {
      context.handle(
        _entidadMeta,
        entidad.isAcceptableOrUnknown(data['entidad']!, _entidadMeta),
      );
    } else if (isInserting) {
      context.missing(_entidadMeta);
    }
    if (data.containsKey('entidad_id')) {
      context.handle(
        _entidadIdMeta,
        entidadId.isAcceptableOrUnknown(data['entidad_id']!, _entidadIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entidadIdMeta);
    }
    if (data.containsKey('operacion')) {
      context.handle(
        _operacionMeta,
        operacion.isAcceptableOrUnknown(data['operacion']!, _operacionMeta),
      );
    } else if (isInserting) {
      context.missing(_operacionMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    }
    if (data.containsKey('archivo_path')) {
      context.handle(
        _archivoPathMeta,
        archivoPath.isAcceptableOrUnknown(
          data['archivo_path']!,
          _archivoPathMeta,
        ),
      );
    }
    if (data.containsKey('intentos')) {
      context.handle(
        _intentosMeta,
        intentos.isAcceptableOrUnknown(data['intentos']!, _intentosMeta),
      );
    }
    if (data.containsKey('proximo_intento_en')) {
      context.handle(
        _proximoIntentoEnMeta,
        proximoIntentoEn.isAcceptableOrUnknown(
          data['proximo_intento_en']!,
          _proximoIntentoEnMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_proximoIntentoEnMeta);
    }
    if (data.containsKey('bytes_subidos')) {
      context.handle(
        _bytesSubidosMeta,
        bytesSubidos.isAcceptableOrUnknown(
          data['bytes_subidos']!,
          _bytesSubidosMeta,
        ),
      );
    }
    if (data.containsKey('bytes_totales')) {
      context.handle(
        _bytesTotalesMeta,
        bytesTotales.isAcceptableOrUnknown(
          data['bytes_totales']!,
          _bytesTotalesMeta,
        ),
      );
    }
    if (data.containsKey('ultimo_error')) {
      context.handle(
        _ultimoErrorMeta,
        ultimoError.isAcceptableOrUnknown(
          data['ultimo_error']!,
          _ultimoErrorMeta,
        ),
      );
    }
    if (data.containsKey('prioridad')) {
      context.handle(
        _prioridadMeta,
        prioridad.isAcceptableOrUnknown(data['prioridad']!, _prioridadMeta),
      );
    }
    if (data.containsKey('creado_en')) {
      context.handle(
        _creadoEnMeta,
        creadoEn.isAcceptableOrUnknown(data['creado_en']!, _creadoEnMeta),
      );
    } else if (isInserting) {
      context.missing(_creadoEnMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entidad: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entidad'],
      )!,
      entidadId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entidad_id'],
      )!,
      operacion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operacion'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      ),
      archivoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}archivo_path'],
      ),
      estado: $SyncQueueTable.$converterestado.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}estado'],
        )!,
      ),
      intentos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}intentos'],
      )!,
      proximoIntentoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}proximo_intento_en'],
      )!,
      bytesSubidos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bytes_subidos'],
      )!,
      bytesTotales: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bytes_totales'],
      )!,
      ultimoError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ultimo_error'],
      ),
      prioridad: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prioridad'],
      )!,
      creadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}creado_en'],
      )!,
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }

  static TypeConverter<EstadoSync, String> $converterestado =
      const EstadoSyncConverter();
}

class SyncItem extends DataClass implements Insertable<SyncItem> {
  final String id;

  /// visita | grabacion | evidencia | hallazgos | productor | finca
  final String entidad;
  final String entidadId;

  /// upsert | upload_audio | upload_foto | upload_informe
  final String operacion;
  final String? payload;
  final String? archivoPath;
  final EstadoSync estado;
  final int intentos;

  /// Retroceso exponencial. La cola solo toma items cuyo proximo intento ya paso.
  final DateTime proximoIntentoEn;

  /// Subida por partes de 512 KB. Permite retomar donde quedo si se cae la red
  /// a la mitad de un audio de 7 MB, sin volver a subir lo ya subido.
  final int bytesSubidos;
  final int bytesTotales;

  /// Se muestra tal cual en la pantalla de estado. El visitador merece saber
  /// por que fallo, no un spinner indefinido.
  final String? ultimoError;

  /// Menor primero. El audio va antes que las fotos: es lo irrecuperable.
  final int prioridad;
  final DateTime creadoEn;
  const SyncItem({
    required this.id,
    required this.entidad,
    required this.entidadId,
    required this.operacion,
    this.payload,
    this.archivoPath,
    required this.estado,
    required this.intentos,
    required this.proximoIntentoEn,
    required this.bytesSubidos,
    required this.bytesTotales,
    this.ultimoError,
    required this.prioridad,
    required this.creadoEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entidad'] = Variable<String>(entidad);
    map['entidad_id'] = Variable<String>(entidadId);
    map['operacion'] = Variable<String>(operacion);
    if (!nullToAbsent || payload != null) {
      map['payload'] = Variable<String>(payload);
    }
    if (!nullToAbsent || archivoPath != null) {
      map['archivo_path'] = Variable<String>(archivoPath);
    }
    {
      map['estado'] = Variable<String>(
        $SyncQueueTable.$converterestado.toSql(estado),
      );
    }
    map['intentos'] = Variable<int>(intentos);
    map['proximo_intento_en'] = Variable<DateTime>(proximoIntentoEn);
    map['bytes_subidos'] = Variable<int>(bytesSubidos);
    map['bytes_totales'] = Variable<int>(bytesTotales);
    if (!nullToAbsent || ultimoError != null) {
      map['ultimo_error'] = Variable<String>(ultimoError);
    }
    map['prioridad'] = Variable<int>(prioridad);
    map['creado_en'] = Variable<DateTime>(creadoEn);
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      entidad: Value(entidad),
      entidadId: Value(entidadId),
      operacion: Value(operacion),
      payload: payload == null && nullToAbsent
          ? const Value.absent()
          : Value(payload),
      archivoPath: archivoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(archivoPath),
      estado: Value(estado),
      intentos: Value(intentos),
      proximoIntentoEn: Value(proximoIntentoEn),
      bytesSubidos: Value(bytesSubidos),
      bytesTotales: Value(bytesTotales),
      ultimoError: ultimoError == null && nullToAbsent
          ? const Value.absent()
          : Value(ultimoError),
      prioridad: Value(prioridad),
      creadoEn: Value(creadoEn),
    );
  }

  factory SyncItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncItem(
      id: serializer.fromJson<String>(json['id']),
      entidad: serializer.fromJson<String>(json['entidad']),
      entidadId: serializer.fromJson<String>(json['entidadId']),
      operacion: serializer.fromJson<String>(json['operacion']),
      payload: serializer.fromJson<String?>(json['payload']),
      archivoPath: serializer.fromJson<String?>(json['archivoPath']),
      estado: serializer.fromJson<EstadoSync>(json['estado']),
      intentos: serializer.fromJson<int>(json['intentos']),
      proximoIntentoEn: serializer.fromJson<DateTime>(json['proximoIntentoEn']),
      bytesSubidos: serializer.fromJson<int>(json['bytesSubidos']),
      bytesTotales: serializer.fromJson<int>(json['bytesTotales']),
      ultimoError: serializer.fromJson<String?>(json['ultimoError']),
      prioridad: serializer.fromJson<int>(json['prioridad']),
      creadoEn: serializer.fromJson<DateTime>(json['creadoEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entidad': serializer.toJson<String>(entidad),
      'entidadId': serializer.toJson<String>(entidadId),
      'operacion': serializer.toJson<String>(operacion),
      'payload': serializer.toJson<String?>(payload),
      'archivoPath': serializer.toJson<String?>(archivoPath),
      'estado': serializer.toJson<EstadoSync>(estado),
      'intentos': serializer.toJson<int>(intentos),
      'proximoIntentoEn': serializer.toJson<DateTime>(proximoIntentoEn),
      'bytesSubidos': serializer.toJson<int>(bytesSubidos),
      'bytesTotales': serializer.toJson<int>(bytesTotales),
      'ultimoError': serializer.toJson<String?>(ultimoError),
      'prioridad': serializer.toJson<int>(prioridad),
      'creadoEn': serializer.toJson<DateTime>(creadoEn),
    };
  }

  SyncItem copyWith({
    String? id,
    String? entidad,
    String? entidadId,
    String? operacion,
    Value<String?> payload = const Value.absent(),
    Value<String?> archivoPath = const Value.absent(),
    EstadoSync? estado,
    int? intentos,
    DateTime? proximoIntentoEn,
    int? bytesSubidos,
    int? bytesTotales,
    Value<String?> ultimoError = const Value.absent(),
    int? prioridad,
    DateTime? creadoEn,
  }) => SyncItem(
    id: id ?? this.id,
    entidad: entidad ?? this.entidad,
    entidadId: entidadId ?? this.entidadId,
    operacion: operacion ?? this.operacion,
    payload: payload.present ? payload.value : this.payload,
    archivoPath: archivoPath.present ? archivoPath.value : this.archivoPath,
    estado: estado ?? this.estado,
    intentos: intentos ?? this.intentos,
    proximoIntentoEn: proximoIntentoEn ?? this.proximoIntentoEn,
    bytesSubidos: bytesSubidos ?? this.bytesSubidos,
    bytesTotales: bytesTotales ?? this.bytesTotales,
    ultimoError: ultimoError.present ? ultimoError.value : this.ultimoError,
    prioridad: prioridad ?? this.prioridad,
    creadoEn: creadoEn ?? this.creadoEn,
  );
  SyncItem copyWithCompanion(SyncQueueCompanion data) {
    return SyncItem(
      id: data.id.present ? data.id.value : this.id,
      entidad: data.entidad.present ? data.entidad.value : this.entidad,
      entidadId: data.entidadId.present ? data.entidadId.value : this.entidadId,
      operacion: data.operacion.present ? data.operacion.value : this.operacion,
      payload: data.payload.present ? data.payload.value : this.payload,
      archivoPath: data.archivoPath.present
          ? data.archivoPath.value
          : this.archivoPath,
      estado: data.estado.present ? data.estado.value : this.estado,
      intentos: data.intentos.present ? data.intentos.value : this.intentos,
      proximoIntentoEn: data.proximoIntentoEn.present
          ? data.proximoIntentoEn.value
          : this.proximoIntentoEn,
      bytesSubidos: data.bytesSubidos.present
          ? data.bytesSubidos.value
          : this.bytesSubidos,
      bytesTotales: data.bytesTotales.present
          ? data.bytesTotales.value
          : this.bytesTotales,
      ultimoError: data.ultimoError.present
          ? data.ultimoError.value
          : this.ultimoError,
      prioridad: data.prioridad.present ? data.prioridad.value : this.prioridad,
      creadoEn: data.creadoEn.present ? data.creadoEn.value : this.creadoEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncItem(')
          ..write('id: $id, ')
          ..write('entidad: $entidad, ')
          ..write('entidadId: $entidadId, ')
          ..write('operacion: $operacion, ')
          ..write('payload: $payload, ')
          ..write('archivoPath: $archivoPath, ')
          ..write('estado: $estado, ')
          ..write('intentos: $intentos, ')
          ..write('proximoIntentoEn: $proximoIntentoEn, ')
          ..write('bytesSubidos: $bytesSubidos, ')
          ..write('bytesTotales: $bytesTotales, ')
          ..write('ultimoError: $ultimoError, ')
          ..write('prioridad: $prioridad, ')
          ..write('creadoEn: $creadoEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entidad,
    entidadId,
    operacion,
    payload,
    archivoPath,
    estado,
    intentos,
    proximoIntentoEn,
    bytesSubidos,
    bytesTotales,
    ultimoError,
    prioridad,
    creadoEn,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncItem &&
          other.id == this.id &&
          other.entidad == this.entidad &&
          other.entidadId == this.entidadId &&
          other.operacion == this.operacion &&
          other.payload == this.payload &&
          other.archivoPath == this.archivoPath &&
          other.estado == this.estado &&
          other.intentos == this.intentos &&
          other.proximoIntentoEn == this.proximoIntentoEn &&
          other.bytesSubidos == this.bytesSubidos &&
          other.bytesTotales == this.bytesTotales &&
          other.ultimoError == this.ultimoError &&
          other.prioridad == this.prioridad &&
          other.creadoEn == this.creadoEn);
}

class SyncQueueCompanion extends UpdateCompanion<SyncItem> {
  final Value<String> id;
  final Value<String> entidad;
  final Value<String> entidadId;
  final Value<String> operacion;
  final Value<String?> payload;
  final Value<String?> archivoPath;
  final Value<EstadoSync> estado;
  final Value<int> intentos;
  final Value<DateTime> proximoIntentoEn;
  final Value<int> bytesSubidos;
  final Value<int> bytesTotales;
  final Value<String?> ultimoError;
  final Value<int> prioridad;
  final Value<DateTime> creadoEn;
  final Value<int> rowid;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.entidad = const Value.absent(),
    this.entidadId = const Value.absent(),
    this.operacion = const Value.absent(),
    this.payload = const Value.absent(),
    this.archivoPath = const Value.absent(),
    this.estado = const Value.absent(),
    this.intentos = const Value.absent(),
    this.proximoIntentoEn = const Value.absent(),
    this.bytesSubidos = const Value.absent(),
    this.bytesTotales = const Value.absent(),
    this.ultimoError = const Value.absent(),
    this.prioridad = const Value.absent(),
    this.creadoEn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    required String id,
    required String entidad,
    required String entidadId,
    required String operacion,
    this.payload = const Value.absent(),
    this.archivoPath = const Value.absent(),
    this.estado = const Value.absent(),
    this.intentos = const Value.absent(),
    required DateTime proximoIntentoEn,
    this.bytesSubidos = const Value.absent(),
    this.bytesTotales = const Value.absent(),
    this.ultimoError = const Value.absent(),
    this.prioridad = const Value.absent(),
    required DateTime creadoEn,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entidad = Value(entidad),
       entidadId = Value(entidadId),
       operacion = Value(operacion),
       proximoIntentoEn = Value(proximoIntentoEn),
       creadoEn = Value(creadoEn);
  static Insertable<SyncItem> custom({
    Expression<String>? id,
    Expression<String>? entidad,
    Expression<String>? entidadId,
    Expression<String>? operacion,
    Expression<String>? payload,
    Expression<String>? archivoPath,
    Expression<String>? estado,
    Expression<int>? intentos,
    Expression<DateTime>? proximoIntentoEn,
    Expression<int>? bytesSubidos,
    Expression<int>? bytesTotales,
    Expression<String>? ultimoError,
    Expression<int>? prioridad,
    Expression<DateTime>? creadoEn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entidad != null) 'entidad': entidad,
      if (entidadId != null) 'entidad_id': entidadId,
      if (operacion != null) 'operacion': operacion,
      if (payload != null) 'payload': payload,
      if (archivoPath != null) 'archivo_path': archivoPath,
      if (estado != null) 'estado': estado,
      if (intentos != null) 'intentos': intentos,
      if (proximoIntentoEn != null) 'proximo_intento_en': proximoIntentoEn,
      if (bytesSubidos != null) 'bytes_subidos': bytesSubidos,
      if (bytesTotales != null) 'bytes_totales': bytesTotales,
      if (ultimoError != null) 'ultimo_error': ultimoError,
      if (prioridad != null) 'prioridad': prioridad,
      if (creadoEn != null) 'creado_en': creadoEn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncQueueCompanion copyWith({
    Value<String>? id,
    Value<String>? entidad,
    Value<String>? entidadId,
    Value<String>? operacion,
    Value<String?>? payload,
    Value<String?>? archivoPath,
    Value<EstadoSync>? estado,
    Value<int>? intentos,
    Value<DateTime>? proximoIntentoEn,
    Value<int>? bytesSubidos,
    Value<int>? bytesTotales,
    Value<String?>? ultimoError,
    Value<int>? prioridad,
    Value<DateTime>? creadoEn,
    Value<int>? rowid,
  }) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      entidad: entidad ?? this.entidad,
      entidadId: entidadId ?? this.entidadId,
      operacion: operacion ?? this.operacion,
      payload: payload ?? this.payload,
      archivoPath: archivoPath ?? this.archivoPath,
      estado: estado ?? this.estado,
      intentos: intentos ?? this.intentos,
      proximoIntentoEn: proximoIntentoEn ?? this.proximoIntentoEn,
      bytesSubidos: bytesSubidos ?? this.bytesSubidos,
      bytesTotales: bytesTotales ?? this.bytesTotales,
      ultimoError: ultimoError ?? this.ultimoError,
      prioridad: prioridad ?? this.prioridad,
      creadoEn: creadoEn ?? this.creadoEn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entidad.present) {
      map['entidad'] = Variable<String>(entidad.value);
    }
    if (entidadId.present) {
      map['entidad_id'] = Variable<String>(entidadId.value);
    }
    if (operacion.present) {
      map['operacion'] = Variable<String>(operacion.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (archivoPath.present) {
      map['archivo_path'] = Variable<String>(archivoPath.value);
    }
    if (estado.present) {
      map['estado'] = Variable<String>(
        $SyncQueueTable.$converterestado.toSql(estado.value),
      );
    }
    if (intentos.present) {
      map['intentos'] = Variable<int>(intentos.value);
    }
    if (proximoIntentoEn.present) {
      map['proximo_intento_en'] = Variable<DateTime>(proximoIntentoEn.value);
    }
    if (bytesSubidos.present) {
      map['bytes_subidos'] = Variable<int>(bytesSubidos.value);
    }
    if (bytesTotales.present) {
      map['bytes_totales'] = Variable<int>(bytesTotales.value);
    }
    if (ultimoError.present) {
      map['ultimo_error'] = Variable<String>(ultimoError.value);
    }
    if (prioridad.present) {
      map['prioridad'] = Variable<int>(prioridad.value);
    }
    if (creadoEn.present) {
      map['creado_en'] = Variable<DateTime>(creadoEn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('entidad: $entidad, ')
          ..write('entidadId: $entidadId, ')
          ..write('operacion: $operacion, ')
          ..write('payload: $payload, ')
          ..write('archivoPath: $archivoPath, ')
          ..write('estado: $estado, ')
          ..write('intentos: $intentos, ')
          ..write('proximoIntentoEn: $proximoIntentoEn, ')
          ..write('bytesSubidos: $bytesSubidos, ')
          ..write('bytesTotales: $bytesTotales, ')
          ..write('ultimoError: $ultimoError, ')
          ..write('prioridad: $prioridad, ')
          ..write('creadoEn: $creadoEn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AjustesTable ajustes = $AjustesTable(this);
  late final $CatalogoCamposTable catalogoCampos = $CatalogoCamposTable(this);
  late final $VeredasTable veredas = $VeredasTable(this);
  late final $VisitadoresTable visitadores = $VisitadoresTable(this);
  late final $CredencialesLocalesTable credencialesLocales =
      $CredencialesLocalesTable(this);
  late final $SesionesTable sesiones = $SesionesTable(this);
  late final $ProductoresTable productores = $ProductoresTable(this);
  late final $FincasTable fincas = $FincasTable(this);
  late final $VisitasTable visitas = $VisitasTable(this);
  late final $GrabacionesTable grabaciones = $GrabacionesTable(this);
  late final $EvidenciasTable evidencias = $EvidenciasTable(this);
  late final $HallazgosTable hallazgos = $HallazgosTable(this);
  late final $InformesTable informes = $InformesTable(this);
  late final $TrazadosTable trazados = $TrazadosTable(this);
  late final $PuntosTrazadoTable puntosTrazado = $PuntosTrazadoTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    ajustes,
    catalogoCampos,
    veredas,
    visitadores,
    credencialesLocales,
    sesiones,
    productores,
    fincas,
    visitas,
    grabaciones,
    evidencias,
    hallazgos,
    informes,
    trazados,
    puntosTrazado,
    syncQueue,
  ];
}

typedef $$AjustesTableCreateCompanionBuilder =
    AjustesCompanion Function({
      required String clave,
      required String valor,
      Value<int> rowid,
    });
typedef $$AjustesTableUpdateCompanionBuilder =
    AjustesCompanion Function({
      Value<String> clave,
      Value<String> valor,
      Value<int> rowid,
    });

class $$AjustesTableFilterComposer
    extends Composer<_$AppDatabase, $AjustesTable> {
  $$AjustesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clave => $composableBuilder(
    column: $table.clave,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valor => $composableBuilder(
    column: $table.valor,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AjustesTableOrderingComposer
    extends Composer<_$AppDatabase, $AjustesTable> {
  $$AjustesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clave => $composableBuilder(
    column: $table.clave,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valor => $composableBuilder(
    column: $table.valor,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AjustesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AjustesTable> {
  $$AjustesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clave =>
      $composableBuilder(column: $table.clave, builder: (column) => column);

  GeneratedColumn<String> get valor =>
      $composableBuilder(column: $table.valor, builder: (column) => column);
}

class $$AjustesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AjustesTable,
          Ajuste,
          $$AjustesTableFilterComposer,
          $$AjustesTableOrderingComposer,
          $$AjustesTableAnnotationComposer,
          $$AjustesTableCreateCompanionBuilder,
          $$AjustesTableUpdateCompanionBuilder,
          (Ajuste, BaseReferences<_$AppDatabase, $AjustesTable, Ajuste>),
          Ajuste,
          PrefetchHooks Function()
        > {
  $$AjustesTableTableManager(_$AppDatabase db, $AjustesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AjustesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AjustesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AjustesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> clave = const Value.absent(),
                Value<String> valor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AjustesCompanion(clave: clave, valor: valor, rowid: rowid),
          createCompanionCallback:
              ({
                required String clave,
                required String valor,
                Value<int> rowid = const Value.absent(),
              }) => AjustesCompanion.insert(
                clave: clave,
                valor: valor,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AjustesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AjustesTable,
      Ajuste,
      $$AjustesTableFilterComposer,
      $$AjustesTableOrderingComposer,
      $$AjustesTableAnnotationComposer,
      $$AjustesTableCreateCompanionBuilder,
      $$AjustesTableUpdateCompanionBuilder,
      (Ajuste, BaseReferences<_$AppDatabase, $AjustesTable, Ajuste>),
      Ajuste,
      PrefetchHooks Function()
    >;
typedef $$CatalogoCamposTableCreateCompanionBuilder =
    CatalogoCamposCompanion Function({
      required String claveTecnica,
      required String campo,
      required String modulo,
      Value<String> tipoDato,
      Value<String?> unidad,
      Value<String?> opciones,
      Value<String?> preguntaGuia,
      Value<String?> descripcion,
      Value<bool> obligatorioMvp,
      Value<String?> prioridad,
      Value<bool> activo,
      Value<bool> noSugerir,
      Value<DateTime?> actualizadoEn,
      Value<int> rowid,
    });
typedef $$CatalogoCamposTableUpdateCompanionBuilder =
    CatalogoCamposCompanion Function({
      Value<String> claveTecnica,
      Value<String> campo,
      Value<String> modulo,
      Value<String> tipoDato,
      Value<String?> unidad,
      Value<String?> opciones,
      Value<String?> preguntaGuia,
      Value<String?> descripcion,
      Value<bool> obligatorioMvp,
      Value<String?> prioridad,
      Value<bool> activo,
      Value<bool> noSugerir,
      Value<DateTime?> actualizadoEn,
      Value<int> rowid,
    });

class $$CatalogoCamposTableFilterComposer
    extends Composer<_$AppDatabase, $CatalogoCamposTable> {
  $$CatalogoCamposTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get claveTecnica => $composableBuilder(
    column: $table.claveTecnica,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get campo => $composableBuilder(
    column: $table.campo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modulo => $composableBuilder(
    column: $table.modulo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipoDato => $composableBuilder(
    column: $table.tipoDato,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unidad => $composableBuilder(
    column: $table.unidad,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get opciones => $composableBuilder(
    column: $table.opciones,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preguntaGuia => $composableBuilder(
    column: $table.preguntaGuia,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get obligatorioMvp => $composableBuilder(
    column: $table.obligatorioMvp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prioridad => $composableBuilder(
    column: $table.prioridad,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get noSugerir => $composableBuilder(
    column: $table.noSugerir,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CatalogoCamposTableOrderingComposer
    extends Composer<_$AppDatabase, $CatalogoCamposTable> {
  $$CatalogoCamposTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get claveTecnica => $composableBuilder(
    column: $table.claveTecnica,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get campo => $composableBuilder(
    column: $table.campo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modulo => $composableBuilder(
    column: $table.modulo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipoDato => $composableBuilder(
    column: $table.tipoDato,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unidad => $composableBuilder(
    column: $table.unidad,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get opciones => $composableBuilder(
    column: $table.opciones,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preguntaGuia => $composableBuilder(
    column: $table.preguntaGuia,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get obligatorioMvp => $composableBuilder(
    column: $table.obligatorioMvp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prioridad => $composableBuilder(
    column: $table.prioridad,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get noSugerir => $composableBuilder(
    column: $table.noSugerir,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CatalogoCamposTableAnnotationComposer
    extends Composer<_$AppDatabase, $CatalogoCamposTable> {
  $$CatalogoCamposTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get claveTecnica => $composableBuilder(
    column: $table.claveTecnica,
    builder: (column) => column,
  );

  GeneratedColumn<String> get campo =>
      $composableBuilder(column: $table.campo, builder: (column) => column);

  GeneratedColumn<String> get modulo =>
      $composableBuilder(column: $table.modulo, builder: (column) => column);

  GeneratedColumn<String> get tipoDato =>
      $composableBuilder(column: $table.tipoDato, builder: (column) => column);

  GeneratedColumn<String> get unidad =>
      $composableBuilder(column: $table.unidad, builder: (column) => column);

  GeneratedColumn<String> get opciones =>
      $composableBuilder(column: $table.opciones, builder: (column) => column);

  GeneratedColumn<String> get preguntaGuia => $composableBuilder(
    column: $table.preguntaGuia,
    builder: (column) => column,
  );

  GeneratedColumn<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get obligatorioMvp => $composableBuilder(
    column: $table.obligatorioMvp,
    builder: (column) => column,
  );

  GeneratedColumn<String> get prioridad =>
      $composableBuilder(column: $table.prioridad, builder: (column) => column);

  GeneratedColumn<bool> get activo =>
      $composableBuilder(column: $table.activo, builder: (column) => column);

  GeneratedColumn<bool> get noSugerir =>
      $composableBuilder(column: $table.noSugerir, builder: (column) => column);

  GeneratedColumn<DateTime> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => column,
  );
}

class $$CatalogoCamposTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CatalogoCamposTable,
          CatalogoCampo,
          $$CatalogoCamposTableFilterComposer,
          $$CatalogoCamposTableOrderingComposer,
          $$CatalogoCamposTableAnnotationComposer,
          $$CatalogoCamposTableCreateCompanionBuilder,
          $$CatalogoCamposTableUpdateCompanionBuilder,
          (
            CatalogoCampo,
            BaseReferences<_$AppDatabase, $CatalogoCamposTable, CatalogoCampo>,
          ),
          CatalogoCampo,
          PrefetchHooks Function()
        > {
  $$CatalogoCamposTableTableManager(
    _$AppDatabase db,
    $CatalogoCamposTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CatalogoCamposTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CatalogoCamposTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CatalogoCamposTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> claveTecnica = const Value.absent(),
                Value<String> campo = const Value.absent(),
                Value<String> modulo = const Value.absent(),
                Value<String> tipoDato = const Value.absent(),
                Value<String?> unidad = const Value.absent(),
                Value<String?> opciones = const Value.absent(),
                Value<String?> preguntaGuia = const Value.absent(),
                Value<String?> descripcion = const Value.absent(),
                Value<bool> obligatorioMvp = const Value.absent(),
                Value<String?> prioridad = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<bool> noSugerir = const Value.absent(),
                Value<DateTime?> actualizadoEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CatalogoCamposCompanion(
                claveTecnica: claveTecnica,
                campo: campo,
                modulo: modulo,
                tipoDato: tipoDato,
                unidad: unidad,
                opciones: opciones,
                preguntaGuia: preguntaGuia,
                descripcion: descripcion,
                obligatorioMvp: obligatorioMvp,
                prioridad: prioridad,
                activo: activo,
                noSugerir: noSugerir,
                actualizadoEn: actualizadoEn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String claveTecnica,
                required String campo,
                required String modulo,
                Value<String> tipoDato = const Value.absent(),
                Value<String?> unidad = const Value.absent(),
                Value<String?> opciones = const Value.absent(),
                Value<String?> preguntaGuia = const Value.absent(),
                Value<String?> descripcion = const Value.absent(),
                Value<bool> obligatorioMvp = const Value.absent(),
                Value<String?> prioridad = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<bool> noSugerir = const Value.absent(),
                Value<DateTime?> actualizadoEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CatalogoCamposCompanion.insert(
                claveTecnica: claveTecnica,
                campo: campo,
                modulo: modulo,
                tipoDato: tipoDato,
                unidad: unidad,
                opciones: opciones,
                preguntaGuia: preguntaGuia,
                descripcion: descripcion,
                obligatorioMvp: obligatorioMvp,
                prioridad: prioridad,
                activo: activo,
                noSugerir: noSugerir,
                actualizadoEn: actualizadoEn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CatalogoCamposTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CatalogoCamposTable,
      CatalogoCampo,
      $$CatalogoCamposTableFilterComposer,
      $$CatalogoCamposTableOrderingComposer,
      $$CatalogoCamposTableAnnotationComposer,
      $$CatalogoCamposTableCreateCompanionBuilder,
      $$CatalogoCamposTableUpdateCompanionBuilder,
      (
        CatalogoCampo,
        BaseReferences<_$AppDatabase, $CatalogoCamposTable, CatalogoCampo>,
      ),
      CatalogoCampo,
      PrefetchHooks Function()
    >;
typedef $$VeredasTableCreateCompanionBuilder =
    VeredasCompanion Function({
      required String id,
      required String vereda,
      required String municipio,
      Value<String?> departamento,
      Value<String?> remoteId,
      Value<int> rowid,
    });
typedef $$VeredasTableUpdateCompanionBuilder =
    VeredasCompanion Function({
      Value<String> id,
      Value<String> vereda,
      Value<String> municipio,
      Value<String?> departamento,
      Value<String?> remoteId,
      Value<int> rowid,
    });

class $$VeredasTableFilterComposer
    extends Composer<_$AppDatabase, $VeredasTable> {
  $$VeredasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vereda => $composableBuilder(
    column: $table.vereda,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get municipio => $composableBuilder(
    column: $table.municipio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get departamento => $composableBuilder(
    column: $table.departamento,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VeredasTableOrderingComposer
    extends Composer<_$AppDatabase, $VeredasTable> {
  $$VeredasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vereda => $composableBuilder(
    column: $table.vereda,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get municipio => $composableBuilder(
    column: $table.municipio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get departamento => $composableBuilder(
    column: $table.departamento,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VeredasTableAnnotationComposer
    extends Composer<_$AppDatabase, $VeredasTable> {
  $$VeredasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get vereda =>
      $composableBuilder(column: $table.vereda, builder: (column) => column);

  GeneratedColumn<String> get municipio =>
      $composableBuilder(column: $table.municipio, builder: (column) => column);

  GeneratedColumn<String> get departamento => $composableBuilder(
    column: $table.departamento,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);
}

class $$VeredasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VeredasTable,
          Vereda,
          $$VeredasTableFilterComposer,
          $$VeredasTableOrderingComposer,
          $$VeredasTableAnnotationComposer,
          $$VeredasTableCreateCompanionBuilder,
          $$VeredasTableUpdateCompanionBuilder,
          (Vereda, BaseReferences<_$AppDatabase, $VeredasTable, Vereda>),
          Vereda,
          PrefetchHooks Function()
        > {
  $$VeredasTableTableManager(_$AppDatabase db, $VeredasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VeredasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VeredasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VeredasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> vereda = const Value.absent(),
                Value<String> municipio = const Value.absent(),
                Value<String?> departamento = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VeredasCompanion(
                id: id,
                vereda: vereda,
                municipio: municipio,
                departamento: departamento,
                remoteId: remoteId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String vereda,
                required String municipio,
                Value<String?> departamento = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VeredasCompanion.insert(
                id: id,
                vereda: vereda,
                municipio: municipio,
                departamento: departamento,
                remoteId: remoteId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VeredasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VeredasTable,
      Vereda,
      $$VeredasTableFilterComposer,
      $$VeredasTableOrderingComposer,
      $$VeredasTableAnnotationComposer,
      $$VeredasTableCreateCompanionBuilder,
      $$VeredasTableUpdateCompanionBuilder,
      (Vereda, BaseReferences<_$AppDatabase, $VeredasTable, Vereda>),
      Vereda,
      PrefetchHooks Function()
    >;
typedef $$VisitadoresTableCreateCompanionBuilder =
    VisitadoresCompanion Function({
      required String id,
      Value<String?> idEmpleado,
      required String nombre,
      required String usuarioApp,
      Value<String?> cargo,
      Value<String?> email,
      Value<String?> telefono,
      Value<String?> rol,
      Value<bool> activo,
      Value<String?> remoteId,
      Value<int> rowid,
    });
typedef $$VisitadoresTableUpdateCompanionBuilder =
    VisitadoresCompanion Function({
      Value<String> id,
      Value<String?> idEmpleado,
      Value<String> nombre,
      Value<String> usuarioApp,
      Value<String?> cargo,
      Value<String?> email,
      Value<String?> telefono,
      Value<String?> rol,
      Value<bool> activo,
      Value<String?> remoteId,
      Value<int> rowid,
    });

class $$VisitadoresTableFilterComposer
    extends Composer<_$AppDatabase, $VisitadoresTable> {
  $$VisitadoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idEmpleado => $composableBuilder(
    column: $table.idEmpleado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get usuarioApp => $composableBuilder(
    column: $table.usuarioApp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cargo => $composableBuilder(
    column: $table.cargo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get telefono => $composableBuilder(
    column: $table.telefono,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rol => $composableBuilder(
    column: $table.rol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VisitadoresTableOrderingComposer
    extends Composer<_$AppDatabase, $VisitadoresTable> {
  $$VisitadoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idEmpleado => $composableBuilder(
    column: $table.idEmpleado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get usuarioApp => $composableBuilder(
    column: $table.usuarioApp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cargo => $composableBuilder(
    column: $table.cargo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get telefono => $composableBuilder(
    column: $table.telefono,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rol => $composableBuilder(
    column: $table.rol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VisitadoresTableAnnotationComposer
    extends Composer<_$AppDatabase, $VisitadoresTable> {
  $$VisitadoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get idEmpleado => $composableBuilder(
    column: $table.idEmpleado,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get usuarioApp => $composableBuilder(
    column: $table.usuarioApp,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cargo =>
      $composableBuilder(column: $table.cargo, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get telefono =>
      $composableBuilder(column: $table.telefono, builder: (column) => column);

  GeneratedColumn<String> get rol =>
      $composableBuilder(column: $table.rol, builder: (column) => column);

  GeneratedColumn<bool> get activo =>
      $composableBuilder(column: $table.activo, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);
}

class $$VisitadoresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VisitadoresTable,
          Visitador,
          $$VisitadoresTableFilterComposer,
          $$VisitadoresTableOrderingComposer,
          $$VisitadoresTableAnnotationComposer,
          $$VisitadoresTableCreateCompanionBuilder,
          $$VisitadoresTableUpdateCompanionBuilder,
          (
            Visitador,
            BaseReferences<_$AppDatabase, $VisitadoresTable, Visitador>,
          ),
          Visitador,
          PrefetchHooks Function()
        > {
  $$VisitadoresTableTableManager(_$AppDatabase db, $VisitadoresTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VisitadoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VisitadoresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VisitadoresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> idEmpleado = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String> usuarioApp = const Value.absent(),
                Value<String?> cargo = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> telefono = const Value.absent(),
                Value<String?> rol = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VisitadoresCompanion(
                id: id,
                idEmpleado: idEmpleado,
                nombre: nombre,
                usuarioApp: usuarioApp,
                cargo: cargo,
                email: email,
                telefono: telefono,
                rol: rol,
                activo: activo,
                remoteId: remoteId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> idEmpleado = const Value.absent(),
                required String nombre,
                required String usuarioApp,
                Value<String?> cargo = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> telefono = const Value.absent(),
                Value<String?> rol = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VisitadoresCompanion.insert(
                id: id,
                idEmpleado: idEmpleado,
                nombre: nombre,
                usuarioApp: usuarioApp,
                cargo: cargo,
                email: email,
                telefono: telefono,
                rol: rol,
                activo: activo,
                remoteId: remoteId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VisitadoresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VisitadoresTable,
      Visitador,
      $$VisitadoresTableFilterComposer,
      $$VisitadoresTableOrderingComposer,
      $$VisitadoresTableAnnotationComposer,
      $$VisitadoresTableCreateCompanionBuilder,
      $$VisitadoresTableUpdateCompanionBuilder,
      (Visitador, BaseReferences<_$AppDatabase, $VisitadoresTable, Visitador>),
      Visitador,
      PrefetchHooks Function()
    >;
typedef $$CredencialesLocalesTableCreateCompanionBuilder =
    CredencialesLocalesCompanion Function({
      required String cedula,
      required String idEmpleado,
      required String nombre,
      Value<String?> email,
      required String hashBcrypt,
      Value<String> rolApp,
      Value<String?> nivelAcceso,
      Value<int> ordenNivel,
      required DateTime ultimoLoginOnline,
      required DateTime validoHasta,
      Value<String?> fotoUrl,
      Value<String?> fotoPath,
      Value<int> rowid,
    });
typedef $$CredencialesLocalesTableUpdateCompanionBuilder =
    CredencialesLocalesCompanion Function({
      Value<String> cedula,
      Value<String> idEmpleado,
      Value<String> nombre,
      Value<String?> email,
      Value<String> hashBcrypt,
      Value<String> rolApp,
      Value<String?> nivelAcceso,
      Value<int> ordenNivel,
      Value<DateTime> ultimoLoginOnline,
      Value<DateTime> validoHasta,
      Value<String?> fotoUrl,
      Value<String?> fotoPath,
      Value<int> rowid,
    });

class $$CredencialesLocalesTableFilterComposer
    extends Composer<_$AppDatabase, $CredencialesLocalesTable> {
  $$CredencialesLocalesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cedula => $composableBuilder(
    column: $table.cedula,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idEmpleado => $composableBuilder(
    column: $table.idEmpleado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hashBcrypt => $composableBuilder(
    column: $table.hashBcrypt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rolApp => $composableBuilder(
    column: $table.rolApp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nivelAcceso => $composableBuilder(
    column: $table.nivelAcceso,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ordenNivel => $composableBuilder(
    column: $table.ordenNivel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get ultimoLoginOnline => $composableBuilder(
    column: $table.ultimoLoginOnline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get validoHasta => $composableBuilder(
    column: $table.validoHasta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fotoUrl => $composableBuilder(
    column: $table.fotoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fotoPath => $composableBuilder(
    column: $table.fotoPath,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CredencialesLocalesTableOrderingComposer
    extends Composer<_$AppDatabase, $CredencialesLocalesTable> {
  $$CredencialesLocalesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cedula => $composableBuilder(
    column: $table.cedula,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idEmpleado => $composableBuilder(
    column: $table.idEmpleado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hashBcrypt => $composableBuilder(
    column: $table.hashBcrypt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rolApp => $composableBuilder(
    column: $table.rolApp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nivelAcceso => $composableBuilder(
    column: $table.nivelAcceso,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ordenNivel => $composableBuilder(
    column: $table.ordenNivel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get ultimoLoginOnline => $composableBuilder(
    column: $table.ultimoLoginOnline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get validoHasta => $composableBuilder(
    column: $table.validoHasta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fotoUrl => $composableBuilder(
    column: $table.fotoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fotoPath => $composableBuilder(
    column: $table.fotoPath,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CredencialesLocalesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CredencialesLocalesTable> {
  $$CredencialesLocalesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cedula =>
      $composableBuilder(column: $table.cedula, builder: (column) => column);

  GeneratedColumn<String> get idEmpleado => $composableBuilder(
    column: $table.idEmpleado,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get hashBcrypt => $composableBuilder(
    column: $table.hashBcrypt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rolApp =>
      $composableBuilder(column: $table.rolApp, builder: (column) => column);

  GeneratedColumn<String> get nivelAcceso => $composableBuilder(
    column: $table.nivelAcceso,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ordenNivel => $composableBuilder(
    column: $table.ordenNivel,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get ultimoLoginOnline => $composableBuilder(
    column: $table.ultimoLoginOnline,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get validoHasta => $composableBuilder(
    column: $table.validoHasta,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fotoUrl =>
      $composableBuilder(column: $table.fotoUrl, builder: (column) => column);

  GeneratedColumn<String> get fotoPath =>
      $composableBuilder(column: $table.fotoPath, builder: (column) => column);
}

class $$CredencialesLocalesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CredencialesLocalesTable,
          CredencialLocal,
          $$CredencialesLocalesTableFilterComposer,
          $$CredencialesLocalesTableOrderingComposer,
          $$CredencialesLocalesTableAnnotationComposer,
          $$CredencialesLocalesTableCreateCompanionBuilder,
          $$CredencialesLocalesTableUpdateCompanionBuilder,
          (
            CredencialLocal,
            BaseReferences<
              _$AppDatabase,
              $CredencialesLocalesTable,
              CredencialLocal
            >,
          ),
          CredencialLocal,
          PrefetchHooks Function()
        > {
  $$CredencialesLocalesTableTableManager(
    _$AppDatabase db,
    $CredencialesLocalesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CredencialesLocalesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CredencialesLocalesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CredencialesLocalesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> cedula = const Value.absent(),
                Value<String> idEmpleado = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String> hashBcrypt = const Value.absent(),
                Value<String> rolApp = const Value.absent(),
                Value<String?> nivelAcceso = const Value.absent(),
                Value<int> ordenNivel = const Value.absent(),
                Value<DateTime> ultimoLoginOnline = const Value.absent(),
                Value<DateTime> validoHasta = const Value.absent(),
                Value<String?> fotoUrl = const Value.absent(),
                Value<String?> fotoPath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CredencialesLocalesCompanion(
                cedula: cedula,
                idEmpleado: idEmpleado,
                nombre: nombre,
                email: email,
                hashBcrypt: hashBcrypt,
                rolApp: rolApp,
                nivelAcceso: nivelAcceso,
                ordenNivel: ordenNivel,
                ultimoLoginOnline: ultimoLoginOnline,
                validoHasta: validoHasta,
                fotoUrl: fotoUrl,
                fotoPath: fotoPath,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cedula,
                required String idEmpleado,
                required String nombre,
                Value<String?> email = const Value.absent(),
                required String hashBcrypt,
                Value<String> rolApp = const Value.absent(),
                Value<String?> nivelAcceso = const Value.absent(),
                Value<int> ordenNivel = const Value.absent(),
                required DateTime ultimoLoginOnline,
                required DateTime validoHasta,
                Value<String?> fotoUrl = const Value.absent(),
                Value<String?> fotoPath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CredencialesLocalesCompanion.insert(
                cedula: cedula,
                idEmpleado: idEmpleado,
                nombre: nombre,
                email: email,
                hashBcrypt: hashBcrypt,
                rolApp: rolApp,
                nivelAcceso: nivelAcceso,
                ordenNivel: ordenNivel,
                ultimoLoginOnline: ultimoLoginOnline,
                validoHasta: validoHasta,
                fotoUrl: fotoUrl,
                fotoPath: fotoPath,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CredencialesLocalesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CredencialesLocalesTable,
      CredencialLocal,
      $$CredencialesLocalesTableFilterComposer,
      $$CredencialesLocalesTableOrderingComposer,
      $$CredencialesLocalesTableAnnotationComposer,
      $$CredencialesLocalesTableCreateCompanionBuilder,
      $$CredencialesLocalesTableUpdateCompanionBuilder,
      (
        CredencialLocal,
        BaseReferences<
          _$AppDatabase,
          $CredencialesLocalesTable,
          CredencialLocal
        >,
      ),
      CredencialLocal,
      PrefetchHooks Function()
    >;
typedef $$SesionesTableCreateCompanionBuilder =
    SesionesCompanion Function({
      Value<int> unica,
      required String cedula,
      required DateTime abierta,
      Value<bool> offline,
    });
typedef $$SesionesTableUpdateCompanionBuilder =
    SesionesCompanion Function({
      Value<int> unica,
      Value<String> cedula,
      Value<DateTime> abierta,
      Value<bool> offline,
    });

class $$SesionesTableFilterComposer
    extends Composer<_$AppDatabase, $SesionesTable> {
  $$SesionesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get unica => $composableBuilder(
    column: $table.unica,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cedula => $composableBuilder(
    column: $table.cedula,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get abierta => $composableBuilder(
    column: $table.abierta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get offline => $composableBuilder(
    column: $table.offline,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SesionesTableOrderingComposer
    extends Composer<_$AppDatabase, $SesionesTable> {
  $$SesionesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get unica => $composableBuilder(
    column: $table.unica,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cedula => $composableBuilder(
    column: $table.cedula,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get abierta => $composableBuilder(
    column: $table.abierta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get offline => $composableBuilder(
    column: $table.offline,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SesionesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SesionesTable> {
  $$SesionesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get unica =>
      $composableBuilder(column: $table.unica, builder: (column) => column);

  GeneratedColumn<String> get cedula =>
      $composableBuilder(column: $table.cedula, builder: (column) => column);

  GeneratedColumn<DateTime> get abierta =>
      $composableBuilder(column: $table.abierta, builder: (column) => column);

  GeneratedColumn<bool> get offline =>
      $composableBuilder(column: $table.offline, builder: (column) => column);
}

class $$SesionesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SesionesTable,
          Sesion,
          $$SesionesTableFilterComposer,
          $$SesionesTableOrderingComposer,
          $$SesionesTableAnnotationComposer,
          $$SesionesTableCreateCompanionBuilder,
          $$SesionesTableUpdateCompanionBuilder,
          (Sesion, BaseReferences<_$AppDatabase, $SesionesTable, Sesion>),
          Sesion,
          PrefetchHooks Function()
        > {
  $$SesionesTableTableManager(_$AppDatabase db, $SesionesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SesionesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SesionesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SesionesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> unica = const Value.absent(),
                Value<String> cedula = const Value.absent(),
                Value<DateTime> abierta = const Value.absent(),
                Value<bool> offline = const Value.absent(),
              }) => SesionesCompanion(
                unica: unica,
                cedula: cedula,
                abierta: abierta,
                offline: offline,
              ),
          createCompanionCallback:
              ({
                Value<int> unica = const Value.absent(),
                required String cedula,
                required DateTime abierta,
                Value<bool> offline = const Value.absent(),
              }) => SesionesCompanion.insert(
                unica: unica,
                cedula: cedula,
                abierta: abierta,
                offline: offline,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SesionesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SesionesTable,
      Sesion,
      $$SesionesTableFilterComposer,
      $$SesionesTableOrderingComposer,
      $$SesionesTableAnnotationComposer,
      $$SesionesTableCreateCompanionBuilder,
      $$SesionesTableUpdateCompanionBuilder,
      (Sesion, BaseReferences<_$AppDatabase, $SesionesTable, Sesion>),
      Sesion,
      PrefetchHooks Function()
    >;
typedef $$ProductoresTableCreateCompanionBuilder =
    ProductoresCompanion Function({
      required String id,
      required String nombreCompleto,
      Value<String?> documento,
      Value<String?> tipoDocumento,
      Value<String?> telefono,
      Value<String?> telefonoAlterno,
      Value<String?> genero,
      Value<DateTime?> fechaNacimiento,
      Value<String?> nivelEducativo,
      Value<int?> aniosExperiencia,
      Value<int?> personasHogar,
      Value<String?> organizacion,
      Value<String?> notas,
      Value<String?> fotoPath,
      Value<String?> enlaceFoto,
      Value<String?> fotoRemota,
      Value<bool> consentimientoDatos,
      Value<DateTime?> fechaConsentimiento,
      Value<DateTime?> datosCompletadosEn,
      Value<String?> codigoProductor,
      Value<String?> remoteId,
      Value<bool> sincronizado,
      Value<int> rowid,
    });
typedef $$ProductoresTableUpdateCompanionBuilder =
    ProductoresCompanion Function({
      Value<String> id,
      Value<String> nombreCompleto,
      Value<String?> documento,
      Value<String?> tipoDocumento,
      Value<String?> telefono,
      Value<String?> telefonoAlterno,
      Value<String?> genero,
      Value<DateTime?> fechaNacimiento,
      Value<String?> nivelEducativo,
      Value<int?> aniosExperiencia,
      Value<int?> personasHogar,
      Value<String?> organizacion,
      Value<String?> notas,
      Value<String?> fotoPath,
      Value<String?> enlaceFoto,
      Value<String?> fotoRemota,
      Value<bool> consentimientoDatos,
      Value<DateTime?> fechaConsentimiento,
      Value<DateTime?> datosCompletadosEn,
      Value<String?> codigoProductor,
      Value<String?> remoteId,
      Value<bool> sincronizado,
      Value<int> rowid,
    });

class $$ProductoresTableFilterComposer
    extends Composer<_$AppDatabase, $ProductoresTable> {
  $$ProductoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombreCompleto => $composableBuilder(
    column: $table.nombreCompleto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documento => $composableBuilder(
    column: $table.documento,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipoDocumento => $composableBuilder(
    column: $table.tipoDocumento,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get telefono => $composableBuilder(
    column: $table.telefono,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get telefonoAlterno => $composableBuilder(
    column: $table.telefonoAlterno,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genero => $composableBuilder(
    column: $table.genero,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fechaNacimiento => $composableBuilder(
    column: $table.fechaNacimiento,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nivelEducativo => $composableBuilder(
    column: $table.nivelEducativo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get aniosExperiencia => $composableBuilder(
    column: $table.aniosExperiencia,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get personasHogar => $composableBuilder(
    column: $table.personasHogar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get organizacion => $composableBuilder(
    column: $table.organizacion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notas => $composableBuilder(
    column: $table.notas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fotoPath => $composableBuilder(
    column: $table.fotoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get enlaceFoto => $composableBuilder(
    column: $table.enlaceFoto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fotoRemota => $composableBuilder(
    column: $table.fotoRemota,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get consentimientoDatos => $composableBuilder(
    column: $table.consentimientoDatos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fechaConsentimiento => $composableBuilder(
    column: $table.fechaConsentimiento,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get datosCompletadosEn => $composableBuilder(
    column: $table.datosCompletadosEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codigoProductor => $composableBuilder(
    column: $table.codigoProductor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get sincronizado => $composableBuilder(
    column: $table.sincronizado,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductoresTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductoresTable> {
  $$ProductoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombreCompleto => $composableBuilder(
    column: $table.nombreCompleto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documento => $composableBuilder(
    column: $table.documento,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipoDocumento => $composableBuilder(
    column: $table.tipoDocumento,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get telefono => $composableBuilder(
    column: $table.telefono,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get telefonoAlterno => $composableBuilder(
    column: $table.telefonoAlterno,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genero => $composableBuilder(
    column: $table.genero,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaNacimiento => $composableBuilder(
    column: $table.fechaNacimiento,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nivelEducativo => $composableBuilder(
    column: $table.nivelEducativo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get aniosExperiencia => $composableBuilder(
    column: $table.aniosExperiencia,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get personasHogar => $composableBuilder(
    column: $table.personasHogar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get organizacion => $composableBuilder(
    column: $table.organizacion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notas => $composableBuilder(
    column: $table.notas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fotoPath => $composableBuilder(
    column: $table.fotoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get enlaceFoto => $composableBuilder(
    column: $table.enlaceFoto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fotoRemota => $composableBuilder(
    column: $table.fotoRemota,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get consentimientoDatos => $composableBuilder(
    column: $table.consentimientoDatos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaConsentimiento => $composableBuilder(
    column: $table.fechaConsentimiento,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get datosCompletadosEn => $composableBuilder(
    column: $table.datosCompletadosEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codigoProductor => $composableBuilder(
    column: $table.codigoProductor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get sincronizado => $composableBuilder(
    column: $table.sincronizado,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductoresTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductoresTable> {
  $$ProductoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombreCompleto => $composableBuilder(
    column: $table.nombreCompleto,
    builder: (column) => column,
  );

  GeneratedColumn<String> get documento =>
      $composableBuilder(column: $table.documento, builder: (column) => column);

  GeneratedColumn<String> get tipoDocumento => $composableBuilder(
    column: $table.tipoDocumento,
    builder: (column) => column,
  );

  GeneratedColumn<String> get telefono =>
      $composableBuilder(column: $table.telefono, builder: (column) => column);

  GeneratedColumn<String> get telefonoAlterno => $composableBuilder(
    column: $table.telefonoAlterno,
    builder: (column) => column,
  );

  GeneratedColumn<String> get genero =>
      $composableBuilder(column: $table.genero, builder: (column) => column);

  GeneratedColumn<DateTime> get fechaNacimiento => $composableBuilder(
    column: $table.fechaNacimiento,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nivelEducativo => $composableBuilder(
    column: $table.nivelEducativo,
    builder: (column) => column,
  );

  GeneratedColumn<int> get aniosExperiencia => $composableBuilder(
    column: $table.aniosExperiencia,
    builder: (column) => column,
  );

  GeneratedColumn<int> get personasHogar => $composableBuilder(
    column: $table.personasHogar,
    builder: (column) => column,
  );

  GeneratedColumn<String> get organizacion => $composableBuilder(
    column: $table.organizacion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notas =>
      $composableBuilder(column: $table.notas, builder: (column) => column);

  GeneratedColumn<String> get fotoPath =>
      $composableBuilder(column: $table.fotoPath, builder: (column) => column);

  GeneratedColumn<String> get enlaceFoto => $composableBuilder(
    column: $table.enlaceFoto,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fotoRemota => $composableBuilder(
    column: $table.fotoRemota,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get consentimientoDatos => $composableBuilder(
    column: $table.consentimientoDatos,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fechaConsentimiento => $composableBuilder(
    column: $table.fechaConsentimiento,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get datosCompletadosEn => $composableBuilder(
    column: $table.datosCompletadosEn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get codigoProductor => $composableBuilder(
    column: $table.codigoProductor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<bool> get sincronizado => $composableBuilder(
    column: $table.sincronizado,
    builder: (column) => column,
  );
}

class $$ProductoresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductoresTable,
          Productor,
          $$ProductoresTableFilterComposer,
          $$ProductoresTableOrderingComposer,
          $$ProductoresTableAnnotationComposer,
          $$ProductoresTableCreateCompanionBuilder,
          $$ProductoresTableUpdateCompanionBuilder,
          (
            Productor,
            BaseReferences<_$AppDatabase, $ProductoresTable, Productor>,
          ),
          Productor,
          PrefetchHooks Function()
        > {
  $$ProductoresTableTableManager(_$AppDatabase db, $ProductoresTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductoresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductoresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nombreCompleto = const Value.absent(),
                Value<String?> documento = const Value.absent(),
                Value<String?> tipoDocumento = const Value.absent(),
                Value<String?> telefono = const Value.absent(),
                Value<String?> telefonoAlterno = const Value.absent(),
                Value<String?> genero = const Value.absent(),
                Value<DateTime?> fechaNacimiento = const Value.absent(),
                Value<String?> nivelEducativo = const Value.absent(),
                Value<int?> aniosExperiencia = const Value.absent(),
                Value<int?> personasHogar = const Value.absent(),
                Value<String?> organizacion = const Value.absent(),
                Value<String?> notas = const Value.absent(),
                Value<String?> fotoPath = const Value.absent(),
                Value<String?> enlaceFoto = const Value.absent(),
                Value<String?> fotoRemota = const Value.absent(),
                Value<bool> consentimientoDatos = const Value.absent(),
                Value<DateTime?> fechaConsentimiento = const Value.absent(),
                Value<DateTime?> datosCompletadosEn = const Value.absent(),
                Value<String?> codigoProductor = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<bool> sincronizado = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductoresCompanion(
                id: id,
                nombreCompleto: nombreCompleto,
                documento: documento,
                tipoDocumento: tipoDocumento,
                telefono: telefono,
                telefonoAlterno: telefonoAlterno,
                genero: genero,
                fechaNacimiento: fechaNacimiento,
                nivelEducativo: nivelEducativo,
                aniosExperiencia: aniosExperiencia,
                personasHogar: personasHogar,
                organizacion: organizacion,
                notas: notas,
                fotoPath: fotoPath,
                enlaceFoto: enlaceFoto,
                fotoRemota: fotoRemota,
                consentimientoDatos: consentimientoDatos,
                fechaConsentimiento: fechaConsentimiento,
                datosCompletadosEn: datosCompletadosEn,
                codigoProductor: codigoProductor,
                remoteId: remoteId,
                sincronizado: sincronizado,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nombreCompleto,
                Value<String?> documento = const Value.absent(),
                Value<String?> tipoDocumento = const Value.absent(),
                Value<String?> telefono = const Value.absent(),
                Value<String?> telefonoAlterno = const Value.absent(),
                Value<String?> genero = const Value.absent(),
                Value<DateTime?> fechaNacimiento = const Value.absent(),
                Value<String?> nivelEducativo = const Value.absent(),
                Value<int?> aniosExperiencia = const Value.absent(),
                Value<int?> personasHogar = const Value.absent(),
                Value<String?> organizacion = const Value.absent(),
                Value<String?> notas = const Value.absent(),
                Value<String?> fotoPath = const Value.absent(),
                Value<String?> enlaceFoto = const Value.absent(),
                Value<String?> fotoRemota = const Value.absent(),
                Value<bool> consentimientoDatos = const Value.absent(),
                Value<DateTime?> fechaConsentimiento = const Value.absent(),
                Value<DateTime?> datosCompletadosEn = const Value.absent(),
                Value<String?> codigoProductor = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<bool> sincronizado = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductoresCompanion.insert(
                id: id,
                nombreCompleto: nombreCompleto,
                documento: documento,
                tipoDocumento: tipoDocumento,
                telefono: telefono,
                telefonoAlterno: telefonoAlterno,
                genero: genero,
                fechaNacimiento: fechaNacimiento,
                nivelEducativo: nivelEducativo,
                aniosExperiencia: aniosExperiencia,
                personasHogar: personasHogar,
                organizacion: organizacion,
                notas: notas,
                fotoPath: fotoPath,
                enlaceFoto: enlaceFoto,
                fotoRemota: fotoRemota,
                consentimientoDatos: consentimientoDatos,
                fechaConsentimiento: fechaConsentimiento,
                datosCompletadosEn: datosCompletadosEn,
                codigoProductor: codigoProductor,
                remoteId: remoteId,
                sincronizado: sincronizado,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductoresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductoresTable,
      Productor,
      $$ProductoresTableFilterComposer,
      $$ProductoresTableOrderingComposer,
      $$ProductoresTableAnnotationComposer,
      $$ProductoresTableCreateCompanionBuilder,
      $$ProductoresTableUpdateCompanionBuilder,
      (Productor, BaseReferences<_$AppDatabase, $ProductoresTable, Productor>),
      Productor,
      PrefetchHooks Function()
    >;
typedef $$FincasTableCreateCompanionBuilder =
    FincasCompanion Function({
      required String id,
      required String productorLocalId,
      required String nombre,
      Value<String?> veredaLocalId,
      Value<double?> latitud,
      Value<double?> longitud,
      Value<double?> areaTotalHa,
      Value<String?> remoteId,
      Value<bool> sincronizada,
      Value<int> rowid,
    });
typedef $$FincasTableUpdateCompanionBuilder =
    FincasCompanion Function({
      Value<String> id,
      Value<String> productorLocalId,
      Value<String> nombre,
      Value<String?> veredaLocalId,
      Value<double?> latitud,
      Value<double?> longitud,
      Value<double?> areaTotalHa,
      Value<String?> remoteId,
      Value<bool> sincronizada,
      Value<int> rowid,
    });

class $$FincasTableFilterComposer
    extends Composer<_$AppDatabase, $FincasTable> {
  $$FincasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productorLocalId => $composableBuilder(
    column: $table.productorLocalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get veredaLocalId => $composableBuilder(
    column: $table.veredaLocalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitud => $composableBuilder(
    column: $table.latitud,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitud => $composableBuilder(
    column: $table.longitud,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get areaTotalHa => $composableBuilder(
    column: $table.areaTotalHa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get sincronizada => $composableBuilder(
    column: $table.sincronizada,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FincasTableOrderingComposer
    extends Composer<_$AppDatabase, $FincasTable> {
  $$FincasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productorLocalId => $composableBuilder(
    column: $table.productorLocalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get veredaLocalId => $composableBuilder(
    column: $table.veredaLocalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitud => $composableBuilder(
    column: $table.latitud,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitud => $composableBuilder(
    column: $table.longitud,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get areaTotalHa => $composableBuilder(
    column: $table.areaTotalHa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get sincronizada => $composableBuilder(
    column: $table.sincronizada,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FincasTableAnnotationComposer
    extends Composer<_$AppDatabase, $FincasTable> {
  $$FincasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get productorLocalId => $composableBuilder(
    column: $table.productorLocalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get veredaLocalId => $composableBuilder(
    column: $table.veredaLocalId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latitud =>
      $composableBuilder(column: $table.latitud, builder: (column) => column);

  GeneratedColumn<double> get longitud =>
      $composableBuilder(column: $table.longitud, builder: (column) => column);

  GeneratedColumn<double> get areaTotalHa => $composableBuilder(
    column: $table.areaTotalHa,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<bool> get sincronizada => $composableBuilder(
    column: $table.sincronizada,
    builder: (column) => column,
  );
}

class $$FincasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FincasTable,
          Finca,
          $$FincasTableFilterComposer,
          $$FincasTableOrderingComposer,
          $$FincasTableAnnotationComposer,
          $$FincasTableCreateCompanionBuilder,
          $$FincasTableUpdateCompanionBuilder,
          (Finca, BaseReferences<_$AppDatabase, $FincasTable, Finca>),
          Finca,
          PrefetchHooks Function()
        > {
  $$FincasTableTableManager(_$AppDatabase db, $FincasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FincasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FincasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FincasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> productorLocalId = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String?> veredaLocalId = const Value.absent(),
                Value<double?> latitud = const Value.absent(),
                Value<double?> longitud = const Value.absent(),
                Value<double?> areaTotalHa = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<bool> sincronizada = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FincasCompanion(
                id: id,
                productorLocalId: productorLocalId,
                nombre: nombre,
                veredaLocalId: veredaLocalId,
                latitud: latitud,
                longitud: longitud,
                areaTotalHa: areaTotalHa,
                remoteId: remoteId,
                sincronizada: sincronizada,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String productorLocalId,
                required String nombre,
                Value<String?> veredaLocalId = const Value.absent(),
                Value<double?> latitud = const Value.absent(),
                Value<double?> longitud = const Value.absent(),
                Value<double?> areaTotalHa = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<bool> sincronizada = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FincasCompanion.insert(
                id: id,
                productorLocalId: productorLocalId,
                nombre: nombre,
                veredaLocalId: veredaLocalId,
                latitud: latitud,
                longitud: longitud,
                areaTotalHa: areaTotalHa,
                remoteId: remoteId,
                sincronizada: sincronizada,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FincasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FincasTable,
      Finca,
      $$FincasTableFilterComposer,
      $$FincasTableOrderingComposer,
      $$FincasTableAnnotationComposer,
      $$FincasTableCreateCompanionBuilder,
      $$FincasTableUpdateCompanionBuilder,
      (Finca, BaseReferences<_$AppDatabase, $FincasTable, Finca>),
      Finca,
      PrefetchHooks Function()
    >;
typedef $$VisitasTableCreateCompanionBuilder =
    VisitasCompanion Function({
      required String id,
      required DateTime inicio,
      Value<DateTime?> fin,
      Value<String?> visitadorLocalId,
      Value<String?> productorLocalId,
      Value<String?> fincaLocalId,
      Value<String?> veredaLocalId,
      Value<String?> tipoVisita,
      Value<double?> latitud,
      Value<double?> longitud,
      Value<double?> precisionGps,
      Value<String> estado,
      Value<bool> consienteAudio,
      Value<bool> consienteFotos,
      Value<bool> consienteUsoDatos,
      Value<int?> segundoConsentimiento,
      Value<bool> marcadaParaEliminacion,
      Value<String?> objetivo,
      Value<String?> observaciones,
      Value<String?> resumen,
      Value<String?> temasPendientes,
      Value<String?> notasPruebaCampo,
      Value<int> completitudPct,
      Value<bool> sincronizada,
      Value<DateTime?> sincronizadaEn,
      Value<bool> soloLectura,
      Value<DateTime?> descargadaEn,
      Value<DateTime?> detalleEn,
      Value<int> rowid,
    });
typedef $$VisitasTableUpdateCompanionBuilder =
    VisitasCompanion Function({
      Value<String> id,
      Value<DateTime> inicio,
      Value<DateTime?> fin,
      Value<String?> visitadorLocalId,
      Value<String?> productorLocalId,
      Value<String?> fincaLocalId,
      Value<String?> veredaLocalId,
      Value<String?> tipoVisita,
      Value<double?> latitud,
      Value<double?> longitud,
      Value<double?> precisionGps,
      Value<String> estado,
      Value<bool> consienteAudio,
      Value<bool> consienteFotos,
      Value<bool> consienteUsoDatos,
      Value<int?> segundoConsentimiento,
      Value<bool> marcadaParaEliminacion,
      Value<String?> objetivo,
      Value<String?> observaciones,
      Value<String?> resumen,
      Value<String?> temasPendientes,
      Value<String?> notasPruebaCampo,
      Value<int> completitudPct,
      Value<bool> sincronizada,
      Value<DateTime?> sincronizadaEn,
      Value<bool> soloLectura,
      Value<DateTime?> descargadaEn,
      Value<DateTime?> detalleEn,
      Value<int> rowid,
    });

class $$VisitasTableFilterComposer
    extends Composer<_$AppDatabase, $VisitasTable> {
  $$VisitasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get inicio => $composableBuilder(
    column: $table.inicio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fin => $composableBuilder(
    column: $table.fin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visitadorLocalId => $composableBuilder(
    column: $table.visitadorLocalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productorLocalId => $composableBuilder(
    column: $table.productorLocalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fincaLocalId => $composableBuilder(
    column: $table.fincaLocalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get veredaLocalId => $composableBuilder(
    column: $table.veredaLocalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipoVisita => $composableBuilder(
    column: $table.tipoVisita,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitud => $composableBuilder(
    column: $table.latitud,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitud => $composableBuilder(
    column: $table.longitud,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get precisionGps => $composableBuilder(
    column: $table.precisionGps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get consienteAudio => $composableBuilder(
    column: $table.consienteAudio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get consienteFotos => $composableBuilder(
    column: $table.consienteFotos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get consienteUsoDatos => $composableBuilder(
    column: $table.consienteUsoDatos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get segundoConsentimiento => $composableBuilder(
    column: $table.segundoConsentimiento,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get marcadaParaEliminacion => $composableBuilder(
    column: $table.marcadaParaEliminacion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get objetivo => $composableBuilder(
    column: $table.objetivo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get observaciones => $composableBuilder(
    column: $table.observaciones,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resumen => $composableBuilder(
    column: $table.resumen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get temasPendientes => $composableBuilder(
    column: $table.temasPendientes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notasPruebaCampo => $composableBuilder(
    column: $table.notasPruebaCampo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completitudPct => $composableBuilder(
    column: $table.completitudPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get sincronizada => $composableBuilder(
    column: $table.sincronizada,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sincronizadaEn => $composableBuilder(
    column: $table.sincronizadaEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get soloLectura => $composableBuilder(
    column: $table.soloLectura,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get descargadaEn => $composableBuilder(
    column: $table.descargadaEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get detalleEn => $composableBuilder(
    column: $table.detalleEn,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VisitasTableOrderingComposer
    extends Composer<_$AppDatabase, $VisitasTable> {
  $$VisitasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get inicio => $composableBuilder(
    column: $table.inicio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fin => $composableBuilder(
    column: $table.fin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visitadorLocalId => $composableBuilder(
    column: $table.visitadorLocalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productorLocalId => $composableBuilder(
    column: $table.productorLocalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fincaLocalId => $composableBuilder(
    column: $table.fincaLocalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get veredaLocalId => $composableBuilder(
    column: $table.veredaLocalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipoVisita => $composableBuilder(
    column: $table.tipoVisita,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitud => $composableBuilder(
    column: $table.latitud,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitud => $composableBuilder(
    column: $table.longitud,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get precisionGps => $composableBuilder(
    column: $table.precisionGps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get consienteAudio => $composableBuilder(
    column: $table.consienteAudio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get consienteFotos => $composableBuilder(
    column: $table.consienteFotos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get consienteUsoDatos => $composableBuilder(
    column: $table.consienteUsoDatos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get segundoConsentimiento => $composableBuilder(
    column: $table.segundoConsentimiento,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get marcadaParaEliminacion => $composableBuilder(
    column: $table.marcadaParaEliminacion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get objetivo => $composableBuilder(
    column: $table.objetivo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get observaciones => $composableBuilder(
    column: $table.observaciones,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resumen => $composableBuilder(
    column: $table.resumen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get temasPendientes => $composableBuilder(
    column: $table.temasPendientes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notasPruebaCampo => $composableBuilder(
    column: $table.notasPruebaCampo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completitudPct => $composableBuilder(
    column: $table.completitudPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get sincronizada => $composableBuilder(
    column: $table.sincronizada,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sincronizadaEn => $composableBuilder(
    column: $table.sincronizadaEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get soloLectura => $composableBuilder(
    column: $table.soloLectura,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get descargadaEn => $composableBuilder(
    column: $table.descargadaEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get detalleEn => $composableBuilder(
    column: $table.detalleEn,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VisitasTableAnnotationComposer
    extends Composer<_$AppDatabase, $VisitasTable> {
  $$VisitasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get inicio =>
      $composableBuilder(column: $table.inicio, builder: (column) => column);

  GeneratedColumn<DateTime> get fin =>
      $composableBuilder(column: $table.fin, builder: (column) => column);

  GeneratedColumn<String> get visitadorLocalId => $composableBuilder(
    column: $table.visitadorLocalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productorLocalId => $composableBuilder(
    column: $table.productorLocalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fincaLocalId => $composableBuilder(
    column: $table.fincaLocalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get veredaLocalId => $composableBuilder(
    column: $table.veredaLocalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tipoVisita => $composableBuilder(
    column: $table.tipoVisita,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latitud =>
      $composableBuilder(column: $table.latitud, builder: (column) => column);

  GeneratedColumn<double> get longitud =>
      $composableBuilder(column: $table.longitud, builder: (column) => column);

  GeneratedColumn<double> get precisionGps => $composableBuilder(
    column: $table.precisionGps,
    builder: (column) => column,
  );

  GeneratedColumn<String> get estado =>
      $composableBuilder(column: $table.estado, builder: (column) => column);

  GeneratedColumn<bool> get consienteAudio => $composableBuilder(
    column: $table.consienteAudio,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get consienteFotos => $composableBuilder(
    column: $table.consienteFotos,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get consienteUsoDatos => $composableBuilder(
    column: $table.consienteUsoDatos,
    builder: (column) => column,
  );

  GeneratedColumn<int> get segundoConsentimiento => $composableBuilder(
    column: $table.segundoConsentimiento,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get marcadaParaEliminacion => $composableBuilder(
    column: $table.marcadaParaEliminacion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get objetivo =>
      $composableBuilder(column: $table.objetivo, builder: (column) => column);

  GeneratedColumn<String> get observaciones => $composableBuilder(
    column: $table.observaciones,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resumen =>
      $composableBuilder(column: $table.resumen, builder: (column) => column);

  GeneratedColumn<String> get temasPendientes => $composableBuilder(
    column: $table.temasPendientes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notasPruebaCampo => $composableBuilder(
    column: $table.notasPruebaCampo,
    builder: (column) => column,
  );

  GeneratedColumn<int> get completitudPct => $composableBuilder(
    column: $table.completitudPct,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get sincronizada => $composableBuilder(
    column: $table.sincronizada,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get sincronizadaEn => $composableBuilder(
    column: $table.sincronizadaEn,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get soloLectura => $composableBuilder(
    column: $table.soloLectura,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get descargadaEn => $composableBuilder(
    column: $table.descargadaEn,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get detalleEn =>
      $composableBuilder(column: $table.detalleEn, builder: (column) => column);
}

class $$VisitasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VisitasTable,
          Visita,
          $$VisitasTableFilterComposer,
          $$VisitasTableOrderingComposer,
          $$VisitasTableAnnotationComposer,
          $$VisitasTableCreateCompanionBuilder,
          $$VisitasTableUpdateCompanionBuilder,
          (Visita, BaseReferences<_$AppDatabase, $VisitasTable, Visita>),
          Visita,
          PrefetchHooks Function()
        > {
  $$VisitasTableTableManager(_$AppDatabase db, $VisitasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VisitasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VisitasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VisitasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> inicio = const Value.absent(),
                Value<DateTime?> fin = const Value.absent(),
                Value<String?> visitadorLocalId = const Value.absent(),
                Value<String?> productorLocalId = const Value.absent(),
                Value<String?> fincaLocalId = const Value.absent(),
                Value<String?> veredaLocalId = const Value.absent(),
                Value<String?> tipoVisita = const Value.absent(),
                Value<double?> latitud = const Value.absent(),
                Value<double?> longitud = const Value.absent(),
                Value<double?> precisionGps = const Value.absent(),
                Value<String> estado = const Value.absent(),
                Value<bool> consienteAudio = const Value.absent(),
                Value<bool> consienteFotos = const Value.absent(),
                Value<bool> consienteUsoDatos = const Value.absent(),
                Value<int?> segundoConsentimiento = const Value.absent(),
                Value<bool> marcadaParaEliminacion = const Value.absent(),
                Value<String?> objetivo = const Value.absent(),
                Value<String?> observaciones = const Value.absent(),
                Value<String?> resumen = const Value.absent(),
                Value<String?> temasPendientes = const Value.absent(),
                Value<String?> notasPruebaCampo = const Value.absent(),
                Value<int> completitudPct = const Value.absent(),
                Value<bool> sincronizada = const Value.absent(),
                Value<DateTime?> sincronizadaEn = const Value.absent(),
                Value<bool> soloLectura = const Value.absent(),
                Value<DateTime?> descargadaEn = const Value.absent(),
                Value<DateTime?> detalleEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VisitasCompanion(
                id: id,
                inicio: inicio,
                fin: fin,
                visitadorLocalId: visitadorLocalId,
                productorLocalId: productorLocalId,
                fincaLocalId: fincaLocalId,
                veredaLocalId: veredaLocalId,
                tipoVisita: tipoVisita,
                latitud: latitud,
                longitud: longitud,
                precisionGps: precisionGps,
                estado: estado,
                consienteAudio: consienteAudio,
                consienteFotos: consienteFotos,
                consienteUsoDatos: consienteUsoDatos,
                segundoConsentimiento: segundoConsentimiento,
                marcadaParaEliminacion: marcadaParaEliminacion,
                objetivo: objetivo,
                observaciones: observaciones,
                resumen: resumen,
                temasPendientes: temasPendientes,
                notasPruebaCampo: notasPruebaCampo,
                completitudPct: completitudPct,
                sincronizada: sincronizada,
                sincronizadaEn: sincronizadaEn,
                soloLectura: soloLectura,
                descargadaEn: descargadaEn,
                detalleEn: detalleEn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime inicio,
                Value<DateTime?> fin = const Value.absent(),
                Value<String?> visitadorLocalId = const Value.absent(),
                Value<String?> productorLocalId = const Value.absent(),
                Value<String?> fincaLocalId = const Value.absent(),
                Value<String?> veredaLocalId = const Value.absent(),
                Value<String?> tipoVisita = const Value.absent(),
                Value<double?> latitud = const Value.absent(),
                Value<double?> longitud = const Value.absent(),
                Value<double?> precisionGps = const Value.absent(),
                Value<String> estado = const Value.absent(),
                Value<bool> consienteAudio = const Value.absent(),
                Value<bool> consienteFotos = const Value.absent(),
                Value<bool> consienteUsoDatos = const Value.absent(),
                Value<int?> segundoConsentimiento = const Value.absent(),
                Value<bool> marcadaParaEliminacion = const Value.absent(),
                Value<String?> objetivo = const Value.absent(),
                Value<String?> observaciones = const Value.absent(),
                Value<String?> resumen = const Value.absent(),
                Value<String?> temasPendientes = const Value.absent(),
                Value<String?> notasPruebaCampo = const Value.absent(),
                Value<int> completitudPct = const Value.absent(),
                Value<bool> sincronizada = const Value.absent(),
                Value<DateTime?> sincronizadaEn = const Value.absent(),
                Value<bool> soloLectura = const Value.absent(),
                Value<DateTime?> descargadaEn = const Value.absent(),
                Value<DateTime?> detalleEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VisitasCompanion.insert(
                id: id,
                inicio: inicio,
                fin: fin,
                visitadorLocalId: visitadorLocalId,
                productorLocalId: productorLocalId,
                fincaLocalId: fincaLocalId,
                veredaLocalId: veredaLocalId,
                tipoVisita: tipoVisita,
                latitud: latitud,
                longitud: longitud,
                precisionGps: precisionGps,
                estado: estado,
                consienteAudio: consienteAudio,
                consienteFotos: consienteFotos,
                consienteUsoDatos: consienteUsoDatos,
                segundoConsentimiento: segundoConsentimiento,
                marcadaParaEliminacion: marcadaParaEliminacion,
                objetivo: objetivo,
                observaciones: observaciones,
                resumen: resumen,
                temasPendientes: temasPendientes,
                notasPruebaCampo: notasPruebaCampo,
                completitudPct: completitudPct,
                sincronizada: sincronizada,
                sincronizadaEn: sincronizadaEn,
                soloLectura: soloLectura,
                descargadaEn: descargadaEn,
                detalleEn: detalleEn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VisitasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VisitasTable,
      Visita,
      $$VisitasTableFilterComposer,
      $$VisitasTableOrderingComposer,
      $$VisitasTableAnnotationComposer,
      $$VisitasTableCreateCompanionBuilder,
      $$VisitasTableUpdateCompanionBuilder,
      (Visita, BaseReferences<_$AppDatabase, $VisitasTable, Visita>),
      Visita,
      PrefetchHooks Function()
    >;
typedef $$GrabacionesTableCreateCompanionBuilder =
    GrabacionesCompanion Function({
      required String id,
      required String visitaId,
      required int orden,
      required String archivoPath,
      required DateTime inicio,
      Value<int> duracionSeg,
      Value<int> tamanoBytes,
      Value<String?> enlaceAudio,
      Value<String?> transcripcion,
      Value<String?> transcripcionMarcas,
      Value<String?> motorTranscripcion,
      Value<String> estado,
      Value<int> rowid,
    });
typedef $$GrabacionesTableUpdateCompanionBuilder =
    GrabacionesCompanion Function({
      Value<String> id,
      Value<String> visitaId,
      Value<int> orden,
      Value<String> archivoPath,
      Value<DateTime> inicio,
      Value<int> duracionSeg,
      Value<int> tamanoBytes,
      Value<String?> enlaceAudio,
      Value<String?> transcripcion,
      Value<String?> transcripcionMarcas,
      Value<String?> motorTranscripcion,
      Value<String> estado,
      Value<int> rowid,
    });

class $$GrabacionesTableFilterComposer
    extends Composer<_$AppDatabase, $GrabacionesTable> {
  $$GrabacionesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visitaId => $composableBuilder(
    column: $table.visitaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orden => $composableBuilder(
    column: $table.orden,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get archivoPath => $composableBuilder(
    column: $table.archivoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get inicio => $composableBuilder(
    column: $table.inicio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get duracionSeg => $composableBuilder(
    column: $table.duracionSeg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tamanoBytes => $composableBuilder(
    column: $table.tamanoBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get enlaceAudio => $composableBuilder(
    column: $table.enlaceAudio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transcripcion => $composableBuilder(
    column: $table.transcripcion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transcripcionMarcas => $composableBuilder(
    column: $table.transcripcionMarcas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get motorTranscripcion => $composableBuilder(
    column: $table.motorTranscripcion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GrabacionesTableOrderingComposer
    extends Composer<_$AppDatabase, $GrabacionesTable> {
  $$GrabacionesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visitaId => $composableBuilder(
    column: $table.visitaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orden => $composableBuilder(
    column: $table.orden,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get archivoPath => $composableBuilder(
    column: $table.archivoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get inicio => $composableBuilder(
    column: $table.inicio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get duracionSeg => $composableBuilder(
    column: $table.duracionSeg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tamanoBytes => $composableBuilder(
    column: $table.tamanoBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get enlaceAudio => $composableBuilder(
    column: $table.enlaceAudio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transcripcion => $composableBuilder(
    column: $table.transcripcion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transcripcionMarcas => $composableBuilder(
    column: $table.transcripcionMarcas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get motorTranscripcion => $composableBuilder(
    column: $table.motorTranscripcion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GrabacionesTableAnnotationComposer
    extends Composer<_$AppDatabase, $GrabacionesTable> {
  $$GrabacionesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get visitaId =>
      $composableBuilder(column: $table.visitaId, builder: (column) => column);

  GeneratedColumn<int> get orden =>
      $composableBuilder(column: $table.orden, builder: (column) => column);

  GeneratedColumn<String> get archivoPath => $composableBuilder(
    column: $table.archivoPath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get inicio =>
      $composableBuilder(column: $table.inicio, builder: (column) => column);

  GeneratedColumn<int> get duracionSeg => $composableBuilder(
    column: $table.duracionSeg,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tamanoBytes => $composableBuilder(
    column: $table.tamanoBytes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get enlaceAudio => $composableBuilder(
    column: $table.enlaceAudio,
    builder: (column) => column,
  );

  GeneratedColumn<String> get transcripcion => $composableBuilder(
    column: $table.transcripcion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get transcripcionMarcas => $composableBuilder(
    column: $table.transcripcionMarcas,
    builder: (column) => column,
  );

  GeneratedColumn<String> get motorTranscripcion => $composableBuilder(
    column: $table.motorTranscripcion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get estado =>
      $composableBuilder(column: $table.estado, builder: (column) => column);
}

class $$GrabacionesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GrabacionesTable,
          Grabacion,
          $$GrabacionesTableFilterComposer,
          $$GrabacionesTableOrderingComposer,
          $$GrabacionesTableAnnotationComposer,
          $$GrabacionesTableCreateCompanionBuilder,
          $$GrabacionesTableUpdateCompanionBuilder,
          (
            Grabacion,
            BaseReferences<_$AppDatabase, $GrabacionesTable, Grabacion>,
          ),
          Grabacion,
          PrefetchHooks Function()
        > {
  $$GrabacionesTableTableManager(_$AppDatabase db, $GrabacionesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GrabacionesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GrabacionesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GrabacionesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> visitaId = const Value.absent(),
                Value<int> orden = const Value.absent(),
                Value<String> archivoPath = const Value.absent(),
                Value<DateTime> inicio = const Value.absent(),
                Value<int> duracionSeg = const Value.absent(),
                Value<int> tamanoBytes = const Value.absent(),
                Value<String?> enlaceAudio = const Value.absent(),
                Value<String?> transcripcion = const Value.absent(),
                Value<String?> transcripcionMarcas = const Value.absent(),
                Value<String?> motorTranscripcion = const Value.absent(),
                Value<String> estado = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GrabacionesCompanion(
                id: id,
                visitaId: visitaId,
                orden: orden,
                archivoPath: archivoPath,
                inicio: inicio,
                duracionSeg: duracionSeg,
                tamanoBytes: tamanoBytes,
                enlaceAudio: enlaceAudio,
                transcripcion: transcripcion,
                transcripcionMarcas: transcripcionMarcas,
                motorTranscripcion: motorTranscripcion,
                estado: estado,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String visitaId,
                required int orden,
                required String archivoPath,
                required DateTime inicio,
                Value<int> duracionSeg = const Value.absent(),
                Value<int> tamanoBytes = const Value.absent(),
                Value<String?> enlaceAudio = const Value.absent(),
                Value<String?> transcripcion = const Value.absent(),
                Value<String?> transcripcionMarcas = const Value.absent(),
                Value<String?> motorTranscripcion = const Value.absent(),
                Value<String> estado = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GrabacionesCompanion.insert(
                id: id,
                visitaId: visitaId,
                orden: orden,
                archivoPath: archivoPath,
                inicio: inicio,
                duracionSeg: duracionSeg,
                tamanoBytes: tamanoBytes,
                enlaceAudio: enlaceAudio,
                transcripcion: transcripcion,
                transcripcionMarcas: transcripcionMarcas,
                motorTranscripcion: motorTranscripcion,
                estado: estado,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GrabacionesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GrabacionesTable,
      Grabacion,
      $$GrabacionesTableFilterComposer,
      $$GrabacionesTableOrderingComposer,
      $$GrabacionesTableAnnotationComposer,
      $$GrabacionesTableCreateCompanionBuilder,
      $$GrabacionesTableUpdateCompanionBuilder,
      (Grabacion, BaseReferences<_$AppDatabase, $GrabacionesTable, Grabacion>),
      Grabacion,
      PrefetchHooks Function()
    >;
typedef $$EvidenciasTableCreateCompanionBuilder =
    EvidenciasCompanion Function({
      required String id,
      required String visitaId,
      Value<String?> tipo,
      required String archivoPath,
      required DateTime tomadaEn,
      Value<double?> latitud,
      Value<double?> longitud,
      Value<int?> segundoAudio,
      Value<String?> descripcionVisitador,
      Value<String?> descripcionIa,
      Value<String?> textoOcr,
      Value<String?> enlaceArchivo,
      Value<String> estadoValidacion,
      Value<int> rowid,
    });
typedef $$EvidenciasTableUpdateCompanionBuilder =
    EvidenciasCompanion Function({
      Value<String> id,
      Value<String> visitaId,
      Value<String?> tipo,
      Value<String> archivoPath,
      Value<DateTime> tomadaEn,
      Value<double?> latitud,
      Value<double?> longitud,
      Value<int?> segundoAudio,
      Value<String?> descripcionVisitador,
      Value<String?> descripcionIa,
      Value<String?> textoOcr,
      Value<String?> enlaceArchivo,
      Value<String> estadoValidacion,
      Value<int> rowid,
    });

class $$EvidenciasTableFilterComposer
    extends Composer<_$AppDatabase, $EvidenciasTable> {
  $$EvidenciasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visitaId => $composableBuilder(
    column: $table.visitaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get archivoPath => $composableBuilder(
    column: $table.archivoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get tomadaEn => $composableBuilder(
    column: $table.tomadaEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitud => $composableBuilder(
    column: $table.latitud,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitud => $composableBuilder(
    column: $table.longitud,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get segundoAudio => $composableBuilder(
    column: $table.segundoAudio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descripcionVisitador => $composableBuilder(
    column: $table.descripcionVisitador,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descripcionIa => $composableBuilder(
    column: $table.descripcionIa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textoOcr => $composableBuilder(
    column: $table.textoOcr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get enlaceArchivo => $composableBuilder(
    column: $table.enlaceArchivo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get estadoValidacion => $composableBuilder(
    column: $table.estadoValidacion,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EvidenciasTableOrderingComposer
    extends Composer<_$AppDatabase, $EvidenciasTable> {
  $$EvidenciasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visitaId => $composableBuilder(
    column: $table.visitaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get archivoPath => $composableBuilder(
    column: $table.archivoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get tomadaEn => $composableBuilder(
    column: $table.tomadaEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitud => $composableBuilder(
    column: $table.latitud,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitud => $composableBuilder(
    column: $table.longitud,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get segundoAudio => $composableBuilder(
    column: $table.segundoAudio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descripcionVisitador => $composableBuilder(
    column: $table.descripcionVisitador,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descripcionIa => $composableBuilder(
    column: $table.descripcionIa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textoOcr => $composableBuilder(
    column: $table.textoOcr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get enlaceArchivo => $composableBuilder(
    column: $table.enlaceArchivo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get estadoValidacion => $composableBuilder(
    column: $table.estadoValidacion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EvidenciasTableAnnotationComposer
    extends Composer<_$AppDatabase, $EvidenciasTable> {
  $$EvidenciasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get visitaId =>
      $composableBuilder(column: $table.visitaId, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<String> get archivoPath => $composableBuilder(
    column: $table.archivoPath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get tomadaEn =>
      $composableBuilder(column: $table.tomadaEn, builder: (column) => column);

  GeneratedColumn<double> get latitud =>
      $composableBuilder(column: $table.latitud, builder: (column) => column);

  GeneratedColumn<double> get longitud =>
      $composableBuilder(column: $table.longitud, builder: (column) => column);

  GeneratedColumn<int> get segundoAudio => $composableBuilder(
    column: $table.segundoAudio,
    builder: (column) => column,
  );

  GeneratedColumn<String> get descripcionVisitador => $composableBuilder(
    column: $table.descripcionVisitador,
    builder: (column) => column,
  );

  GeneratedColumn<String> get descripcionIa => $composableBuilder(
    column: $table.descripcionIa,
    builder: (column) => column,
  );

  GeneratedColumn<String> get textoOcr =>
      $composableBuilder(column: $table.textoOcr, builder: (column) => column);

  GeneratedColumn<String> get enlaceArchivo => $composableBuilder(
    column: $table.enlaceArchivo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get estadoValidacion => $composableBuilder(
    column: $table.estadoValidacion,
    builder: (column) => column,
  );
}

class $$EvidenciasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EvidenciasTable,
          Evidencia,
          $$EvidenciasTableFilterComposer,
          $$EvidenciasTableOrderingComposer,
          $$EvidenciasTableAnnotationComposer,
          $$EvidenciasTableCreateCompanionBuilder,
          $$EvidenciasTableUpdateCompanionBuilder,
          (
            Evidencia,
            BaseReferences<_$AppDatabase, $EvidenciasTable, Evidencia>,
          ),
          Evidencia,
          PrefetchHooks Function()
        > {
  $$EvidenciasTableTableManager(_$AppDatabase db, $EvidenciasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EvidenciasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EvidenciasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EvidenciasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> visitaId = const Value.absent(),
                Value<String?> tipo = const Value.absent(),
                Value<String> archivoPath = const Value.absent(),
                Value<DateTime> tomadaEn = const Value.absent(),
                Value<double?> latitud = const Value.absent(),
                Value<double?> longitud = const Value.absent(),
                Value<int?> segundoAudio = const Value.absent(),
                Value<String?> descripcionVisitador = const Value.absent(),
                Value<String?> descripcionIa = const Value.absent(),
                Value<String?> textoOcr = const Value.absent(),
                Value<String?> enlaceArchivo = const Value.absent(),
                Value<String> estadoValidacion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EvidenciasCompanion(
                id: id,
                visitaId: visitaId,
                tipo: tipo,
                archivoPath: archivoPath,
                tomadaEn: tomadaEn,
                latitud: latitud,
                longitud: longitud,
                segundoAudio: segundoAudio,
                descripcionVisitador: descripcionVisitador,
                descripcionIa: descripcionIa,
                textoOcr: textoOcr,
                enlaceArchivo: enlaceArchivo,
                estadoValidacion: estadoValidacion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String visitaId,
                Value<String?> tipo = const Value.absent(),
                required String archivoPath,
                required DateTime tomadaEn,
                Value<double?> latitud = const Value.absent(),
                Value<double?> longitud = const Value.absent(),
                Value<int?> segundoAudio = const Value.absent(),
                Value<String?> descripcionVisitador = const Value.absent(),
                Value<String?> descripcionIa = const Value.absent(),
                Value<String?> textoOcr = const Value.absent(),
                Value<String?> enlaceArchivo = const Value.absent(),
                Value<String> estadoValidacion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EvidenciasCompanion.insert(
                id: id,
                visitaId: visitaId,
                tipo: tipo,
                archivoPath: archivoPath,
                tomadaEn: tomadaEn,
                latitud: latitud,
                longitud: longitud,
                segundoAudio: segundoAudio,
                descripcionVisitador: descripcionVisitador,
                descripcionIa: descripcionIa,
                textoOcr: textoOcr,
                enlaceArchivo: enlaceArchivo,
                estadoValidacion: estadoValidacion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EvidenciasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EvidenciasTable,
      Evidencia,
      $$EvidenciasTableFilterComposer,
      $$EvidenciasTableOrderingComposer,
      $$EvidenciasTableAnnotationComposer,
      $$EvidenciasTableCreateCompanionBuilder,
      $$EvidenciasTableUpdateCompanionBuilder,
      (Evidencia, BaseReferences<_$AppDatabase, $EvidenciasTable, Evidencia>),
      Evidencia,
      PrefetchHooks Function()
    >;
typedef $$HallazgosTableCreateCompanionBuilder =
    HallazgosCompanion Function({
      required String id,
      required String visitaId,
      required String claveTecnica,
      Value<EntidadDestino?> entidadDestino,
      Value<String?> entidadLocalId,
      Value<String?> valorTexto,
      Value<double?> valorNumerico,
      Value<String?> unidad,
      Value<FuenteHallazgo> fuente,
      Value<String?> citaTextual,
      Value<int?> segundoAudio,
      Value<Hablante?> hablante,
      Value<Certeza> certeza,
      Value<String?> razonamiento,
      Value<double?> confianza,
      Value<EstadoHallazgo> estado,
      Value<String?> valorCorregido,
      Value<String?> validadoPorLocalId,
      Value<DateTime?> validadoEn,
      required DateTime creadoEn,
      Value<int> rowid,
    });
typedef $$HallazgosTableUpdateCompanionBuilder =
    HallazgosCompanion Function({
      Value<String> id,
      Value<String> visitaId,
      Value<String> claveTecnica,
      Value<EntidadDestino?> entidadDestino,
      Value<String?> entidadLocalId,
      Value<String?> valorTexto,
      Value<double?> valorNumerico,
      Value<String?> unidad,
      Value<FuenteHallazgo> fuente,
      Value<String?> citaTextual,
      Value<int?> segundoAudio,
      Value<Hablante?> hablante,
      Value<Certeza> certeza,
      Value<String?> razonamiento,
      Value<double?> confianza,
      Value<EstadoHallazgo> estado,
      Value<String?> valorCorregido,
      Value<String?> validadoPorLocalId,
      Value<DateTime?> validadoEn,
      Value<DateTime> creadoEn,
      Value<int> rowid,
    });

class $$HallazgosTableFilterComposer
    extends Composer<_$AppDatabase, $HallazgosTable> {
  $$HallazgosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visitaId => $composableBuilder(
    column: $table.visitaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get claveTecnica => $composableBuilder(
    column: $table.claveTecnica,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<EntidadDestino?, EntidadDestino, String>
  get entidadDestino => $composableBuilder(
    column: $table.entidadDestino,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get entidadLocalId => $composableBuilder(
    column: $table.entidadLocalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valorTexto => $composableBuilder(
    column: $table.valorTexto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get valorNumerico => $composableBuilder(
    column: $table.valorNumerico,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unidad => $composableBuilder(
    column: $table.unidad,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<FuenteHallazgo, FuenteHallazgo, String>
  get fuente => $composableBuilder(
    column: $table.fuente,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get citaTextual => $composableBuilder(
    column: $table.citaTextual,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get segundoAudio => $composableBuilder(
    column: $table.segundoAudio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Hablante?, Hablante, String> get hablante =>
      $composableBuilder(
        column: $table.hablante,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Certeza, Certeza, String> get certeza =>
      $composableBuilder(
        column: $table.certeza,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get razonamiento => $composableBuilder(
    column: $table.razonamiento,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confianza => $composableBuilder(
    column: $table.confianza,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<EstadoHallazgo, EstadoHallazgo, String>
  get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get valorCorregido => $composableBuilder(
    column: $table.valorCorregido,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get validadoPorLocalId => $composableBuilder(
    column: $table.validadoPorLocalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get validadoEn => $composableBuilder(
    column: $table.validadoEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HallazgosTableOrderingComposer
    extends Composer<_$AppDatabase, $HallazgosTable> {
  $$HallazgosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visitaId => $composableBuilder(
    column: $table.visitaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get claveTecnica => $composableBuilder(
    column: $table.claveTecnica,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entidadDestino => $composableBuilder(
    column: $table.entidadDestino,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entidadLocalId => $composableBuilder(
    column: $table.entidadLocalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valorTexto => $composableBuilder(
    column: $table.valorTexto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get valorNumerico => $composableBuilder(
    column: $table.valorNumerico,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unidad => $composableBuilder(
    column: $table.unidad,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fuente => $composableBuilder(
    column: $table.fuente,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get citaTextual => $composableBuilder(
    column: $table.citaTextual,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get segundoAudio => $composableBuilder(
    column: $table.segundoAudio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hablante => $composableBuilder(
    column: $table.hablante,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get certeza => $composableBuilder(
    column: $table.certeza,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get razonamiento => $composableBuilder(
    column: $table.razonamiento,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confianza => $composableBuilder(
    column: $table.confianza,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valorCorregido => $composableBuilder(
    column: $table.valorCorregido,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get validadoPorLocalId => $composableBuilder(
    column: $table.validadoPorLocalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get validadoEn => $composableBuilder(
    column: $table.validadoEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HallazgosTableAnnotationComposer
    extends Composer<_$AppDatabase, $HallazgosTable> {
  $$HallazgosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get visitaId =>
      $composableBuilder(column: $table.visitaId, builder: (column) => column);

  GeneratedColumn<String> get claveTecnica => $composableBuilder(
    column: $table.claveTecnica,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<EntidadDestino?, String>
  get entidadDestino => $composableBuilder(
    column: $table.entidadDestino,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entidadLocalId => $composableBuilder(
    column: $table.entidadLocalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get valorTexto => $composableBuilder(
    column: $table.valorTexto,
    builder: (column) => column,
  );

  GeneratedColumn<double> get valorNumerico => $composableBuilder(
    column: $table.valorNumerico,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unidad =>
      $composableBuilder(column: $table.unidad, builder: (column) => column);

  GeneratedColumnWithTypeConverter<FuenteHallazgo, String> get fuente =>
      $composableBuilder(column: $table.fuente, builder: (column) => column);

  GeneratedColumn<String> get citaTextual => $composableBuilder(
    column: $table.citaTextual,
    builder: (column) => column,
  );

  GeneratedColumn<int> get segundoAudio => $composableBuilder(
    column: $table.segundoAudio,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Hablante?, String> get hablante =>
      $composableBuilder(column: $table.hablante, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Certeza, String> get certeza =>
      $composableBuilder(column: $table.certeza, builder: (column) => column);

  GeneratedColumn<String> get razonamiento => $composableBuilder(
    column: $table.razonamiento,
    builder: (column) => column,
  );

  GeneratedColumn<double> get confianza =>
      $composableBuilder(column: $table.confianza, builder: (column) => column);

  GeneratedColumnWithTypeConverter<EstadoHallazgo, String> get estado =>
      $composableBuilder(column: $table.estado, builder: (column) => column);

  GeneratedColumn<String> get valorCorregido => $composableBuilder(
    column: $table.valorCorregido,
    builder: (column) => column,
  );

  GeneratedColumn<String> get validadoPorLocalId => $composableBuilder(
    column: $table.validadoPorLocalId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get validadoEn => $composableBuilder(
    column: $table.validadoEn,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get creadoEn =>
      $composableBuilder(column: $table.creadoEn, builder: (column) => column);
}

class $$HallazgosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HallazgosTable,
          Hallazgo,
          $$HallazgosTableFilterComposer,
          $$HallazgosTableOrderingComposer,
          $$HallazgosTableAnnotationComposer,
          $$HallazgosTableCreateCompanionBuilder,
          $$HallazgosTableUpdateCompanionBuilder,
          (Hallazgo, BaseReferences<_$AppDatabase, $HallazgosTable, Hallazgo>),
          Hallazgo,
          PrefetchHooks Function()
        > {
  $$HallazgosTableTableManager(_$AppDatabase db, $HallazgosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HallazgosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HallazgosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HallazgosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> visitaId = const Value.absent(),
                Value<String> claveTecnica = const Value.absent(),
                Value<EntidadDestino?> entidadDestino = const Value.absent(),
                Value<String?> entidadLocalId = const Value.absent(),
                Value<String?> valorTexto = const Value.absent(),
                Value<double?> valorNumerico = const Value.absent(),
                Value<String?> unidad = const Value.absent(),
                Value<FuenteHallazgo> fuente = const Value.absent(),
                Value<String?> citaTextual = const Value.absent(),
                Value<int?> segundoAudio = const Value.absent(),
                Value<Hablante?> hablante = const Value.absent(),
                Value<Certeza> certeza = const Value.absent(),
                Value<String?> razonamiento = const Value.absent(),
                Value<double?> confianza = const Value.absent(),
                Value<EstadoHallazgo> estado = const Value.absent(),
                Value<String?> valorCorregido = const Value.absent(),
                Value<String?> validadoPorLocalId = const Value.absent(),
                Value<DateTime?> validadoEn = const Value.absent(),
                Value<DateTime> creadoEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HallazgosCompanion(
                id: id,
                visitaId: visitaId,
                claveTecnica: claveTecnica,
                entidadDestino: entidadDestino,
                entidadLocalId: entidadLocalId,
                valorTexto: valorTexto,
                valorNumerico: valorNumerico,
                unidad: unidad,
                fuente: fuente,
                citaTextual: citaTextual,
                segundoAudio: segundoAudio,
                hablante: hablante,
                certeza: certeza,
                razonamiento: razonamiento,
                confianza: confianza,
                estado: estado,
                valorCorregido: valorCorregido,
                validadoPorLocalId: validadoPorLocalId,
                validadoEn: validadoEn,
                creadoEn: creadoEn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String visitaId,
                required String claveTecnica,
                Value<EntidadDestino?> entidadDestino = const Value.absent(),
                Value<String?> entidadLocalId = const Value.absent(),
                Value<String?> valorTexto = const Value.absent(),
                Value<double?> valorNumerico = const Value.absent(),
                Value<String?> unidad = const Value.absent(),
                Value<FuenteHallazgo> fuente = const Value.absent(),
                Value<String?> citaTextual = const Value.absent(),
                Value<int?> segundoAudio = const Value.absent(),
                Value<Hablante?> hablante = const Value.absent(),
                Value<Certeza> certeza = const Value.absent(),
                Value<String?> razonamiento = const Value.absent(),
                Value<double?> confianza = const Value.absent(),
                Value<EstadoHallazgo> estado = const Value.absent(),
                Value<String?> valorCorregido = const Value.absent(),
                Value<String?> validadoPorLocalId = const Value.absent(),
                Value<DateTime?> validadoEn = const Value.absent(),
                required DateTime creadoEn,
                Value<int> rowid = const Value.absent(),
              }) => HallazgosCompanion.insert(
                id: id,
                visitaId: visitaId,
                claveTecnica: claveTecnica,
                entidadDestino: entidadDestino,
                entidadLocalId: entidadLocalId,
                valorTexto: valorTexto,
                valorNumerico: valorNumerico,
                unidad: unidad,
                fuente: fuente,
                citaTextual: citaTextual,
                segundoAudio: segundoAudio,
                hablante: hablante,
                certeza: certeza,
                razonamiento: razonamiento,
                confianza: confianza,
                estado: estado,
                valorCorregido: valorCorregido,
                validadoPorLocalId: validadoPorLocalId,
                validadoEn: validadoEn,
                creadoEn: creadoEn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HallazgosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HallazgosTable,
      Hallazgo,
      $$HallazgosTableFilterComposer,
      $$HallazgosTableOrderingComposer,
      $$HallazgosTableAnnotationComposer,
      $$HallazgosTableCreateCompanionBuilder,
      $$HallazgosTableUpdateCompanionBuilder,
      (Hallazgo, BaseReferences<_$AppDatabase, $HallazgosTable, Hallazgo>),
      Hallazgo,
      PrefetchHooks Function()
    >;
typedef $$InformesTableCreateCompanionBuilder =
    InformesCompanion Function({
      required String id,
      required String visitaId,
      required String titulo,
      Value<String> tipo,
      required String contenido,
      Value<int> version,
      required DateTime generadoEn,
      Value<String?> modelo,
      Value<bool> entregado,
      Value<String?> medioEntrega,
      Value<String?> pdfPath,
      Value<String?> enlacePdf,
      Value<String?> remoteId,
      Value<bool> sincronizado,
      Value<int> rowid,
    });
typedef $$InformesTableUpdateCompanionBuilder =
    InformesCompanion Function({
      Value<String> id,
      Value<String> visitaId,
      Value<String> titulo,
      Value<String> tipo,
      Value<String> contenido,
      Value<int> version,
      Value<DateTime> generadoEn,
      Value<String?> modelo,
      Value<bool> entregado,
      Value<String?> medioEntrega,
      Value<String?> pdfPath,
      Value<String?> enlacePdf,
      Value<String?> remoteId,
      Value<bool> sincronizado,
      Value<int> rowid,
    });

class $$InformesTableFilterComposer
    extends Composer<_$AppDatabase, $InformesTable> {
  $$InformesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visitaId => $composableBuilder(
    column: $table.visitaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titulo => $composableBuilder(
    column: $table.titulo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contenido => $composableBuilder(
    column: $table.contenido,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get generadoEn => $composableBuilder(
    column: $table.generadoEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelo => $composableBuilder(
    column: $table.modelo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get entregado => $composableBuilder(
    column: $table.entregado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medioEntrega => $composableBuilder(
    column: $table.medioEntrega,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pdfPath => $composableBuilder(
    column: $table.pdfPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get enlacePdf => $composableBuilder(
    column: $table.enlacePdf,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get sincronizado => $composableBuilder(
    column: $table.sincronizado,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InformesTableOrderingComposer
    extends Composer<_$AppDatabase, $InformesTable> {
  $$InformesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visitaId => $composableBuilder(
    column: $table.visitaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titulo => $composableBuilder(
    column: $table.titulo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contenido => $composableBuilder(
    column: $table.contenido,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get generadoEn => $composableBuilder(
    column: $table.generadoEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelo => $composableBuilder(
    column: $table.modelo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get entregado => $composableBuilder(
    column: $table.entregado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medioEntrega => $composableBuilder(
    column: $table.medioEntrega,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pdfPath => $composableBuilder(
    column: $table.pdfPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get enlacePdf => $composableBuilder(
    column: $table.enlacePdf,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get sincronizado => $composableBuilder(
    column: $table.sincronizado,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InformesTableAnnotationComposer
    extends Composer<_$AppDatabase, $InformesTable> {
  $$InformesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get visitaId =>
      $composableBuilder(column: $table.visitaId, builder: (column) => column);

  GeneratedColumn<String> get titulo =>
      $composableBuilder(column: $table.titulo, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<String> get contenido =>
      $composableBuilder(column: $table.contenido, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get generadoEn => $composableBuilder(
    column: $table.generadoEn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modelo =>
      $composableBuilder(column: $table.modelo, builder: (column) => column);

  GeneratedColumn<bool> get entregado =>
      $composableBuilder(column: $table.entregado, builder: (column) => column);

  GeneratedColumn<String> get medioEntrega => $composableBuilder(
    column: $table.medioEntrega,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pdfPath =>
      $composableBuilder(column: $table.pdfPath, builder: (column) => column);

  GeneratedColumn<String> get enlacePdf =>
      $composableBuilder(column: $table.enlacePdf, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<bool> get sincronizado => $composableBuilder(
    column: $table.sincronizado,
    builder: (column) => column,
  );
}

class $$InformesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InformesTable,
          Informe,
          $$InformesTableFilterComposer,
          $$InformesTableOrderingComposer,
          $$InformesTableAnnotationComposer,
          $$InformesTableCreateCompanionBuilder,
          $$InformesTableUpdateCompanionBuilder,
          (Informe, BaseReferences<_$AppDatabase, $InformesTable, Informe>),
          Informe,
          PrefetchHooks Function()
        > {
  $$InformesTableTableManager(_$AppDatabase db, $InformesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InformesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InformesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InformesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> visitaId = const Value.absent(),
                Value<String> titulo = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<String> contenido = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime> generadoEn = const Value.absent(),
                Value<String?> modelo = const Value.absent(),
                Value<bool> entregado = const Value.absent(),
                Value<String?> medioEntrega = const Value.absent(),
                Value<String?> pdfPath = const Value.absent(),
                Value<String?> enlacePdf = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<bool> sincronizado = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InformesCompanion(
                id: id,
                visitaId: visitaId,
                titulo: titulo,
                tipo: tipo,
                contenido: contenido,
                version: version,
                generadoEn: generadoEn,
                modelo: modelo,
                entregado: entregado,
                medioEntrega: medioEntrega,
                pdfPath: pdfPath,
                enlacePdf: enlacePdf,
                remoteId: remoteId,
                sincronizado: sincronizado,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String visitaId,
                required String titulo,
                Value<String> tipo = const Value.absent(),
                required String contenido,
                Value<int> version = const Value.absent(),
                required DateTime generadoEn,
                Value<String?> modelo = const Value.absent(),
                Value<bool> entregado = const Value.absent(),
                Value<String?> medioEntrega = const Value.absent(),
                Value<String?> pdfPath = const Value.absent(),
                Value<String?> enlacePdf = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<bool> sincronizado = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InformesCompanion.insert(
                id: id,
                visitaId: visitaId,
                titulo: titulo,
                tipo: tipo,
                contenido: contenido,
                version: version,
                generadoEn: generadoEn,
                modelo: modelo,
                entregado: entregado,
                medioEntrega: medioEntrega,
                pdfPath: pdfPath,
                enlacePdf: enlacePdf,
                remoteId: remoteId,
                sincronizado: sincronizado,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InformesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InformesTable,
      Informe,
      $$InformesTableFilterComposer,
      $$InformesTableOrderingComposer,
      $$InformesTableAnnotationComposer,
      $$InformesTableCreateCompanionBuilder,
      $$InformesTableUpdateCompanionBuilder,
      (Informe, BaseReferences<_$AppDatabase, $InformesTable, Informe>),
      Informe,
      PrefetchHooks Function()
    >;
typedef $$TrazadosTableCreateCompanionBuilder =
    TrazadosCompanion Function({
      required String id,
      required String visitaId,
      required String nombre,
      Value<TipoTrazado> tipo,
      Value<ModoCaptura> modoCaptura,
      Value<String?> etiqueta,
      Value<String?> notas,
      Value<int?> intervaloSeg,
      Value<double?> distanciaMinM,
      Value<double?> precisionMaxM,
      Value<bool> cerrado,
      Value<double?> areaM2,
      Value<double?> perimetroM,
      required DateTime creadoEn,
      Value<DateTime?> actualizadoEn,
      Value<String?> remoteId,
      Value<bool> sincronizado,
      Value<int> rowid,
    });
typedef $$TrazadosTableUpdateCompanionBuilder =
    TrazadosCompanion Function({
      Value<String> id,
      Value<String> visitaId,
      Value<String> nombre,
      Value<TipoTrazado> tipo,
      Value<ModoCaptura> modoCaptura,
      Value<String?> etiqueta,
      Value<String?> notas,
      Value<int?> intervaloSeg,
      Value<double?> distanciaMinM,
      Value<double?> precisionMaxM,
      Value<bool> cerrado,
      Value<double?> areaM2,
      Value<double?> perimetroM,
      Value<DateTime> creadoEn,
      Value<DateTime?> actualizadoEn,
      Value<String?> remoteId,
      Value<bool> sincronizado,
      Value<int> rowid,
    });

class $$TrazadosTableFilterComposer
    extends Composer<_$AppDatabase, $TrazadosTable> {
  $$TrazadosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visitaId => $composableBuilder(
    column: $table.visitaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TipoTrazado, TipoTrazado, String> get tipo =>
      $composableBuilder(
        column: $table.tipo,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<ModoCaptura, ModoCaptura, String>
  get modoCaptura => $composableBuilder(
    column: $table.modoCaptura,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get etiqueta => $composableBuilder(
    column: $table.etiqueta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notas => $composableBuilder(
    column: $table.notas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervaloSeg => $composableBuilder(
    column: $table.intervaloSeg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanciaMinM => $composableBuilder(
    column: $table.distanciaMinM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get precisionMaxM => $composableBuilder(
    column: $table.precisionMaxM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get cerrado => $composableBuilder(
    column: $table.cerrado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get areaM2 => $composableBuilder(
    column: $table.areaM2,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get perimetroM => $composableBuilder(
    column: $table.perimetroM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get sincronizado => $composableBuilder(
    column: $table.sincronizado,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TrazadosTableOrderingComposer
    extends Composer<_$AppDatabase, $TrazadosTable> {
  $$TrazadosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visitaId => $composableBuilder(
    column: $table.visitaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modoCaptura => $composableBuilder(
    column: $table.modoCaptura,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etiqueta => $composableBuilder(
    column: $table.etiqueta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notas => $composableBuilder(
    column: $table.notas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervaloSeg => $composableBuilder(
    column: $table.intervaloSeg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanciaMinM => $composableBuilder(
    column: $table.distanciaMinM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get precisionMaxM => $composableBuilder(
    column: $table.precisionMaxM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get cerrado => $composableBuilder(
    column: $table.cerrado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get areaM2 => $composableBuilder(
    column: $table.areaM2,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get perimetroM => $composableBuilder(
    column: $table.perimetroM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get sincronizado => $composableBuilder(
    column: $table.sincronizado,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TrazadosTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrazadosTable> {
  $$TrazadosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get visitaId =>
      $composableBuilder(column: $table.visitaId, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TipoTrazado, String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ModoCaptura, String> get modoCaptura =>
      $composableBuilder(
        column: $table.modoCaptura,
        builder: (column) => column,
      );

  GeneratedColumn<String> get etiqueta =>
      $composableBuilder(column: $table.etiqueta, builder: (column) => column);

  GeneratedColumn<String> get notas =>
      $composableBuilder(column: $table.notas, builder: (column) => column);

  GeneratedColumn<int> get intervaloSeg => $composableBuilder(
    column: $table.intervaloSeg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get distanciaMinM => $composableBuilder(
    column: $table.distanciaMinM,
    builder: (column) => column,
  );

  GeneratedColumn<double> get precisionMaxM => $composableBuilder(
    column: $table.precisionMaxM,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get cerrado =>
      $composableBuilder(column: $table.cerrado, builder: (column) => column);

  GeneratedColumn<double> get areaM2 =>
      $composableBuilder(column: $table.areaM2, builder: (column) => column);

  GeneratedColumn<double> get perimetroM => $composableBuilder(
    column: $table.perimetroM,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get creadoEn =>
      $composableBuilder(column: $table.creadoEn, builder: (column) => column);

  GeneratedColumn<DateTime> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<bool> get sincronizado => $composableBuilder(
    column: $table.sincronizado,
    builder: (column) => column,
  );
}

class $$TrazadosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrazadosTable,
          Trazado,
          $$TrazadosTableFilterComposer,
          $$TrazadosTableOrderingComposer,
          $$TrazadosTableAnnotationComposer,
          $$TrazadosTableCreateCompanionBuilder,
          $$TrazadosTableUpdateCompanionBuilder,
          (Trazado, BaseReferences<_$AppDatabase, $TrazadosTable, Trazado>),
          Trazado,
          PrefetchHooks Function()
        > {
  $$TrazadosTableTableManager(_$AppDatabase db, $TrazadosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrazadosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrazadosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrazadosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> visitaId = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<TipoTrazado> tipo = const Value.absent(),
                Value<ModoCaptura> modoCaptura = const Value.absent(),
                Value<String?> etiqueta = const Value.absent(),
                Value<String?> notas = const Value.absent(),
                Value<int?> intervaloSeg = const Value.absent(),
                Value<double?> distanciaMinM = const Value.absent(),
                Value<double?> precisionMaxM = const Value.absent(),
                Value<bool> cerrado = const Value.absent(),
                Value<double?> areaM2 = const Value.absent(),
                Value<double?> perimetroM = const Value.absent(),
                Value<DateTime> creadoEn = const Value.absent(),
                Value<DateTime?> actualizadoEn = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<bool> sincronizado = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrazadosCompanion(
                id: id,
                visitaId: visitaId,
                nombre: nombre,
                tipo: tipo,
                modoCaptura: modoCaptura,
                etiqueta: etiqueta,
                notas: notas,
                intervaloSeg: intervaloSeg,
                distanciaMinM: distanciaMinM,
                precisionMaxM: precisionMaxM,
                cerrado: cerrado,
                areaM2: areaM2,
                perimetroM: perimetroM,
                creadoEn: creadoEn,
                actualizadoEn: actualizadoEn,
                remoteId: remoteId,
                sincronizado: sincronizado,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String visitaId,
                required String nombre,
                Value<TipoTrazado> tipo = const Value.absent(),
                Value<ModoCaptura> modoCaptura = const Value.absent(),
                Value<String?> etiqueta = const Value.absent(),
                Value<String?> notas = const Value.absent(),
                Value<int?> intervaloSeg = const Value.absent(),
                Value<double?> distanciaMinM = const Value.absent(),
                Value<double?> precisionMaxM = const Value.absent(),
                Value<bool> cerrado = const Value.absent(),
                Value<double?> areaM2 = const Value.absent(),
                Value<double?> perimetroM = const Value.absent(),
                required DateTime creadoEn,
                Value<DateTime?> actualizadoEn = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<bool> sincronizado = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrazadosCompanion.insert(
                id: id,
                visitaId: visitaId,
                nombre: nombre,
                tipo: tipo,
                modoCaptura: modoCaptura,
                etiqueta: etiqueta,
                notas: notas,
                intervaloSeg: intervaloSeg,
                distanciaMinM: distanciaMinM,
                precisionMaxM: precisionMaxM,
                cerrado: cerrado,
                areaM2: areaM2,
                perimetroM: perimetroM,
                creadoEn: creadoEn,
                actualizadoEn: actualizadoEn,
                remoteId: remoteId,
                sincronizado: sincronizado,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TrazadosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrazadosTable,
      Trazado,
      $$TrazadosTableFilterComposer,
      $$TrazadosTableOrderingComposer,
      $$TrazadosTableAnnotationComposer,
      $$TrazadosTableCreateCompanionBuilder,
      $$TrazadosTableUpdateCompanionBuilder,
      (Trazado, BaseReferences<_$AppDatabase, $TrazadosTable, Trazado>),
      Trazado,
      PrefetchHooks Function()
    >;
typedef $$PuntosTrazadoTableCreateCompanionBuilder =
    PuntosTrazadoCompanion Function({
      required String id,
      required String trazadoId,
      required int orden,
      required double latitud,
      required double longitud,
      Value<double?> altitud,
      Value<double?> precisionM,
      required DateTime capturadoEn,
      Value<bool> automatico,
      Value<String?> nota,
      Value<int> rowid,
    });
typedef $$PuntosTrazadoTableUpdateCompanionBuilder =
    PuntosTrazadoCompanion Function({
      Value<String> id,
      Value<String> trazadoId,
      Value<int> orden,
      Value<double> latitud,
      Value<double> longitud,
      Value<double?> altitud,
      Value<double?> precisionM,
      Value<DateTime> capturadoEn,
      Value<bool> automatico,
      Value<String?> nota,
      Value<int> rowid,
    });

class $$PuntosTrazadoTableFilterComposer
    extends Composer<_$AppDatabase, $PuntosTrazadoTable> {
  $$PuntosTrazadoTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trazadoId => $composableBuilder(
    column: $table.trazadoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orden => $composableBuilder(
    column: $table.orden,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitud => $composableBuilder(
    column: $table.latitud,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitud => $composableBuilder(
    column: $table.longitud,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get altitud => $composableBuilder(
    column: $table.altitud,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get precisionM => $composableBuilder(
    column: $table.precisionM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get capturadoEn => $composableBuilder(
    column: $table.capturadoEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get automatico => $composableBuilder(
    column: $table.automatico,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nota => $composableBuilder(
    column: $table.nota,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PuntosTrazadoTableOrderingComposer
    extends Composer<_$AppDatabase, $PuntosTrazadoTable> {
  $$PuntosTrazadoTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trazadoId => $composableBuilder(
    column: $table.trazadoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orden => $composableBuilder(
    column: $table.orden,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitud => $composableBuilder(
    column: $table.latitud,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitud => $composableBuilder(
    column: $table.longitud,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get altitud => $composableBuilder(
    column: $table.altitud,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get precisionM => $composableBuilder(
    column: $table.precisionM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get capturadoEn => $composableBuilder(
    column: $table.capturadoEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get automatico => $composableBuilder(
    column: $table.automatico,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nota => $composableBuilder(
    column: $table.nota,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PuntosTrazadoTableAnnotationComposer
    extends Composer<_$AppDatabase, $PuntosTrazadoTable> {
  $$PuntosTrazadoTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get trazadoId =>
      $composableBuilder(column: $table.trazadoId, builder: (column) => column);

  GeneratedColumn<int> get orden =>
      $composableBuilder(column: $table.orden, builder: (column) => column);

  GeneratedColumn<double> get latitud =>
      $composableBuilder(column: $table.latitud, builder: (column) => column);

  GeneratedColumn<double> get longitud =>
      $composableBuilder(column: $table.longitud, builder: (column) => column);

  GeneratedColumn<double> get altitud =>
      $composableBuilder(column: $table.altitud, builder: (column) => column);

  GeneratedColumn<double> get precisionM => $composableBuilder(
    column: $table.precisionM,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get capturadoEn => $composableBuilder(
    column: $table.capturadoEn,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get automatico => $composableBuilder(
    column: $table.automatico,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nota =>
      $composableBuilder(column: $table.nota, builder: (column) => column);
}

class $$PuntosTrazadoTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PuntosTrazadoTable,
          PuntoTrazado,
          $$PuntosTrazadoTableFilterComposer,
          $$PuntosTrazadoTableOrderingComposer,
          $$PuntosTrazadoTableAnnotationComposer,
          $$PuntosTrazadoTableCreateCompanionBuilder,
          $$PuntosTrazadoTableUpdateCompanionBuilder,
          (
            PuntoTrazado,
            BaseReferences<_$AppDatabase, $PuntosTrazadoTable, PuntoTrazado>,
          ),
          PuntoTrazado,
          PrefetchHooks Function()
        > {
  $$PuntosTrazadoTableTableManager(_$AppDatabase db, $PuntosTrazadoTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PuntosTrazadoTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PuntosTrazadoTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PuntosTrazadoTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> trazadoId = const Value.absent(),
                Value<int> orden = const Value.absent(),
                Value<double> latitud = const Value.absent(),
                Value<double> longitud = const Value.absent(),
                Value<double?> altitud = const Value.absent(),
                Value<double?> precisionM = const Value.absent(),
                Value<DateTime> capturadoEn = const Value.absent(),
                Value<bool> automatico = const Value.absent(),
                Value<String?> nota = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PuntosTrazadoCompanion(
                id: id,
                trazadoId: trazadoId,
                orden: orden,
                latitud: latitud,
                longitud: longitud,
                altitud: altitud,
                precisionM: precisionM,
                capturadoEn: capturadoEn,
                automatico: automatico,
                nota: nota,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String trazadoId,
                required int orden,
                required double latitud,
                required double longitud,
                Value<double?> altitud = const Value.absent(),
                Value<double?> precisionM = const Value.absent(),
                required DateTime capturadoEn,
                Value<bool> automatico = const Value.absent(),
                Value<String?> nota = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PuntosTrazadoCompanion.insert(
                id: id,
                trazadoId: trazadoId,
                orden: orden,
                latitud: latitud,
                longitud: longitud,
                altitud: altitud,
                precisionM: precisionM,
                capturadoEn: capturadoEn,
                automatico: automatico,
                nota: nota,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PuntosTrazadoTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PuntosTrazadoTable,
      PuntoTrazado,
      $$PuntosTrazadoTableFilterComposer,
      $$PuntosTrazadoTableOrderingComposer,
      $$PuntosTrazadoTableAnnotationComposer,
      $$PuntosTrazadoTableCreateCompanionBuilder,
      $$PuntosTrazadoTableUpdateCompanionBuilder,
      (
        PuntoTrazado,
        BaseReferences<_$AppDatabase, $PuntosTrazadoTable, PuntoTrazado>,
      ),
      PuntoTrazado,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueTableCreateCompanionBuilder =
    SyncQueueCompanion Function({
      required String id,
      required String entidad,
      required String entidadId,
      required String operacion,
      Value<String?> payload,
      Value<String?> archivoPath,
      Value<EstadoSync> estado,
      Value<int> intentos,
      required DateTime proximoIntentoEn,
      Value<int> bytesSubidos,
      Value<int> bytesTotales,
      Value<String?> ultimoError,
      Value<int> prioridad,
      required DateTime creadoEn,
      Value<int> rowid,
    });
typedef $$SyncQueueTableUpdateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<String> id,
      Value<String> entidad,
      Value<String> entidadId,
      Value<String> operacion,
      Value<String?> payload,
      Value<String?> archivoPath,
      Value<EstadoSync> estado,
      Value<int> intentos,
      Value<DateTime> proximoIntentoEn,
      Value<int> bytesSubidos,
      Value<int> bytesTotales,
      Value<String?> ultimoError,
      Value<int> prioridad,
      Value<DateTime> creadoEn,
      Value<int> rowid,
    });

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entidad => $composableBuilder(
    column: $table.entidad,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entidadId => $composableBuilder(
    column: $table.entidadId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operacion => $composableBuilder(
    column: $table.operacion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get archivoPath => $composableBuilder(
    column: $table.archivoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<EstadoSync, EstadoSync, String> get estado =>
      $composableBuilder(
        column: $table.estado,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get intentos => $composableBuilder(
    column: $table.intentos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get proximoIntentoEn => $composableBuilder(
    column: $table.proximoIntentoEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bytesSubidos => $composableBuilder(
    column: $table.bytesSubidos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bytesTotales => $composableBuilder(
    column: $table.bytesTotales,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ultimoError => $composableBuilder(
    column: $table.ultimoError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get prioridad => $composableBuilder(
    column: $table.prioridad,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entidad => $composableBuilder(
    column: $table.entidad,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entidadId => $composableBuilder(
    column: $table.entidadId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operacion => $composableBuilder(
    column: $table.operacion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get archivoPath => $composableBuilder(
    column: $table.archivoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intentos => $composableBuilder(
    column: $table.intentos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get proximoIntentoEn => $composableBuilder(
    column: $table.proximoIntentoEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bytesSubidos => $composableBuilder(
    column: $table.bytesSubidos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bytesTotales => $composableBuilder(
    column: $table.bytesTotales,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ultimoError => $composableBuilder(
    column: $table.ultimoError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get prioridad => $composableBuilder(
    column: $table.prioridad,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entidad =>
      $composableBuilder(column: $table.entidad, builder: (column) => column);

  GeneratedColumn<String> get entidadId =>
      $composableBuilder(column: $table.entidadId, builder: (column) => column);

  GeneratedColumn<String> get operacion =>
      $composableBuilder(column: $table.operacion, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get archivoPath => $composableBuilder(
    column: $table.archivoPath,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<EstadoSync, String> get estado =>
      $composableBuilder(column: $table.estado, builder: (column) => column);

  GeneratedColumn<int> get intentos =>
      $composableBuilder(column: $table.intentos, builder: (column) => column);

  GeneratedColumn<DateTime> get proximoIntentoEn => $composableBuilder(
    column: $table.proximoIntentoEn,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bytesSubidos => $composableBuilder(
    column: $table.bytesSubidos,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bytesTotales => $composableBuilder(
    column: $table.bytesTotales,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ultimoError => $composableBuilder(
    column: $table.ultimoError,
    builder: (column) => column,
  );

  GeneratedColumn<int> get prioridad =>
      $composableBuilder(column: $table.prioridad, builder: (column) => column);

  GeneratedColumn<DateTime> get creadoEn =>
      $composableBuilder(column: $table.creadoEn, builder: (column) => column);
}

class $$SyncQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueTable,
          SyncItem,
          $$SyncQueueTableFilterComposer,
          $$SyncQueueTableOrderingComposer,
          $$SyncQueueTableAnnotationComposer,
          $$SyncQueueTableCreateCompanionBuilder,
          $$SyncQueueTableUpdateCompanionBuilder,
          (SyncItem, BaseReferences<_$AppDatabase, $SyncQueueTable, SyncItem>),
          SyncItem,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entidad = const Value.absent(),
                Value<String> entidadId = const Value.absent(),
                Value<String> operacion = const Value.absent(),
                Value<String?> payload = const Value.absent(),
                Value<String?> archivoPath = const Value.absent(),
                Value<EstadoSync> estado = const Value.absent(),
                Value<int> intentos = const Value.absent(),
                Value<DateTime> proximoIntentoEn = const Value.absent(),
                Value<int> bytesSubidos = const Value.absent(),
                Value<int> bytesTotales = const Value.absent(),
                Value<String?> ultimoError = const Value.absent(),
                Value<int> prioridad = const Value.absent(),
                Value<DateTime> creadoEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueCompanion(
                id: id,
                entidad: entidad,
                entidadId: entidadId,
                operacion: operacion,
                payload: payload,
                archivoPath: archivoPath,
                estado: estado,
                intentos: intentos,
                proximoIntentoEn: proximoIntentoEn,
                bytesSubidos: bytesSubidos,
                bytesTotales: bytesTotales,
                ultimoError: ultimoError,
                prioridad: prioridad,
                creadoEn: creadoEn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entidad,
                required String entidadId,
                required String operacion,
                Value<String?> payload = const Value.absent(),
                Value<String?> archivoPath = const Value.absent(),
                Value<EstadoSync> estado = const Value.absent(),
                Value<int> intentos = const Value.absent(),
                required DateTime proximoIntentoEn,
                Value<int> bytesSubidos = const Value.absent(),
                Value<int> bytesTotales = const Value.absent(),
                Value<String?> ultimoError = const Value.absent(),
                Value<int> prioridad = const Value.absent(),
                required DateTime creadoEn,
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueCompanion.insert(
                id: id,
                entidad: entidad,
                entidadId: entidadId,
                operacion: operacion,
                payload: payload,
                archivoPath: archivoPath,
                estado: estado,
                intentos: intentos,
                proximoIntentoEn: proximoIntentoEn,
                bytesSubidos: bytesSubidos,
                bytesTotales: bytesTotales,
                ultimoError: ultimoError,
                prioridad: prioridad,
                creadoEn: creadoEn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueTable,
      SyncItem,
      $$SyncQueueTableFilterComposer,
      $$SyncQueueTableOrderingComposer,
      $$SyncQueueTableAnnotationComposer,
      $$SyncQueueTableCreateCompanionBuilder,
      $$SyncQueueTableUpdateCompanionBuilder,
      (SyncItem, BaseReferences<_$AppDatabase, $SyncQueueTable, SyncItem>),
      SyncItem,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AjustesTableTableManager get ajustes =>
      $$AjustesTableTableManager(_db, _db.ajustes);
  $$CatalogoCamposTableTableManager get catalogoCampos =>
      $$CatalogoCamposTableTableManager(_db, _db.catalogoCampos);
  $$VeredasTableTableManager get veredas =>
      $$VeredasTableTableManager(_db, _db.veredas);
  $$VisitadoresTableTableManager get visitadores =>
      $$VisitadoresTableTableManager(_db, _db.visitadores);
  $$CredencialesLocalesTableTableManager get credencialesLocales =>
      $$CredencialesLocalesTableTableManager(_db, _db.credencialesLocales);
  $$SesionesTableTableManager get sesiones =>
      $$SesionesTableTableManager(_db, _db.sesiones);
  $$ProductoresTableTableManager get productores =>
      $$ProductoresTableTableManager(_db, _db.productores);
  $$FincasTableTableManager get fincas =>
      $$FincasTableTableManager(_db, _db.fincas);
  $$VisitasTableTableManager get visitas =>
      $$VisitasTableTableManager(_db, _db.visitas);
  $$GrabacionesTableTableManager get grabaciones =>
      $$GrabacionesTableTableManager(_db, _db.grabaciones);
  $$EvidenciasTableTableManager get evidencias =>
      $$EvidenciasTableTableManager(_db, _db.evidencias);
  $$HallazgosTableTableManager get hallazgos =>
      $$HallazgosTableTableManager(_db, _db.hallazgos);
  $$InformesTableTableManager get informes =>
      $$InformesTableTableManager(_db, _db.informes);
  $$TrazadosTableTableManager get trazados =>
      $$TrazadosTableTableManager(_db, _db.trazados);
  $$PuntosTrazadoTableTableManager get puntosTrazado =>
      $$PuntosTrazadoTableTableManager(_db, _db.puntosTrazado);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
}
