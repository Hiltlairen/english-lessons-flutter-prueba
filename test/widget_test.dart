import 'package:flutter_test/flutter_test.dart';

import 'package:prueba/actividades/catalogo.dart';
import 'package:prueba/main.dart';

void main() {
  testWidgets('El menú muestra las actividades de prueba', (tester) async {
    await tester.pumpWidget(const App());
    expect(find.text('English Lessons'), findsOneWidget);
    expect(find.text('Match the words'), findsOneWidget);
  });

  test('El catálogo trae las 20 actividades sin códigos repetidos', () {
    expect(catalogo.length, 20);
    expect(catalogo.map((a) => a.codigo).toSet().length, 20);
  });
}
