// ============================================================
// PRIMITIVA — Sopa de letras (04-sopa-letras)
// ============================================================
// Un solo GestureDetector para toda la cuadrícula (no 144 botones):
//   · Arrastrar de la primera a la última letra (la selección se
//     "endereza" a una línea recta horizontal/vertical/diagonal).
//   · Alternativa por toques: tocar la primera letra y luego la última.
// ============================================================
import 'dart:math';

import 'package:flutter/material.dart';

import '../../logica/generadores.dart';
import '../comun.dart';

class SopaLetras extends StatefulWidget {
  const SopaLetras({super.key, required this.palabras, required this.onFinish, this.onSalir, this.filas = 10, this.columnas = 10});

  final List<PalabraSopa> palabras;
  final int filas;
  final int columnas;
  final AlTerminar onFinish;
  final VoidCallback? onSalir;

  @override
  State<SopaLetras> createState() => _SopaLetrasState();
}

class _SopaLetrasState extends State<SopaLetras> {
  late final Sopa _sopa = construirSopa(widget.palabras, filas: widget.filas, columnas: widget.columnas);
  final _encontradas = <String>[];
  List<(int, int)> _seleccion = [];
  (int, int)? _inicioArrastre;
  (int, int)? _inicioToque;
  Offset? _bajada;
  bool _listo = false;

  Map<String, dynamic> get _respuestas =>
      {'encontradas': _encontradas, 'colocadas': _sopa.colocaciones.map((c) => c.palabra).toList()};

  /// Celdas en línea recta entre dos puntos (o null si no están alineadas).
  List<(int, int)>? _linea((int, int) a, (int, int) b) {
    final (r1, c1) = a;
    final (r2, c2) = b;
    if (r1 != r2 && c1 != c2 && (r2 - r1).abs() != (c2 - c1).abs()) return null;
    final dr = (r2 - r1).sign, dc = (c2 - c1).sign;
    final pasos = max((r2 - r1).abs(), (c2 - c1).abs());
    return [for (var i = 0; i <= pasos; i++) (r1 + dr * i, c1 + dc * i)];
  }

  void _intentar(List<(int, int)> celdas) {
    final texto = celdas.map((p) => _sopa.grid[p.$1][p.$2]).join();
    final alReves = texto.split('').reversed.join();
    for (final w in _sopa.colocaciones) {
      if (!_encontradas.contains(w.palabra) && (w.palabra == texto || w.palabra == alReves)) {
        setState(() => _encontradas.add(w.palabra));
        if (_encontradas.length == _sopa.colocaciones.length) {
          Future.delayed(const Duration(milliseconds: 350), () {
            if (mounted) setState(() => _listo = true);
          });
        }
        return;
      }
    }
  }

  (int, int)? _celdaEn(Offset p, double lado) {
    final c = (p.dx / lado).floor(), r = (p.dy / lado).floor();
    if (r < 0 || r >= widget.filas || c < 0 || c >= widget.columnas) return null;
    return (r, c);
  }

  void _toque((int, int) celda) {
    if (_inicioToque == null) {
      setState(() => _inicioToque = celda);
      return;
    }
    if (_inicioToque == celda) {
      setState(() => _inicioToque = null);
      return;
    }
    final l = _linea(_inicioToque!, celda);
    if (l != null) _intentar(l);
    setState(() => _inicioToque = l == null ? celda : null);
  }

  @override
  Widget build(BuildContext context) {
    final halladas = <(int, int)>{
      for (final w in _sopa.colocaciones)
        if (_encontradas.contains(w.palabra)) ...w.celdas
    };
    final total = _sopa.colocaciones.length;

    return Marco(
      top: BarraSuperior(hechos: _encontradas.length, total: total, onSalir: widget.onSalir),
      pie: Pie(
        secundario: TextButton(
          onPressed: () => widget.onFinish(pct(_encontradas.length, total), _respuestas),
          child: const Text('Terminar ahora'),
        ),
        child: BotonCTA(texto: 'Comprobar', onPressed: _listo ? () => widget.onFinish(100, _respuestas) : null),
      ),
      hoja: !_listo
          ? null
          : HojaFeedback(
              ok: true,
              significado: 'Encontraste las $total palabras',
              onContinuar: () => widget.onFinish(100, _respuestas),
            ),
      cabecera: const Encabezado(etiqueta: 'Vocabulario', icono: '⌗', titulo: 'Encuentra las palabras'),
      escenario: LayoutBuilder(builder: (context, cons) {
        final lado = min(cons.maxWidth / widget.columnas, cons.maxHeight / widget.filas);
        return Center(
          child: GestureDetector(
            onPanDown: (d) => _bajada = d.localPosition,
            onPanStart: (d) {
              final c = _celdaEn(_bajada ?? d.localPosition, lado);
              if (c == null) return;
              setState(() {
                _inicioArrastre = c;
                _inicioToque = null;
                _seleccion = [c];
              });
            },
            onPanUpdate: (d) {
              final c = _celdaEn(d.localPosition, lado);
              if (_inicioArrastre == null || c == null) return;
              final l = _linea(_inicioArrastre!, c);
              if (l != null) setState(() => _seleccion = l);
            },
            onPanEnd: (_) {
              if (_seleccion.length > 1) _intentar(_seleccion);
              setState(() {
                _seleccion = [];
                _inicioArrastre = null;
              });
            },
            onTapUp: (d) {
              final c = _celdaEn(d.localPosition, lado);
              if (c != null) _toque(c);
            },
            child: SizedBox(
              width: lado * widget.columnas,
              height: lado * widget.filas,
              child: Column(children: [
                for (var r = 0; r < widget.filas; r++)
                  Row(children: [
                    for (var c = 0; c < widget.columnas; c++)
                      _Letra(
                        letra: _sopa.grid[r][c],
                        lado: lado,
                        hallada: halladas.contains((r, c)),
                        marcada: _seleccion.contains((r, c)) || _inicioToque == (r, c),
                      ),
                  ]),
              ]),
            ),
          ),
        );
      }),
      cuerpo: [
        Wrap(spacing: 8, runSpacing: 6, children: [
          for (final w in _sopa.colocaciones)
            Chip(
              label: Text('${w.palabra} · ${w.pista}',
                  style: TextStyle(
                    decoration: _encontradas.contains(w.palabra) ? TextDecoration.lineThrough : null,
                    color: _encontradas.contains(w.palabra) ? Paleta.ok : Paleta.tinta,
                  )),
              backgroundColor: _encontradas.contains(w.palabra) ? Paleta.okFondo : Paleta.superficie,
            ),
        ]),
        const Pista('Arrastra de la primera a la última letra, o toca la primera y luego la última.'),
      ],
    );
  }
}

class _Letra extends StatelessWidget {
  const _Letra({required this.letra, required this.lado, required this.hallada, required this.marcada});
  final String letra;
  final double lado;
  final bool hallada;
  final bool marcada;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: lado,
      height: lado,
      alignment: Alignment.center,
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: marcada ? Paleta.selFondo : (hallada ? Paleta.okFondo : Paleta.superficie),
        border: Border.all(color: Paleta.linea, width: .5),
      ),
      child: Text(letra,
          style: TextStyle(
            fontSize: lado * .5,
            fontWeight: FontWeight.w700,
            color: marcada ? Paleta.marcaOscura : (hallada ? Paleta.ok : Paleta.tinta),
          )),
    );
  }
}
