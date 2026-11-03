// ============================================================
// PRIMITIVA — Producción libre (05-redaccion)
// ============================================================
// En la app real la corrige una IA y el docente confirma la nota;
// aquí se entrega sin puntaje (null).
// ============================================================
import 'package:flutter/material.dart';

import '../comun.dart';

class Criterio {
  const Criterio(this.nombre, this.peso);
  final String nombre;
  final int peso;
}

class Libre extends StatefulWidget {
  const Libre({
    super.key,
    required this.consigna,
    required this.onFinish,
    this.onSalir,
    this.contexto,
    this.minimo = 40,
    this.criterios = const [],
  });

  final String consigna;
  final String? contexto;
  final int minimo;
  final List<Criterio> criterios;
  final AlTerminar onFinish;
  final VoidCallback? onSalir;

  @override
  State<Libre> createState() => _LibreState();
}

class _LibreState extends State<Libre> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _ctrl,
      builder: (context, v, _) {
        final t = v.text.trim();
        final palabras = t.isEmpty ? 0 : t.split(RegExp(r'\s+')).length;
        final suficiente = palabras >= widget.minimo;
        return Marco(
          top: BarraSuperior(
              hechos: palabras.clamp(0, widget.minimo), total: widget.minimo, onSalir: widget.onSalir),
          pie: Pie(
            secundario: Text('$palabras / ${widget.minimo} palabras',
                style: TextStyle(color: suficiente ? Paleta.ok : Paleta.suave, fontWeight: FontWeight.w700)),
            child: BotonCTA(
              texto: 'Entregar',
              onPressed: suficiente ? () => widget.onFinish(null, {'texto': v.text, 'palabras': palabras}) : null,
            ),
          ),
          cuerpo: [
            const Encabezado(etiqueta: 'Redacción', icono: '✎', titulo: 'Escribe tu respuesta'),
            Globo(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (widget.contexto != null)
                  Text('📍 ${widget.contexto}', style: const TextStyle(color: Paleta.suave)),
                const SizedBox(height: 4),
                Text(widget.consigna, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ]),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              maxLines: 8,
              minLines: 6,
              decoration: InputDecoration(
                hintText: 'Write your answer in English…',
                filled: true,
                fillColor: Paleta.superficie,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 8),
            for (final c in widget.criterios) Pista('• ${c.nombre} · ${c.peso}%'),
            const Pista(
                'Al entregar, una IA revisa que tu texto encaje en la situación y que esté bien escrito. '
                'Tu profesor confirma la nota. (En esta prueba no se califica.)'),
          ],
        );
      },
    );
  }
}
