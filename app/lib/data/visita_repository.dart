import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'db/app_database.dart';

/// Un hallazgo tal como lo devuelve el modelo, antes de pasar por las reglas.
/// Es el borde entre el JSON del backend y la base local.
class HallazgoExtraido {
  const HallazgoExtraido({
    required this.claveTecnica,
    this.entidadDestino,
    this.entidadLocalId,
    this.valorTexto,
    this.valorNumerico,
    this.unidad,
    this.certeza = Certeza.pendiente,
    this.hablante,
    this.citaTextual,
    this.segundoAudio,
    this.razonamiento,
    this.confianza,
    this.fuente = FuenteHallazgo.audio,
  });

  final String claveTecnica;
  final EntidadDestino? entidadDestino;
  final String? entidadLocalId;
  final String? valorTexto;
  final double? valorNumerico;
  final String? unidad;
  final Certeza certeza;
  final Hablante? hablante;
  final String? citaTextual;
  final int? segundoAudio;
  final String? razonamiento;
  final double? confianza;
  final FuenteHallazgo fuente;

  factory HallazgoExtraido.fromJson(Map<String, dynamic> j) {
    T? porNombre<T extends Enum>(List<T> valores, String Function(T) nombre) {
      final crudo = j[_llaveDe(valores)] as String?;
      if (crudo == null) return null;
      for (final v in valores) {
        if (nombre(v) == crudo) return v;
      }
      return null;
    }

    return HallazgoExtraido(
      claveTecnica: j['clave'] as String,
      entidadDestino:
          porNombre(EntidadDestino.values, (v) => v.airtable),
      entidadLocalId: j['entidad_local_id'] as String?,
      valorTexto: j['valor_texto'] as String?,
      valorNumerico: (j['valor_numerico'] as num?)?.toDouble(),
      unidad: j['unidad'] as String?,
      certeza: porNombre(Certeza.values, (v) => v.airtable) ?? Certeza.pendiente,
      hablante: porNombre(Hablante.values, (v) => v.airtable),
      citaTextual: j['cita'] as String?,
      segundoAudio: (j['segundo'] as num?)?.round(),
      razonamiento: j['razonamiento'] as String?,
      confianza: (j['confianza'] as num?)?.toDouble(),
      fuente:
          porNombre(FuenteHallazgo.values, (v) => v.airtable) ??
              FuenteHallazgo.audio,
    );
  }

  /// Las llaves del JSON no coinciden con los nombres de los enums, asi que el
  /// mapeo se hace por tipo. Es fragil por naturaleza; si el contrato cambia,
  /// cambia aqui y en `docs/airtable-schema.md`, no en un solo lado.
  static String _llaveDe(List<Enum> valores) => switch (valores.first) {
        EntidadDestino _ => 'entidad_destino',
        Certeza _ => 'certeza',
        Hablante _ => 'hablante',
        FuenteHallazgo _ => 'fuente',
        _ => throw ArgumentError('enum sin llave: ${valores.first}'),
      };
}

/// Reemplaza a `MeetingStore`. La diferencia que importa: `MeetingStore`
/// serializaba la lista completa en cada cambio, asi que no podia consultar
/// nada — ni "cuantos obligatorios faltan", ni "que le queda por subir a esta
/// visita". Todo eso es una consulta aqui.
class VisitaRepository {
  VisitaRepository(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  /// Crea la visita con un UUID v4 del dispositivo. Ese id es la llave de
  /// idempotencia: se genera SIN RED y no cambia al sincronizar.
  Future<String> crearVisita({
    required DateTime inicio,
    String? visitadorLocalId,
    String? productorLocalId,
    String? fincaLocalId,
    String? veredaLocalId,
    double? latitud,
    double? longitud,
    double? precisionGps,
    String? tipoVisita,
  }) async {
    final id = _uuid.v4();
    await _db.into(_db.visitas).insert(
          VisitasCompanion.insert(
            id: id,
            inicio: inicio,
            visitadorLocalId: Value(visitadorLocalId),
            productorLocalId: Value(productorLocalId),
            fincaLocalId: Value(fincaLocalId),
            veredaLocalId: Value(veredaLocalId),
            latitud: Value(latitud),
            longitud: Value(longitud),
            precisionGps: Value(precisionGps),
            tipoVisita: Value(tipoVisita),
          ),
        );
    return id;
  }

  /// Crea productor, finca y visita de una sola vez, al llegar a la finca.
  ///
  /// Los tres nacen con UUID local y `sincronizado = false`. El productor no
  /// lleva `codigoProductor`: ese consecutivo lo asigna el backend, porque dos
  /// telefonos trabajando offline generarian el mismo BU-0001.
  ///
  /// Va en una transaccion para que no quede una visita apuntando a un
  /// productor que no se escribio.
  Future<String> crearVisitaConProductor({
    required DateTime inicio,
    required String nombreProductor,
    String? nombreFinca,
    String? veredaLocalId,
    String? visitadorLocalId,
    double? latitud,
    double? longitud,
    double? precisionGps,
  }) {
    return _db.transaction(() async {
      final productorId = _uuid.v4();
      await _db.into(_db.productores).insert(
            ProductoresCompanion.insert(
              id: productorId,
              nombreCompleto: nombreProductor,
            ),
          );

      String? fincaId;
      if (nombreFinca != null && nombreFinca.trim().isNotEmpty) {
        fincaId = _uuid.v4();
        await _db.into(_db.fincas).insert(
              FincasCompanion.insert(
                id: fincaId,
                productorLocalId: productorId,
                nombre: nombreFinca.trim(),
                veredaLocalId: Value(veredaLocalId),
                latitud: Value(latitud),
                longitud: Value(longitud),
              ),
            );
      }

      return crearVisita(
        inicio: inicio,
        visitadorLocalId: visitadorLocalId,
        productorLocalId: productorId,
        fincaLocalId: fincaId,
        veredaLocalId: veredaLocalId,
        latitud: latitud,
        longitud: longitud,
        precisionGps: precisionGps,
        tipoVisita: 'Primera visita',
      );
    });
  }

  /// Los tres consentimientos. Mientras `consienteAudio` sea false, la UI
  /// mantiene el boton de grabar deshabilitado — la regla no vive en la
  /// pantalla, vive en el dato.
  Future<void> registrarConsentimiento(
    String visitaId, {
    required bool audio,
    required bool fotos,
    required bool usoDatos,
    int? segundoDelAudio,
  }) =>
      (_db.update(_db.visitas)..where((v) => v.id.equals(visitaId))).write(
        VisitasCompanion(
          consienteAudio: Value(audio),
          consienteFotos: Value(fotos),
          consienteUsoDatos: Value(usoDatos),
          // Sin segundo no se escribe nada: volver a pedir el permiso a mitad
          // de la visita no puede borrar la prueba de la vez anterior.
          segundoConsentimiento: segundoDelAudio == null
              ? const Value.absent()
              : Value(segundoDelAudio),
        ),
      );

  Future<bool> puedeGrabar(String visitaId) async {
    final v = await (_db.select(_db.visitas)
          ..where((v) => v.id.equals(visitaId)))
        .getSingleOrNull();
    return v?.consienteAudio ?? false;
  }

  /// Registra un tramo de grabacion y lo encola con prioridad 0: el audio es
  /// lo unico irrecuperable de una visita.
  Future<String> registrarGrabacion({
    required String visitaId,
    required int orden,
    required String archivoPath,
    required DateTime inicio,
    int duracionSeg = 0,
    int tamanoBytes = 0,
  }) async {
    final id = _uuid.v4();
    await _db.into(_db.grabaciones).insert(
          GrabacionesCompanion.insert(
            id: id,
            visitaId: visitaId,
            orden: orden,
            archivoPath: archivoPath,
            inicio: inicio,
            duracionSeg: Value(duracionSeg),
            tamanoBytes: Value(tamanoBytes),
          ),
        );
    await _db.encolar(
      id: _uuid.v4(),
      entidad: 'grabacion',
      entidadId: visitaId,
      operacion: 'upload_audio',
      archivoPath: archivoPath,
      bytesTotales: tamanoBytes,
      prioridad: 0,
    );
    return id;
  }

  Future<List<Grabacion>> grabacionesDeVisita(String visitaId) =>
      (_db.select(_db.grabaciones)
            ..where((g) => g.visitaId.equals(visitaId))
            ..orderBy([(g) => OrderingTerm(expression: g.orden)]))
          .get();

  /// Registra los archivos de audio que quedaron en la carpeta de la visita
  /// pero no en la base. Devuelve cuantos rescato.
  ///
  /// Pasa cuando la app muere entre `stop` del encoder y el insert: el audio
  /// esta completo en disco pero nadie sabe que existe, asi que nunca se sube
  /// ni se transcribe. Se ejecuta al abrir la visita.
  ///
  /// Los archivos de menos de 1 KB se ignoran: son encabezados sin audio que
  /// deja un microfono cortado de inmediato, y encolarlos solo produce un
  /// fallo de transcripcion mas adelante.
  ///
  /// Limitacion conocida: un archivo AAC que el encoder nunca cerro le falta
  /// el indice final y no se puede reproducir. Este rescate no lo arregla —
  /// lo que limita el dano es cerrar un tramo cada pocos minutos.
  Future<int> rescatarTramosHuerfanos(
    String visitaId, {
    Directory? carpeta,
  }) async {
    final dir = carpeta ?? await _carpetaDeVisita(visitaId);
    if (!await dir.exists()) return 0;

    final registradas = await grabacionesDeVisita(visitaId);
    // Se compara por nombre de archivo, no por ruta completa: la carpeta ya
    // es la de esta visita, y las rutas se escriben con separadores distintos
    // segun quien las armo (la app con '/', el sistema de archivos con el
    // suyo). Comparar el texto crudo hacia que un tramo ya registrado se
    // volviera a registrar y a encolar.
    final yaRegistrados =
        registradas.map((g) => p.basename(g.archivoPath)).toSet();
    var maxOrden =
        registradas.fold<int>(0, (max, g) => g.orden > max ? g.orden : max);

    var rescatados = 0;
    final archivos = await dir
        .list()
        .where((e) => e is File && e.path.endsWith('.m4a'))
        .cast<File>()
        .toList();
    archivos.sort((a, b) => a.path.compareTo(b.path));

    for (final archivo in archivos) {
      if (yaRegistrados.contains(p.basename(archivo.path))) continue;

      final bytes = await archivo.length();
      if (bytes < 1024) {
        await archivo.delete();
        continue;
      }

      final stat = await archivo.stat();
      await _db.into(_db.grabaciones).insert(
            GrabacionesCompanion.insert(
              id: _uuid.v4(),
              visitaId: visitaId,
              orden: ++maxOrden,
              archivoPath: archivo.path,
              inicio: stat.modified,
              tamanoBytes: Value(bytes),
              // La duracion real se sabra al transcribir: el reloj de la app
              // se perdio con el proceso. Poner un numero inventado aqui
              // desplazaria todas las citas del tramo.
              estado: const Value('Recuperada'),
            ),
          );
      await _db.encolar(
        id: _uuid.v4(),
        entidad: 'grabacion',
        entidadId: visitaId,
        operacion: 'upload_audio',
        archivoPath: archivo.path,
        bytesTotales: bytes,
        prioridad: 0,
      );
      rescatados++;
    }
    return rescatados;
  }

  Future<Directory> _carpetaDeVisita(String visitaId) async {
    final base = await getApplicationDocumentsDirectory();
    return Directory('${base.path}/visitas/$visitaId');
  }

  /// Registra una foto y la encola con prioridad 200: el audio va primero.
  ///
  /// El audio es irrecuperable; una foto, en el peor caso, se vuelve a tomar.
  /// Y si la cola sube fotos antes que el audio en una vereda con senal
  /// intermitente, se gasta la ventana de red en lo reemplazable.
  Future<String> registrarEvidencia({
    required String visitaId,
    required String archivoPath,
    required DateTime tomadaEn,
    int? segundoAudio,
    String? tipo,
    double? latitud,
    double? longitud,
    String? descripcion,
  }) async {
    final id = _uuid.v4();
    final bytes = await File(archivoPath).length();

    await _db.into(_db.evidencias).insert(
          EvidenciasCompanion.insert(
            id: id,
            visitaId: visitaId,
            archivoPath: archivoPath,
            tomadaEn: tomadaEn,
            segundoAudio: Value(segundoAudio),
            tipo: Value(tipo),
            latitud: Value(latitud),
            longitud: Value(longitud),
            descripcionVisitador: Value(descripcion),
          ),
        );
    await _db.encolar(
      id: _uuid.v4(),
      entidad: 'evidencia',
      entidadId: visitaId,
      operacion: 'upload_foto',
      archivoPath: archivoPath,
      bytesTotales: bytes,
      prioridad: 200,
    );
    return id;
  }

  Future<List<Evidencia>> evidenciasDeVisita(String visitaId) =>
      (_db.select(_db.evidencias)
            ..where((e) => e.visitaId.equals(visitaId))
            ..orderBy([(e) => OrderingTerm(expression: e.tomadaEn)]))
          .get();

  /// Terminos de refuerzo especificos de esta visita.
  ///
  /// El nombre del productor va completo y partido en palabras: el agricultor
  /// va a decir "Pedro" a secas y el visitador "don Pedro Rodriguez". Las
  /// palabras de una o dos letras se descartan porque no aportan y gastan cupo
  /// del limite del proveedor ("de", "la", "y").
  ///
  /// Sin esto el motor transcribe "Guaicaramo" como "guai caramo" y el
  /// apellido del productor como cualquier cosa — y ese nombre termina impreso
  /// en el informe que se le entrega en la mano.
  Future<List<String>> terminosDeVisita(String visitaId) async {
    final visita = await (_db.select(_db.visitas)
          ..where((v) => v.id.equals(visitaId)))
        .getSingleOrNull();
    if (visita == null) return const [];

    final terminos = <String>[];

    if (visita.productorLocalId != null) {
      final productor = await (_db.select(_db.productores)
            ..where((p) => p.id.equals(visita.productorLocalId!)))
          .getSingleOrNull();
      if (productor != null) {
        final partes = productor.nombreCompleto
            .split(RegExp(r'\s+'))
            .where((p) => p.length > 2)
            .toList();
        if (partes.length > 1) terminos.add(partes.join(' '));
        terminos.addAll(partes);
      }
    }

    if (visita.veredaLocalId != null) {
      final vereda = await (_db.select(_db.veredas)
            ..where((v) => v.id.equals(visita.veredaLocalId!)))
          .getSingleOrNull();
      if (vereda != null) {
        terminos.add(vereda.vereda);
        terminos.add(vereda.municipio);
      }
    }

    if (visita.fincaLocalId != null) {
      final finca = await (_db.select(_db.fincas)
            ..where((f) => f.id.equals(visita.fincaLocalId!)))
          .getSingleOrNull();
      if (finca != null) terminos.add(finca.nombre);
    }

    // Sin repetidos y sin vacios, conservando el orden: lo mas especifico
    // primero, porque si el backend recorta por el limite, sobra lo generico.
    final vistos = <String>{};
    return terminos
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty && vistos.add(t.toLowerCase()))
        .toList();
  }

  /// El catalogo activo en el formato que espera `/v1/extracciones`.
  Future<List<Map<String, dynamic>>> camposParaExtraccion() async {
    final campos = await _db.camposActivos();
    return [
      for (final c in campos)
        {
          'clave_tecnica': c.claveTecnica,
          'campo': c.campo,
          'modulo': c.modulo,
          'tipo_dato': c.tipoDato,
          'unidad': c.unidad,
          'opciones': c.opciones,
          'pregunta_guia': c.preguntaGuia,
        },
    ];
  }

  /// Guarda la transcripcion de un tramo.
  ///
  /// `textoConMarcas` es lo que de verdad importa: es lo que va a
  /// `Grabaciones.Transcripcion con marcas de tiempo` y lo que lee el modelo
  /// de extraccion para poder devolver el segundo de cada cita.
  Future<void> guardarTranscripcion({
    required String grabacionId,
    required String texto,
    String? textoConMarcas,
    String? motor,
    int? duracionSeg,
  }) =>
      (_db.update(_db.grabaciones)..where((g) => g.id.equals(grabacionId)))
          .write(
        GrabacionesCompanion(
          transcripcion: Value(texto),
          transcripcionMarcas: Value(textoConMarcas),
          motorTranscripcion: Value(motor),
          duracionSeg:
              duracionSeg == null ? const Value.absent() : Value(duracionSeg),
          // Sin marcas de tiempo la transcripcion sirve para leer pero no para
          // citar, asi que no se puede dar por lista.
          estado: Value(
            (textoConMarcas ?? '').isEmpty ? 'Sin diarizar' : 'Transcrita',
          ),
        ),
      );

  /// Toda la conversacion de la visita, en orden, para mandarla a extraer.
  ///
  /// Se concatenan las marcas de tiempo de cada tramo, no el texto plano: la
  /// extraccion necesita los segundos o los hallazgos no pueden llevar cita.
  Future<String> transcripcionCompleta(String visitaId) async {
    final tramos = await grabacionesDeVisita(visitaId);
    final partes = <String>[];

    for (final g in tramos) {
      final marcas = g.transcripcionMarcas;
      if (marcas != null && marcas.trim().isNotEmpty) {
        partes.add('--- Tramo ${g.orden} ---\n$marcas');
      }
    }
    return partes.join('\n\n');
  }

  /// Guarda lo que extrajo el modelo, aplicando las reglas duras a cada
  /// hallazgo, y deja la completitud recalculada.
  ///
  /// Todo en una transaccion: una extraccion a medias es peor que ninguna,
  /// porque la completitud diria un numero que no corresponde a nada.
  Future<int> guardarExtraccion({
    required String visitaId,
    required List<HallazgoExtraido> extraidos,
    String? resumen,
    List<String> temasPendientes = const [],
  }) async {
    return _db.transaction(() async {
      for (final h in extraidos) {
        await _db.insertarHallazgo(
          HallazgosCompanion.insert(
            id: _uuid.v4(),
            visitaId: visitaId,
            claveTecnica: h.claveTecnica,
            entidadDestino: Value(h.entidadDestino),
            entidadLocalId: Value(h.entidadLocalId),
            valorTexto: Value(h.valorTexto),
            valorNumerico: Value(h.valorNumerico),
            unidad: Value(h.unidad),
            fuente: Value(h.fuente),
            citaTextual: Value(h.citaTextual),
            segundoAudio: Value(h.segundoAudio),
            hablante: Value(h.hablante),
            certeza: Value(h.certeza),
            razonamiento: Value(h.razonamiento),
            confianza: Value(h.confianza),
            creadoEn: DateTime.now(),
          ),
        );
      }

      if (resumen != null || temasPendientes.isNotEmpty) {
        await (_db.update(_db.visitas)..where((v) => v.id.equals(visitaId)))
            .write(
          VisitasCompanion(
            resumen: Value(resumen),
            temasPendientes: Value(
              temasPendientes.isEmpty ? null : temasPendientes.join('\n'),
            ),
          ),
        );
      }

      return _db.refrescarCompletitud(visitaId);
    });
  }

  /// Encola la visita entera para sincronizar. El payload lleva el UUID, asi
  /// que `POST /v1/visitas` es idempotente: reintentar no duplica.
  Future<void> encolarVisita(String visitaId) async {
    final visita = await (_db.select(_db.visitas)
          ..where((v) => v.id.equals(visitaId)))
        .getSingle();

    // Id derivado de la visita y no un UUID nuevo: `encolar` reemplaza por id,
    // asi que volver a encolar la misma visita actualiza el item en vez de
    // dejar dos upserts encolados. El visitador toca Sincronizar varias veces.
    await _db.encolar(
      id: 'upsert-$visitaId',
      entidad: 'visita',
      entidadId: visitaId,
      operacion: 'upsert',
      payload: jsonEncode({'codigo_visita': visita.id}),
      prioridad: 10,
    );
  }

  /// Arma el payload de `POST /v1/visitas` desde la base local.
  ///
  /// La base local es la fuente de verdad mientras no hay senal, asi que esto
  /// no consulta nada remoto: lee lo que el telefono tiene y lo manda tal
  /// cual, aunque la visita este a medias. Esperar a que este completa
  /// significaria que un telefono que se moja en el potrero se lleva la visita.
  ///
  /// Los enlaces de audio y foto van solo si ya se subieron. La cola sube los
  /// archivos antes de encolar el upsert, pero si uno fallo y el visitador
  /// sincroniza igual, es mejor guardar la transcripcion sin el audio que no
  /// guardar nada.
  Future<Map<String, dynamic>> payloadDeVisita(String visitaId) async {
    final v = await (_db.select(_db.visitas)
          ..where((t) => t.id.equals(visitaId)))
        .getSingle();

    final visitador = v.visitadorLocalId == null
        ? null
        : await (_db.select(_db.visitadores)
              ..where((t) => t.id.equals(v.visitadorLocalId!)))
            .getSingleOrNull();

    final productor = v.productorLocalId == null
        ? null
        : await (_db.select(_db.productores)
              ..where((t) => t.id.equals(v.productorLocalId!)))
            .getSingleOrNull();

    final finca = v.fincaLocalId == null
        ? null
        : await (_db.select(_db.fincas)
              ..where((t) => t.id.equals(v.fincaLocalId!)))
            .getSingleOrNull();

    final vereda = v.veredaLocalId == null
        ? null
        : await (_db.select(_db.veredas)
              ..where((t) => t.id.equals(v.veredaLocalId!)))
            .getSingleOrNull();

    final grabaciones = await grabacionesDeVisita(visitaId);
    final evidencias = await evidenciasDeVisita(visitaId);
    final hallazgos = await (_db.select(_db.hallazgos)
          ..where((h) => h.visitaId.equals(visitaId)))
        .get();

    return {
      'codigo_visita': v.id,
      'inicio': v.inicio.toIso8601String(),
      if (v.fin != null) 'fin': v.fin!.toIso8601String(),
      if (v.tipoVisita != null) 'tipo_visita': v.tipoVisita,
      'estado': v.estado,
      if (visitador?.idEmpleado != null)
        'visitador_id_empleado': visitador!.idEmpleado,
      if (visitador != null) 'visitador_nombre': visitador.nombre,
      if (productor != null)
        'productor': {
          'nombre_completo': productor.nombreCompleto,
          if (productor.documento != null) 'documento': productor.documento,
          if (productor.telefono != null) 'telefono': productor.telefono,
          if (productor.codigoProductor != null)
            'codigo_productor': productor.codigoProductor,
        },
      if (finca != null)
        'finca': {
          'nombre': finca.nombre,
          if (vereda != null) 'vereda': vereda.vereda,
        },
      if (vereda != null) 'vereda': vereda.vereda,
      if (v.latitud != null) 'latitud': v.latitud,
      if (v.longitud != null) 'longitud': v.longitud,
      'consiente_audio': v.consienteAudio,
      'consiente_fotos': v.consienteFotos,
      'consiente_uso_datos': v.consienteUsoDatos,
      if (v.segundoConsentimiento != null)
        'segundo_consentimiento': v.segundoConsentimiento,
      'marcada_para_eliminacion': v.marcadaParaEliminacion,
      if (v.objetivo != null) 'objetivo': v.objetivo,
      if (v.observaciones != null) 'observaciones': v.observaciones,
      if (v.resumen != null) 'resumen': v.resumen,
      if (v.temasPendientes != null) 'temas_pendientes': v.temasPendientes,
      if (v.notasPruebaCampo != null) 'notas_prueba_campo': v.notasPruebaCampo,
      'completitud_pct': v.completitudPct,
      'grabaciones': [
        for (final g in grabaciones)
          {
            'id': g.id,
            'orden': g.orden,
            'inicio': g.inicio.toIso8601String(),
            'duracion_seg': g.duracionSeg,
            'tamano_bytes': g.tamanoBytes,
            if (g.enlaceAudio != null) 'enlace_audio': g.enlaceAudio,
            if (g.transcripcion != null) 'transcripcion': g.transcripcion,
            if (g.transcripcionMarcas != null)
              'transcripcion_marcas': g.transcripcionMarcas,
            if (g.motorTranscripcion != null)
              'motor_transcripcion': g.motorTranscripcion,
            'estado': g.estado,
          },
      ],
      'evidencias': [
        for (final e in evidencias)
          {
            'id': e.id,
            if (e.tipo != null) 'tipo': e.tipo,
            'tomada_en': e.tomadaEn.toIso8601String(),
            if (e.latitud != null) 'latitud': e.latitud,
            if (e.longitud != null) 'longitud': e.longitud,
            if (e.segundoAudio != null) 'segundo_audio': e.segundoAudio,
            if (e.descripcionVisitador != null)
              'descripcion_visitador': e.descripcionVisitador,
            if (e.descripcionIa != null) 'descripcion_ia': e.descripcionIa,
            if (e.textoOcr != null) 'texto_ocr': e.textoOcr,
            if (e.enlaceArchivo != null) 'enlace_archivo': e.enlaceArchivo,
            'estado_validacion': e.estadoValidacion,
          },
      ],
      'hallazgos': [
        for (final h in hallazgos)
          {
            'id': h.id,
            'clave_tecnica': h.claveTecnica,
            if (h.entidadDestino != null)
              'entidad_destino': h.entidadDestino!.airtable,
            if (h.entidadLocalId != null) 'entidad_local_id': h.entidadLocalId,
            if (h.valorTexto != null) 'valor_texto': h.valorTexto,
            if (h.valorNumerico != null) 'valor_numerico': h.valorNumerico,
            if (h.unidad != null) 'unidad': h.unidad,
            'fuente': h.fuente.airtable,
            if (h.citaTextual != null) 'cita_textual': h.citaTextual,
            if (h.segundoAudio != null) 'segundo_audio': h.segundoAudio,
            if (h.hablante != null) 'hablante': h.hablante!.airtable,
            'certeza': h.certeza.airtable,
            if (h.razonamiento != null) 'razonamiento': h.razonamiento,
            if (h.confianza != null) 'confianza': h.confianza,
            'estado': h.estado.airtable,
            if (h.valorCorregido != null) 'valor_corregido': h.valorCorregido,
          },
      ],
    };
  }

  /// Posicion de un archivo dentro de su visita, contando desde 1.
  ///
  /// Con esto la foto queda en el bucket como `foto-03.jpg` en vez del reloj
  /// en milisegundos que le pone la camara. El orden es por hora de toma, que
  /// es el mismo criterio con el que Airtable numera las evidencias: si los
  /// dos no coinciden, la "Foto 3" de Airtable apunta a otra imagen.
  ///
  /// Devuelve null si el archivo no se encuentra: es preferible conservar el
  /// nombre feo a inventar una posicion.
  Future<int?> ordenDeArchivo(String archivoPath) async {
    final evidencia = await (_db.select(_db.evidencias)
          ..where((e) => e.archivoPath.equals(archivoPath)))
        .getSingleOrNull();
    if (evidencia != null) {
      final todas = await evidenciasDeVisita(evidencia.visitaId);
      final i = todas.indexWhere((e) => e.id == evidencia.id);
      return i < 0 ? null : i + 1;
    }

    final grabacion = await (_db.select(_db.grabaciones)
          ..where((g) => g.archivoPath.equals(archivoPath)))
        .getSingleOrNull();
    return grabacion?.orden;
  }

  /// Guarda la URL del bucket de un tramo ya subido.
  ///
  /// Se busca por ruta de archivo y no por id porque la cola encola contra la
  /// visita, no contra el tramo: `SyncQueue.entidadId` es el UUID de la visita
  /// y `archivoPath` es lo que identifica al archivo concreto.
  ///
  /// Se guarda en cuanto la subida termina, no al final de la visita: si la
  /// app muere despues de subir, el byte ya viajo y no hay que volver a
  /// gastarlo en una vereda con senal contada.
  Future<void> registrarEnlaceAudio(String archivoPath, String url) =>
      (_db.update(_db.grabaciones)
            ..where((g) => g.archivoPath.equals(archivoPath)))
          .write(GrabacionesCompanion(enlaceAudio: Value(url)));

  Future<void> registrarEnlaceEvidencia(String archivoPath, String url) =>
      (_db.update(_db.evidencias)
            ..where((e) => e.archivoPath.equals(archivoPath)))
          .write(EvidenciasCompanion(enlaceArchivo: Value(url)));

  /// Marca la visita como sincronizada. Solo lo llama la cola, y solo cuando
  /// el backend confirmo: sincronizada en falso es recuperable, en verdadero
  /// sin haberlo estado significa una visita que nadie va a volver a mandar.
  Future<void> marcarSincronizada(String visitaId) =>
      (_db.update(_db.visitas)..where((v) => v.id.equals(visitaId))).write(
        VisitasCompanion(
          sincronizada: const Value(true),
          sincronizadaEn: Value(DateTime.now()),
        ),
      );

  Future<List<Visita>> visitas() =>
      (_db.select(_db.visitas)
            ..orderBy([
              (v) => OrderingTerm(
                    expression: v.inicio,
                    mode: OrderingMode.desc,
                  ),
            ]))
          .get();
}
