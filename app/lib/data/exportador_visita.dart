import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/informe_pdf.dart';
import '../core/kml.dart';
import 'db/app_database.dart';
import 'nombres_archivo.dart';
import 'trazado_repository.dart';
import 'visita_repository.dart';

/// Arma un .zip con TODO lo que el telefono tiene de una visita.
///
/// Existe porque la visita vive en dos mitades que nunca estan juntas: las
/// filas en SQLite y los archivos en el directorio privado de la app. Ninguna
/// de las dos se puede sacar del telefono a mano — el directorio no es
/// accesible sin root, y la base no le sirve a nadie fuera de la app. Este es
/// el unico camino para que el audio, las fotos y el informe salgan del
/// telefono sin depender de que la sincronizacion haya funcionado.
///
/// Por eso mismo es tambien el paso previo a borrar: quien elimina una visita
/// deberia poder descargarla primero.
class ExportadorVisitas {
  ExportadorVisitas(this._db, this._repo);

  final AppDatabase _db;
  final VisitaRepository _repo;

  /// Se arma aca en vez de inyectarse: el exportador es el unico que lo usa y
  /// no tiene estado propio.
  late final TrazadoRepository _trazados = TrazadoRepository(_db, _repo);

  /// Devuelve el .zip escrito en el directorio temporal, listo para compartir.
  ///
  /// El zip se escribe a disco a medida que se agregan los archivos y no se
  /// arma en memoria: un audio de una visita de una hora pesa varios MB y el
  /// visitador puede exportar varias visitas juntas.
  ///
  /// `onPaso` alimenta el texto del dialogo de progreso. Armar esto tarda —
  /// los PDF y la compresion del audio no son gratis — y un spinner mudo
  /// durante medio minuto parece una app colgada.
  Future<File> exportar(
    List<String> visitaIds, {
    void Function(String)? onPaso,
  }) async {
    final visitas = await (_db.select(_db.visitas)
          ..where((v) => v.id.isIn(visitaIds))
          ..orderBy([
            (v) => OrderingTerm(expression: v.inicio, mode: OrderingMode.desc),
          ]))
        .get();

    if (visitas.isEmpty) {
      throw Exception('Las visitas seleccionadas ya no estan en el telefono.');
    }

    final temporal = await getTemporaryDirectory();
    final destino = p.join(
      temporal.path,
      visitas.length == 1
          ? '${await _nombreDeVisita(visitas.first)}.zip'
          : 'visitas-${visitas.length}-${selloFecha(DateTime.now())}.zip',
    );

    // Un zip viejo con el mismo nombre haria que el encoder escriba encima a
    // medias. Se borra antes de empezar.
    final archivoZip = File(destino);
    if (await archivoZip.exists()) await archivoZip.delete();

    final zip = ZipFileEncoder();
    zip.create(destino);

    try {
      for (var i = 0; i < visitas.length; i++) {
        final visita = visitas[i];
        onPaso?.call(
          visitas.length == 1
              ? 'Recogiendo la visita...'
              : 'Visita ${i + 1} de ${visitas.length}...',
        );

        // Con una sola visita todo va en la raiz del zip; con varias, cada una
        // en su carpeta. Abrir un zip y encontrar `fotos/` de tres visitas
        // mezcladas no le sirve a nadie.
        final raiz = visitas.length == 1
            ? ''
            : '${await _nombreDeVisita(visita)}/';

        await _agregarVisita(zip, visita, raiz, onPaso);
      }
    } catch (_) {
      // Cerrar antes de propagar: si no, queda el descriptor abierto y un zip
      // truncado en el temporal con cara de archivo bueno.
      await zip.close();
      if (await archivoZip.exists()) await archivoZip.delete();
      rethrow;
    }

    await zip.close();
    return archivoZip;
  }

  Future<void> _agregarVisita(
    ZipFileEncoder zip,
    Visita visita,
    String raiz,
    void Function(String)? onPaso,
  ) async {
    final faltantes = <String>[];

    // --- Los datos ---
    final payload = await _repo.payloadDeVisita(visita.id);
    zip.addArchiveFile(
      ArchiveFile.string(
        '${raiz}visita.json',
        const JsonEncoder.withIndent('  ').convert(payload),
      ),
    );

    final ctx = await _repo.contextoInforme(visita.id);
    zip.addArchiveFile(
      ArchiveFile.string('${raiz}resumen.txt', _resumen(visita, ctx, payload)),
    );

    // Las coordenadas aparte y en CSV aunque ya esten en el JSON: es el
    // formato que se abre en un mapa o en una hoja de calculo sin programar
    // nada, que es lo que se hace con ellas.
    zip.addArchiveFile(
      ArchiveFile.string(
        '${raiz}coordenadas.csv',
        await _coordenadasCsv(visita),
      ),
    );

    // El KML aparte del CSV: el CSV son puntos sueltos y esto son las figuras.
    // Va con los vertices incluidos porque este zip es la copia de archivo de
    // la visita — el KML para mostrarle a alguien se exporta desde la pantalla
    // del trazado, y ahi el visitador elige.
    final doc = await _trazados.documentoKml(visita.id, incluirVertices: true);
    if (!doc.vacio) {
      zip.addArchiveFile(
        ArchiveFile.string('${raiz}trazados.kml', construirKml(doc)),
      );
    }

    final transcripcion = await _repo.transcripcionCompleta(visita.id);
    if (transcripcion.trim().isNotEmpty) {
      zip.addArchiveFile(
        ArchiveFile.string('${raiz}transcripcion.txt', transcripcion),
      );
    }

    // --- Los informes: markdown y PDF ---
    final informes = await _repo.informesDeVisita(visita.id);
    for (final informe in informes) {
      final base = 'v${informe.version}-${slugArchivo(informe.titulo)}';
      zip.addArchiveFile(
        ArchiveFile.string(
          '${raiz}informes/$base.md',
          '# ${informe.titulo}\n\n${informe.contenido}\n',
        ),
      );

      onPaso?.call('Armando el PDF del informe...');
      // El PDF se arma aca y no se busca en disco porque nunca se guarda:
      // la app lo genera al momento de compartirlo. Si falla (una foto
      // corrupta, por ejemplo) sigue el markdown, que es el contenido real.
      try {
        final bytes = await construirInformePdf(
          DatosInforme(
            titulo: informe.titulo,
            contenido: informe.contenido,
            generadoEn: informe.generadoEn,
            productor: ctx['productor'] as String?,
            finca: ctx['finca'] as String?,
            vereda: ctx['vereda'] as String?,
            municipio: ctx['municipio'] as String?,
            visitador: ctx['visitador'] as String?,
            fechaVisita: visita.inicio,
            fotos: [
              for (final f in await _repo.evidenciasDeVisita(visita.id))
                f.archivoPath,
            ],
          ),
        );
        zip.addArchiveFile(ArchiveFile.bytes('${raiz}informes/$base.pdf', bytes));
      } catch (e) {
        faltantes.add('El PDF de «${informe.titulo}» no se pudo armar: $e');
      }
    }

    // --- Los audios ---
    final grabaciones = await _repo.grabacionesDeVisita(visita.id);
    for (final g in grabaciones) {
      final archivo = File(g.archivoPath);
      if (!await archivo.exists()) {
        faltantes.add(
          'Audio del tramo ${g.orden}: el archivo ya no esta en el telefono '
          '(${g.archivoPath})',
        );
        continue;
      }
      onPaso?.call('Comprimiendo audio del tramo ${g.orden}...');
      final ext = p.extension(g.archivoPath);
      await zip.addFile(
        archivo,
        '${raiz}audios/tramo-${g.orden.toString().padLeft(2, '0')}$ext',
      );
    }

    // --- Las fotos ---
    final fotos = await _repo.evidenciasDeVisita(visita.id);
    for (var i = 0; i < fotos.length; i++) {
      final archivo = File(fotos[i].archivoPath);
      if (!await archivo.exists()) {
        faltantes.add(
          'Foto ${i + 1}: el archivo ya no esta en el telefono '
          '(${fotos[i].archivoPath})',
        );
        continue;
      }
      onPaso?.call('Copiando foto ${i + 1} de ${fotos.length}...');
      final ext = p.extension(fotos[i].archivoPath);
      await zip.addFile(
        archivo,
        '${raiz}fotos/foto-${(i + 1).toString().padLeft(2, '0')}$ext',
      );
    }

    // Un zip al que le falta el audio tiene que decirlo. Si no, el que lo abre
    // asume que la visita no se grabo, y esa es la conclusion equivocada.
    if (faltantes.isNotEmpty) {
      zip.addArchiveFile(
        ArchiveFile.string(
          '${raiz}FALTANTES.txt',
          'Estos archivos estaban registrados en la base pero no se '
              'encontraron en el telefono:\n\n'
              '${faltantes.map((f) => '- $f').join('\n')}\n',
        ),
      );
    }
  }

  /// La ficha legible. El JSON es para el que va a procesar la visita; esto es
  /// para el que abre el zip y quiere saber de que visita se trata.
  String _resumen(
    Visita v,
    Map<String, dynamic> ctx,
    Map<String, dynamic> payload,
  ) {
    final b = StringBuffer()
      ..writeln('VISITA DE CAMPO — SIRIUS REGENERATIVE')
      ..writeln('=' * 46)
      ..writeln()
      ..writeln('Codigo de visita : ${v.id}')
      ..writeln('Inicio           : ${v.inicio.toLocal()}')
      ..writeln('Fin              : ${v.fin?.toLocal() ?? 'sin cerrar'}')
      ..writeln('Estado           : ${v.estado}')
      ..writeln('Tipo             : ${v.tipoVisita ?? '—'}')
      ..writeln('Completitud      : ${v.completitudPct}%')
      ..writeln()
      ..writeln('Visitador        : ${ctx['visitador'] ?? '—'}')
      ..writeln('Productor        : ${ctx['productor'] ?? '—'}')
      ..writeln('Finca            : ${ctx['finca'] ?? '—'}')
      ..writeln('Vereda           : ${ctx['vereda'] ?? '—'}')
      ..writeln('Municipio        : ${ctx['municipio'] ?? '—'}')
      ..writeln()
      ..writeln('Coordenadas      : ${_coordenadas(v)}')
      ..writeln('Precision GPS    : '
          '${v.precisionGps == null ? '—' : '${v.precisionGps!.toStringAsFixed(1)} m'}')
      ..writeln()
      ..writeln('CONSENTIMIENTO (Ley 1581/2012)')
      ..writeln('  Audio          : ${_si(v.consienteAudio)}')
      ..writeln('  Fotos          : ${_si(v.consienteFotos)}')
      ..writeln('  Uso de datos   : ${_si(v.consienteUsoDatos)}')
      ..writeln('  Consta al seg. : ${v.segundoConsentimiento ?? '—'}')
      ..writeln()
      ..writeln('Sincronizada     : ${_si(v.sincronizada)}'
          '${v.sincronizadaEn == null ? '' : ' (${v.sincronizadaEn!.toLocal()})'}');

    final hallazgos = (payload['hallazgos'] as List?) ?? const [];
    if (hallazgos.isNotEmpty) {
      b
        ..writeln()
        ..writeln('DATOS EXTRAIDOS DE LA CONVERSACION (${hallazgos.length})')
        ..writeln('-' * 46);
      for (final h in hallazgos.cast<Map<String, dynamic>>()) {
        final unidad = h['unidad'] == null ? '' : ' ${h['unidad']}';
        b.writeln('  ${h['campo'] ?? h['clave_tecnica']}: '
            '${h['valor']}$unidad  [${h['certeza']}]');
      }
    }

    final trazados = (payload['trazados'] as List?) ?? const [];
    if (trazados.isNotEmpty) {
      b
        ..writeln()
        ..writeln('TRAZADOS CAPTURADOS EN CAMPO (${trazados.length})')
        ..writeln('-' * 46)
        ..writeln('El dibujo esta en trazados.kml — este es el resumen.');
      for (final t in trazados.cast<Map<String, dynamic>>()) {
        final puntos = (t['puntos'] as List?)?.length ?? 0;
        final medida = t['area_ha'] != null
            ? '${(t['area_ha'] as num).toStringAsFixed(2)} ha'
            : t['perimetro_m'] != null
                ? '${(t['perimetro_m'] as num).toStringAsFixed(0)} m de recorrido'
                : 'sin medida';
        b.writeln('  ${t['nombre']} (${t['tipo']}, ${t['modo_captura']}): '
            '$puntos punto(s), $medida'
            '${t['etiqueta'] == null ? '' : ' — ${t['etiqueta']}'}');
      }
    }

    if (v.temasPendientes != null && v.temasPendientes!.trim().isNotEmpty) {
      b
        ..writeln()
        ..writeln('TEMAS PENDIENTES')
        ..writeln('-' * 46)
        ..writeln(v.temasPendientes);
    }

    if (v.observaciones != null && v.observaciones!.trim().isNotEmpty) {
      b
        ..writeln()
        ..writeln('OBSERVACIONES DEL VISITADOR')
        ..writeln('-' * 46)
        ..writeln(v.observaciones);
    }

    b
      ..writeln()
      ..writeln('-' * 46)
      ..writeln('Exportado el ${DateTime.now().toLocal()}');

    return b.toString();
  }

  /// La de la visita y la de cada foto que la traiga. Las fotos tienen su
  /// propia coordenada porque se toman caminando el lote, no en la casa.
  Future<String> _coordenadasCsv(Visita v) async {
    final filas = <String>['tipo,referencia,latitud,longitud,momento'];

    if (v.latitud != null && v.longitud != null) {
      filas.add(
        'visita,${v.id},${v.latitud},${v.longitud},'
        '${v.inicio.toIso8601String()}',
      );
    }

    final fotos = await _repo.evidenciasDeVisita(v.id);
    for (var i = 0; i < fotos.length; i++) {
      final f = fotos[i];
      if (f.latitud == null || f.longitud == null) continue;
      filas.add(
        'foto,foto-${(i + 1).toString().padLeft(2, '0')},'
        '${f.latitud},${f.longitud},${f.tomadaEn.toIso8601String()}',
      );
    }

    if (filas.length == 1) {
      return '${filas.first}\n# La visita no tiene coordenadas registradas.\n';
    }
    return '${filas.join('\n')}\n';
  }

  String _coordenadas(Visita v) => v.latitud == null || v.longitud == null
      ? 'sin registrar'
      : '${v.latitud!.toStringAsFixed(6)}, ${v.longitud!.toStringAsFixed(6)}';

  String _si(bool valor) => valor ? 'si' : 'no';

  /// `visita-2026-09-03-1430-don-pedro`. Lleva fecha y productor porque el
  /// visitador va a tener varios de estos en la carpeta de descargas y el UUID
  /// no le dice nada.
  Future<String> _nombreDeVisita(Visita v) async {
    final ctx = await _repo.contextoInforme(v.id);
    final quien = slugArchivo((ctx['productor'] ?? ctx['finca'] ?? '') as String);
    return 'visita-${selloFecha(v.inicio)}${quien.isEmpty ? '' : '-$quien'}';
  }

}
