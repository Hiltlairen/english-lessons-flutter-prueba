import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prueba/actividades/catalogo.dart';
import 'package:prueba/pantallas/actividad.dart';

void main() {
  // Pantalla de celular típica (≈ 393 × 851 dp).
  void comoCelular(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
  }

  for (final a in catalogo) {
    testWidgets('${a.codigo} se abre sin errores en un celular', (tester) async {
      comoCelular(tester);
      await tester.pumpWidget(MaterialApp(home: ActividadPantalla(actividad: a)));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      // Desmonta para cancelar relojes (laberinto) y animaciones.
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('Quiz: elegir, comprobar y ver la hoja de feedback', (tester) async {
    comoCelular(tester);
    final quiz = catalogo.firstWhere((a) => a.codigo == '20-basquetbol');
    await tester.pumpWidget(MaterialApp(home: ActividadPantalla(actividad: quiz)));
    await tester.pump();
    await tester.tap(find.text('Dog'));
    await tester.pump(const Duration(milliseconds: 1600));
    expect(find.text('¡Canasta!'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
