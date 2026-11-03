// ============================================================
// PRIMITIVAS — Ordenar pasos (11) y Rompecabezas de oración (16)
// ============================================================
// Mismo esqueleto: banco de fichas → tira ordenada. El rompecabezas
// además dibuja conectores (forma + color) en cada pieza.
// ============================================================
import 'package:flutter/material.dart';

import '../../logica/generadores.dart';
import '../comun.dart';

class Paso {
  const Paso(this.id, this.texto);
  final String id;
  final String texto;
}

// ════════════════════════════════════════════════════════════
//  ORDENAR (11-indicaciones)
// ════════════════════════════════════════════════════════════
class Ordenar extends StatefulWidget {
  const Ordenar({super.key, required this.pasos, required this.ordenCorrecto, required this.onFinish, this.onSalir});

  final List<Paso> pasos;
  final List<String> ordenCorrecto;
  final AlTerminar onFinish;
  final VoidCallback? onSalir;

  @override
  State<Ordenar> createState() => _OrdenarState();
}

class _OrdenarState extends State<Ordenar> {
  late final List<Paso> _disponibles = barajar(widget.pasos);
  final _elegidos = <Paso>[];
  int? _nota;

  void _comprobar() {
    var ok = 0;
    for (var k = 0; k < _elegidos.length; k++) {
      if (_elegidos[k].id == widget.ordenCorrecto[k]) ok++;
    }
    setState(() => _nota = pct(ok, widget.ordenCorrecto.length));
  }

  @override
  Widget build(BuildContext context) {
    final bueno = widget.ordenCorrecto.map((id) => widget.pasos.firstWhere((p) => p.id == id).texto).join(' → ');
    final completo = _elegidos.length == widget.pasos.length;

    return Marco(
      top: BarraSuperior(hechos: _elegidos.length, total: widget.pasos.length, onSalir: widget.onSalir),
      pie: Pie(child: BotonCTA(texto: 'Comprobar', onPressed: completo && _nota == null ? _comprobar : null)),
      hoja: _nota == null
          ? null
          : HojaFeedback(
              ok: _nota == 100,
              significado: _nota == 100 ? null : bueno,
              detalle: 'Puntaje: $_nota/100',
              onContinuar: () => widget.onFinish(_nota, {'orden': _elegidos.map((p) => p.id).toList()}),
            ),
      cuerpo: [
        const Encabezado(etiqueta: 'Nuevo patrón', icono: '≡', titulo: 'Ordena los pasos'),
        Container(
          constraints: const BoxConstraints(minHeight: 80),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Paleta.linea, width: 2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: _elegidos.isEmpty
              ? const Center(child: Pista('Toca las fichas en el orden correcto'))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var k = 0; k < _elegidos.length; k++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Ficha(
                          estado: _nota == null
                              ? EstadoOpcion.normal
                              : (_elegidos[k].id == widget.ordenCorrecto[k] ? EstadoOpcion.ok : EstadoOpcion.mal),
                          onTap: _nota != null
                              ? null
                              : () => setState(() {
                                    _disponibles.add(_elegidos[k]);
                                    _elegidos.removeAt(k);
                                  }),
                          child: Text('${k + 1}. ${_elegidos[k].texto}'),
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in _disponibles)
              Ficha(
                onTap: () => setState(() {
                  _disponibles.remove(p);
                  _elegidos.add(p);
                }),
                child: Text(p.texto),
              ),
          ],
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
//  ROMPECABEZAS (16-rompecabezas-oracion)
// ════════════════════════════════════════════════════════════
class OracionPuzzle {
  const OracionPuzzle({required this.oracion, required this.traduccion, required this.piezas});
  final String oracion;
  final String traduccion;

  /// Piezas YA en el orden correcto.
  final List<String> piezas;
}

class Rompecabezas extends StatefulWidget {
  const Rompecabezas({super.key, required this.oraciones, required this.onFinish, this.onSalir});

  final List<OracionPuzzle> oraciones;
  final AlTerminar onFinish;
  final VoidCallback? onSalir;

  @override
  State<Rompecabezas> createState() => _RompecabezasState();
}

class _RompecabezasState extends State<Rompecabezas> {
  int _i = 0;
  late List<Pieza> _piezas;
  late List<Pieza> _disponibles;
  final _armadas = <Pieza>[];
  int? _nota;
  int _resueltos = 0;
  final _respuestas = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    _piezas = generarPiezas(widget.oraciones[_i].piezas);
    _disponibles = barajar(_piezas);
    _armadas.clear();
    _nota = null;
  }

  void _comprobar() {
    var ok = 0;
    for (var k = 0; k < _armadas.length; k++) {
      if (_armadas[k].indiceCorrecto == k) ok++;
    }
    setState(() {
      _nota = pct(ok, _piezas.length);
      if (_nota == 100) _resueltos++;
      _respuestas.add({'i': _i, 'piezas': _armadas.map((p) => p.texto).toList()});
    });
  }

  void _continuar() {
    if (_i + 1 >= widget.oraciones.length) {
      widget.onFinish(pct(_resueltos, widget.oraciones.length), {'items': _respuestas});
    } else {
      setState(() {
        _i++;
        _cargar();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.oraciones[_i];
    final ultimo = _i + 1 >= widget.oraciones.length;

    return Marco(
      clave: _i,
      top: BarraSuperior(hechos: _i, total: widget.oraciones.length, onSalir: widget.onSalir),
      pie: Pie(
        child: _nota == null
            ? BotonCTA(texto: 'Comprobar', onPressed: _armadas.length == _piezas.length ? _comprobar : null)
            : BotonCTA(
                texto: ultimo ? 'Terminar' : 'Siguiente oración',
                tono: _nota == 100 ? Tono.ok : Tono.mal,
                onPressed: _continuar,
              ),
      ),
      cuerpo: [
        const Encabezado(etiqueta: 'Rompecabezas', icono: '🧩', titulo: 'Arma la oración'),
        Container(
          constraints: const BoxConstraints(minHeight: 70),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            border: Border.all(color: const Color(0xFFFCD34D), width: 2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: _armadas.isEmpty
              ? const Center(child: Pista('Toca las piezas en el orden correcto'))
              : Wrap(spacing: 2, runSpacing: 6, children: [
                  for (var k = 0; k < _armadas.length; k++)
                    _PiezaWidget(
                      pieza: _armadas[k],
                      estado: _nota == null
                          ? EstadoOpcion.normal
                          : (_armadas[k].indiceCorrecto == k ? EstadoOpcion.ok : EstadoOpcion.mal),
                      onTap: _nota != null
                          ? null
                          : () => setState(() {
                                _disponibles.add(_armadas[k]);
                                _armadas.removeAt(k);
                              }),
                    ),
                ]),
        ),
        if (_nota != null && _nota! < 100) Pista('💡 ${item.oracion}'),
        Pista('🇪🇸 ${item.traduccion}'),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final p in _disponibles)
            _PiezaWidget(
              pieza: p,
              onTap: _nota != null
                  ? null
                  : () => setState(() {
                        _disponibles.remove(p);
                        _armadas.add(p);
                      }),
            ),
        ]),
      ],
    );
  }
}

class _PiezaWidget extends StatelessWidget {
  const _PiezaWidget({required this.pieza, this.onTap, this.estado = EstadoOpcion.normal});
  final Pieza pieza;
  final VoidCallback? onTap;
  final EstadoOpcion estado;

  @override
  Widget build(BuildContext context) {
    Widget conector(Conector? c) => c == null
        ? const SizedBox(width: 4)
        : Text(c.glifo, style: TextStyle(color: c.color, fontSize: 16));
    return Ficha(
      estado: estado,
      onTap: onTap,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        conector(pieza.izquierdo),
        const SizedBox(width: 6),
        Text(pieza.texto),
        const SizedBox(width: 6),
        conector(pieza.derecho),
      ]),
    );
  }
}
