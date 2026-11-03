// ============================================================
// PRIMITIVA — Encuentra al impostor (19-impostor)
// ============================================================
// Matriz fija de 3×2 (6 tarjetas: imagen + traducción). Una sola
// traducción está mal a propósito; el estudiante la señala.
// ============================================================
import 'package:flutter/material.dart';

import '../comun.dart';

class Tarjeta {
  const Tarjeta(this.imagen, this.palabraEn, this.traduccionMostrada, {this.correcta = true});
  final String imagen;
  final String palabraEn;
  final String traduccionMostrada;

  /// false = es el impostor.
  final bool correcta;
}

class Impostor extends StatefulWidget {
  const Impostor({super.key, required this.rondas, required this.onFinish, this.onSalir});

  final List<List<Tarjeta>> rondas;
  final AlTerminar onFinish;
  final VoidCallback? onSalir;

  @override
  State<Impostor> createState() => _ImpostorState();
}

class _ImpostorState extends State<Impostor> {
  late final List<List<Tarjeta>> _rondas = [for (final r in widget.rondas) barajar(r)];
  int _i = 0;
  Tarjeta? _elegida;
  int _aciertos = 0;
  final _respuestas = <Map<String, dynamic>>[];

  void _elegir(Tarjeta t) {
    if (_elegida != null) return;
    setState(() {
      _elegida = t;
      if (!t.correcta) _aciertos++;
      _respuestas.add({'i': _i, 'tarjeta': t.palabraEn});
    });
  }

  void _continuar() {
    if (_i + 1 >= _rondas.length) {
      widget.onFinish(pct(_aciertos, _rondas.length), {'items': _respuestas});
    } else {
      setState(() {
        _i++;
        _elegida = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ronda = _rondas[_i];
    final impostor = ronda.firstWhere((t) => !t.correcta);
    return Marco(
      clave: _i,
      top: BarraSuperior(hechos: _i, total: _rondas.length, onSalir: widget.onSalir),
      pie: const Pie(secundario: Pista('Toca la tarjeta con la traducción incorrecta')),
      hoja: _elegida == null
          ? null
          : HojaFeedback(
              ok: !_elegida!.correcta,
              significado: '"${impostor.traduccionMostrada}" no es la traducción de "${impostor.palabraEn}".',
              textoBoton: _i + 1 >= _rondas.length ? 'Terminar' : 'Siguiente ronda',
              onContinuar: _continuar,
            ),
      cuerpo: [
        const Encabezado(etiqueta: 'Vocabulario', icono: '🕵️', titulo: 'Una traducción está mal. ¿Cuál?'),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          crossAxisSpacing: 10,
          childAspectRatio: 1.15,
          children: [
            for (final t in ronda)
              BotonOpcion(
                // Si el alumno erró, no se delata cuál era: solo se marca la que tocó.
                estado: _elegida == null
                    ? EstadoOpcion.normal
                    : (t == _elegida ? (!t.correcta ? EstadoOpcion.ok : EstadoOpcion.mal) : EstadoOpcion.gris),
                onTap: _elegida == null ? () => _elegir(t) : null,
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(t.imagen, style: const TextStyle(fontSize: 34)),
                  Text(t.palabraEn, style: const TextStyle(fontSize: 12, color: Paleta.suave)),
                  Text(t.traduccionMostrada, textAlign: TextAlign.center),
                ]),
              ),
          ],
        ),
      ],
    );
  }
}
