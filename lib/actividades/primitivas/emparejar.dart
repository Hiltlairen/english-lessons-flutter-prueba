// ============================================================
// PRIMITIVA — Emparejar dos columnas
// Códigos: 01-emparejar, 17-emparejar-imagenes (con imágenes)
// ============================================================
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../comun.dart';

class CeldaPar {
  const CeldaPar(this.id, this.texto, {this.imagen});
  final String id;
  final String texto;

  /// En la web es un PNG; en esta prueba, un emoji.
  final String? imagen;
}

class Emparejar extends StatefulWidget {
  const Emparejar({
    super.key,
    required this.izquierda,
    required this.derecha,
    required this.pares,
    required this.onFinish,
    this.onSalir,
    this.penalizacion = 10,
  });

  final List<CeldaPar> izquierda;
  final List<CeldaPar> derecha;

  /// id izquierda → id derecha
  final Map<String, String> pares;
  final int penalizacion;
  final AlTerminar onFinish;
  final VoidCallback? onSalir;

  @override
  State<Emparejar> createState() => _EmparejarState();
}

class _EmparejarState extends State<Emparejar> {
  late final List<CeldaPar> _derecha = barajar(widget.derecha);
  String? _selIzq;
  final _resueltos = <String>[];
  int _fallos = 0;
  final _intentos = <Map<String, String>>[];
  String? _sacudida;
  bool _listo = false;
  Timer? _t;

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  int get _puntaje => max(0, 100 - _fallos * widget.penalizacion);

  void _tocarDerecha(String idDer) {
    if (_selIzq == null || _listo) return;
    _intentos.add({'izq': _selIzq!, 'der': idDer});
    if (widget.pares[_selIzq] == idDer) {
      setState(() {
        _resueltos.add(_selIzq!);
        _selIzq = null;
      });
      if (_resueltos.length == widget.pares.length) {
        _t = Timer(const Duration(milliseconds: 350), () => setState(() => _listo = true));
      }
    } else {
      setState(() {
        _fallos++;
        _sacudida = idDer;
        _selIzq = null;
      });
      _t = Timer(const Duration(milliseconds: 450), () => setState(() => _sacudida = null));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hechoDer(String id) => _resueltos.any((l) => widget.pares[l] == id);

    return Marco(
      top: BarraSuperior(hechos: _resueltos.length, total: widget.pares.length, onSalir: widget.onSalir),
      pie: Pie(
        child: BotonCTA(
          texto: 'Comprobar',
          onPressed: _listo ? () => widget.onFinish(_puntaje, {'intentos': _intentos}) : null,
        ),
      ),
      hoja: !_listo
          ? null
          : HojaFeedback(
              ok: _fallos == 0,
              titulo: _fallos == 0 ? '¡Buen trabajo!' : 'Pares completados',
              significado: '${widget.pares.length} pares · $_fallos error(es)',
              onContinuar: () => widget.onFinish(_puntaje, {'intentos': _intentos}),
            ),
      cuerpo: [
        const Encabezado(etiqueta: 'Vocabulario', icono: '⇄', titulo: 'Selecciona los pares'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(children: [
                for (final it in widget.izquierda)
                  _Celda(
                    item: it,
                    estado: _resueltos.contains(it.id)
                        ? EstadoOpcion.gris
                        : (_selIzq == it.id ? EstadoOpcion.sel : EstadoOpcion.normal),
                    onTap: _resueltos.contains(it.id) ? null : () => setState(() => _selIzq = it.id),
                  ),
              ]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(children: [
                for (final it in _derecha)
                  _Sacudir(
                    activo: _sacudida == it.id,
                    child: _Celda(
                      item: it,
                      estado: hechoDer(it.id)
                          ? EstadoOpcion.gris
                          : (_sacudida == it.id ? EstadoOpcion.mal : EstadoOpcion.normal),
                      onTap: hechoDer(it.id) ? null : () => _tocarDerecha(it.id),
                    ),
                  ),
              ]),
            ),
          ],
        ),
      ],
    );
  }
}

class _Celda extends StatelessWidget {
  const _Celda({required this.item, required this.estado, this.onTap});
  final CeldaPar item;
  final EstadoOpcion estado;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: BotonOpcion(
        estado: estado,
        onTap: onTap,
        child: item.imagen == null
            ? Text(item.texto, textAlign: TextAlign.center)
            : Column(children: [
                Text(item.imagen!, style: const TextStyle(fontSize: 34)),
                Text(item.texto, style: const TextStyle(fontSize: 12)),
              ]),
      ),
    );
  }
}

/// Sacudida horizontal al fallar.
class _Sacudir extends StatelessWidget {
  const _Sacudir({required this.activo, required this.child});
  final bool activo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!activo) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      builder: (_, v, c) => Transform.translate(offset: Offset(sin(v * pi * 6) * 8 * (1 - v), 0), child: c),
      child: child,
    );
  }
}
