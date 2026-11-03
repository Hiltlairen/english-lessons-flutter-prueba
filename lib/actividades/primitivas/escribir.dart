// ============================================================
// PRIMITIVA — Escribir la respuesta
// Códigos: 06-diccionario, 08-inflexion
// ============================================================
import 'package:flutter/material.dart';

import '../comun.dart';

class ItemEscribir {
  const ItemEscribir({
    required this.prompt,
    required this.respuesta,
    this.alternativas = const [],
    this.lang = 'en-US',
    this.regla,
    this.pista,
  });
  final String prompt;
  final String respuesta;
  final List<String> alternativas;
  final String lang;
  final String? regla;
  final String? pista;
}

class Escribir extends StatefulWidget {
  const Escribir({
    super.key,
    required this.items,
    required this.onFinish,
    this.onSalir,
    this.etiqueta = 'Palabra nueva',
    this.icono = '✦',
    this.titulo = 'Traduce esta palabra',
  });

  final List<ItemEscribir> items;
  final String etiqueta;
  final String icono;
  final String titulo;
  final AlTerminar onFinish;
  final VoidCallback? onSalir;

  @override
  State<Escribir> createState() => _EscribirState();
}

class _EscribirState extends State<Escribir> {
  final _ctrl = TextEditingController();
  int _i = 0;
  bool? _ok;
  int _aciertos = 0;
  int _combo = 0;
  final _respuestas = <Map<String, dynamic>>[];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _norm(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  void _comprobar() {
    if (_ok != null || _ctrl.text.trim().isEmpty) return;
    final item = widget.items[_i];
    final ok = [item.respuesta, ...item.alternativas].map(_norm).contains(_norm(_ctrl.text));
    setState(() {
      _ok = ok;
      if (ok) _aciertos++;
      _combo = ok ? _combo + 1 : 0;
      _respuestas.add({'i': _i, 'texto': _ctrl.text});
    });
  }

  void _continuar() {
    if (_i + 1 >= widget.items.length) {
      widget.onFinish(pct(_aciertos, widget.items.length), {'items': _respuestas});
    } else {
      setState(() {
        _i++;
        _ok = null;
        _ctrl.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.items[_i];
    return Marco(
      clave: _i,
      top: BarraSuperior(hechos: _i, total: widget.items.length, combo: _combo, onSalir: widget.onSalir),
      pie: Pie(
        child: ValueListenableBuilder(
          valueListenable: _ctrl,
          builder: (_, v, _) =>
              BotonCTA(texto: 'Comprobar', onPressed: v.text.trim().isNotEmpty && _ok == null ? _comprobar : null),
        ),
      ),
      hoja: _ok == null
          ? null
          : HojaFeedback(ok: _ok!, significado: _ok! ? item.prompt : item.respuesta, onContinuar: _continuar),
      cuerpo: [
        Encabezado(etiqueta: item.regla ?? widget.etiqueta, icono: widget.icono, titulo: widget.titulo),
        Escena(texto: item.prompt, lang: item.lang),
        if (item.pista != null) Pista('💡 ${item.pista}'),
        const SizedBox(height: 20),
        TextField(
          controller: _ctrl,
          enabled: _ok == null,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _comprobar(),
          style: const TextStyle(fontSize: 18),
          decoration: InputDecoration(
            hintText: 'Escribe aquí…',
            filled: true,
            fillColor: _ok == null ? Paleta.superficie : (_ok! ? Paleta.okFondo : Paleta.malFondo),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }
}
