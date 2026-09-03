import 'package:drift/drift.dart';

/// Los enums de aqui se serializan con el nombre EXACTO de la opcion en Airtable.
/// No hay capa de traduccion: lo que sale de la app es lo que entra al select.
/// Si alguien renombra una opcion en Airtable, hay que renombrarla aqui.

/// De donde viene el dato. Eje de procedencia, ortogonal a [EstadoHallazgo].
enum Certeza {
  confirmado('Confirmado'),
  estimado('Estimado'),
  inferido('Inferido'),
  pendiente('Pendiente'),

  /// Campo de etiqueta que la camara no pudo leer. Distinto de [pendiente]:
  /// pendiente es "no se menciono", noLegible es "esta ahi y no se ve".
  /// La pantalla de validacion lo muestra con la foto recortada al lado.
  noLegible('No legible');

  const Certeza(this.airtable);
  final String airtable;

  /// Un hallazgo cuenta para la completitud solo si tiene un valor utilizable.
  bool get resuelve =>
      this == Certeza.confirmado ||
      this == Certeza.estimado ||
      this == Certeza.inferido;
}

/// Que hizo el visitador con el dato. Eje de validacion humana.
enum EstadoHallazgo {
  propuestoPorIa('Propuesto por IA'),
  requiereConfirmacion('Requiere confirmacion'),
  confirmado('Confirmado'),
  corregido('Corregido'),
  descartado('Descartado');

  const EstadoHallazgo(this.airtable);
  final String airtable;
}

/// Quien dijo el dato en la conversacion.
enum Hablante {
  agricultor('agricultor'),
  visitador('visitador'),
  noIdentificado('no identificado');

  const Hablante(this.airtable);
  final String airtable;
}

/// A que entidad se refiere el hallazgo. Sin esto, tres cultivos se pisan.
enum EntidadDestino {
  productor('Productor'),
  finca('Finca'),
  lote('Lote'),
  cultivo('Cultivo'),
  animal('Animal'),
  insumo('Insumo'),
  visita('Visita');

  const EntidadDestino(this.airtable);
  final String airtable;
}

enum FuenteHallazgo {
  audio('Audio'),
  foto('Foto'),
  ocrEtiqueta('OCR de etiqueta'),
  gps('GPS'),
  manual('Manual'),
  visitaAnterior('Visita anterior');

  const FuenteHallazgo(this.airtable);
  final String airtable;
}

enum EstadoSync {
  pendiente('Pendiente'),
  enCurso('En curso'),
  fallida('Fallida'),
  completada('Completada');

  const EstadoSync(this.airtable);
  final String airtable;
}

/// Convierte un enum a su nombre de Airtable y de vuelta. Si el valor guardado
/// ya no existe en el enum (renombre en Airtable, downgrade de la app), cae en
/// [fallback] en vez de tumbar la consulta: perder un select no vale perder
/// una visita de campo.
class _AirtableConverter<T extends Enum> extends TypeConverter<T, String> {
  const _AirtableConverter(this._values, this._name, this._fallback);

  final List<T> _values;
  final String Function(T) _name;
  final T _fallback;

  @override
  T fromSql(String fromDb) {
    for (final v in _values) {
      if (_name(v) == fromDb) return v;
    }
    return _fallback;
  }

  @override
  String toSql(T value) => _name(value);
}

class CertezaConverter extends _AirtableConverter<Certeza> {
  const CertezaConverter()
      : super(Certeza.values, _airtable, Certeza.pendiente);
  static String _airtable(Certeza v) => v.airtable;
}

class EstadoHallazgoConverter extends _AirtableConverter<EstadoHallazgo> {
  const EstadoHallazgoConverter()
      : super(EstadoHallazgo.values, _airtable, EstadoHallazgo.propuestoPorIa);
  static String _airtable(EstadoHallazgo v) => v.airtable;
}

class HablanteConverter extends _AirtableConverter<Hablante> {
  const HablanteConverter()
      : super(Hablante.values, _airtable, Hablante.noIdentificado);
  static String _airtable(Hablante v) => v.airtable;
}

class EntidadDestinoConverter extends _AirtableConverter<EntidadDestino> {
  const EntidadDestinoConverter()
      : super(EntidadDestino.values, _airtable, EntidadDestino.visita);
  static String _airtable(EntidadDestino v) => v.airtable;
}

class FuenteHallazgoConverter extends _AirtableConverter<FuenteHallazgo> {
  const FuenteHallazgoConverter()
      : super(FuenteHallazgo.values, _airtable, FuenteHallazgo.audio);
  static String _airtable(FuenteHallazgo v) => v.airtable;
}

class EstadoSyncConverter extends _AirtableConverter<EstadoSync> {
  const EstadoSyncConverter()
      : super(EstadoSync.values, _airtable, EstadoSync.pendiente);
  static String _airtable(EstadoSync v) => v.airtable;
}
