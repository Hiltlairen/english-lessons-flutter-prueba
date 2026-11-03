// ============================================================
// PRIMITIVA — Letra con huecos (10-canciones)
// ============================================================
// En la app real suena la canción (YouTube / Spotify / URL) con la
// letra sincronizada. En esta prueba no hay reproductor: cada verso se
// escucha con texto a voz (▶) y el estudiante escribe lo que falta.
// "Comprobar" compara sin mayúsculas, tildes ni signos (igual que el
// servidor) y marca en rojo los errores con la palabra original.
// ============================================================
import 'package:flutter/material.dart';

import '../comun.dart';

/// Un trozo de verso: texto fijo, o un hueco con su respuesta.
class Parte {
  const Parte.texto(this.texto) : respuesta = null;
  const Parte.hueco(this.respuesta) : texto = null;
  final String? texto;
  final String? respuesta;
  bool get esHueco => respuesta != null;
}

String _norm(String s) {
  const tildes = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n'};
  var r = s.toLowerCase().replaceAll(RegExp('[’‘`´]'), "'");
  tildes.forEach((k, v) => r = r.replaceAll(k, v));
  return r.replaceAll(RegExp(r"[^a-z0-9']"), '');
}

class Cancion extends StatefulWidget {
  const Cancion({super.key, required this.titulo, required this.versos, required this.onFinish, this.onSalir});

  final String titulo;
  final List<List<Parte>> versos;
  final AlTerminar onFinish;
  final VoidCallback? onSalir;

  @override
  State<Cancion> createState() => _CancionState();
}

class _CancionState extends State<Cancion> {
  /// Un controlador por hueco, en orden de aparición.
  late final List<TextEditingController> _ctrls = [
    for (final v in widget.versos)
      for (final p in v)
        if (p.esHueco) TextEditingController()
  ];
  late final List<String> _respuestas = [
    for (final v in widget.versos)
      for (final p in v)
        if (p.esHueco) p.respuesta!
  ];
  bool _revisado = false;

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  bool _correcto(int h) => _norm(_ctrls[h].text) == _norm(_respuestas[h]);

  String _versoCompleto(List<Parte> v) => v.map((p) => p.texto ?? p.respuesta).join();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(_ctrls),
      builder: (context, _) {
        final llenos = _ctrls.where((c) => c.text.trim().isNotEmpty).length;
        final aciertos = [for (var h = 0; h < _ctrls.length; h++) _correcto(h)].where((x) => x).length;
        final nota = pct(aciertos, _ctrls.length);
        var h = 0; // índice global de hueco mientras se dibuja

        return Marco(
          top: BarraSuperior(hechos: _revisado ? aciertos : llenos, total: _ctrls.length, onSalir: widget.onSalir),
          pie: Pie(
            secundario: Text('$llenos / ${_ctrls.length} palabras', style: const TextStyle(color: Paleta.suave)),
            child: BotonCTA(
              texto: 'Comprobar',
              onPressed: !_revisado && llenos > 0
                  ? () {
                      Voz.callar();
                      setState(() => _revisado = true);
                    }
                  : null,
            ),
          ),
          hoja: !_revisado
              ? null
              : HojaFeedback(
                  ok: nota >= 60,
                  titulo: '$aciertos de ${_ctrls.length} correctas · $nota%',
                  detalle: aciertos < _ctrls.length
                      ? 'En la letra quedaron marcadas en rojo, con la palabra original al lado.'
                      : '¡Completaste toda la letra!',
                  onContinuar: () => widget.onFinish(nota, {'huecos': _ctrls.map((c) => c.text).toList()}),
                ),
          cuerpo: [
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(color: const Color(0xFF312E81), borderRadius: BorderRadius.circular(12)),
              child: Text('🎤  ${widget.titulo}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
            const Encabezado(etiqueta: 'Canción', icono: '🎤', titulo: 'Escucha y completa la letra'),
            for (var i = 0; i < widget.versos.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  BotonAltavoz(
                    icono: '▶',
                    tamano: 18,
                    onTap: () => Voz.hablar(_versoCompleto(widget.versos[i]), velocidad: .8),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      runSpacing: 4,
                      children: [
                        for (final p in widget.versos[i])
                          if (!p.esHueco)
                            Text(p.texto!, style: const TextStyle(fontSize: 17))
                          else
                            _Hueco(
                              ctrl: _ctrls[h],
                              respuesta: _respuestas[h],
                              revisado: _revisado,
                              ok: _correcto(h++),
                            ),
                      ],
                    ),
                  ),
                ]),
              ),
            const Pista('Toca ▶ para escuchar cada verso (en la app real suena la canción).'),
          ],
        );
      },
    );
  }
}

class _Hueco extends StatelessWidget {
  const _Hueco({required this.ctrl, required this.respuesta, required this.revisado, required this.ok});
  final TextEditingController ctrl;
  final String respuesta;
  final bool revisado;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final color = !revisado ? Paleta.marca : (ok ? Paleta.ok : Paleta.mal);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          width: 18.0 + respuesta.length * 11,
          child: TextField(
            controller: ctrl,
            readOnly: revisado,
            autocorrect: false,
            enableSuggestions: false,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, color: color, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: color, width: 2)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: color, width: 2.5)),
            ),
          ),
        ),
        if (revisado && !ok) Text(respuesta, style: const TextStyle(color: Paleta.ok, fontSize: 12)),
      ]),
    );
  }
}
