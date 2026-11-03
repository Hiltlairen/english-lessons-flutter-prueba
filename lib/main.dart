// ============================================================
// Prototipo Flutter — actividades de English Lessons (modo prueba)
// ============================================================
// Menú inicial → elegir actividad → jugarla con preguntas y
// respuestas fijas → ver la nota. Sin servidor ni cuentas.
// ============================================================
import 'package:flutter/material.dart';

import 'actividades/comun.dart';
import 'pantallas/menu.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'English Lessons',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Paleta.marca),
        scaffoldBackgroundColor: Paleta.fondo,
        useMaterial3: true,
      ),
      home: const MenuPantalla(),
    );
  }
}
