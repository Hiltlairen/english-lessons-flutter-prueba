// ============================================================
// PRIMITIVA — Laberinto de palabras (15-laberinto-palabras)
// ============================================================
// Estilo Helltaker: hay que pisar cada palabra en el orden de la
// oración, con pasos y tiempo limitados por piso. Pisar un distractor
// o quedarse sin pasos/tiempo cuesta una vida y pasa al piso
// siguiente. Sin vidas, se cierra la actividad.
// Movimiento: tocar una casilla vecina o deslizar el dedo (swipe).
// ============================================================
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../logica/generadores.dart';
import '../comun.dart';

enum _Fase { jugando, pisoOk, pisoPerdido, fin }

class Laberinto extends StatefulWidget {
  const Laberinto({
    super.key,
    required this.niveles,
    required this.onFinish,
    this.onSalir,
    this.vidasIniciales = 3,
    this.tiempoPorNivel = 40,
  });

  final List<NivelLaberinto> niveles;
  final int vidasIniciales;
  final int tiempoPorNivel;
  final AlTerminar onFinish;
  final VoidCallback? onSalir;

  @override
  State<Laberinto> createState() => _LaberintoState();
}

class _LaberintoState extends State<Laberinto> {
  int _nivel = 0;
  late int _vidas = widget.vidasIniciales;
  final _pisos = <bool>[];
  late MapaLaberinto _mapa;
  late (int, int) _pos;
  late int _pasos;
  int _siguiente = 0;
  late int _tiempo;
  _Fase _fase = _Fase.jugando;
  String? _mensaje;
  Timer? _reloj;

  @override
  void initState() {
    super.initState();
    _cargarPiso();
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  void _cargarPiso() {
    _mapa = construirLaberinto(widget.niveles[_nivel]);
    _pos = _mapa.inicio;
    _pasos = _mapa.presupuestoPasos;
    _siguiente = 0;
    _tiempo = widget.tiempoPorNivel;
    _fase = _Fase.jugando;
    _mensaje = null;
    _reloj?.cancel();
    _reloj = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_fase != _Fase.jugando) return;
      setState(() => _tiempo--);
      if (_tiempo <= 0) _perderVida('Se acabó el tiempo de este piso.');
    });
  }

  void _terminar(List<bool> pisos) {
    _reloj?.cancel();
    widget.onFinish(pct(pisos.where((p) => p).length, widget.niveles.length), {'pisos': pisos});
  }

  void _avanzar(bool gano) {
    _pisos.add(gano);
    if (_nivel + 1 >= widget.niveles.length) {
      _terminar(_pisos);
    } else {
      setState(() {
        _nivel++;
        _cargarPiso();
      });
    }
  }

  void _perderVida(String motivo) {
    _reloj?.cancel();
    setState(() {
      _vidas--;
      _mensaje = motivo;
      _fase = _vidas <= 0 ? _Fase.fin : _Fase.pisoPerdido;
    });
  }

  void _moverA(int f, int c) {
    if (_fase != _Fase.jugando) return;
    if ((f - _pos.$1).abs() + (c - _pos.$2).abs() != 1) return; // 1 casilla ortogonal
    if (f < 0 || f >= _mapa.filas || c < 0 || c >= _mapa.columnas) return;
    final tipo = _mapa.tipos[f][c];
    if (tipo == TipoCelda.obstaculo) return;

    setState(() {
      _pos = (f, c);
      _pasos--;
    });
    if (tipo == TipoCelda.distractor) {
      _perderVida('Pisaste una palabra que no es de la oración.');
      return;
    }
    if (tipo == TipoCelda.objetivo) {
      final obj = _mapa.objetivos.where((o) => o.fila == f && o.columna == c).firstOrNull;
      if (obj != null && obj.indice == _siguiente) {
        setState(() => _siguiente++);
        if (_siguiente >= _mapa.objetivos.length) {
          _reloj?.cancel();
          setState(() {
            _fase = _Fase.pisoOk;
            _mensaje = '¡Oración completa!';
          });
          return;
        }
      }
    }
    if (_pasos <= 0) _perderVida('Te quedaste sin pasos.');
  }

  void _swipe(DragEndDetails d) {
    final v = d.velocity.pixelsPerSecond;
    if (v.distance < 150) return;
    if (v.dx.abs() > v.dy.abs()) {
      _moverA(_pos.$1, _pos.$2 + (v.dx > 0 ? 1 : -1));
    } else {
      _moverA(_pos.$1 + (v.dy > 0 ? 1 : -1), _pos.$2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nivel = widget.niveles[_nivel];
    final ultimo = _nivel + 1 >= widget.niveles.length;
    final parcial = [for (final o in _mapa.objetivos) o.indice < _siguiente ? o.palabra : '▢'].join(' ');

    return Marco(
      clave: _nivel,
      top: BarraSuperior(hechos: _pisos.where((p) => p).length, total: widget.niveles.length, onSalir: widget.onSalir),
      pie: Pie(secundario: TextButton(onPressed: () => _terminar(_pisos), child: const Text('Terminar ahora'))),
      hoja: _fase == _Fase.jugando
          ? null
          : HojaFeedback(
              ok: _fase == _Fase.pisoOk,
              titulo: switch (_fase) {
                _Fase.fin => 'Sin vidas — fin del juego',
                _Fase.pisoOk => '¡Oración completa!',
                _ => 'Piso perdido',
              },
              significado: _mensaje,
              detalle: _fase != _Fase.fin ? 'Oración: ${nivel.oracion}' : null,
              textoBoton: _fase == _Fase.fin ? 'Ver resultado' : (ultimo ? 'Terminar' : 'Siguiente piso'),
              onContinuar: () => _fase == _Fase.fin ? _terminar([..._pisos, false]) : _avanzar(_fase == _Fase.pisoOk),
            ),
      cabecera: Encabezado(
          etiqueta: 'Piso ${_nivel + 1} de ${widget.niveles.length}', icono: '🗼', titulo: 'Recorre la oración en orden'),
      escenario: GestureDetector(
        onPanEnd: _swipe,
        child: LayoutBuilder(builder: (context, cons) {
          final lado = min(cons.maxWidth / _mapa.columnas, cons.maxHeight / _mapa.filas);
          return Center(
            child: SizedBox(
              width: lado * _mapa.columnas,
              height: lado * _mapa.filas,
              child: Stack(children: [
                for (var r = 0; r < _mapa.filas; r++)
                  for (var c = 0; c < _mapa.columnas; c++)
                    Positioned(
                      left: c * lado,
                      top: r * lado,
                      width: lado,
                      height: lado,
                      child: _CeldaLab(
                        tipo: _mapa.tipos[r][c],
                        objetivo: _mapa.objetivos.where((o) => o.fila == r && o.columna == c).firstOrNull,
                        distractor: _mapa.distractores.where((o) => o.fila == r && o.columna == c).firstOrNull,
                        siguiente: _siguiente,
                        onTap: () => _moverA(r, c),
                      ),
                    ),
                // El personaje se desliza entre casillas.
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  left: _pos.$2 * lado,
                  top: _pos.$1 * lado,
                  width: lado,
                  height: lado,
                  child: IgnorePointer(
                    child: Center(child: Text('🧍', style: TextStyle(fontSize: lado * .55))),
                  ),
                ),
              ]),
            ),
          );
        }),
      ),
      cuerpo: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          Text('${'❤️' * max(0, _vidas)}${'🖤' * max(0, widget.vidasIniciales - _vidas)}'),
          Text('👣 ${max(0, _pasos)}', style: const TextStyle(fontWeight: FontWeight.w700)),
          Text('⏱ ${_tiempo}s',
              style: TextStyle(fontWeight: FontWeight.w700, color: _tiempo <= 10 ? Paleta.mal : Paleta.tinta)),
        ]),
        const SizedBox(height: 8),
        Text(parcial, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        Text('— ${nivel.traduccion}', textAlign: TextAlign.center, style: const TextStyle(color: Paleta.suave)),
        const Pista('Toca una casilla vecina o desliza el dedo hacia donde quieres ir.'),
      ],
    );
  }
}

class _CeldaLab extends StatelessWidget {
  const _CeldaLab({required this.tipo, this.objetivo, this.distractor, required this.siguiente, required this.onTap});
  final TipoCelda tipo;
  final CeldaPalabra? objetivo;
  final CeldaPalabra? distractor;
  final int siguiente;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hallado = objetivo != null && objetivo!.indice < siguiente;
    final palabra = objetivo?.palabra ?? distractor?.palabra;
    // Distractores y objetivos se ven IGUAL: hay que leer la oración.
    final fondo = switch (tipo) {
      TipoCelda.obstaculo => const Color(0xFF6B7280),
      _ when hallado => Paleta.okFondo,
      TipoCelda.objetivo || TipoCelda.distractor => const Color(0xFFFEF3C7),
      _ => const Color(0xFFF3F4F6),
    };
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: fondo,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Center(
            child: tipo == TipoCelda.obstaculo
                ? const Text('🧱', style: TextStyle(fontSize: 26))
                : palabra == null
                    ? null
                    : Padding(
                        padding: const EdgeInsets.all(2),
                        child: FittedBox(
                          child: Text(palabra,
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, color: hallado ? Paleta.ok : Paleta.tinta)),
                        ),
                      ),
          ),
        ),
      ),
    );
  }
}
