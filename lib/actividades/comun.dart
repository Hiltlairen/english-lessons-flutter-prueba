// ============================================================
// comun.dart — Piezas de interfaz que comparten las actividades
// ============================================================
// Equivale a la parte "PIEZAS DE INTERFAZ COMPARTIDAS" de
// ActivityRunner.jsx: todas las actividades se dibujan dentro del
// mismo MARCO de 3 zonas:
//
//   ┌───────────────────────────────────────┐
//   │  ✕   ▓▓▓▓▓░░░░░░░░░░░░░░░   ⚡ 12      │  ← BarraSuperior
//   ├───────────────────────────────────────┤
//   │  ▣ ETIQUETA                           │  ← Encabezado
//   │  Título grande                        │
//   │  … cuerpo de la actividad …           │
//   ├───────────────────────────────────────┤
//   │        [    COMPROBAR    ]            │  ← Pie (fijo)
//   └───────────────────────────────────────┘
//
// El flujo es SIEMPRE: elegir → COMPROBAR → hoja de feedback →
// CONTINUAR. Nunca avanza solo.
// ============================================================
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

// ── Paleta (la misma de ActivityRunner.css) ────────────────
class Paleta {
  static const fondo = Color(0xFFF8F9FB);
  static const superficie = Colors.white;
  static const tinta = Color(0xFF111827);
  static const suave = Color(0xFF6B7280);
  static const linea = Color(0xFFE5E7EB);
  static const marca = Color(0xFF2563EB);
  static const marcaOscura = Color(0xFF1D4ED8);
  static const ok = Color(0xFF16A34A);
  static const okFondo = Color(0xFFDCFCE7);
  static const mal = Color(0xFFDC2626);
  static const malFondo = Color(0xFFFEE2E2);
  static const selFondo = Color(0xFFDBEAFE);
}

/// Lo que devuelve cada actividad al terminar.
/// `puntaje` null = la corrige otra persona (redacción).
typedef AlTerminar = void Function(int? puntaje, Map<String, dynamic> respuestas);

int pct(int ok, int total) => total == 0 ? 0 : (ok * 100 / total).round();

final _azar = Random();

/// Fisher–Yates: cada orden es igual de probable.
List<T> barajar<T>(List<T> lista) {
  final a = [...lista];
  for (var i = a.length - 1; i > 0; i--) {
    final j = _azar.nextInt(i + 1);
    final t = a[i];
    a[i] = a[j];
    a[j] = t;
  }
  return a;
}

// ── Texto a voz (reemplaza a speechSynthesis del navegador) ─
class Voz {
  Voz._();
  static final FlutterTts _tts = FlutterTts();

  /// `velocidad` usa la escala del navegador (1 = normal); flutter_tts
  /// en Android usa 0.5 como velocidad normal, por eso se divide.
  static Future<void> hablar(String texto, {String lang = 'en-US', double velocidad = 0.9}) async {
    try {
      await _tts.stop();
      await _tts.setLanguage(lang);
      await _tts.setSpeechRate((velocidad * 0.5).clamp(0.1, 1.0));
      await _tts.speak(texto);
    } catch (_) {
      // Si el dispositivo no tiene motor de voz, el texto igual se ve.
    }
  }

  static Future<void> callar() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}

// ── Barra superior: salir · progreso · restantes · combo ───
class BarraSuperior extends StatelessWidget {
  const BarraSuperior({super.key, required this.hechos, required this.total, this.combo = 0, this.onSalir});

  final int hechos;
  final int total;
  final int combo;
  final VoidCallback? onSalir;

  @override
  Widget build(BuildContext context) {
    final avance = total == 0 ? 0.0 : (hechos / total).clamp(0.0, 1.0);
    final restantes = max(0, total - hechos);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
      child: Column(
        children: [
          if (combo >= 2)
            Align(
              alignment: Alignment.centerRight,
              child: Text('COMBO x$combo',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFEA580C), fontSize: 12)),
            ),
          Row(
            children: [
              IconButton(
                onPressed: onSalir,
                icon: const Icon(Icons.close),
                color: Paleta.suave,
                tooltip: 'Salir',
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: avance),
                    duration: const Duration(milliseconds: 300),
                    builder: (_, v, _) => LinearProgressIndicator(
                      value: v,
                      minHeight: 14,
                      backgroundColor: Paleta.linea,
                      color: Paleta.ok,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('⚡$restantes', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFF59E0B))),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Etiqueta pequeña + título grande ───────────────────────
class Encabezado extends StatelessWidget {
  const Encabezado({super.key, this.etiqueta, this.icono = '✦', this.titulo});

  final String? etiqueta;
  final String icono;
  final String? titulo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (etiqueta != null)
            Text('$icono  ${etiqueta!.toUpperCase()}',
                style: const TextStyle(
                    color: Color(0xFF9333EA), fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: .8)),
          if (titulo != null) ...[
            const SizedBox(height: 4),
            Text(titulo!,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Paleta.tinta)),
          ],
        ],
      ),
    );
  }
}

// ── Personaje + globo de diálogo con botón de audio ────────
class Escena extends StatelessWidget {
  const Escena({super.key, required this.texto, this.lang = 'en-US', this.conLento = false, this.personaje = '🧑‍🏫'});

  final String texto;
  final String lang;
  final bool conLento;
  final String? personaje;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (personaje != null) Text(personaje!, style: const TextStyle(fontSize: 52)),
        const SizedBox(width: 8),
        Flexible(
          child: Globo(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                BotonAltavoz(onTap: () => Voz.hablar(texto, lang: lang)),
                if (conLento) BotonAltavoz(icono: '🐢', onTap: () => Voz.hablar(texto, lang: lang, velocidad: .55)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(texto,
                      style: const TextStyle(
                          fontSize: 17,
                          decoration: TextDecoration.underline,
                          decorationStyle: TextDecorationStyle.dotted,
                          decorationColor: Paleta.suave)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class Globo extends StatelessWidget {
  const Globo({super.key, required this.child, this.color = Paleta.superficie, this.padding});
  final Widget child;
  final Color color;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Paleta.linea, width: 2),
      ),
      child: child,
    );
  }
}

class BotonAltavoz extends StatelessWidget {
  const BotonAltavoz({super.key, required this.onTap, this.icono = '🔊', this.tamano = 20});
  final VoidCallback onTap;
  final String icono;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Text(icono, style: TextStyle(fontSize: tamano)),
      ),
    );
  }
}

// ── Botón principal ─────────────────────────────────────────
enum Tono { marca, ok, mal }

class BotonCTA extends StatelessWidget {
  const BotonCTA({super.key, required this.texto, this.onPressed, this.tono = Tono.marca});

  final String texto;
  final VoidCallback? onPressed;
  final Tono tono;

  @override
  Widget build(BuildContext context) {
    final color = switch (tono) {
      Tono.ok => Paleta.ok,
      Tono.mal => Paleta.mal,
      Tono.marca => Paleta.marca,
    };
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: Paleta.linea,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(texto.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: .8)),
      ),
    );
  }
}

// ── Hoja de resultado que sube desde abajo ─────────────────
class HojaFeedback extends StatelessWidget {
  const HojaFeedback({
    super.key,
    required this.ok,
    required this.onContinuar,
    this.titulo,
    this.significado,
    this.detalle,
    this.textoBoton = 'Continuar',
  });

  final bool ok;
  final String? titulo;
  final String? significado;
  final String? detalle;
  final String textoBoton;
  final VoidCallback onContinuar;

  @override
  Widget build(BuildContext context) {
    final color = ok ? Paleta.ok : Paleta.mal;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => FractionalTranslation(translation: Offset(0, v), child: child),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: BoxDecoration(
          color: ok ? Paleta.okFondo : Paleta.malFondo,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: const [BoxShadow(blurRadius: 16, color: Color(0x22000000))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: color,
                child: Icon(ok ? Icons.check : Icons.close, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(titulo ?? (ok ? '¡Buen trabajo!' : 'Respuesta incorrecta'),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
              ),
            ]),
            if (significado != null) ...[
              const SizedBox(height: 10),
              Text(ok ? 'Significado:' : 'Respuesta correcta:',
                  style: TextStyle(fontWeight: FontWeight.w800, color: color)),
              Text(significado!, style: TextStyle(color: color, fontSize: 16)),
            ],
            if (detalle != null) ...[
              const SizedBox(height: 6),
              Text(detalle!, style: TextStyle(color: color.withValues(alpha: .85))),
            ],
            const SizedBox(height: 14),
            BotonCTA(texto: textoBoton, tono: ok ? Tono.ok : Tono.mal, onPressed: onContinuar),
          ],
        ),
      ),
    );
  }
}

// ── Marco: une las 3 zonas en el mismo esqueleto ───────────
// `clave` cambia con cada ítem: el cuerpo entra deslizándose.
// `escenario` (opcional) es el elemento visual dominante (mapa,
// laberinto, cancha): ocupa el espacio flexible y el cuerpo queda abajo.
class Marco extends StatelessWidget {
  const Marco({
    super.key,
    required this.top,
    required this.cuerpo,
    this.pie,
    this.hoja,
    this.clave,
    this.cabecera,
    this.escenario,
  });

  final Widget top;
  final List<Widget> cuerpo;
  final Widget? pie;
  final Widget? hoja;
  final Object? clave;
  final Widget? cabecera;
  final Widget? escenario;

  @override
  Widget build(BuildContext context) {
    final contenido = TweenAnimationBuilder<double>(
      key: ValueKey(clave),
      tween: Tween(begin: 1, end: 0),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(
        opacity: 1 - v,
        child: Transform.translate(offset: Offset(24 * v, 0), child: child),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: cuerpo),
    );

    final columna = escenario == null
        ? Column(children: [
            top,
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: contenido,
              ),
            ),
            ?pie,
          ])
        : Column(children: [
            top,
            if (cabecera != null)
              Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 0), child: cabecera),
            Expanded(
              flex: 6,
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: escenario),
            ),
            Flexible(
              flex: 4,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: contenido,
              ),
            ),
            ?pie,
          ]);

    return Stack(
      children: [
        Positioned.fill(child: columna),
        if (hoja != null) ...[
          const Positioned.fill(child: ModalBarrier(color: Color(0x33000000), dismissible: false)),
          Positioned(left: 0, right: 0, bottom: 0, child: hoja!),
        ],
      ],
    );
  }
}

class Pie extends StatelessWidget {
  const Pie({super.key, this.child, this.secundario});
  final Widget? child;
  final Widget? secundario;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Paleta.linea, width: 2))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (secundario != null) ...[secundario!, if (child != null) const SizedBox(height: 8)],
        ?child,
      ]),
    );
  }
}

// ── Botón de opción (quiz, mapa…) ──────────────────────────
enum EstadoOpcion { normal, sel, ok, mal, gris }

class BotonOpcion extends StatelessWidget {
  const BotonOpcion({super.key, required this.child, this.estado = EstadoOpcion.normal, this.onTap});

  final Widget child;
  final EstadoOpcion estado;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (borde, fondo, texto) = colorEstado(estado);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Material(
        color: fondo,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: borde, width: 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: DefaultTextStyle.merge(
              style: TextStyle(fontSize: 16, color: texto, fontWeight: FontWeight.w600),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

(Color borde, Color fondo, Color texto) colorEstado(EstadoOpcion e) => switch (e) {
      EstadoOpcion.sel => (Paleta.marca, Paleta.selFondo, Paleta.marcaOscura),
      EstadoOpcion.ok => (Paleta.ok, Paleta.okFondo, Paleta.ok),
      EstadoOpcion.mal => (Paleta.mal, Paleta.malFondo, Paleta.mal),
      EstadoOpcion.gris => (Paleta.linea, Paleta.superficie, Paleta.suave),
      EstadoOpcion.normal => (Paleta.linea, Paleta.superficie, Paleta.tinta),
    };

/// Ficha chica (ordenar, rompecabezas…).
class Ficha extends StatelessWidget {
  const Ficha({super.key, required this.child, this.onTap, this.estado = EstadoOpcion.normal});
  final Widget child;
  final VoidCallback? onTap;
  final EstadoOpcion estado;

  @override
  Widget build(BuildContext context) {
    final (borde, fondo, texto) = colorEstado(estado);
    return Material(
      color: fondo,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: borde, width: 2)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: DefaultTextStyle.merge(
            style: TextStyle(fontSize: 15, color: texto, fontWeight: FontWeight.w600),
            child: child,
          ),
        ),
      ),
    );
  }
}

class Pista extends StatelessWidget {
  const Pista(this.texto, {super.key});
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(texto, style: const TextStyle(color: Paleta.suave, fontSize: 14)),
      );
}

/// Diálogo "¿Salir de la actividad?".
Future<bool> confirmarSalida(BuildContext context) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('¿Salir de la actividad?'),
      content: const Text('Perderás el avance de esta actividad.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Seguir')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Salir')),
      ],
    ),
  );
  return r ?? false;
}
