// ============================================================
// PRIMITIVA — Quiz de opción múltiple por turnos
// Códigos: 02, 03, 09, 12, 13, 14
// ============================================================
import 'dart:math';

import 'package:flutter/material.dart';

import '../comun.dart';

class Opcion {
  const Opcion(this.texto, {this.correcta = false, this.accion});
  final String texto;
  final bool correcta;

  /// Solo en 07-direcciones: izquierda | derecha | recto | llegar.
  final String? accion;
}

class ItemQuiz {
  const ItemQuiz({required this.enunciado, required this.opciones, this.hasta, this.significado});
  final String enunciado;
  final List<Opcion> opciones;

  /// Cuántos turnos del contexto se ven al llegar a este ítem.
  final int? hasta;
  final String? significado;
}

class Turno {
  const Turno(this.hablante, this.texto, {this.mio = false});
  final String hablante;
  final String texto;
  final bool mio;
}

enum FormatoQuiz { chat, panel }

class Quiz extends StatefulWidget {
  const Quiz({
    super.key,
    required this.items,
    required this.onFinish,
    this.onSalir,
    this.contexto = const [],
    this.penalizacion = 0,
    this.formato = FormatoQuiz.chat,
    this.etiqueta,
    this.icono = '✦',
    this.titulo,
    this.interlocutor = '🧑',
  });

  final List<ItemQuiz> items;
  final List<Turno> contexto;
  final int penalizacion;
  final FormatoQuiz formato;
  final String? etiqueta;
  final String icono;
  final String? titulo;
  final String interlocutor;
  final AlTerminar onFinish;
  final VoidCallback? onSalir;

  @override
  State<Quiz> createState() => _QuizState();
}

class _QuizState extends State<Quiz> {
  late final List<List<Opcion>> _opciones = [for (final it in widget.items) barajar(it.opciones)];
  int _i = 0;
  Opcion? _elegida;
  bool? _ok;
  int _aciertos = 0;
  int _combo = 0;
  final _respuestas = <Map<String, dynamic>>[];

  void _comprobar() {
    if (_elegida == null || _ok != null) return;
    final ok = _elegida!.correcta;
    setState(() {
      _ok = ok;
      if (ok) _aciertos++;
      _combo = ok ? _combo + 1 : 0;
      _respuestas.add({'i': _i, 'opcion': _elegida!.texto});
    });
  }

  void _continuar() {
    final n = widget.items.length;
    if (_i + 1 >= n) {
      final errores = n - _aciertos;
      final nota = max(0, pct(_aciertos, n) - (errores * widget.penalizacion / 10).round());
      widget.onFinish(nota, {'items': _respuestas});
    } else {
      setState(() {
        _i++;
        _elegida = null;
        _ok = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.items[_i];
    final opciones = _opciones[_i];
    final visibles = widget.contexto.take(item.hasta ?? widget.contexto.length).toList();
    final correcta = opciones.firstWhere((o) => o.correcta, orElse: () => opciones.first);

    return Marco(
      clave: _i,
      top: BarraSuperior(hechos: _i, total: widget.items.length, combo: _combo, onSalir: widget.onSalir),
      pie: Pie(child: BotonCTA(texto: 'Comprobar', onPressed: _elegida != null && _ok == null ? _comprobar : null)),
      hoja: _ok == null
          ? null
          : HojaFeedback(
              ok: _ok!,
              significado: _ok! ? item.significado : correcta.texto,
              onContinuar: _continuar,
            ),
      cuerpo: [
        Encabezado(etiqueta: widget.etiqueta, icono: widget.icono, titulo: widget.titulo ?? item.enunciado),

        // Contexto como conversación (burbujas)
        if (widget.formato == FormatoQuiz.chat && visibles.isNotEmpty)
          for (var k = 0; k < visibles.length; k++)
            _Burbuja(
              turno: visibles[k],
              avatar: !visibles[k].mio && k == visibles.indexWhere((t) => !t.mio) ? widget.interlocutor : null,
            ),

        // Contexto como panel (canción / anuncio)
        if (widget.formato == FormatoQuiz.panel)
          Globo(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (final t in visibles) Text(t.texto, style: const TextStyle(color: Paleta.suave)),
              Text(item.enunciado, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ]),
          ),

        // El enunciado solo se repite si no es ya el título
        if (widget.formato == FormatoQuiz.chat && widget.titulo != null)
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Text(item.enunciado, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),

        const SizedBox(height: 8),
        for (final op in opciones)
          BotonOpcion(
            // Solo se marca la que tocó el alumno: no se delata la correcta.
            estado: _ok == null
                ? (_elegida == op ? EstadoOpcion.sel : EstadoOpcion.normal)
                : (op == _elegida ? (op.correcta ? EstadoOpcion.ok : EstadoOpcion.mal) : EstadoOpcion.gris),
            onTap: _ok == null ? () => setState(() => _elegida = op) : null,
            child: Text(op.texto),
          ),
      ],
    );
  }
}

class _Burbuja extends StatelessWidget {
  const _Burbuja({required this.turno, this.avatar});
  final Turno turno;
  final String? avatar;

  @override
  Widget build(BuildContext context) {
    final mio = turno.mio;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: mio ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!mio) SizedBox(width: 36, child: Text(avatar ?? '', style: const TextStyle(fontSize: 28))),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: mio ? Paleta.selFondo : Paleta.superficie,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: mio ? Paleta.marca.withValues(alpha: .4) : Paleta.linea, width: 2),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (!mio)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Flexible(
                      child: Text(turno.hablante,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Paleta.suave)),
                    ),
                    BotonAltavoz(tamano: 14, onTap: () => Voz.hablar(turno.texto)),
                  ]),
                Text(turno.texto, style: const TextStyle(fontSize: 15)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
