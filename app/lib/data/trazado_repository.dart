import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../core/geo.dart';
import '../core/kml.dart';
import 'db/app_database.dart';
import 'nombres_archivo.dart';
import 'visita_repository.dart';

/// Que paso con un punto que se intento agregar.
///
/// No es un bool a proposito: el visitador tiene derecho a saber POR QUE un
/// punto no entro. En modo automatico, un contador que sube menos rapido de lo
/// esperado sin explicacion se lee como que la app dejo de funcionar, y lo
/// siguiente es caminar el lote otra vez.
enum ResultadoPunto {
  agregado,

  /// Estaba a menos de `distanciaMinM` del punto anterior. Es lo normal
  /// cuando el visitador se detiene a hablar: el reloj sigue, el lote no
  /// cambia.
  muyCerca,

  /// El GPS reporto un error mayor que `precisionMaxM`. El punto se descarta
  /// entero: promediarlo o meterlo igual mueve el lindero.
  precisionInsuficiente,
}

/// Los trazados de una visita: los poligonos del cultivo y los recorridos.
///
/// La decision que gobierna todo este archivo: **nada se captura solo y nada
/// se filtra por defecto de forma oculta**. El tipo de figura, el intervalo, la
/// distancia minima y la precision maxima son del visitador y viven en la fila
/// del trazado. Aca solo se aplican; no se eligen.
class TrazadoRepository {
  TrazadoRepository(this._db, this._visitas, {Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final VisitaRepository _visitas;
  final Uuid _uuid;

  // ------------------------------------------------------------------ crear

  /// Crea el trazado vacio. Nace sin puntos: la figura se construye caminando,
  /// no rellenando un formulario.
  ///
  /// [intervaloSeg], [distanciaMinM] y [precisionMaxM] se guardan aunque el
  /// trazado arranque en manual: son la configuracion del trazado, no del
  /// momento, y tienen que seguir ahi cuando el visitador prenda el automatico
  /// media hora despues, con la app reabierta.
  Future<String> crearTrazado({
    required String visitaId,
    String? nombre,
    TipoTrazado tipo = TipoTrazado.poligono,
    ModoCaptura modoCaptura = ModoCaptura.manual,
    String? etiqueta,
    String? notas,
    int? intervaloSeg,
    double? distanciaMinM,
    double? precisionMaxM,
    bool? cerrado,
  }) async {
    final id = _uuid.v4();
    await _db.into(_db.trazados).insert(
          TrazadosCompanion.insert(
            id: id,
            visitaId: visitaId,
            nombre: nombre?.trim().isNotEmpty == true
                ? nombre!.trim()
                : await _nombrePorDefecto(visitaId, tipo),
            tipo: Value(tipo),
            modoCaptura: Value(modoCaptura),
            etiqueta: Value(_limpio(etiqueta)),
            notas: Value(_limpio(notas)),
            intervaloSeg: Value(intervaloSeg),
            distanciaMinM: Value(distanciaMinM),
            precisionMaxM: Value(precisionMaxM),
            // Un punto suelto y una ruta no cierran nunca; un poligono cierra
            // salvo que el visitador diga lo contrario.
            cerrado: Value(cerrado ?? tipo.esPoligono),
            creadoEn: DateTime.now(),
          ),
        );
    return id;
  }

  /// `Lote 2`, `Recorrido 1`. Numera por tipo y dentro de la visita: el
  /// visitador va a tener tres lotes y un recorrido, y «Trazado 4» no le dice
  /// cual es cual.
  Future<String> _nombrePorDefecto(String visitaId, TipoTrazado tipo) async {
    final existentes = await _db.trazadosDeVisita(visitaId);
    final n = existentes.where((t) => t.tipo == tipo).length + 1;
    return switch (tipo) {
      TipoTrazado.poligono => 'Lote $n',
      TipoTrazado.ruta => 'Recorrido $n',
      TipoTrazado.punto => 'Punto $n',
    };
  }

  // ------------------------------------------------------------------ puntos

  /// Agrega un punto al final del trazado y devuelve si entro.
  ///
  /// Los filtros de distancia y precision se aplican **solo a los puntos
  /// automaticos**. Un punto marcado a mano se respeta siempre: el visitador
  /// esta parado en la esquina del lote y sabe algo que el filtro no. Si el GPS
  /// anda mal en ese momento, lo que corresponde es avisarlo en pantalla, no
  /// descartar la esquina en silencio.
  Future<ResultadoPunto> agregarPunto({
    required String trazadoId,
    required double latitud,
    required double longitud,
    double? altitud,
    double? precisionM,
    bool automatico = false,
    String? nota,
    DateTime? capturadoEn,
  }) async {
    final trazado = await porId(trazadoId);
    if (trazado == null) return ResultadoPunto.muyCerca;

    final puntos = await _db.puntosDeTrazado(trazadoId);

    if (automatico) {
      final maxima = trazado.precisionMaxM;
      if (maxima != null &&
          maxima > 0 &&
          precisionM != null &&
          precisionM > maxima) {
        return ResultadoPunto.precisionInsuficiente;
      }

      final minima = trazado.distanciaMinM;
      if (minima != null && minima > 0 && puntos.isNotEmpty) {
        final anterior = puntos.last;
        final d = distanciaMetros(
          PuntoGeo(anterior.latitud, anterior.longitud),
          PuntoGeo(latitud, longitud),
        );
        if (d < minima) return ResultadoPunto.muyCerca;
      }
    }

    await _db.into(_db.puntosTrazado).insert(
          PuntosTrazadoCompanion.insert(
            id: _uuid.v4(),
            trazadoId: trazadoId,
            // El orden se calcula sobre el mayor existente y no sobre la
            // cantidad: borrar un punto del medio deja huecos, y reusar un
            // numero pondria dos vertices en la misma posicion del anillo.
            orden: puntos.isEmpty ? 1 : puntos.last.orden + 1,
            latitud: latitud,
            longitud: longitud,
            altitud: Value(altitud),
            precisionM: Value(precisionM),
            capturadoEn: capturadoEn ?? DateTime.now(),
            automatico: Value(automatico),
            nota: Value(_limpio(nota)),
          ),
        );

    await _marcarModo(trazado, automatico);
    await _db.refrescarGeometria(trazadoId);
    return ResultadoPunto.agregado;
  }

  /// Un trazado que empezo automatico y recibio un punto a mano (o al
  /// contrario) queda `mixto`. Importa despues: un lindero mixto se revisa
  /// distinto de uno caminado entero por el reloj.
  Future<void> _marcarModo(Trazado trazado, bool automatico) async {
    final esperado = automatico ? ModoCaptura.automatico : ModoCaptura.manual;
    if (trazado.modoCaptura == esperado ||
        trazado.modoCaptura == ModoCaptura.mixto) {
      return;
    }
    await (_db.update(_db.trazados)..where((t) => t.id.equals(trazado.id)))
        .write(const TrazadosCompanion(modoCaptura: Value(ModoCaptura.mixto)));
  }

  /// Borra un punto. Es la herramienta contra el salto del GPS: bajo un
  /// guadual el telefono tira un punto a 80 m y deja el lote con una punta.
  Future<void> eliminarPunto(String puntoId) async {
    final punto = await (_db.select(_db.puntosTrazado)
          ..where((p) => p.id.equals(puntoId)))
        .getSingleOrNull();
    if (punto == null) return;

    await (_db.delete(_db.puntosTrazado)..where((p) => p.id.equals(puntoId)))
        .go();
    await _db.refrescarGeometria(punto.trazadoId);
  }

  /// Deshace el ultimo punto. Es el boton que se usa de verdad en campo:
  /// marcar de mas al caminar pasa todo el tiempo.
  Future<void> deshacerUltimoPunto(String trazadoId) async {
    final puntos = await _db.puntosDeTrazado(trazadoId);
    if (puntos.isEmpty) return;
    await eliminarPunto(puntos.last.id);
  }

  Future<void> eliminarTodosLosPuntos(String trazadoId) async {
    await (_db.delete(_db.puntosTrazado)
          ..where((p) => p.trazadoId.equals(trazadoId)))
        .go();
    await _db.refrescarGeometria(trazadoId);
  }

  // ------------------------------------------------------------------ editar

  /// Cambia lo que el visitador puede cambiar. Todo es opcional: la pantalla
  /// manda solo el campo que se toco.
  ///
  /// Al cambiar `tipo` o `cerrado` se recalcula la geometria: pasar un
  /// poligono a ruta le quita el area, y dejarla guardada seria mostrar
  /// hectareas de algo que ya no es un anillo.
  Future<void> actualizarTrazado(
    String trazadoId, {
    String? nombre,
    TipoTrazado? tipo,
    String? etiqueta,
    String? notas,
    int? intervaloSeg,
    double? distanciaMinM,
    double? precisionMaxM,
    bool? cerrado,
  }) async {
    await (_db.update(_db.trazados)..where((t) => t.id.equals(trazadoId))).write(
      TrazadosCompanion(
        nombre: nombre == null || nombre.trim().isEmpty
            ? const Value.absent()
            : Value(nombre.trim()),
        tipo: tipo == null ? const Value.absent() : Value(tipo),
        // Estos tres si aceptan vaciarse: «sin filtro de distancia» es una
        // eleccion valida y hay que poder volver a ella.
        etiqueta: etiqueta == null ? const Value.absent() : Value(_limpio(etiqueta)),
        notas: notas == null ? const Value.absent() : Value(_limpio(notas)),
        intervaloSeg:
            intervaloSeg == null ? const Value.absent() : Value(intervaloSeg),
        distanciaMinM:
            distanciaMinM == null ? const Value.absent() : Value(distanciaMinM),
        precisionMaxM:
            precisionMaxM == null ? const Value.absent() : Value(precisionMaxM),
        cerrado: cerrado == null ? const Value.absent() : Value(cerrado),
        actualizadoEn: Value(DateTime.now()),
      ),
    );
    await _db.refrescarGeometria(trazadoId);
  }

  /// Borra el trazado con sus puntos. Los hijos primero: al revés la clave
  /// foranea rechaza el borrado, igual que al eliminar una visita.
  Future<void> eliminarTrazado(String trazadoId) async {
    await _db.transaction(() async {
      await (_db.delete(_db.puntosTrazado)
            ..where((p) => p.trazadoId.equals(trazadoId)))
          .go();
      await (_db.delete(_db.trazados)..where((t) => t.id.equals(trazadoId)))
          .go();
    });
  }

  // ------------------------------------------------------------------ leer

  Future<Trazado?> porId(String trazadoId) =>
      (_db.select(_db.trazados)..where((t) => t.id.equals(trazadoId)))
          .getSingleOrNull();

  Future<List<Trazado>> trazadosDeVisita(String visitaId) =>
      _db.trazadosDeVisita(visitaId);

  Future<List<PuntoTrazado>> puntosDeTrazado(String trazadoId) =>
      _db.puntosDeTrazado(trazadoId);

  // ------------------------------------------------------------------ KML

  /// El KML de la visita, o de un solo trazado si se pasa [soloTrazadoId].
  ///
  /// [incluirFotos] mete las coordenadas de las fotos como marcas aparte. Se
  /// ofrece porque en la practica ese es el mapa que se quiere ver: el lote
  /// dibujado y, encima, donde se fotografio la mancha en las hojas.
  Future<DocumentoKml> documentoKml(
    String visitaId, {
    String? soloTrazadoId,
    bool incluirVertices = false,
    bool incluirFotos = true,
    bool incluirPuntoVisita = true,
  }) async {
    final ctx = await _visitas.contextoInforme(visitaId);
    final visita = await (_db.select(_db.visitas)
          ..where((v) => v.id.equals(visitaId)))
        .getSingle();

    final lista = soloTrazadoId == null
        ? await _db.trazadosDeVisita(visitaId)
        : [await porId(soloTrazadoId)].whereType<Trazado>().toList();

    final trazadosKml = <TrazadoKml>[];
    for (final t in lista) {
      final puntos = await _db.puntosDeTrazado(t.id);
      if (puntos.isEmpty) continue;
      trazadosKml.add(_aKml(t, puntos, ctx));
    }

    final referencias = <PuntoKml>[];
    if (incluirPuntoVisita && visita.latitud != null && visita.longitud != null) {
      referencias.add(
        PuntoKml(
          nombre: 'Inicio de la visita',
          latitud: visita.latitud!,
          longitud: visita.longitud!,
          precisionM: visita.precisionGps,
          momento: visita.inicio,
        ),
      );
    }
    if (incluirFotos) {
      final fotos = await _visitas.evidenciasDeVisita(visitaId);
      for (var i = 0; i < fotos.length; i++) {
        final f = fotos[i];
        if (f.latitud == null || f.longitud == null) continue;
        referencias.add(
          PuntoKml(
            nombre: 'Foto ${(i + 1).toString().padLeft(2, '0')}',
            latitud: f.latitud!,
            longitud: f.longitud!,
            momento: f.tomadaEn,
            nota: f.descripcionVisitador ?? f.descripcionIa,
          ),
        );
      }
    }

    final quien = (ctx['finca'] ?? ctx['productor'] ?? 'Visita de campo') as String;
    return DocumentoKml(
      nombre: quien,
      descripcion: [
        'Visita del ${_fechaCorta(visita.inicio)}',
        if (ctx['productor'] != null) 'Productor: ${ctx['productor']}',
        if (ctx['vereda'] != null)
          'Vereda: ${ctx['vereda']}${ctx['municipio'] == null ? '' : ' (${ctx['municipio']})'}',
        if (ctx['visitador'] != null) 'Visitador: ${ctx['visitador']}',
        'Codigo de visita: ${visita.id}',
      ].join('\n'),
      trazados: trazadosKml,
      referencias: referencias,
      incluirVertices: incluirVertices,
    );
  }

  TrazadoKml _aKml(
    Trazado t,
    List<PuntoTrazado> puntos,
    Map<String, dynamic> ctx,
  ) {
    final geos = [for (final p in puntos) PuntoGeo(p.latitud, p.longitud)];
    final esAnillo = t.tipo.esPoligono && t.cerrado;

    return TrazadoKml(
      nombre: t.nombre,
      geometria: switch (t.tipo) {
        TipoTrazado.poligono => GeometriaKml.poligono,
        TipoTrazado.ruta => GeometriaKml.ruta,
        TipoTrazado.punto => GeometriaKml.punto,
      },
      cerrado: t.cerrado,
      etiqueta: t.etiqueta,
      notas: t.notas,
      puntos: [
        for (final p in puntos)
          PuntoKml(
            latitud: p.latitud,
            longitud: p.longitud,
            altitud: p.altitud,
            precisionM: p.precisionM,
            momento: p.capturadoEn,
            nota: p.nota,
            automatico: p.automatico,
          ),
      ],
      // Lo que hace que el KML se pueda auditar seis meses despues: como se
      // capturo, con que filtros y de que visita salio.
      datos: {
        'Codigo de visita': t.visitaId,
        if (ctx['productor'] != null) 'Productor': '${ctx['productor']}',
        if (ctx['finca'] != null) 'Finca': '${ctx['finca']}',
        if (ctx['vereda'] != null) 'Vereda': '${ctx['vereda']}',
        if (ctx['visitador'] != null) 'Visitador': '${ctx['visitador']}',
        'Tipo': t.tipo.airtable,
        'Modo de captura': t.modoCaptura.airtable,
        if (t.intervaloSeg != null && t.intervaloSeg! > 0)
          'Intervalo': '${t.intervaloSeg} s',
        if (t.distanciaMinM != null && t.distanciaMinM! > 0)
          'Distancia minima': '${t.distanciaMinM!.toStringAsFixed(0)} m',
        if (t.precisionMaxM != null && t.precisionMaxM! > 0)
          'Precision maxima aceptada': '${t.precisionMaxM!.toStringAsFixed(0)} m',
        'Puntos': '${puntos.length}',
        if (esAnillo) 'Area (ha)': (areaM2(geos) / 10000).toStringAsFixed(4),
        if (esAnillo)
          'Perimetro (m)':
              longitudMetros(geos, cerrado: true).toStringAsFixed(1),
        if (!esAnillo && geos.length > 1)
          'Largo (m)': longitudMetros(geos).toStringAsFixed(1),
        'Capturado el': _fechaCorta(t.creadoEn),
      },
    );
  }

  /// Escribe el KML en el temporal y devuelve el archivo, listo para
  /// compartir. Va al temporal y no a un directorio permanente porque la
  /// fuente de verdad son los puntos en la base: el KML se vuelve a armar
  /// cuando se necesite, y guardarlo dos veces solo abre la puerta a que uno
  /// de los dos quede viejo.
  Future<File> exportarKml(
    String visitaId, {
    String? soloTrazadoId,
    bool incluirVertices = false,
    bool incluirFotos = true,
  }) async {
    final doc = await documentoKml(
      visitaId,
      soloTrazadoId: soloTrazadoId,
      incluirVertices: incluirVertices,
      incluirFotos: incluirFotos,
    );
    // Se mira `trazados` y no `doc.vacio`: un documento que solo lleva la
    // coordenada de llegada y las fotos no esta vacio, pero tampoco es lo que
    // el visitador pidio al tocar «Exportar» en un lote sin caminar.
    if (doc.trazados.isEmpty) {
      throw Exception(
        'Todavia no hay ningun punto capturado, asi que no hay nada que '
        'exportar.',
      );
    }

    final temporal = await getTemporaryDirectory();
    final archivo = File(p.join(temporal.path, await nombreKml(visitaId,
        soloTrazadoId: soloTrazadoId)));
    // Se escribe en UTF-8 explicito: el encabezado del KML lo declara, y si el
    // archivo saliera en otra codificacion los nombres con eñe abririan rotos.
    await archivo.writeAsString(construirKml(doc), encoding: utf8);
    return archivo;
  }

  Future<String> nombreKml(String visitaId, {String? soloTrazadoId}) async {
    final visita = await (_db.select(_db.visitas)
          ..where((v) => v.id.equals(visitaId)))
        .getSingle();
    final ctx = await _visitas.contextoInforme(visitaId);
    final quien = slugArchivo((ctx['finca'] ?? ctx['productor'] ?? '') as String);
    final sufijo = soloTrazadoId == null
        ? ''
        : '-${slugArchivo((await porId(soloTrazadoId))?.nombre ?? 'trazado')}';
    return 'lotes-${selloFecha(visita.inicio)}'
        '${quien.isEmpty ? '' : '-$quien'}$sufijo.kml';
  }

  String? _limpio(String? texto) {
    if (texto == null) return null;
    final t = texto.trim();
    return t.isEmpty ? null : t;
  }

  String _fechaCorta(DateTime d) {
    final l = d.toLocal();
    String dd(int n) => n.toString().padLeft(2, '0');
    return '${dd(l.day)}/${dd(l.month)}/${l.year}';
  }
}
