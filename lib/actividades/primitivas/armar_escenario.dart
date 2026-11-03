// ============================================================
// PRIMITIVA — Armar objetos en un escenario (18-armar-escenario)
// ============================================================
// Se toca un objeto de la bandeja y luego su zona (o el cesto de
// "No pertenece aquí" para los distractores). Tocar un objeto ya
// colocado lo devuelve a la mano.
// ============================================================
import 'package:flutter/material.dart';

import '../comun.dart';

class Zona {
  const Zona(this.id, this.nombre, this.emoji);
  final String id;
  final String nombre;
  final String emoji;
}

class Objeto {
  const Objeto(this.id, this.nombre, this.emoji, {this.zonaCorrecta});
  final String id;
  final String nombre;
  final String emoji;

  /// null = no pertenece a la escena (va al cesto).
  final String? zonaCorrecta;
}

const _descarte = '__descartar__';

class ArmarEscenario extends StatefulWidget {
  const ArmarEscenario({
    super.key,
    required this.nombre,
    required this.emoji,
    required this.zonas,
    required this.objetos,
    required this.onFinish,
    this.onSalir,
  });

  final String nombre;
  final String emoji;
  final List<Zona> zonas;
  final List<Objeto> objetos;
  final AlTerminar onFinish;
  final VoidCallback? onSalir;

  @override
  State<ArmarEscenario> createState() => _ArmarEscenarioState();
}

class _ArmarEscenarioState extends State<ArmarEscenario> {
  final _colocados = <String, String>{}; // objetoId → zonaId
  String? _sel;
  int? _nota;

  void _colocarEn(String zonaId) {
    if (_sel == null || _nota != null) return;
    setState(() {
      _colocados[_sel!] = zonaId;
      _sel = null;
    });
  }

  void _recoger(String objetoId) {
    if (_nota != null) return;
    setState(() {
      _colocados.remove(objetoId);
      _sel = objetoId;
    });
  }

  void _comprobar() {
    var ok = 0;
    for (final o in widget.objetos) {
      if (_colocados[o.id] == (o.zonaCorrecta ?? _descarte)) ok++;
    }
    setState(() => _nota = pct(ok, widget.objetos.length));
  }

  @override
  Widget build(BuildContext context) {
    final pendientes = widget.objetos.where((o) => !_colocados.containsKey(o.id)).toList();

    Widget zona(String id, String titulo, {bool cesto = false}) {
      final dentro = widget.objetos.where((o) => _colocados[o.id] == id).toList();
      var borde = _sel != null ? Paleta.marca : Paleta.linea;
      if (_nota != null && dentro.isNotEmpty) {
        final bien = dentro.every((o) => (o.zonaCorrecta ?? _descarte) == id);
        borde = bien ? Paleta.ok : Paleta.mal;
      }
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: cesto ? const Color(0xFFF3F4F6) : Paleta.superficie,
          border: Border.all(color: borde, width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _colocarEn(id),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
          if (dentro.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Wrap(spacing: 6, runSpacing: 6, children: [
                for (final o in dentro)
                  ActionChip(
                    avatar: Text(o.emoji),
                    label: Text(o.nombre),
                    backgroundColor: _nota == null
                        ? null
                        : ((o.zonaCorrecta ?? _descarte) == id ? Paleta.okFondo : Paleta.malFondo),
                    onPressed: () => _recoger(o.id),
                  ),
              ]),
            ),
        ]),
      );
    }

    return Marco(
      top: BarraSuperior(
          hechos: widget.objetos.length - pendientes.length, total: widget.objetos.length, onSalir: widget.onSalir),
      pie: Pie(
        child: _nota == null ? BotonCTA(texto: 'Comprobar', onPressed: pendientes.isEmpty ? _comprobar : null) : null,
      ),
      hoja: _nota == null
          ? null
          : HojaFeedback(
              ok: _nota == 100,
              significado: '$_nota/100 · revisa los objetos marcados en rojo',
              onContinuar: () => widget.onFinish(_nota, {'colocados': _colocados}),
            ),
      cuerpo: [
        Encabezado(etiqueta: 'Escenografía', icono: '🏠', titulo: 'Arma: ${widget.nombre}'),
        Center(child: Text(widget.emoji, style: const TextStyle(fontSize: 48))),
        for (final z in widget.zonas) zona(z.id, '${z.emoji}  ${z.nombre}'),
        zona(_descarte, '🗑️  No pertenece aquí', cesto: true),
        const SizedBox(height: 8),
        Pista(_sel != null ? 'Toca la zona donde va' : 'Toca un objeto de la bandeja'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final o in pendientes)
            Ficha(
              estado: _sel == o.id ? EstadoOpcion.sel : EstadoOpcion.normal,
              onTap: () => setState(() => _sel = o.id),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(o.emoji, style: const TextStyle(fontSize: 28)),
                Text(o.nombre, style: const TextStyle(fontSize: 12)),
              ]),
            ),
        ]),
      ],
    );
  }
}
