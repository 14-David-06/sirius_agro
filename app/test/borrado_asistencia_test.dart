import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirius_agro/ui/evento_asistencia_page.dart';

/// Borrar del telefono no tiene vuelta atras: la nota y la firma salen del
/// disco. Lo que se protege es que no se pueda hacer de un toque.
void main() {
  Future<List<bool>> abrir(WidgetTester tester, {int sinSubir = 0}) async {
    final resultados = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async => resultados.add(
                  await confirmarBorrado(
                    context,
                    titulo: '¿Borrar este registro del teléfono?',
                    sinSubir: sinSubir,
                  ),
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return resultados;
  }

  FilledButton botonBorrar(WidgetTester tester) => tester.widget<FilledButton>(
    find.widgetWithText(FilledButton, 'Borrar'),
  );

  testWidgets('el boton Borrar no se habilita sin escribir BORRAR', (
    tester,
  ) async {
    await abrir(tester);
    expect(botonBorrar(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'borra');
    await tester.pump();
    expect(botonBorrar(tester).onPressed, isNull);
  });

  testWidgets('escribiendo BORRAR se confirma', (tester) async {
    final resultados = await abrir(tester);

    // Sin importar mayusculas ni espacios de mas: lo que importa es la
    // intencion, no la ortografia del teclado.
    await tester.enterText(find.byType(TextField), ' borrar ');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Borrar'));
    await tester.pumpAndSettle();

    expect(resultados, [true]);
  });

  testWidgets('tocar afuera no cierra ni borra', (tester) async {
    final resultados = await abrir(tester);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(resultados, isEmpty);
  });

  testWidgets('cancelar no borra', (tester) async {
    final resultados = await abrir(tester);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(resultados, [false]);
  });

  testWidgets('lo que no ha subido se advierte con el numero', (tester) async {
    await abrir(tester, sinSubir: 3);

    expect(find.textContaining('3 registros todavía no se han subido'),
        findsOneWidget);
    expect(find.textContaining('se pierden para siempre'), findsOneWidget);
  });
}
