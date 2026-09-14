import 'package:intl/intl.dart';

import 'api_client.dart';

/// El chat de una visita: completar lo que falto y preguntar sobre ella.
///
/// Una conversacion de campo nunca queda completa. El esposo que maneja el
/// cultivo llega despues de las tres, el nombre de la finca quedo a medias, el
/// arriendo se dijo sin decir si era mensual. Hasta ahora eso moria en «temas
/// pendientes» y solo se arreglaba volviendo a la finca.
///
/// Aca el visitador lo escribe y el dato entra al registro — pero entra
/// marcado. Lo que teclea el visitador de memoria y despues no vale lo mismo
/// que lo que dijo el agricultor frente a una grabadora, y el sistema entero
/// depende de que esa diferencia quede en el dato: `fuente = Manual`,
/// `hablante = visitador`, y de ahi la regla dura que impide que sea
/// `Confirmado`.

/// Coincide con una opcion de `Informes.Tipo`. Como los otros tipos, Airtable
/// la crea sola la primera vez gracias a `typecast`.
const tipoComplementoVisita = 'Complemento de la visita';

/// La conversacion en markdown, para `Informes.Contenido`.
///
/// Se guarda entera y literal, no resumida: esto es la PROCEDENCIA de los
/// datos que no vinieron del audio. Un resumen escrito por el modelo seria un
/// registro de procedencia que ya paso por un modelo, que es tanto como no
/// tenerlo.
String markdownConversacion({
  required List<MensajeChat> mensajes,
  required DateTime generadoEn,
  String? visitador,
  List<String> datosEscritos = const [],
}) {
  final hora = DateFormat('h:mm a', 'es');
  final fecha = DateFormat("d 'de' MMMM 'de' y", 'es');

  final l = <String>[
    '# Complemento de la visita',
    '',
    'Conversacion entre el visitador y el asistente, posterior a la visita. '
        'Lo que se registro desde aqui NO salio del audio: lo aporto '
        '${visitador ?? 'el visitador'} de memoria, y por eso ningun dato de '
        'esta conversacion puede quedar como «Confirmado».',
    '',
    '- Fecha: ${fecha.format(generadoEn)}, ${hora.format(generadoEn)}',
    if (visitador != null) '- Visitador: $visitador',
    '',
  ];

  if (datosEscritos.isNotEmpty) {
    l
      ..add('## Datos que quedaron registrados')
      ..add('');
    for (final dato in datosEscritos) {
      l.add('- $dato');
    }
    l.add('');
  }

  l
    ..add('## La conversacion')
    ..add('');

  for (final m in mensajes) {
    l
      ..add('**${m.esDelVisitador ? (visitador ?? 'Visitador') : 'Asistente'}:** '
          '${m.contenido.trim()}')
      ..add('');
  }

  return l.join('\n').trimRight();
}
