class Topic {
  const Topic({required this.titulo, required this.detalle});

  final String titulo;
  final String detalle;

  Map<String, dynamic> toJson() => {'titulo': titulo, 'detalle': detalle};

  factory Topic.fromJson(Map<String, dynamic> j) =>
      Topic(titulo: j['titulo'] as String, detalle: j['detalle'] as String);
}

class ActionItem {
  const ActionItem({
    required this.tarea,
    this.responsable = '',
    this.fechaLimite = '',
  });

  final String tarea;
  final String responsable;
  final String fechaLimite;

  Map<String, dynamic> toJson() => {
        'tarea': tarea,
        'responsable': responsable,
        'fecha_limite': fechaLimite,
      };

  factory ActionItem.fromJson(Map<String, dynamic> j) => ActionItem(
        tarea: j['tarea'] as String,
        responsable: (j['responsable'] as String?) ?? '',
        fechaLimite: (j['fecha_limite'] as String?) ?? '',
      );
}

class Report {
  const Report({
    required this.resumenEjecutivo,
    this.temas = const [],
    this.acuerdos = const [],
    this.pendientes = const [],
    this.riesgos = const [],
  });

  final String resumenEjecutivo;
  final List<Topic> temas;
  final List<String> acuerdos;
  final List<ActionItem> pendientes;
  final List<String> riesgos;

  Map<String, dynamic> toJson() => {
        'resumen_ejecutivo': resumenEjecutivo,
        'temas': temas.map((t) => t.toJson()).toList(),
        'acuerdos': acuerdos,
        'pendientes': pendientes.map((p) => p.toJson()).toList(),
        'riesgos': riesgos,
      };

  factory Report.fromJson(Map<String, dynamic> j) => Report(
        resumenEjecutivo: j['resumen_ejecutivo'] as String,
        temas: ((j['temas'] as List?) ?? [])
            .map((e) => Topic.fromJson(e as Map<String, dynamic>))
            .toList(),
        acuerdos: ((j['acuerdos'] as List?) ?? []).cast<String>(),
        pendientes: ((j['pendientes'] as List?) ?? [])
            .map((e) => ActionItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        riesgos: ((j['riesgos'] as List?) ?? []).cast<String>(),
      );
}
