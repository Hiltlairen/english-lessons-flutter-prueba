// ============================================================
// PRIMITIVA — Tiro a la canasta (20-basquetbol)
// ============================================================
// La palabra a traducir está en el tablero. Abajo hay 3 posiciones de
// tiro, cada una con una traducción. El balón sale DESDE esa posición:
// si era la correcta encesta; si no, pega en el aro y se va a un lado.
// Coordenadas en % de la cancha; el vuelo es una Bézier cuadrática.
// ============================================================
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../comun.dart';
import 'quiz.dart' show Opcion;

class Tiro {
  const Tiro(this.palabra, this.opciones, {this.lang = 'es-ES'});
  final String palabra;
  final List<Opcion> opciones;
  final String lang;
}

const _aro = Offset(50, 31);
const _spots = [18.0, 50.0, 82.0];
const _spotY = 80.0;
const _duracion = 1500;
const _llegada = .68;

Offset _bezier(Offset p0, Offset c, Offset p2, double t) {
  final u = 1 - t;
  return p0 * (u * u) + c * (2 * u * t) + p2 * (t * t);
}

/// Puntos (en %) del recorrido: vuelo (antes de _llegada) y caída/rebote.
List<(Offset, double)> _trayectoria(int spot, bool acierto) {
  final ini = Offset(_spots[spot], _spotY - 6);
  final vuelo = <Offset>[];
  final caida = <Offset>[];
  if (acierto) {
    final fin = Offset(_aro.dx, _aro.dy - 1);
    final c = Offset((ini.dx + fin.dx) / 2, -14);
    for (var k = 0; k <= 26; k++) {
      vuelo.add(_bezier(ini, c, fin, k / 26));
    }
    for (final y in const <double>[36, 43, 52, 62, 70, 64, 70]) {
      caida.add(Offset(_aro.dx, y));
    }
  } else {
    final lado = spot == 0 ? -1 : spot == 2 ? 1 : (Random().nextBool() ? 1 : -1);
    final fin = Offset(_aro.dx + lado * 9, _aro.dy - 2);
    final c = Offset((ini.dx + fin.dx) / 2, -12);
    for (var k = 0; k <= 26; k++) {
      vuelo.add(_bezier(ini, c, fin, k / 26));
    }
    final salida = Offset(_aro.dx + lado * 58, 96);
    final c2 = Offset(_aro.dx + lado * 30, 4);
    for (var k = 1; k <= 14; k++) {
      caida.add(_bezier(fin, c2, salida, k / 14));
    }
  }
  return [
    for (var k = 0; k < vuelo.length; k++) (vuelo[k], _llegada * k / (vuelo.length - 1)),
    for (var k = 0; k < caida.length; k++) (caida[k], _llegada + (1 - _llegada) * (k + 1) / caida.length),
  ];
}

class Basquet extends StatefulWidget {
  const Basquet({super.key, required this.tiros, required this.onFinish, this.onSalir});

  final List<Tiro> tiros;
  final AlTerminar onFinish;
  final VoidCallback? onSalir;

  @override
  State<Basquet> createState() => _BasquetState();
}

class _BasquetState extends State<Basquet> with SingleTickerProviderStateMixin {
  late final AnimationController _anim =
      AnimationController(vsync: this, duration: const Duration(milliseconds: _duracion));
  late final List<List<Opcion>> _opciones = [for (final t in widget.tiros) barajar(t.opciones)];
  int _i = 0;
  int? _lanzado;
  bool? _ok;
  String? _efecto; // swish | clank
  int _aciertos = 0;
  int _combo = 0;
  final _respuestas = <Map<String, dynamic>>[];
  List<(Offset, double)> _pts = [];
  final _timers = <Timer>[];

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _anim.dispose();
    super.dispose();
  }

  void _lanzar(int idx) {
    if (_lanzado != null) return;
    final op = _opciones[_i][idx];
    final ok = op.correcta;
    setState(() {
      _lanzado = idx;
      _pts = _trayectoria(idx, ok);
    });
    _anim.forward(from: 0);
    _timers
      ..add(Timer(Duration(milliseconds: (_duracion * _llegada).round()),
          () => setState(() => _efecto = ok ? 'swish' : 'clank')))
      ..add(Timer(const Duration(milliseconds: _duracion), () {
        setState(() {
          _ok = ok;
          if (ok) _aciertos++;
          _combo = ok ? _combo + 1 : 0;
          _respuestas.add({'i': _i, 'opcion': op.texto});
        });
      }));
  }

  void _continuar() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    _anim.reset();
    if (_i + 1 >= widget.tiros.length) {
      widget.onFinish(pct(_aciertos, widget.tiros.length), {'items': _respuestas});
    } else {
      setState(() {
        _i++;
        _lanzado = null;
        _ok = null;
        _efecto = null;
      });
    }
  }

  /// Posición del balón (en %) para un instante t ∈ [0,1].
  Offset _posBalon(double t) {
    if (_pts.isEmpty) return Offset.zero;
    for (var k = 1; k < _pts.length; k++) {
      final (p1, o1) = _pts[k];
      if (t <= o1) {
        final (p0, o0) = _pts[k - 1];
        final f = o1 == o0 ? 1.0 : (t - o0) / (o1 - o0);
        return Offset.lerp(p0, p1, f)!;
      }
    }
    return _pts.last.$1;
  }

  @override
  Widget build(BuildContext context) {
    final tiro = widget.tiros[_i];
    final opciones = _opciones[_i];
    final correcta = opciones.firstWhere((o) => o.correcta);

    return Marco(
      clave: _i,
      top: BarraSuperior(hechos: _i, total: widget.tiros.length, combo: _combo, onSalir: widget.onSalir),
      pie: const Pie(secundario: Pista('Lanza desde la posición con la traducción correcta')),
      hoja: _ok == null
          ? null
          : HojaFeedback(
              ok: _ok!,
              titulo: _ok! ? '¡Canasta!' : '¡Tiro fallado!',
              significado: _ok! ? '${tiro.palabra} → ${correcta.texto}' : correcta.texto,
              textoBoton: _i + 1 >= widget.tiros.length ? 'Terminar' : 'Siguiente tiro',
              onContinuar: _continuar,
            ),
      cabecera: const Encabezado(etiqueta: 'Básquet', icono: '🏀', titulo: '¿Desde dónde lanzas?'),
      escenario: LayoutBuilder(builder: (context, cons) {
        final w = cons.maxWidth, h = cons.maxHeight;
        Offset px(Offset p) => Offset(p.dx / 100 * w, p.dy / 100 * h);
        final aro = px(_aro);
        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6), Color(0xFFD97706), Color(0xFFB45309)],
                stops: [0, .45, .46, 1],
              ),
            ),
            child: Stack(clipBehavior: Clip.none, children: [
              // Tablero con la palabra
              Positioned(
                left: w * .2,
                right: w * .2,
                top: h * .03,
                height: h * .22,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEA580C), width: 3),
                  ),
                  alignment: Alignment.center,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Flexible(
                      child: FittedBox(
                        child: Text(tiro.palabra,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                      ),
                    ),
                    BotonAltavoz(tamano: 18, onTap: () => Voz.hablar(tiro.palabra, lang: tiro.lang)),
                  ]),
                ),
              ),
              // Aro + red
              Positioned(
                left: aro.dx - w * .1,
                top: aro.dy - 4,
                width: w * .2,
                child: Column(children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: _efecto == 'clank' ? Colors.red : const Color(0xFFEA580C),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: _efecto == 'swish' ? 30 : 22,
                    margin: EdgeInsets.symmetric(horizontal: w * .02),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white70, width: 1.5),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                    ),
                  ),
                ]),
              ),
              if (_efecto == 'swish')
                Positioned(
                  left: aro.dx + w * .12,
                  top: aro.dy - 10,
                  child: const Text('+2',
                      style: TextStyle(color: Colors.yellowAccent, fontSize: 24, fontWeight: FontWeight.w900)),
                ),
              // Posiciones de tiro
              for (var k = 0; k < 3; k++)
                Positioned(
                  left: _spots[k] / 100 * w - w * .15,
                  top: _spotY / 100 * h - 30,
                  width: w * .3,
                  child: GestureDetector(
                    onTap: () => _lanzar(k),
                    child: Column(children: [
                      Opacity(
                        opacity: _lanzado == k ? 0 : 1,
                        child: const Text('🏀', style: TextStyle(fontSize: 30)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        decoration: BoxDecoration(
                          color: _lanzado == null
                              ? Colors.white
                              : _lanzado == k
                                  ? (_ok == null
                                      ? Paleta.selFondo
                                      : (opciones[k].correcta ? Paleta.okFondo : Paleta.malFondo))
                                  : Colors.white54,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(opciones[k].texto,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      ),
                    ]),
                  ),
                ),
              // Balón en vuelo
              if (_lanzado != null)
                AnimatedBuilder(
                  animation: _anim,
                  builder: (_, _) {
                    final t = _anim.value;
                    final p = px(_posBalon(t));
                    final escala = t < _llegada ? 1 - .32 * (t / _llegada) : .68;
                    return Positioned(
                      left: p.dx - 18,
                      top: p.dy - 18,
                      child: Transform.rotate(
                        angle: t * 12,
                        child: Transform.scale(scale: escala, child: const Text('🏀', style: TextStyle(fontSize: 32))),
                      ),
                    );
                  },
                ),
            ]),
          ),
        );
      }),
      cuerpo: const [],
    );
  }
}
