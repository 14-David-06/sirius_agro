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
