// Nombres de archivo que sobreviven a Android, iOS y Windows.
//
// Viven aparte porque los usan dos cosas que no se conocen entre si: el zip de
// la visita y el KML de los trazados. Si cada una tuviera su copia, un dia el
// zip se llamaria `don-pedro` y el KML `don_pedro`, y quien recibe los dos no
// sabria que son de la misma visita.

/// `2026-09-07-1430`. Lleva hora porque un visitador hace dos visitas el mismo
/// dia y la fecha sola las pisaria en la carpeta de descargas.
String selloFecha(DateTime d) {
  final l = d.toLocal();
  String dd(int n) => n.toString().padLeft(2, '0');
  return '${l.year}-${dd(l.month)}-${dd(l.day)}-${dd(l.hour)}${dd(l.minute)}';
}

/// Sin acentos, sin espacios y sin los caracteres que rompen un unzip en
/// alguno de los tres sistemas.
String slugArchivo(String texto) {
  const con = 'áàäâãéèëêíìïîóòöôõúùüûñçÁÀÄÂÃÉÈËÊÍÌÏÎÓÒÖÔÕÚÙÜÛÑÇ';
  const sin = 'aaaaaeeeeiiiiooooouuuuncAAAAAEEEEIIIIOOOOOUUUUNC';

  var salida = texto.toLowerCase().trim();
  for (var i = 0; i < con.length; i++) {
    salida = salida.replaceAll(con[i], sin[i].toLowerCase());
  }
  return salida
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

/// `2026-09-03`. El dia solo, sin hora: es el nombre que ve el productor
/// cuando le llega el PDF por WhatsApp, y ahi la hora no le dice nada.
String selloDia(DateTime d) {
  final l = d.toLocal();
  String dd(int n) => n.toString().padLeft(2, '0');
  return '${l.year}-${dd(l.month)}-${dd(l.day)}';
}

/// `visita-don-pedro-2026-09-03.pdf`: con quien y cuando, no con el serial.
///
/// El nombre con el que sale el PDF al compartirlo, imprimirlo o bajarlo. El
/// codigo de la visita se quedo adentro del documento, que es donde sirve: en
/// la carpeta de descargas del telefono lo unico que permite encontrar el
/// informe del señor Pedro es que se llame como el señor Pedro.
///
/// [sufijo] distingue documentos distintos de la misma visita el mismo dia —
/// el tecnico lleva `-tecnico-v1`, el del agricultor no lleva ninguno.
String nombreArchivoInforme({
  required DateTime fecha,
  String? productor,
  String? finca,
  String sufijo = '',
}) {
  // La finca como respaldo y no el UUID: si no quedo el nombre del productor,
  // «la soledad» todavia le dice algo a quien busca el archivo.
  final quien = slugArchivo(productor ?? finca ?? '');
  return 'visita-${quien.isEmpty ? 'sin-nombre' : quien}'
      '-${selloDia(fecha)}$sufijo.pdf';
}
