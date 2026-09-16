import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:sirius_agro/core/iconos_modulo.dart';

/// El icono de cada modulo del cuestionario.
///
/// Lo que se protege: que los modulos que la app trae sembrados tengan icono
/// propio —si todos cayeran al de reserva, la lista de faltantes seria una
/// columna de la misma etiqueta repetida—, y que el nombre del modulo pueda
/// venir de Airtable escrito de otra forma sin que el icono se caiga.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('todos los modulos del catalogo sembrado tienen icono propio', () async {
    final crudo = await rootBundle.loadString('assets/semilla/catalogo.json');
    final catalogo = jsonDecode(crudo) as Map<String, dynamic>;
    final campos = catalogo['campos'] as List;
    final modulos = {for (final c in campos) c['modulo'] as String};

    expect(modulos, isNotEmpty);
    for (final m in modulos) {
      expect(
        iconoDeModulo(m),
        isNot(iconoModuloPorDefecto),
        reason: 'el modulo «$m» no tiene icono y cae al de reserva',
      );
    }
  });

  test('el nombre del modulo se reconoce con tildes, mayusculas y espacios',
      () {
    // Airtable es texto libre: quien renombre «Identificacion» a
    // «Identificación» no deberia dejar la lista sin icono.
    expect(iconoDeModulo('Identificación'), Icons.badge_outlined);
    expect(iconoDeModulo('  AGUA Y RIEGO '), Icons.water_drop_outlined);
    expect(iconoDeModulo('Economía y Comercialización'),
        Icons.payments_outlined);
  });

  test('un modulo desconocido sale con el de reserva, no sin icono', () {
    // Activar un modulo nuevo en Airtable no puede exigir recompilar la app:
    // una fila coja entre filas con icono se lee como un error.
    expect(iconoDeModulo('Modulo que no existe'), iconoModuloPorDefecto);
  });

  test('el icono del PDF es el mismo glifo que el de la pantalla', () {
    // Dos simbolos distintos para «Suelos» —uno en el telefono y otro en el
    // papel— es peor que no poner ninguno.
    expect(iconoModuloPdf('Suelos'), Icons.terrain_outlined.codePoint);
  });
}
