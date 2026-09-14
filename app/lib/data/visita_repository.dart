import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../core/informe_tecnico.dart';
import 'db/app_database.dart';

/// Un hallazgo tal como lo devuelve el modelo, antes de pasar por las reglas.
/// Es el borde entre el JSON del backend y la base local.
/// Las visitas de un agricultor, para la lista de la pantalla principal.
class GrupoAgricultor {
  GrupoAgricultor({
    required this.nombre,
    required this.visitas,
    this.productorId,
    this.remoteId,
  });

  final String nombre;

  /// Id local. Null en el grupo de las visitas sin ficha.
  final String? productorId;

  /// Record id de Airtable. Es lo que permite pedirle el historial al backend;
  /// sin el, el agricultor solo existe en este telefono y no hay nada que
  /// traer.
  final String? remoteId;

  /// De la mas reciente a la mas vieja.
  final List<Visita> visitas;

  DateTime get ultima => visitas.first.inicio;

  /// Cuantas de estas visitas son espejo de Airtable y no se registraron aqui.
  int get espejadas => visitas.where((v) => v.soloLectura).length;

  int get propias => visitas.length - espejadas;

  bool get sinFicha => productorId == null;
}

/// Lo que dejo una descarga del historial de un agricultor.
///
/// Se devuelve entero en vez de un booleano porque lo que hay que decirle al
/// visitador no es «listo»: es cuantas visitas entraron, cuantas se
/// respetaron por ser suyas y que quedo sin bajar. Un «listo» sobre una
/// descarga que no trajo ninguna foto es una mentira comoda.
class ResultadoEspejo {
  const ResultadoEspejo({
    this.visitas = 0,
    this.propiasRespetadas = 0,
    this.fotos = 0,
    this.audios = 0,
    this.informes = 0,
    this.hallazgosFueraDeCatalogo = 0,
  });

  /// Visitas que quedaron espejadas en el telefono.
  final int visitas;

  /// Visitas que Airtable trajo y NO se tocaron porque son de este telefono.
  /// No es un error: es la regla funcionando.
  final int propiasRespetadas;

  final int fotos;
  final int audios;
  final int informes;

  /// Hallazgos que se descartaron porque su clave no esta en el catalogo de
  /// este telefono. Se cuentan para poder decir que el historial esta
  /// incompleto en vez de mostrarlo como si estuviera entero.
  final int hallazgosFueraDeCatalogo;

  bool get vacio => visitas == 0 && propiasRespetadas == 0;
}

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

/// Deja un texto como se compara en campo: sin tildes, en minusculas y con un
/// solo espacio entre palabras.
///
/// Existe porque el nombre de un agricultor se teclea distinto cada vez —«José
/// Gómez», «jose gomez», «Jose  Gomez»— y sin esto cada forma seria una
/// persona nueva en Airtable, con su propia finca y su propia historia.
///
/// La `ñ` NO se toca: quitarle la tilde a «Muñoz» lo volveria «Munoz», que es
/// otro apellido y ademas frecuente en la misma vereda.
String normalizarBusqueda(String texto) {
  const con = 'áàäâãéèëêíìïîóòöôõúùüûÁÀÄÂÃÉÈËÊÍÌÏÎÓÒÖÔÕÚÙÜÛ';
  const sin = 'aaaaaeeeeiiiiooooouuuuAAAAAEEEEIIIIOOOOOUUUU';

  final limpio = StringBuffer();
  for (final unidad in texto.trim().toLowerCase().runes) {
    final caracter = String.fromCharCode(unidad);
    final i = con.indexOf(caracter);
    limpio.write(i == -1 ? caracter : sin[i]);
  }

  return limpio.toString().replaceAll(RegExp(r'\s+'), ' ');
}

/// Lo que le falta a la ficha del agricultor, en palabras del visitador.
///
/// La lista esta ordenada por lo que cuesta que falte, no por como se ve el
/// formulario:
///
///  1. El documento primero. Es la llave con la que el backend decide si este
///     agricultor ya existe: sin el, el upsert cae al nombre y dos personas
///     que se llaman igual en la misma vereda terminan compartiendo fincas.
///  2. El telefono, que es lo unico que permite volver a llamarlo.
///  3. La foto, que es lo que hace que el visitador de la proxima visita sepa
///     a quien esta buscando en una vereda donde todos son «don Pedro».
///
/// Devuelve vacio cuando la ficha alcanza para trabajar. NO exige el perfil
/// socioeconomico: eso sale de la conversacion y vive en `Hallazgos`. Pedirlo
/// aca convertiria el modulo en la encuesta que este proyecto vino a eliminar.
List<String> faltantesDeAgricultor(Productor? p) {
  if (p == null) return const ['los datos del agricultor'];
  return [
    if ((p.documento ?? '').trim().isEmpty) 'el documento',
    if ((p.telefono ?? '').trim().isEmpty) 'un telefono',
    if ((p.fotoPath ?? '').trim().isEmpty) 'la foto',
  ];
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
  /// [productorLocalId] es el agricultor que el visitador reconocio en el
  /// directorio. Cuando viene, la visita se cuelga de esa ficha en vez de
  /// crear una persona nueva —que es lo que convertia a «Pedro Gomez», «pedro
  /// gomez» y «don Pedro» en tres productores con tres fincas y ninguna
  /// historia— y la visita nace como `Seguimiento`, porque para esa persona
  /// no es la primera. Si el id no existe (la ficha se borro entre que se
  /// eligio y se toco el boton) se cae a crear uno nuevo: quedarse sin poder
  /// registrar la visita seria peor que un duplicado.
  ///
  /// Va en una transaccion para que no quede una visita apuntando a un
  /// productor que no se escribio.
  Future<String> crearVisitaConProductor({
    required DateTime inicio,
    required String nombreProductor,
    String? productorLocalId,
    String? nombreFinca,
    String? veredaLocalId,
    String? visitadorLocalId,
    double? latitud,
    double? longitud,
    double? precisionGps,
  }) {
    return _db.transaction(() async {
      final existente = productorLocalId == null
          ? null
          : await (_db.select(_db.productores)
                ..where((p) => p.id.equals(productorLocalId)))
              .getSingleOrNull();

      final productorId = existente?.id ?? _uuid.v4();
      if (existente == null) {
        await _db.into(_db.productores).insert(
              ProductoresCompanion.insert(
                id: productorId,
                nombreCompleto: nombreProductor,
              ),
            );
      }

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
        tipoVisita: existente == null ? 'Primera visita' : 'Seguimiento',
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

  // ------------------------------------------------------------- el agricultor

  /// El agricultor de esta visita, o null si la visita se creo sin productor.
  Future<Productor?> productorDeVisita(String visitaId) async {
    final v = await (_db.select(_db.visitas)
          ..where((t) => t.id.equals(visitaId)))
        .getSingleOrNull();
    if (v?.productorLocalId == null) return null;
    return (_db.select(_db.productores)
          ..where((p) => p.id.equals(v!.productorLocalId!)))
        .getSingleOrNull();
  }

  Stream<Productor?> observarProductorDeVisita(String visitaId) {
    return (_db.select(_db.visitas)..where((t) => t.id.equals(visitaId)))
        .watchSingleOrNull()
        .asyncExpand((v) {
      if (v?.productorLocalId == null) return Stream<Productor?>.value(null);
      return (_db.select(_db.productores)
            ..where((p) => p.id.equals(v!.productorLocalId!)))
          .watchSingleOrNull();
    });
  }

  // ---------------------------------------------- el directorio de agricultores

  /// Los agricultores que este telefono ya conoce, para completar el nombre.
  ///
  /// Busca en la base local SIEMPRE, tenga o no senal: el directorio remoto se
  /// baja aparte y se guarda aca, asi que en una vereda sin cobertura sigue
  /// habiendo con que reconocer a quien ya se visito. Que devuelva vacio no
  /// significa que el agricultor no exista —significa que este telefono no lo
  /// ha visto— y por eso jamas puede impedir escribir un nombre nuevo.
  ///
  /// Compara sin tildes ni mayusculas y por partes: «gomez» encuentra a «Pedro
  /// Gómez Ruiz», que es como se busca a alguien cuyo apellido se oyo pero
  /// cuyo nombre no. Tambien busca por documento y por codigo, que es lo que
  /// se hace cuando el nombre esta escrito de tres maneras distintas.
  Future<List<Productor>> buscarProductores(
    String texto, {
    int limite = 8,
  }) async {
    final partes = normalizarBusqueda(texto)
        .split(' ')
        .where((t) => t.isNotEmpty)
        .toList();
    if (partes.isEmpty) return const [];

    // Se filtra en Dart y no en SQL porque SQLite no quita tildes: un LIKE
    // sobre «Gómez» no encuentra «gomez», y en campo se teclea sin tildes.
    final todos = await _db.select(_db.productores).get();
    final encontrados = <Productor>[];
    for (final p in todos) {
      final aguja = normalizarBusqueda(
        '${p.nombreCompleto} ${p.documento ?? ''} ${p.codigoProductor ?? ''}',
      );
      if (partes.every(aguja.contains)) encontrados.add(p);
    }
    encontrados.sort((a, b) => normalizarBusqueda(a.nombreCompleto)
        .compareTo(normalizarBusqueda(b.nombreCompleto)));

    return encontrados.take(limite).toList();
  }

  /// Cuantos agricultores hay en el espejo local. La pantalla lo dice en voz
  /// alta: «12 agricultores en este telefono» explica por que el que se busca
  /// puede no aparecer, y un cero explica por que no aparece ninguno.
  Future<int> cuantosProductoresConocidos() async {
    final conteo = _db.productores.id.count();
    final fila =
        await (_db.selectOnly(_db.productores)..addColumns([conteo]))
            .getSingle();
    return fila.read(conteo) ?? 0;
  }

  /// Mete en la base local el directorio que devolvio el backend.
  ///
  /// Reconoce a la misma persona con las mismas llaves que usa el backend y en
  /// el mismo orden: record id, documento y por ultimo el nombre. Si se
  /// invirtiera, dos homonimos de la misma vereda terminarian fundidos en una
  /// sola ficha —con las fincas de ambos— que es justamente lo que el
  /// documento existe para impedir.
  ///
  /// Regla de escritura: **rellena, no pisa**. Lo que el telefono ya tiene se
  /// respeta, porque puede ser lo que el visitador acaba de teclear en la
  /// finca y todavia no sube; lo de Airtable solo entra donde hay un hueco.
  /// Las excepciones son las llaves de identidad (`remoteId`,
  /// `codigoProductor`) y el nombre canonico cuando la persona se reconocio
  /// por una llave fuerte: ahi manda Airtable, que es de donde salio.
  ///
  /// Devuelve cuantas fichas quedaron tocadas (nuevas mas actualizadas).
  Future<int> refrescarDirectorioProductores(
    List<Map<String, dynamic>> remotos,
  ) async {
    if (remotos.isEmpty) return 0;

    var tocados = 0;

    await _db.transaction(() async {
      final locales = await _db.select(_db.productores).get();

      for (final r in remotos) {
        final remoteId = _texto(r['id']);
        final nombre = _texto(r['nombre_completo']);
        if (remoteId == null || nombre == null) continue;

        final documento = _texto(r['documento']);
        final codigo = _texto(r['codigo_productor']);

        var llaveFuerte = true;
        Productor? local = _primero(locales, (p) => p.remoteId == remoteId);
        if (local == null && documento != null) {
          local = _primero(
            locales,
            (p) =>
                _texto(p.documento) == documento &&
                (p.remoteId == null || p.remoteId == remoteId),
          );
        }
        if (local == null) {
          // El nombre es la ultima opcion y solo sobre fichas que todavia no
          // estan atadas a nadie en Airtable: robarle la fila a otra persona
          // seria peor que crear una de mas.
          llaveFuerte = false;
          local = _primero(
            locales,
            (p) =>
                p.remoteId == null &&
                normalizarBusqueda(p.nombreCompleto) ==
                    normalizarBusqueda(nombre),
          );
        }

        final fecha = _fecha(r['fecha_nacimiento']);
        final campos = ProductoresCompanion(
          remoteId: Value(remoteId),
          sincronizado: const Value(true),
          codigoProductor:
              codigo == null ? const Value.absent() : Value(codigo),
          nombreCompleto: llaveFuerte ? Value(nombre) : const Value.absent(),
          documento: _rellenar(local?.documento, documento),
          tipoDocumento:
              _rellenar(local?.tipoDocumento, _texto(r['tipo_documento'])),
          telefono: _rellenar(local?.telefono, _texto(r['telefono'])),
          telefonoAlterno: _rellenar(
            local?.telefonoAlterno,
            _texto(r['telefono_alterno']),
          ),
          genero: _rellenar(local?.genero, _texto(r['genero'])),
          fechaNacimiento: local?.fechaNacimiento != null || fecha == null
              ? const Value.absent()
              : Value(fecha),
          nivelEducativo:
              _rellenar(local?.nivelEducativo, _texto(r['nivel_educativo'])),
          aniosExperiencia: local?.aniosExperiencia != null
              ? const Value.absent()
              : Value(_entero(r['anios_experiencia'])),
          personasHogar: local?.personasHogar != null
              ? const Value.absent()
              : Value(_entero(r['personas_hogar'])),
          organizacion:
              _rellenar(local?.organizacion, _texto(r['organizacion'])),
          // La miniatura se refresca siempre: Airtable rota esas URL cada
          // pocas horas y conservar la vieja seria conservar un enlace roto.
          fotoRemota: Value(_texto(r['foto_url'])),
          // La autorizacion solo se prende. Que este telefono no sepa que la
          // dio no puede borrarla: el permiso se dio delante de alguien y eso
          // ya paso.
          consentimientoDatos: r['consentimiento_datos'] == true
              ? const Value(true)
              : const Value.absent(),
        );

        if (local == null) {
          await _db.into(_db.productores).insert(
                ProductoresCompanion.insert(
                  id: _uuid.v4(),
                  nombreCompleto: nombre,
                ).copyWith(
                  remoteId: campos.remoteId,
                  sincronizado: campos.sincronizado,
                  codigoProductor: campos.codigoProductor,
                  documento: campos.documento,
                  tipoDocumento: campos.tipoDocumento,
                  telefono: campos.telefono,
                  telefonoAlterno: campos.telefonoAlterno,
                  genero: campos.genero,
                  fechaNacimiento: campos.fechaNacimiento,
                  nivelEducativo: campos.nivelEducativo,
                  aniosExperiencia: campos.aniosExperiencia,
                  personasHogar: campos.personasHogar,
                  organizacion: campos.organizacion,
                  fotoRemota: campos.fotoRemota,
                  consentimientoDatos: campos.consentimientoDatos,
                ),
              );
        } else {
          final id = local.id;
          await (_db.update(_db.productores)..where((p) => p.id.equals(id)))
              .write(campos);
        }
        tocados++;
      }
    });

    return tocados;
  }

  /// El primero que cumple, o null. Generico porque lo usan el directorio de
  /// productores y el espejo del historial, que ademas busca veredas y fincas.
  static T? _primero<T>(List<T> lista, bool Function(T) prueba) {
    for (final elemento in lista) {
      if (prueba(elemento)) return elemento;
    }
    return null;
  }

  static double? _decimal(Object? v) {
    if (v is num) return v.toDouble();
    final t = _texto(v);
    return t == null ? null : double.tryParse(t);
  }

  /// Los enums viajan como el nombre EXACTO de la opcion de Airtable. Si
  /// llegara uno que este telefono no conoce —porque alguien renombro la
  /// opcion o porque la app esta atrasada— cae al valor mas prudente en vez de
  /// tumbar la importacion: perder un select no vale perder el historial.
  static Certeza _certeza(String? valor) => Certeza.values.firstWhere(
        (c) => c.airtable == valor,
        orElse: () => Certeza.pendiente,
      );

  static FuenteHallazgo _fuente(String? valor) =>
      FuenteHallazgo.values.firstWhere(
        (f) => f.airtable == valor,
        orElse: () => FuenteHallazgo.audio,
      );

  static EstadoHallazgo _estadoHallazgo(String? valor) =>
      EstadoHallazgo.values.firstWhere(
        (e) => e.airtable == valor,
        orElse: () => EstadoHallazgo.propuestoPorIa,
      );

  /// Solo escribe si el telefono no tenia nada. Lo que el visitador tecleo en
  /// la finca vale mas que lo que Airtable sabia antes de esa visita.
  static Value<String?> _rellenar(String? local, String? remoto) {
    if (_texto(local) != null) return const Value.absent();
    if (remoto == null) return const Value.absent();
    return Value(remoto);
  }

  static String? _texto(Object? v) {
    if (v == null) return null;
    final t = v.toString().trim();
    return t.isEmpty ? null : t;
  }

  static int? _entero(Object? v) => v is num ? v.toInt() : null;

  static DateTime? _fecha(Object? v) {
    final t = _texto(v);
    return t == null ? null : DateTime.tryParse(t);
  }

  /// Guarda la ficha del agricultor y vuelve a encolar la visita.
  ///
  /// Se encola aca y no lo deja a cargo de la pantalla porque el productor no
  /// sube por su propia cuenta: viaja dentro del payload de la visita. Sin
  /// este encolado, el visitador llena la ficha, ve el nombre completo en el
  /// telefono y en Airtable sigue estando «Rumil» a secas.
  ///
  /// El upsert de la cola se reemplaza por id (`upsert-<visita>`), asi que
  /// guardar cinco veces deja un item, no cinco.
  Future<void> guardarDatosAgricultor({
    required String visitaId,
    String? nombreCompleto,
    String? documento,
    String? tipoDocumento,
    String? telefono,
    String? telefonoAlterno,
    String? genero,
    DateTime? fechaNacimiento,
    String? nivelEducativo,
    int? aniosExperiencia,
    int? personasHogar,
    String? organizacion,
    String? notas,
  }) async {
    final productor = await productorDeVisita(visitaId);
    if (productor == null) {
      throw StateError('La visita $visitaId no tiene productor.');
    }

    final visita = await (_db.select(_db.visitas)
          ..where((t) => t.id.equals(visitaId)))
        .getSingle();

    String? limpio(String? v) {
      final t = v?.trim();
      return t == null || t.isEmpty ? null : t;
    }

    await (_db.update(_db.productores)
          ..where((p) => p.id.equals(productor.id)))
        .write(
      ProductoresCompanion(
        // El nombre solo se sobreescribe si vino con algo: la visita nacio con
        // el nombre y borrarlo dejaria un agricultor sin como llamarlo.
        nombreCompleto: limpio(nombreCompleto) == null
            ? const Value.absent()
            : Value(limpio(nombreCompleto)!),
        documento: Value(limpio(documento)),
        tipoDocumento: Value(limpio(tipoDocumento)),
        telefono: Value(limpio(telefono)),
        telefonoAlterno: Value(limpio(telefonoAlterno)),
        genero: Value(limpio(genero)),
        fechaNacimiento: Value(fechaNacimiento),
        nivelEducativo: Value(limpio(nivelEducativo)),
        aniosExperiencia: Value(aniosExperiencia),
        personasHogar: Value(personasHogar),
        organizacion: Value(limpio(organizacion)),
        notas: Value(limpio(notas)),
        // La autorizacion de tratamiento se copia de la visita en la que se
        // pidio, con su fecha. No se puede apagar desde aca: si en una visita
        // anterior el productor autorizo, esa autorizacion existio.
        consentimientoDatos: visita.consienteUsoDatos
            ? const Value(true)
            : const Value.absent(),
        fechaConsentimiento:
            visita.consienteUsoDatos && productor.fechaConsentimiento == null
                ? Value(visita.inicio)
                : const Value.absent(),
        datosCompletadosEn: Value(DateTime.now()),
        sincronizado: const Value(false),
      ),
    );

    await encolarVisita(visitaId);
  }

  /// Registra la foto de perfil del agricultor y la encola.
  ///
  /// Prioridad 220: despues de las fotos de la conversacion (200) y antes del
  /// informe. Una etiqueta de insumo mal leida cuesta un diagnostico; el
  /// retrato se vuelve a tomar en la proxima visita.
  ///
  /// La anterior se borra del telefono: la foto de perfil es una, y dejar la
  /// vieja en disco solo ocupa un espacio que en el piloto se llena con audio.
  Future<void> registrarFotoAgricultor({
    required String visitaId,
    required String archivoPath,
  }) async {
    final productor = await productorDeVisita(visitaId);
    if (productor == null) {
      throw StateError('La visita $visitaId no tiene productor.');
    }

    final bytes = await File(archivoPath).length();
    final anterior = productor.fotoPath;

    await (_db.update(_db.productores)
          ..where((p) => p.id.equals(productor.id)))
        .write(
      ProductoresCompanion(
        fotoPath: Value(archivoPath),
        // El enlace viejo apunta a la foto vieja: dejarlo haria que Airtable
        // se siguiera trayendo el retrato que se acaba de reemplazar.
        enlaceFoto: const Value(null),
        sincronizado: const Value(false),
      ),
    );

    await _db.encolar(
      id: 'foto-agricultor-${productor.id}',
      entidad: 'productor',
      entidadId: visitaId,
      operacion: 'upload_foto_agricultor',
      archivoPath: archivoPath,
      bytesTotales: bytes,
      prioridad: 220,
    );

    if (anterior != null && anterior != archivoPath) {
      try {
        final vieja = File(anterior);
        if (await vieja.exists()) await vieja.delete();
      } catch (_) {
        // Una foto que no se puede borrar no puede impedir guardar la nueva.
      }
    }
  }

  Future<void> registrarEnlaceFotoAgricultor(String archivoPath, String url) =>
      (_db.update(_db.productores)
            ..where((p) => p.fotoPath.equals(archivoPath)))
          .write(ProductoresCompanion(enlaceFoto: Value(url)));

  /// Carpeta de la foto de perfil, dentro de la visita donde se toma.
  Future<Directory> carpetaPerfil(String visitaId) async {
    final dir = Directory(
      p.join((await _carpetaDeVisita(visitaId)).path, 'perfil'),
    );
    await dir.create(recursive: true);
    return dir;
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

  /// Todo lo que hace falta para armar el informe del agricultor.
  ///
  /// Los hallazgos se cruzan con el catalogo para que el modelo reciba el
  /// nombre legible del campo y su modulo, no la clave tecnica: el informe lo
  /// lee el productor, no un desarrollador.
  Future<Map<String, dynamic>> contextoInforme(String visitaId) async {
    final v = await (_db.select(_db.visitas)..where((x) => x.id.equals(visitaId)))
        .getSingle();

    final visitador = v.visitadorLocalId == null
        ? null
        : await (_db.select(_db.visitadores)
              ..where((x) => x.id.equals(v.visitadorLocalId!)))
            .getSingleOrNull();
    final productor = v.productorLocalId == null
        ? null
        : await (_db.select(_db.productores)
              ..where((x) => x.id.equals(v.productorLocalId!)))
            .getSingleOrNull();
    final finca = v.fincaLocalId == null
        ? null
        : await (_db.select(_db.fincas)
              ..where((x) => x.id.equals(v.fincaLocalId!)))
            .getSingleOrNull();
    final vereda = v.veredaLocalId == null
        ? null
        : await (_db.select(_db.veredas)
              ..where((x) => x.id.equals(v.veredaLocalId!)))
            .getSingleOrNull();

    final catalogo = {
      for (final c in await _db.select(_db.catalogoCampos).get())
        c.claveTecnica: c,
    };
    final hallazgos = await (_db.select(_db.hallazgos)
          ..where((h) => h.visitaId.equals(visitaId)))
        .get();

    final transcripcion = await transcripcionCompleta(visitaId);

    return {
      'codigo_visita': v.id,
      'fecha': v.inicio.toIso8601String(),
      if (productor != null) 'productor': productor.nombreCompleto,
      if (finca != null) 'finca': finca.nombre,
      if (vereda != null) 'vereda': vereda.vereda,
      if (vereda != null) 'municipio': vereda.municipio,
      if (visitador != null) 'visitador': visitador.nombre,
      if (transcripcion.isNotEmpty) 'transcripcion': transcripcion,
      if (v.temasPendientes != null) 'temas_pendientes': v.temasPendientes,
      'completitud_pct': v.completitudPct,
      'hallazgos': [
        for (final h in hallazgos)
          {
            'campo': catalogo[h.claveTecnica]?.campo ?? h.claveTecnica,
            'clave_tecnica': h.claveTecnica,
            'valor': h.valorTexto ?? '${h.valorNumerico ?? ''}',
            if (h.unidad != null) 'unidad': h.unidad,
            // `.airtable` y no el enum: esto se serializa a JSON.
            'certeza': h.certeza.airtable,
            if (catalogo[h.claveTecnica] != null)
              'modulo': catalogo[h.claveTecnica]!.modulo,
          },
      ],
    };
  }

  /// Guarda el informe generado y lo encola. La version sube en cada
  /// regeneracion y el anterior NO se borra: si el visitador regenera y el
  /// nuevo sale peor, el que ya le mostro al productor sigue existiendo.
  Future<Informe> guardarInforme({
    required String visitaId,
    required String titulo,
    required String contenido,
    required String tipo,
    String? modelo,
  }) async {
    final id = _uuid.v4();
    await _db.into(_db.informes).insert(
          InformesCompanion.insert(
            id: id,
            visitaId: visitaId,
            titulo: titulo,
            tipo: Value(tipo),
            contenido: contenido,
            version: Value(await proximaVersion(visitaId, tipo)),
            generadoEn: DateTime.now(),
            modelo: Value(modelo),
          ),
        );
    // Prioridad alta pero por debajo del audio: el informe se puede volver a
    // generar, la grabacion no.
    await encolarVisita(visitaId);
    // Por id y no `informesDeVisita().first`: esa lista viene ordenada por
    // version descendente, y desde que una visita puede tener informes de dos
    // tipos —el del productor y el tecnico— la version mas alta no es
    // necesariamente el que se acaba de guardar.
    return (_db.select(_db.informes)..where((i) => i.id.equals(id)))
        .getSingle();
  }

  /// Que version le toca al proximo informe de este TIPO.
  ///
  /// Por tipo y no por visita: el informe del productor y el tecnico son dos
  /// series distintas. Contando todo junto, el primer tecnico de una visita
  /// que ya tenia un informe entregado saldria como «version 2» de algo que
  /// nunca tuvo version 1, y en el bucket se llamaria con el numero de otro
  /// documento.
  Future<int> proximaVersion(String visitaId, String tipo) async {
    final previos = await (_db.select(_db.informes)
          ..where((i) => i.visitaId.equals(visitaId) & i.tipo.equals(tipo)))
        .get();
    return previos.length + 1;
  }

  /// Guarda el PDF en disco y lo encola para el bucket.
  ///
  /// El PDF se guarda aunque el markdown ya este en Airtable: regenerarlo
  /// meses despues con otra version del renderizador daria otro papel, y el
  /// documento que respalda lo acordado en la finca es el que el productor
  /// tiene en la mano.
  ///
  /// El nombre lleva la version porque las versiones no se borran: sin eso, el
  /// informe regenerado sobreescribiria en el bucket el que ya se entrego.
  ///
  /// Idempotente: si ya se habia guardado, reescribe el mismo archivo y
  /// `encolar` reemplaza el item por id en vez de duplicarlo.
  Future<String> guardarPdfInforme(String informeId, List<int> bytes) async {
    final informe = await (_db.select(_db.informes)
          ..where((i) => i.id.equals(informeId)))
        .getSingle();

    final carpeta = Directory(
      p.join((await _carpetaDeVisita(informe.visitaId)).path, 'informes'),
    );
    await carpeta.create(recursive: true);

    // El tipo va en el nombre. Sin eso, el tecnico y el del productor —dos
    // documentos distintos de la misma visita, cada uno con su propia serie de
    // versiones— se llamarian igual y el segundo pisaria al primero, tanto en
    // la carpeta del telefono como en el bucket.
    final ruta = p.join(
      carpeta.path,
      '${_prefijoPdf(informe.tipo)}-'
      '${informe.version.toString().padLeft(2, '0')}.pdf',
    );
    await File(ruta).writeAsBytes(bytes, flush: true);

    await (_db.update(_db.informes)..where((i) => i.id.equals(informeId)))
        .write(InformesCompanion(pdfPath: Value(ruta)));

    // Prioridad 300: detras del audio (0) y de las fotos (200). El audio es
    // irrecuperable y las fotos casi; el PDF se puede volver a armar desde el
    // markdown mientras el telefono viva, asi que es lo ultimo que merece la
    // ventana de red de una vereda.
    //
    // Id derivado del informe y no un UUID nuevo: entregar dos veces el mismo
    // informe actualiza el item en vez de encolar dos subidas del mismo byte.
    await _db.encolar(
      id: 'informe-pdf-$informeId',
      entidad: 'informe',
      entidadId: informe.visitaId,
      operacion: 'upload_informe',
      archivoPath: ruta,
      bytesTotales: bytes.length,
      prioridad: 300,
    );
    return ruta;
  }

  /// La version del informe, que es el `orden` con el que se nombra en el
  /// bucket. Se consulta por la ruta porque es lo unico que lleva el item de
  /// la cola, igual que el audio y las fotos.
  Future<int?> versionDeInformePorPdf(String pdfPath) async {
    final informe = await (_db.select(_db.informes)
          ..where((i) => i.pdfPath.equals(pdfPath)))
        .getSingleOrNull();
    return informe?.version;
  }

  /// La carpeta del bucket donde va este PDF.
  ///
  /// El backend renombra por categoria (`informes/informe-01.pdf`), asi que la
  /// categoria es lo que evita que el tecnico y el del productor compartan
  /// ruta. Se consulta por el pdfPath por la misma razon que la version: es lo
  /// unico que lleva el item de la cola.
  Future<String> categoriaDeInformePorPdf(String pdfPath) async {
    final informe = await (_db.select(_db.informes)
          ..where((i) => i.pdfPath.equals(pdfPath)))
        .getSingleOrNull();
    return informe?.tipo == tipoInformeTecnico
        ? 'informes_tecnicos'
        : 'informes';
  }

  /// `informe` para el del productor, `informe-tecnico` para el de la empresa.
  /// Coincide con el prefijo que usa el backend al renombrar en el bucket, a
  /// proposito: el archivo se llama igual en el telefono y en la nube.
  String _prefijoPdf(String tipo) =>
      tipo == tipoInformeTecnico ? 'informe-tecnico' : 'informe';

  Future<void> registrarEnlaceInforme(String pdfPath, String url) =>
      (_db.update(_db.informes)..where((i) => i.pdfPath.equals(pdfPath)))
          .write(InformesCompanion(enlacePdf: Value(url)));

  /// Los informes de una visita, el mas nuevo primero.
  Future<List<Informe>> informesDeVisita(String visitaId) =>
      (_db.select(_db.informes)
            ..where((i) => i.visitaId.equals(visitaId))
            ..orderBy([
              (i) => OrderingTerm(expression: i.version, mode: OrderingMode.desc),
            ]))
          .get();

  Stream<List<Informe>> observarInformes(String visitaId) =>
      (_db.select(_db.informes)
            ..where((i) => i.visitaId.equals(visitaId))
            ..orderBy([
              (i) => OrderingTerm(expression: i.version, mode: OrderingMode.desc),
            ]))
          .watch();

  /// Lo que el PDF necesita y no esta en el informe: la ficha de la visita y
  /// las rutas de las fotos en disco.
  Future<Map<String, dynamic>> contextoPdf(String visitaId) async {
    final ctx = await contextoInforme(visitaId);
    final fotos = await evidenciasDeVisita(visitaId);
    return {
      ...ctx,
      'fotos': [for (final f in fotos) f.archivoPath],
    };
  }

  /// Todo lo que lleva el informe tecnico, leido de la base.
  ///
  /// No pasa por el backend ni por el modelo: se arma en el telefono con lo
  /// que ya esta guardado, y por eso funciona sin senal en la finca. Es
  /// tambien la razon por la que las coordenadas de ese documento se pueden
  /// auditar — ningun numero paso por un modelo de lenguaje.
  ///
  /// Sin [version], trae la que le TOCARIA al proximo informe tecnico de esta
  /// visita: se calcula antes de guardarlo porque el documento la imprime en
  /// el membrete, y `guardarInforme` le va a asignar la misma. Se pasa
  /// explicita cuando se rearma el PDF de un informe que ya existe, para que
  /// el papel no diga una version que no es la suya.
  Future<DatosInformeTecnico> datosInformeTecnico(
    String visitaId, {
    int? version,
  }) async {
    final v = await (_db.select(_db.visitas)..where((x) => x.id.equals(visitaId)))
        .getSingle();

    final visitador = v.visitadorLocalId == null
        ? null
        : await (_db.select(_db.visitadores)
              ..where((x) => x.id.equals(v.visitadorLocalId!)))
            .getSingleOrNull();
    final productor = v.productorLocalId == null
        ? null
        : await (_db.select(_db.productores)
              ..where((x) => x.id.equals(v.productorLocalId!)))
            .getSingleOrNull();
    final finca = v.fincaLocalId == null
        ? null
        : await (_db.select(_db.fincas)
              ..where((x) => x.id.equals(v.fincaLocalId!)))
            .getSingleOrNull();
    final vereda = v.veredaLocalId == null
        ? null
        : await (_db.select(_db.veredas)
              ..where((x) => x.id.equals(v.veredaLocalId!)))
            .getSingleOrNull();

    // El catalogo da el nombre legible del campo y su modulo. Sin el, la tabla
    // de datos del informe mostraria `area_total_ha` en vez de «Área total»:
    // una clave tecnica en un documento institucional obliga a quien lo lee a
    // conocer el esquema de la base.
    final catalogo = {
      for (final c in await _db.select(_db.catalogoCampos).get())
        c.claveTecnica: c,
    };

    final hallazgos = await (_db.select(_db.hallazgos)
          ..where((h) => h.visitaId.equals(visitaId))
          ..orderBy([(h) => OrderingTerm(expression: h.creadoEn)]))
        .get();

    final trazados = await (_db.select(_db.trazados)
          ..where((t) => t.visitaId.equals(visitaId))
          ..orderBy([(t) => OrderingTerm(expression: t.creadoEn)]))
        .get();

    final trazadosTecnicos = <TrazadoTecnico>[];
    for (final t in trazados) {
      final puntos = await (_db.select(_db.puntosTrazado)
            ..where((x) => x.trazadoId.equals(t.id))
            ..orderBy([(x) => OrderingTerm(expression: x.orden)]))
          .get();
      trazadosTecnicos.add(
        TrazadoTecnico(
          nombre: t.nombre,
          tipo: t.tipo.airtable,
          modoCaptura: t.modoCaptura.airtable,
          cerrado: t.cerrado,
          etiqueta: t.etiqueta,
          notas: t.notas,
          areaM2: t.areaM2,
          perimetroM: t.perimetroM,
          puntos: [
            for (final p in puntos)
              PuntoTecnico(
                orden: p.orden,
                latitud: p.latitud,
                longitud: p.longitud,
                capturadoEn: p.capturadoEn,
                altitud: p.altitud,
                precisionM: p.precisionM,
                automatico: p.automatico,
                nota: p.nota,
              ),
          ],
        ),
      );
    }

    final grabaciones = await grabacionesDeVisita(visitaId);
    final evidencias = await evidenciasDeVisita(visitaId);

    // El modelo que se registro en la visita. Sale del ultimo informe que se
    // genero con IA —el del productor— porque es el unico lugar donde queda
    // guardado. Los hallazgos no llevan columna de modelo.
    final informes = await informesDeVisita(visitaId);
    final modelo = informes
        .where((i) => i.tipo != tipoInformeTecnico && i.modelo != null)
        .firstOrNull
        ?.modelo;

    return DatosInformeTecnico(
      codigoVisita: v.id,
      inicio: v.inicio,
      fin: v.fin,
      generadoEn: DateTime.now(),
      version: version ?? await proximaVersion(visitaId, tipoInformeTecnico),
      estado: v.estado,
      tipoVisita: v.tipoVisita,
      completitudPct: v.completitudPct,
      visitador: visitador?.nombre,
      productor: productor == null
          ? null
          : ProductorTecnico(
              nombre: productor.nombreCompleto,
              documento: productor.documento,
              tipoDocumento: productor.tipoDocumento,
              telefono: productor.telefono,
              organizacion: productor.organizacion,
              codigoProductor: productor.codigoProductor,
              consentimientoDatos: productor.consentimientoDatos,
              fechaConsentimiento: productor.fechaConsentimiento,
            ),
      finca: finca == null
          ? null
          : FincaTecnica(
              nombre: finca.nombre,
              latitud: finca.latitud,
              longitud: finca.longitud,
              areaDeclaradaHa: finca.areaTotalHa,
            ),
      vereda: vereda?.vereda,
      municipio: vereda?.municipio,
      latitud: v.latitud,
      longitud: v.longitud,
      precisionGps: v.precisionGps,
      objetivo: v.objetivo,
      observaciones: v.observaciones,
      temasPendientes: v.temasPendientes,
      trazados: trazadosTecnicos,
      hallazgos: [
        for (final h in hallazgos)
          HallazgoTecnico(
            modulo: catalogo[h.claveTecnica]?.modulo ?? 'Sin módulo',
            campo: catalogo[h.claveTecnica]?.campo ?? h.claveTecnica,
            claveTecnica: h.claveTecnica,
            valor: h.valorTexto ?? _numero(h.valorNumerico),
            unidad: h.unidad,
            certeza: h.certeza.airtable,
            fuente: h.fuente.airtable,
            estado: h.estado.airtable,
            confianza: h.confianza,
            segundoAudio: h.segundoAudio,
            citaTextual: h.citaTextual,
            razonamiento: h.razonamiento,
            valorCorregido: h.valorCorregido,
            entidad: h.entidadLocalId,
          ),
      ],
      evidencias: [
        for (final e in evidencias)
          EvidenciaTecnica(
            archivoPath: e.archivoPath,
            tomadaEn: e.tomadaEn,
            tipo: e.tipo,
            latitud: e.latitud,
            longitud: e.longitud,
            segundoAudio: e.segundoAudio,
            // La del visitador manda sobre la que escribio la IA: si el
            // visitador escribio que es, eso es lo que la foto muestra.
            descripcion: e.descripcionVisitador ?? e.descripcionIa,
            textoOcr: e.textoOcr,
            estadoValidacion: e.estadoValidacion,
          ),
      ],
      grabaciones: [
        for (final g in grabaciones)
          GrabacionTecnica(
            orden: g.orden,
            inicio: g.inicio,
            duracionSeg: g.duracionSeg,
            tamanoBytes: g.tamanoBytes,
            motor: g.motorTranscripcion,
            estado: g.estado,
            transcrita: (g.transcripcion ?? '').isNotEmpty,
          ),
      ],
      consentimiento: ConsentimientoTecnico(
        audio: v.consienteAudio,
        fotos: v.consienteFotos,
        usoDatos: v.consienteUsoDatos,
        segundoConsentimiento: v.segundoConsentimiento,
        marcadaParaEliminacion: v.marcadaParaEliminacion,
      ),
      sincronizada: v.sincronizada,
      modeloIa: modelo,
    );
  }

  /// El valor numerico sin el `.0` de los enteros: «3 pozos», no «3.0 pozos».
  String _numero(double? valor) {
    if (valor == null) return '';
    return valor == valor.roundToDouble()
        ? valor.toInt().toString()
        : valor.toString();
  }

  /// Las visitas agrupadas por agricultor, la persona mas reciente primero.
  ///
  /// La lista plana por fecha servia cuando cada visita era un evento suelto.
  /// Desde que el telefono puede tener el historial de una finca —varias
  /// visitas de la misma persona, algunas de otro visitador— lo que se busca
  /// ya no es «que hice el martes» sino «que sabemos de don Pedro».
  ///
  /// Las visitas sin agricultor no se esconden: van juntas al final, bajo su
  /// propio encabezado. Una visita sin ficha es un pendiente, y esconderlo
  /// seria taparlo.
  Stream<List<GrupoAgricultor>> observarVisitasPorAgricultor() {
    final consulta = _db.select(_db.visitas).join([
      leftOuterJoin(
        _db.productores,
        _db.productores.id.equalsExp(_db.visitas.productorLocalId),
      ),
    ])
      ..orderBy([
        OrderingTerm(expression: _db.visitas.inicio, mode: OrderingMode.desc),
      ]);

    return consulta.watch().map((filas) {
      final grupos = <String, GrupoAgricultor>{};

      for (final fila in filas) {
        final visita = fila.readTable(_db.visitas);
        final productor = fila.readTableOrNull(_db.productores);
        // Sin ficha, todas juntas bajo una sola llave: si se agrupara por id
        // de visita, cada una seria su propio encabezado y la pantalla
        // quedaria peor que la lista plana.
        final llave = productor?.id ?? '';

        final grupo = grupos.putIfAbsent(
          llave,
          () => GrupoAgricultor(
            productorId: productor?.id,
            nombre: productor?.nombreCompleto ?? 'Sin agricultor',
            remoteId: productor?.remoteId,
            visitas: [],
          ),
        );
        grupo.visitas.add(visita);
      }

      // Las filas ya vienen ordenadas por fecha, asi que la primera visita de
      // cada grupo es la mas reciente y sirve para ordenar los grupos.
      final lista = grupos.values.toList()
        ..sort((a, b) => b.ultima.compareTo(a.ultima));
      return lista;
    });
  }

  // ------------------------------------------- el espejo del historial

  /// Mete en la base local el historial que devolvio el backend.
  ///
  /// Las visitas entran marcadas `soloLectura`: se consultan y nada mas. No es
  /// una limitacion pendiente de levantar, es la garantia de la funcion — con
  /// ella es IMPOSIBLE que traer el historial de un agricultor pise una visita
  /// que el visitador todavia no ha subido. En una vereda sin senal ese
  /// trabajo no tiene de donde rescatarse.
  ///
  /// La regla que lo sostiene esta en una sola linea de abajo: una visita que
  /// ya existe en el telefono y NO es un espejo se salta entera. Da igual lo
  /// que traiga Airtable; en ese caso el telefono es la fuente de verdad,
  /// porque es donde se registro.
  ///
  /// [bajar] trae los bytes de una URL. Se recibe como funcion en vez de
  /// llamar al backend desde aqui para que el repositorio siga sin saber de
  /// red: quien orquesta es `HistorialController`.
  Future<ResultadoEspejo> importarHistorial(
    Map<String, dynamic> historial, {
    Future<List<int>?> Function(String url)? bajar,
    void Function(String)? onPaso,
  }) async {
    final visitas = (historial['visitas'] as List?) ?? const [];
    if (visitas.isEmpty) return const ResultadoEspejo();

    final nombreProductor = _texto(historial['productor']);
    var espejadas = 0;
    var propias = 0;
    var fotos = 0;
    var audios = 0;
    var informes = 0;
    var hallazgosFuera = 0;

    // El catalogo decide que hallazgos pueden entrar: `Hallazgos.claveTecnica`
    // es una clave foranea, y una clave que este telefono no conoce —porque su
    // catalogo es mas viejo— reventaria la insercion entera.
    final catalogo = {
      for (final c in await _db.select(_db.catalogoCampos).get()) c.claveTecnica,
    };

    for (final cruda in visitas) {
      final v = (cruda as Map).cast<String, dynamic>();
      final codigo = _texto(v['codigo_visita']);
      if (codigo == null) continue;

      final local = await (_db.select(_db.visitas)
            ..where((x) => x.id.equals(codigo)))
          .getSingleOrNull();

      if (local != null && !local.soloLectura) {
        // La visita es de este telefono. No se toca ni para "completarla":
        // lo que esta aca es lo que se registro en la finca.
        propias++;
        continue;
      }

      onPaso?.call(
        'Trayendo la visita de ${_texto(v['finca']) ?? nombreProductor ?? 'la finca'}...',
      );

      final productorId = await _productorEspejo(nombreProductor);
      final veredaId = await _veredaEspejo(_texto(v['vereda']));
      final fincaId = await _fincaEspejo(
        _texto(v['finca']),
        productorId,
        veredaId,
      );

      await _db.transaction(() async {
        final fila = VisitasCompanion(
          id: Value(codigo),
          inicio: Value(_fecha(v['inicio']) ?? DateTime.now()),
          fin: Value(_fecha(v['fin'])),
          productorLocalId: Value(productorId),
          fincaLocalId: Value(fincaId),
          veredaLocalId: Value(veredaId),
          tipoVisita: Value(_texto(v['tipo_visita'])),
          estado: Value(_texto(v['estado']) ?? 'Cerrada'),
          latitud: Value(_decimal(v['latitud'])),
          longitud: Value(_decimal(v['longitud'])),
          consienteAudio: Value(v['consiente_audio'] == true),
          consienteFotos: Value(v['consiente_fotos'] == true),
          consienteUsoDatos: Value(v['consiente_uso_datos'] == true),
          segundoConsentimiento: Value(_entero(v['segundo_consentimiento'])),
          marcadaParaEliminacion: Value(v['marcada_para_eliminacion'] == true),
          objetivo: Value(_texto(v['objetivo'])),
          observaciones: Value(_texto(v['observaciones'])),
          resumen: Value(_texto(v['resumen'])),
          temasPendientes: Value(_texto(v['temas_pendientes'])),
          completitudPct: Value(_entero(v['completitud_pct']) ?? 0),
          // Viene de Airtable: ya esta sincronizada por definicion. Marcarla
          // asi tambien la mantiene fuera de cualquier barrido de pendientes.
          sincronizada: const Value(true),
          soloLectura: const Value(true),
          descargadaEn: Value(DateTime.now()),
        );

        if (local == null) {
          await _db.into(_db.visitas).insert(fila);
        } else {
          // Ya era un espejo: se reemplaza con lo que dice Airtable hoy, que
          // es la fuente de verdad de una visita que no es de este telefono.
          await (_db.update(_db.visitas)..where((x) => x.id.equals(codigo)))
              .write(fila);
          await _borrarHijosDe(codigo);
        }

        for (final cruda in (v['hallazgos'] as List?) ?? const []) {
          final h = (cruda as Map).cast<String, dynamic>();
          final clave = _texto(h['clave_tecnica']);
          if (clave == null || !catalogo.contains(clave)) {
            // Un campo que este telefono no tiene en su catalogo. Se cuenta y
            // se dice, en vez de tumbar el historial entero por un hallazgo.
            hallazgosFuera++;
            continue;
          }
          await _db.into(_db.hallazgos).insert(
                HallazgosCompanion.insert(
                  id: _uuid.v4(),
                  visitaId: codigo,
                  claveTecnica: clave,
                  valorTexto: Value(_texto(h['valor_texto'])),
                  valorNumerico: Value(_decimal(h['valor_numerico'])),
                  unidad: Value(_texto(h['unidad'])),
                  certeza: Value(_certeza(_texto(h['certeza']))),
                  fuente: Value(_fuente(_texto(h['fuente']))),
                  estado: Value(_estadoHallazgo(_texto(h['estado']))),
                  citaTextual: Value(_texto(h['cita_textual'])),
                  segundoAudio: Value(_entero(h['segundo_audio'])),
                  razonamiento: Value(_texto(h['razonamiento'])),
                  confianza: Value(_decimal(h['confianza'])),
                  valorCorregido: Value(_texto(h['valor_corregido'])),
                  entidadLocalId: Value(_texto(h['entidad_local_id'])),
                  creadoEn: DateTime.now(),
                ),
              );
        }

        for (final cruda in (v['informes'] as List?) ?? const []) {
          final i = (cruda as Map).cast<String, dynamic>();
          final contenido = _texto(i['contenido']);
          if (contenido == null) continue;
          await _db.into(_db.informes).insert(
                InformesCompanion.insert(
                  id: _uuid.v4(),
                  visitaId: codigo,
                  titulo: _texto(i['titulo']) ?? 'Informe',
                  tipo: Value(
                    _texto(i['tipo']) ?? 'Resumen para el agricultor',
                  ),
                  contenido: contenido,
                  version: Value(_entero(i['version']) ?? 1),
                  generadoEn: _fecha(i['generado_en']) ?? DateTime.now(),
                  entregado: Value(i['entregado'] == true),
                  medioEntrega: Value(_texto(i['medio_entrega'])),
                  enlacePdf: Value(_texto(i['enlace_pdf'])),
                ),
              );
          informes++;
        }
      });

      fotos += await _bajarEvidencias(codigo, v, bajar, onPaso);
      audios += await _bajarAudios(codigo, v, bajar, onPaso);
      espejadas++;
    }

    return ResultadoEspejo(
      visitas: espejadas,
      propiasRespetadas: propias,
      fotos: fotos,
      audios: audios,
      informes: informes,
      hallazgosFueraDeCatalogo: hallazgosFuera,
    );
  }

  /// Borra los hijos de un espejo antes de volver a escribirlo.
  ///
  /// Solo se llama sobre visitas `soloLectura`: si esto corriera sobre una
  /// visita propia borraria el audio y las fotos de una conversacion real.
  Future<void> _borrarHijosDe(String visitaId) async {
    await (_db.delete(_db.hallazgos)..where((h) => h.visitaId.equals(visitaId)))
        .go();
    await (_db.delete(_db.evidencias)..where((e) => e.visitaId.equals(visitaId)))
        .go();
    await (_db.delete(_db.grabaciones)..where((g) => g.visitaId.equals(visitaId)))
        .go();
    await (_db.delete(_db.informes)..where((i) => i.visitaId.equals(visitaId)))
        .go();
  }

  /// Las fotos del espejo, bajadas a la carpeta de la visita.
  ///
  /// Las URL de los adjuntos de Airtable caducan en unas horas: se guardan los
  /// BYTES, no el enlace. Una foto que no se pudo bajar no cancela nada — la
  /// fila queda sin archivo y el historial se ve igual, con un hueco honesto.
  Future<int> _bajarEvidencias(
    String visitaId,
    Map<String, dynamic> v,
    Future<List<int>?> Function(String url)? bajar,
    void Function(String)? onPaso,
  ) async {
    final lista = (v['evidencias'] as List?) ?? const [];
    if (lista.isEmpty) return 0;

    final carpeta = Directory(
      p.join((await _carpetaDeVisita(visitaId)).path, 'fotos'),
    );
    await carpeta.create(recursive: true);

    var bajadas = 0;
    var orden = 0;
    for (final cruda in lista) {
      final e = (cruda as Map).cast<String, dynamic>();
      orden++;

      final url = _texto(e['url']);
      final ruta = p.join(
        carpeta.path,
        'foto-${orden.toString().padLeft(2, '0')}.jpg',
      );

      if (url != null && bajar != null) {
        onPaso?.call('Bajando la foto $orden...');
        final bytes = await bajar(url);
        if (bytes != null) {
          await File(ruta).writeAsBytes(bytes, flush: true);
          bajadas++;
        }
      }

      // La descripcion vuelve con el `[MM:SS]` que le puso la sincronizacion
      // al escribirla, porque `Evidencias` no tiene columna para el segundo
      // del audio. Se separa de nuevo: es lo que permite volver a lo que se
      // estaba hablando mientras se fotografiaba.
      final descripcion = _texto(e['descripcion_visitador']);
      final marca = RegExp(r'^\[(\d{1,2}):(\d{2})\]\s*').firstMatch(
        descripcion ?? '',
      );

      await _db.into(_db.evidencias).insert(
            EvidenciasCompanion.insert(
              id: _uuid.v4(),
              visitaId: visitaId,
              archivoPath: ruta,
              tomadaEn: _fecha(e['tomada_en']) ?? DateTime.now(),
              tipo: Value(_texto(e['tipo'])),
              latitud: Value(_decimal(e['latitud'])),
              longitud: Value(_decimal(e['longitud'])),
              segundoAudio: Value(
                marca == null
                    ? null
                    : int.parse(marca.group(1)!) * 60 +
                        int.parse(marca.group(2)!),
              ),
              descripcionVisitador: Value(
                marca == null ? descripcion : descripcion!.substring(marca.end),
              ),
              descripcionIa: Value(_texto(e['descripcion_ia'])),
              textoOcr: Value(_texto(e['texto_ocr'])),
              estadoValidacion: Value(
                _texto(e['estado_validacion']) ?? 'Sin revisar',
              ),
            ),
          );
    }
    return bajadas;
  }

  /// El audio del espejo. Su enlace es del bucket y no caduca, pero se baja
  /// igual: el historial se consulta en la finca, que es justo donde no hay
  /// con que abrir una URL.
  Future<int> _bajarAudios(
    String visitaId,
    Map<String, dynamic> v,
    Future<List<int>?> Function(String url)? bajar,
    void Function(String)? onPaso,
  ) async {
    final lista = (v['grabaciones'] as List?) ?? const [];
    if (lista.isEmpty) return 0;

    final carpeta = Directory(
      p.join((await _carpetaDeVisita(visitaId)).path, 'audios'),
    );
    await carpeta.create(recursive: true);

    var bajados = 0;
    var posicion = 0;
    for (final cruda in lista) {
      final g = (cruda as Map).cast<String, dynamic>();
      posicion++;
      final orden = _entero(g['orden']) ?? posicion;

      final ruta = p.join(
        carpeta.path,
        'tramo-${orden.toString().padLeft(2, '0')}.m4a',
      );
      final url = _texto(g['url']);

      if (url != null && bajar != null) {
        onPaso?.call('Bajando el audio del tramo $orden...');
        final bytes = await bajar(url);
        if (bytes != null) {
          await File(ruta).writeAsBytes(bytes, flush: true);
          bajados++;
        }
      }

      final minutos = _decimal(g['duracion_min']) ?? 0;
      final megas = _decimal(g['tamano_mb']) ?? 0;

      await _db.into(_db.grabaciones).insert(
            GrabacionesCompanion.insert(
              id: _uuid.v4(),
              visitaId: visitaId,
              orden: orden,
              archivoPath: ruta,
              inicio: _fecha(g['inicio']) ?? DateTime.now(),
              duracionSeg: Value((minutos * 60).round()),
              tamanoBytes: Value((megas * 1024 * 1024).round()),
              enlaceAudio: Value(url),
              transcripcion: Value(_texto(g['transcripcion'])),
              transcripcionMarcas: Value(_texto(g['transcripcion_marcas'])),
              motorTranscripcion: Value(_texto(g['motor_transcripcion'])),
              estado: Value(_texto(g['estado']) ?? 'Grabada'),
            ),
          );
    }
    return bajados;
  }

  /// El agricultor del espejo: el que ya existe con ese nombre, o uno nuevo.
  ///
  /// Se busca por nombre normalizado y no se crea una ficha por visita: sin
  /// esto, bajar cinco visitas de Pedro Gomez dejaria cinco Pedro Gomez en el
  /// directorio del telefono, que es el problema que el directorio existe para
  /// evitar.
  Future<String?> _productorEspejo(String? nombre) async {
    if (nombre == null) return null;
    final buscado = normalizarBusqueda(nombre);
    final locales = await _db.select(_db.productores).get();
    final existente = _primero(
      locales,
      (p) => normalizarBusqueda(p.nombreCompleto) == buscado,
    );
    if (existente != null) return existente.id;

    final id = _uuid.v4();
    await _db.into(_db.productores).insert(
          ProductoresCompanion.insert(id: id, nombreCompleto: nombre),
        );
    return id;
  }

  Future<String?> _veredaEspejo(String? nombre) async {
    if (nombre == null) return null;
    final buscado = normalizarBusqueda(nombre);
    final locales = await _db.select(_db.veredas).get();
    final existente = _primero(
      locales,
      (v) => normalizarBusqueda(v.vereda) == buscado,
    );
    // Las veredas son un catalogo sembrado: si esta no esta, no se inventa.
    // Una vereda de mas en el selector es una opcion equivocada que alguien va
    // a tocar despues.
    return existente?.id;
  }

  Future<String?> _fincaEspejo(
    String? nombre,
    String? productorId,
    String? veredaId,
  ) async {
    if (nombre == null || productorId == null) return null;
    final buscado = normalizarBusqueda(nombre);
    final locales = await (_db.select(_db.fincas)
          ..where((f) => f.productorLocalId.equals(productorId)))
        .get();
    final existente = _primero(
      locales,
      (f) => normalizarBusqueda(f.nombre) == buscado,
    );
    if (existente != null) return existente.id;

    final id = _uuid.v4();
    await _db.into(_db.fincas).insert(
          FincasCompanion.insert(
            id: id,
            productorLocalId: productorId,
            nombre: nombre,
            veredaLocalId: Value(veredaId),
          ),
        );
    return id;
  }

  /// Lo que el chat de campo sabe de estas fincas.
  ///
  /// Va un resumen y no las transcripciones: el hilo del chat viaja completo en
  /// cada pregunta, y meter tres conversaciones enteras lo vuelve lento y caro
  /// sin responder mejor. Solo entran los datos que ya pasaron por las reglas
  /// de certeza — un Pendiente no es un dato y no puede llegar al modelo como
  /// si lo fuera.
  Future<String> contextoChat({int maxVisitas = 8, int maxDatos = 12}) async {
    final lista = await visitas();
    if (lista.isEmpty) return '';

    final catalogo = {
      for (final c in await _db.select(_db.catalogoCampos).get())
        c.claveTecnica: c,
    };

    final bloques = <String>[];
    for (final v in lista.take(maxVisitas)) {
      final productor = v.productorLocalId == null
          ? null
          : await (_db.select(_db.productores)
                ..where((x) => x.id.equals(v.productorLocalId!)))
              .getSingleOrNull();
      final finca = v.fincaLocalId == null
          ? null
          : await (_db.select(_db.fincas)
                ..where((x) => x.id.equals(v.fincaLocalId!)))
              .getSingleOrNull();
      final vereda = v.veredaLocalId == null
          ? null
          : await (_db.select(_db.veredas)
                ..where((x) => x.id.equals(v.veredaLocalId!)))
              .getSingleOrNull();

      final fecha = v.inicio.toIso8601String().substring(0, 10);
      final encabezado = [
        finca?.nombre ?? 'Finca sin registrar',
        if (productor != null) 'productor ${productor.nombreCompleto}',
        if (vereda != null) '${vereda.vereda} (${vereda.municipio})',
        'visita del $fecha',
        '${v.completitudPct}% del cuestionario',
        v.estado,
      ].join(' — ');

      final hallazgos = await (_db.select(_db.hallazgos)
            ..where((h) => h.visitaId.equals(v.id)))
          .get();
      final lineas = <String>[];
      for (final h in hallazgos) {
        if (h.certeza == Certeza.pendiente) continue;
        if (lineas.length >= maxDatos) break;
        final valor = h.valorTexto ?? '${h.valorNumerico ?? ''}';
        final campo = catalogo[h.claveTecnica]?.campo ?? h.claveTecnica;
        lineas.add(
          '  - $campo: ${h.unidad == null ? valor : '$valor ${h.unidad}'} '
          '[${h.certeza.airtable}]',
        );
      }

      bloques.add(
        lineas.isEmpty
            ? '$encabezado\n  (Sin datos registrados todavia.)'
            : '$encabezado\n${lineas.join('\n')}',
      );
    }

    return bloques.join('\n\n');
  }

  /// Se marca al compartir, no al confirmar que llego: el telefono no puede
  /// saber si el productor lo abrio.
  Future<void> marcarInformeEntregado(String informeId, {String? medio}) =>
      (_db.update(_db.informes)..where((i) => i.id.equals(informeId))).write(
        InformesCompanion(
          entregado: const Value(true),
          medioEntrega: Value(medio),
        ),
      );

  /// Encola la visita entera para sincronizar. El payload lleva el UUID, asi
  /// que `POST /v1/visitas` es idempotente: reintentar no duplica.
  Future<void> encolarVisita(String visitaId) async {
    final visita = await (_db.select(_db.visitas)
          ..where((v) => v.id.equals(visitaId)))
        .getSingle();

    // Un espejo NUNCA sube. Esta linea es la garantia de toda la funcion de
    // historial, y vive aca —en el dato— y no en la pantalla a proposito: una
    // pantalla nueva, un boton mal conectado o un flujo que nadie penso
    // pasarian por encima de un guardarraiil que viviera en la UI. Por aqui
    // pasan todos los caminos que terminan escribiendo en Airtable.
    //
    // Sin esto, consultar el historial de un agricultor podria reescribir en
    // el registro central la visita de otro visitador con los datos parciales
    // que este telefono alcanzo a bajar.
    if (visita.soloLectura) return;

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
          if (productor.tipoDocumento != null)
            'tipo_documento': productor.tipoDocumento,
          if (productor.telefono != null) 'telefono': productor.telefono,
          if (productor.telefonoAlterno != null)
            'telefono_alterno': productor.telefonoAlterno,
          if (productor.genero != null) 'genero': productor.genero,
          if (productor.fechaNacimiento != null)
            'fecha_nacimiento':
                productor.fechaNacimiento!.toIso8601String().split('T').first,
          if (productor.nivelEducativo != null)
            'nivel_educativo': productor.nivelEducativo,
          if (productor.aniosExperiencia != null)
            'anios_experiencia': productor.aniosExperiencia,
          if (productor.personasHogar != null)
            'personas_hogar': productor.personasHogar,
          if (productor.organizacion != null)
            'organizacion': productor.organizacion,
          if (productor.notas != null) 'notas': productor.notas,
          'consentimiento_datos': productor.consentimientoDatos,
          if (productor.fechaConsentimiento != null)
            'fecha_consentimiento': productor.fechaConsentimiento!
                .toIso8601String()
                .split('T')
                .first,
          // Va solo si la foto ya subio. El retrato sube por su propio item de
          // la cola, asi que puede quedar pendiente cuando la visita ya
          // sincronizo; el upsert es idempotente y el enlace llega despues.
          if (productor.enlaceFoto != null)
            'enlace_foto': productor.enlaceFoto,
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
      'trazados': await _trazadosDeVisita(visitaId),
      'informes': [
        for (final i in await informesDeVisita(v.id))
          {
            'id': i.id,
            'titulo': i.titulo,
            'tipo': i.tipo,
            'contenido': i.contenido,
            'version': i.version,
            'generado_en': i.generadoEn.toIso8601String(),
            'entregado': i.entregado,
            if (i.medioEntrega != null) 'medio_entrega': i.medioEntrega,
            // Puede ir vacio: el PDF sube por su propio item de la cola y
            // puede quedar pendiente cuando la visita ya se sincronizo. El
            // upsert es idempotente, asi que el enlace llega en el reintento.
            if (i.enlacePdf != null) 'enlace_pdf': i.enlacePdf,
          },
      ],
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

  /// Los poligonos de lote y los recorridos, como los manda `POST /v1/visitas`.
  ///
  /// Se arma aca y no en `TrazadoRepository` para no cerrar un ciclo: el repo
  /// de trazados ya depende de este para poder poner la ficha de la visita en
  /// el KML.
  ///
  /// Los puntos viajan todos, sin diezmar. Un recorrido de 40 minutos son
  /// cientos de coordenadas y el JSON crece, pero submuestrear en el cliente
  /// destruye la unica copia del lindero: lo que se manda es lo que se camino.
  Future<List<Map<String, dynamic>>> _trazadosDeVisita(String visitaId) async {
    final salida = <Map<String, dynamic>>[];

    for (final t in await _db.trazadosDeVisita(visitaId)) {
      final puntos = await _db.puntosDeTrazado(t.id);
      salida.add({
        'id': t.id,
        'nombre': t.nombre,
        'tipo': t.tipo.airtable,
        'modo_captura': t.modoCaptura.airtable,
        if (t.etiqueta != null) 'etiqueta': t.etiqueta,
        if (t.notas != null) 'notas': t.notas,
        if (t.intervaloSeg != null) 'intervalo_seg': t.intervaloSeg,
        if (t.distanciaMinM != null) 'distancia_min_m': t.distanciaMinM,
        if (t.precisionMaxM != null) 'precision_max_m': t.precisionMaxM,
        'cerrado': t.cerrado,
        if (t.areaM2 != null) 'area_m2': t.areaM2,
        if (t.areaM2 != null) 'area_ha': t.areaM2! / 10000,
        if (t.perimetroM != null) 'perimetro_m': t.perimetroM,
        'creado_en': t.creadoEn.toIso8601String(),
        'puntos': [
          for (final p in puntos)
            {
              'id': p.id,
              'orden': p.orden,
              'latitud': p.latitud,
              'longitud': p.longitud,
              if (p.altitud != null) 'altitud': p.altitud,
              if (p.precisionM != null) 'precision_m': p.precisionM,
              'capturado_en': p.capturadoEn.toIso8601String(),
              'automatico': p.automatico,
              if (p.nota != null) 'nota': p.nota,
            },
        ],
      });
    }

    return salida;
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

  /// Cuanto pesa una visita en el telefono: audios y fotos que existen en
  /// disco. Se muestra antes de borrar, para que el visitador sepa que esta
  /// tirando a la basura.
  Future<int> bytesEnDisco(String visitaId) async {
    var total = 0;
    for (final ruta in await _archivosDeVisita(visitaId)) {
      final archivo = File(ruta);
      if (await archivo.exists()) total += await archivo.length();
    }
    return total;
  }

  Future<List<String>> _archivosDeVisita(String visitaId) async => [
        for (final g in await grabacionesDeVisita(visitaId)) g.archivoPath,
        for (final e in await evidenciasDeVisita(visitaId)) e.archivoPath,
      ];

  /// Borra visitas de ESTE telefono: filas, archivos y lo que quedaba en cola.
  ///
  /// Es irreversible y es local. Lo que ya se sincronizo sigue en Airtable —
  /// esto no le pide al backend que borre nada, y confundir las dos cosas
  /// seria grave: para la eliminacion que SI viaja (el productor revoca el
  /// consentimiento) existe `Visitas.marcadaParaEliminacion`, que el backend
  /// respeta al sincronizar.
  ///
  /// El orden no es negociable: primero los hijos y la cola, al final la
  /// visita. Al revés, las claves foráneas rechazan el borrado.
  Future<void> eliminarVisitas(List<String> visitaIds) async {
    if (visitaIds.isEmpty) return;

    // Las rutas se leen ANTES de borrar las filas: despues no hay de donde
    // sacarlas, y los archivos quedarian ocupando el telefono para siempre.
    final archivos = <String>[];
    for (final id in visitaIds) {
      archivos.addAll(await _archivosDeVisita(id));
    }

    await _db.transaction(() async {
      // La cola primero y por `entidadId`: si queda un item apuntando a una
      // visita borrada, el sincronizador va a fallar en cada corrida al leer
      // una fila que ya no existe.
      await (_db.delete(_db.syncQueue)
            ..where((q) => q.entidadId.isIn(visitaIds)))
          .go();

      await (_db.delete(_db.hallazgos)
            ..where((h) => h.visitaId.isIn(visitaIds)))
          .go();
      await (_db.delete(_db.evidencias)
            ..where((e) => e.visitaId.isIn(visitaIds)))
          .go();
      await (_db.delete(_db.grabaciones)
            ..where((g) => g.visitaId.isIn(visitaIds)))
          .go();
      await (_db.delete(_db.informes)
            ..where((i) => i.visitaId.isIn(visitaIds)))
          .go();
      // Los puntos antes que los trazados, y los dos antes que la visita: la
      // cadena de claves foraneas es visita -> trazado -> punto.
      final trazadosDeEsas = await (_db.select(_db.trazados)
            ..where((t) => t.visitaId.isIn(visitaIds)))
          .get();
      final idsTrazados = [for (final t in trazadosDeEsas) t.id];
      if (idsTrazados.isNotEmpty) {
        await (_db.delete(_db.puntosTrazado)
              ..where((p) => p.trazadoId.isIn(idsTrazados)))
            .go();
      }
      await (_db.delete(_db.trazados)
            ..where((t) => t.visitaId.isIn(visitaIds)))
          .go();
      await (_db.delete(_db.visitas)..where((v) => v.id.isIn(visitaIds))).go();
    });

    // La foto de perfil vive dentro de la carpeta de la visita donde se tomo,
    // asi que el barrido de mas abajo se la lleva. El productor NO se borra
    // —es permanente y puede tener otras visitas—, pero se le quita la
    // referencia: una ruta que apunta a un archivo que ya no esta le deja al
    // visitador un recuadro roto donde estaba la cara del agricultor.
    for (final id in visitaIds) {
      // Se busca por el UUID y no por la ruta armada: el separador de
      // directorios no es el mismo en el telefono que donde corren las
      // pruebas, y el UUID de la visita ya es inconfundible.
      await (_db.update(_db.productores)
            ..where((p) => p.fotoPath.contains(id)))
          .write(
        const ProductoresCompanion(
          fotoPath: Value(null),
          enlaceFoto: Value(null),
        ),
      );
    }

    // Los archivos van despues de la transaccion: borrar en disco no se puede
    // deshacer, asi que si la transaccion falla se conservan los archivos de
    // una visita que sigue existiendo en la base.
    for (final ruta in archivos) {
      try {
        final archivo = File(ruta);
        if (await archivo.exists()) await archivo.delete();
      } catch (_) {
        // Un archivo que no se puede borrar no puede dejar la visita a medio
        // eliminar: las filas ya no estan y eso es lo que ve el visitador.
      }
    }

    // Y la carpeta entera, que barre los tramos de audio que quedaron en disco
    // sin fila en la base (la app muerta a mitad de grabacion los deja ahi).
    for (final id in visitaIds) {
      try {
        final carpeta = await _carpetaDeVisita(id);
        if (await carpeta.exists()) await carpeta.delete(recursive: true);
      } catch (_) {
        // Igual que arriba.
      }
    }
  }
}
