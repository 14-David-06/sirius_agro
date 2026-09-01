import '../models/question.dart';

/// Plantillas de preguntas que el asistente va respondiendo durante la reunion.
/// Editar aqui para agregar una nueva; el id se guarda con cada reunion.
const questionnaires = <Questionnaire>[
  Questionnaire(
    id: 'default',
    name: 'Reunion general',
    questions: [
      Question(
        id: 'objetivo',
        text: 'Objetivo de la reunion',
        hint: 'Para que se convoco',
      ),
      Question(
        id: 'temas',
        text: 'Temas principales tratados',
      ),
      Question(
        id: 'decisiones',
        text: 'Decisiones tomadas',
      ),
      Question(
        id: 'compromisos',
        text: 'Compromisos y responsables',
        hint: 'Quien hace que y para cuando',
      ),
      Question(
        id: 'seguimiento',
        text: 'Proxima reunion o seguimiento',
        multiline: false,
      ),
    ],
  ),
  Questionnaire(
    id: 'visita_campo',
    name: 'Visita a campo',
    questions: [
      Question(id: 'finca', text: 'Finca / lote visitado', multiline: false),
      Question(id: 'productor', text: 'Productor y contacto', multiline: false),
      Question(id: 'observaciones', text: 'Observaciones de campo'),
      Question(id: 'practicas', text: 'Practicas regenerativas en curso'),
      Question(id: 'necesidades', text: 'Necesidades detectadas'),
      Question(id: 'acciones', text: 'Acciones acordadas'),
    ],
  ),
];

Questionnaire questionnaireById(String id) => questionnaires.firstWhere(
      (q) => q.id == id,
      orElse: () => questionnaires.first,
    );
