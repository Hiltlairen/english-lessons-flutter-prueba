// ============================================================
// actividad.dart — Ejecuta una actividad y muestra el resultado
// ============================================================
// Equivale a ActivityRunner (modo simple): cintillos opcionales
// (anuncio, llamada), instrucciones y la primitiva. Al terminar se
// muestra la nota con opción de repetir o volver al menú.
// ============================================================
import 'package:flutter/material.dart';

import '../actividades/catalogo.dart';
import '../actividades/comun.dart';

class ActividadPantalla extends StatefulWidget {
  const ActividadPantalla({super.key, required this.actividad});
  final Actividad actividad;

  @override
  State<ActividadPantalla> createState() => _ActividadPantallaState();
}

class _ActividadPantallaState extends State<ActividadPantalla> {
  bool _verTranscripcion = false;

  @override
  void initState() {
    super.initState();
    // El anuncio (14) se lee en voz alta apenas se abre la actividad.
    final anuncio = widget.actividad.anuncio;
    if (anuncio != null) Voz.hablar(anuncio);
  }

  @override
  void dispose() {
    Voz.callar();
    super.dispose();
  }

  Future<void> _salir() async {
    if (await confirmarSalida(context) && mounted) Navigator.of(context).pop();
  }

  void _terminar(int? puntaje, Map<String, dynamic> respuestas) {
    Voz.callar();
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => ResultadoPantalla(actividad: widget.actividad, puntaje: puntaje),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.actividad;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _salir();
      },
      child: Scaffold(
        backgroundColor: Paleta.fondo,
        body: SafeArea(
          child: Column(children: [
            if (a.llamada != null)
              Container(
                width: double.infinity,
                color: const Color(0xFF065F46),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: Row(children: [
                  const Icon(Icons.call, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Llamada en curso · ${a.llamada}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ]),
              ),
            if (a.anuncio != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(children: [
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Voz.hablar(a.anuncio!),
                        icon: const Text('🔊'),
                        label: const Text('Repetir el anuncio'),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _verTranscripcion = !_verTranscripcion),
                      child: Text(_verTranscripcion ? 'Ocultar texto' : 'Ver texto'),
                    ),
                  ]),
                  if (_verTranscripcion) Pista(a.anuncio!),
                ]),
              ),
            if (a.instrucciones != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: Text(a.instrucciones!,
                    textAlign: TextAlign.center, style: const TextStyle(color: Paleta.suave, fontSize: 13)),
              ),
            Expanded(child: a.construir(_terminar, _salir)),
          ]),
        ),
      ),
    );
  }
}

class ResultadoPantalla extends StatelessWidget {
  const ResultadoPantalla({super.key, required this.actividad, required this.puntaje});
  final Actividad actividad;
  final int? puntaje;

  @override
  Widget build(BuildContext context) {
    final p = puntaje;
    final (emoji, mensaje) = p == null
        ? ('📝', 'Entregado. En la app real lo revisa la IA y el docente confirma la nota.')
        : p >= 90
            ? ('🏆', '¡Excelente!')
            : p >= 60
                ? ('👏', '¡Bien hecho!')
                : ('💪', 'Sigue practicando');

    return Scaffold(
      backgroundColor: Paleta.fondo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const Spacer(),
            Text(emoji, style: const TextStyle(fontSize: 72)),
            const SizedBox(height: 12),
            Text(actividad.titulo, style: const TextStyle(fontSize: 18, color: Paleta.suave)),
            const SizedBox(height: 8),
            if (p != null)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: p.toDouble()),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOut,
                builder: (_, v, _) => Text('${v.round()}',
                    style: TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.w900,
                        color: p >= 60 ? Paleta.ok : Paleta.mal)),
              ),
            if (p != null) const Text('de 100 puntos', style: TextStyle(color: Paleta.suave)),
            const SizedBox(height: 12),
            Text(mensaje, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const Spacer(),
            BotonCTA(
              texto: 'Repetir',
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => ActividadPantalla(actividad: actividad)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('VOLVER AL MENÚ', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
