import 'package:flutter/material.dart';

/// Un icono por modulo del cuestionario.
///
/// El modulo llega como texto libre desde el catalogo —y el catalogo se
/// siembra desde Airtable—, asi que la clave se normaliza antes de buscar: sin
/// tildes, en minuscula y sin espacios de sobra. Si alguien renombra «Agua y
/// riego» a «Agua y Riego» en Airtable, el icono no se cae.
///
/// Un modulo que no este en la tabla sale con [iconoModuloPorDefecto] en vez
/// de sin icono: una fila coja entre filas con icono se lee como un error, y
/// activar un modulo nuevo en Airtable no deberia exigir tocar la app.
IconData iconoDeModulo(String modulo) =>
    _iconos[_clave(modulo)] ?? iconoModuloPorDefecto;

const iconoModuloPorDefecto = Icons.label_outlined;

/// El agricultor aplicando insumos, dibujado a mano.
///
/// Material no tiene ningun icono de alguien aplicando: lo mas cerca es un
/// aerosol o un insecto, y ninguno de los dos dice lo que hace un modulo que
/// se llama «Insumos». Este glifo vive en `assets/fuentes/IconosModulo.ttf`,
/// en la zona privada de Unicode, y lo dibuja `tool/iconos_modulo.py`.
///
/// La misma fuente sirve en pantalla y en el papel, que es lo que garantiza
/// que el informe y el telefono muestren el mismo simbolo.
const iconoAplicacion = IconData(0xE900, fontFamily: 'IconosModulo');

/// El mismo icono, para el PDF.
///
/// El generador de PDF no entiende `IconData` de Flutter: quiere el numero del
/// glifo y la fuente aparte. Se saca de la misma tabla y no de una lista
/// paralela, que es como el informe y la pantalla acabarian mostrando dos
/// simbolos distintos para el mismo modulo.
///
/// Los glifos estan recortados en `assets/fuentes/IconosModulo.ttf`. Si se
/// agrega un modulo a [_iconos], hay que volver a generar ese archivo con
/// `python tool/iconos_modulo.py` o el icono nuevo saldra vacio en el papel.
/// `iconos_modulo_test.dart` falla si eso pasa.
int iconoModuloPdf(String modulo) => iconoDeModulo(modulo).codePoint;

/// Los modulos que tienen icono propio. Solo para las pruebas: es lo que
/// permite comprobar que el recorte de la fuente del PDF no se quedo atras del
/// mapa sin tener que repetir la lista en dos sitios.
Iterable<String> get modulosConIcono => _iconos.keys;

const _iconos = <String, IconData>{
  'agua y riego': Icons.water_drop_outlined,
  'cultivos': Icons.grass_outlined,
  'aspiraciones y proyectos': Icons.flag_outlined,
  'identificacion': Icons.badge_outlined,
  // Las capas del perfil del suelo, no una montana: el modulo pregunta
  // por lo que hay DEBAJO —horizontes, materia organica, pH—, y una
  // montana habla del relieve, que es otra cosa.
  'suelos': Icons.layers_outlined,
  'conectividad': Icons.cell_tower_outlined,
  'economia y comercializacion': Icons.payments_outlined,
  'riesgos y clima': Icons.thunderstorm_outlined,
  'familia y social': Icons.groups_outlined,
  'historia y origen': Icons.history_edu_outlined,
  'tierra y tenencia': Icons.map_outlined,
  // Lo que se aplica al cultivo: el modulo llega de Airtable como «Insumos y
  // manejo» o como «Insumos» a secas, y los dos son lo mismo.
  'insumos y manejo': iconoAplicacion,
  'insumos': iconoAplicacion,
  'ganaderia y animales': Icons.pets_outlined,
  'hogar': Icons.home_outlined,
};

String _clave(String modulo) {
  final bajo = modulo.trim().toLowerCase();
  final sb = StringBuffer();
  for (final r in bajo.runes) {
    sb.writeCharCode(_sinTilde[r] ?? r);
  }
  return sb.toString();
}

/// Solo las vocales acentuadas y la enie: es todo lo que aparece en un nombre
/// de modulo, y una tabla corta se lee de un vistazo.
const _sinTilde = <int, int>{
  0xE1: 0x61, // a
  0xE9: 0x65, // e
  0xED: 0x69, // i
  0xF3: 0x6F, // o
  0xFA: 0x75, // u
  0xFC: 0x75, // u con dieresis
  0xF1: 0x6E, // n
};
