// ============================================================
// PRIMITIVA — Indicaciones en el mapa (07-direcciones)
// ============================================================
// En la app real es un mapa de La Paz (Leaflet + OpenStreetMap) que
// rota como un GPS. En esta prueba es un plano de cuadras dibujado a
// mano (sin internet), con la misma mecánica:
//   · En cada esquina se escucha la indicación en inglés.
//   · Tocar una opción ya es responder (sin botón "Comprobar").
//   · Correcta → el auto maneja el tramo. 1er error → queda un intento.
//     2do error → se muestra la correcta y el auto sigue igual.
// ============================================================
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../comun.dart';
import 'quiz.dart' show Opcion;

class PasoRuta {
  const PasoRuta(this.instruccion, this.opciones);
  final String instruccion;
  final List<Opcion> opciones;
}

class Lugar {
  const Lugar(this.emoji, this.x, this.y);
  final String emoji;
  final double x, y;
}

const _flecha = {'izquierda': '↰', 'derecha': '↱', 'recto': '↑', 'llegar': '🏁'};

class Direcciones extends StatefulWidget {
  const Direcciones({
    super.key,
    required this.destino,
    required this.pasos,
    required this.ruta,
    required this.onFinish,
    this.onSalir,
    this.motivo,
    this.guia,
    this.llegada,
    this.lugares = const [],
    this.columnas = 5,
    this.filas = 6,
  });

  final String destino;
  final String? motivo;
  final String? guia;
  final String? llegada;
  final List<PasoRuta> pasos;

  /// Esquinas de la ruta en coordenadas de cuadra: pasos.length + 1 puntos.
  final List<Offset> ruta;
  final List<Lugar> lugares;
  final int columnas, filas;
  final AlTerminar onFinish;
  final VoidCallback? onSalir;

  @override
  State<Direcciones> createState() => _DireccionesState();
}

class _DireccionesState extends State<Direcciones> with SingleTickerProviderStateMixin {
  late final AnimationController _auto =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) _llegoTramo();
        });
  late final List<List<Opcion>> _opciones = [for (final p in widget.pasos) barajar(p.opciones)];
  int _i = 0;
  final _fallidas = <String>[];
  String? _resuelto; // null | ok | revelado
  bool _manejando = false;
  bool _fin = false;
  int _aciertos = 0;
  int _errores = 0;
  final _respuestas = <Map<String, dynamic>>[];
  Timer? _t;

  static const _maxIntentos = 2;

  @override
  void initState() {
    super.initState();
    Voz.hablar(widget.pasos.first.instruccion);
  }

  @override
  void dispose() {
    _t?.cancel();
    _auto.dispose();
    super.dispose();
  }

  void _elegir(Opcion o) {
    if (_resuelto != null || _manejando || _fallidas.contains(o.texto)) return;
    if (o.correcta) {
      setState(() {
        _resuelto = 'ok';
        _aciertos++;
        _respuestas.add({'i': _i, 'elegidas': [..._fallidas, o.texto]});
      });
      _t = Timer(const Duration(milliseconds: 650), _conducir);
      return;
    }
    setState(() {
      _fallidas.add(o.texto);
      _errores++;
      if (_fallidas.length >= _maxIntentos) {
        _resuelto = 'revelado';
        _respuestas.add({'i': _i, 'elegidas': [..._fallidas]});
      }
    });
  }

  void _conducir() {
    setState(() => _manejando = true);
    _auto.forward(from: 0);
  }

  void _llegoTramo() {
    setState(() {
      _manejando = false;
      _resuelto = null;
      _fallidas.clear();
      if (_i + 1 >= widget.pasos.length) {
        _fin = true;
        if (widget.llegada != null) Voz.hablar(widget.llegada!);
      } else {
        _i++;
        Voz.hablar(widget.pasos[_i].instruccion);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final paso = widget.pasos[_i];
    final correcta = _opciones[_i].firstWhere((o) => o.correcta);
    final aviso = _resuelto == 'ok'
        ? '¡Por ahí es!'
        : (_fallidas.length == 1 && _resuelto == null ? 'No es por ahí. Te queda un intento.' : null);

    return Marco(
      clave: _i,
      top: BarraSuperior(hechos: _fin ? widget.pasos.length : _i, total: widget.pasos.length, onSalir: widget.onSalir),
      pie: _fin
          ? Pie(
              child: BotonCTA(
                texto: 'Terminar',
                onPressed: () => widget.onFinish(
                    max(0, pct(_aciertos, widget.pasos.length) - _errores), {'items': _respuestas}),
              ),
            )
          : null,
      hoja: _resuelto == 'revelado' && !_manejando
          ? HojaFeedback(
              ok: false,
              titulo: 'Por ahí no era',
              significado: correcta.texto,
              detalle: 'Escucha con atención la indicación de la próxima esquina.',
              textoBoton: 'Seguir',
              onContinuar: _conducir,
            )
          : null,
      cabecera: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Encabezado(etiqueta: 'Sigue las indicaciones', icono: '🚗', titulo: 'Llega a ${widget.destino}'),
        if (widget.motivo != null && _i == 0) Pista(widget.motivo!),
      ]),
      escenario: AnimatedBuilder(
        animation: _auto,
        builder: (context, _) => _Mapa(
          ruta: widget.ruta,
          lugares: widget.lugares,
          columnas: widget.columnas,
          filas: widget.filas,
          tramo: _i,
          avance: _fin ? 1 : (_manejando ? Curves.easeInOut.transform(_auto.value) : 0),
        ),
      ),
      cuerpo: _fin
          ? [
              Globo(
                child: Text('🏁 ${widget.llegada ?? 'You arrived at ${widget.destino}!'}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ]
          : [
              Globo(
                child: Row(children: [
                  BotonAltavoz(onTap: () => Voz.hablar(paso.instruccion)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text.rich(TextSpan(children: [
                      if (widget.guia != null)
                        TextSpan(text: '${widget.guia}: ', style: const TextStyle(fontWeight: FontWeight.w800)),
                      TextSpan(text: paso.instruccion),
                    ]), style: const TextStyle(fontSize: 16)),
                  ),
                ]),
              ),
              const SizedBox(height: 6),
              for (final o in _opciones[_i])
                BotonOpcion(
                  estado: _fallidas.contains(o.texto)
                      ? EstadoOpcion.mal
                      : (_resuelto != null && o.correcta)
                          ? EstadoOpcion.ok
                          : (_resuelto != null ? EstadoOpcion.gris : EstadoOpcion.normal),
                  onTap: _resuelto != null || _manejando || _fallidas.contains(o.texto) ? null : () => _elegir(o),
                  child: Row(children: [
                    SizedBox(width: 30, child: Text(_flecha[o.accion] ?? '•', style: const TextStyle(fontSize: 20))),
                    Expanded(child: Text(o.texto)),
                  ]),
                ),
              Text(
                aviso ?? (_errores > 0 ? 'Errores: $_errores' : 'Toca la opción que entendiste.'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _resuelto == 'ok' ? Paleta.ok : (aviso != null ? Paleta.mal : Paleta.suave),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
    );
  }
}

/// Plano de cuadras + recorrido + auto.
class _Mapa extends StatelessWidget {
  const _Mapa({
    required this.ruta,
    required this.lugares,
    required this.columnas,
    required this.filas,
    required this.tramo,
    required this.avance,
  });

  final List<Offset> ruta;
  final List<Lugar> lugares;
  final int columnas, filas;
  final int tramo;
  final double avance;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, cons) {
      final u = min(cons.maxWidth / columnas, cons.maxHeight / filas);
      final ancho = u * columnas, alto = u * filas;
      Offset px(Offset p) => Offset((p.dx + .5) * u, (p.dy + .5) * u);

      final a = ruta[tramo], b = ruta[min(tramo + 1, ruta.length - 1)];
      final auto = Offset.lerp(a, b, avance)!;
      var dir = b - a;
      if (dir.distance == 0 && tramo > 0) dir = ruta[tramo] - ruta[tramo - 1];
      final angulo = atan2(dir.dy, dir.dx) + pi / 2;
      final recorrido = [...ruta.take(tramo + 1), auto];

      return Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: ancho,
            height: alto,
            child: Stack(children: [
              Positioned.fill(
                child: CustomPaint(painter: _PlanoPainter(columnas, filas, u, recorrido.map(px).toList())),
              ),
              for (final l in lugares)
                Positioned(
                  left: px(Offset(l.x, l.y)).dx - u * .3,
                  top: px(Offset(l.x, l.y)).dy - u * .3,
                  width: u * .6,
                  height: u * .6,
                  child: FittedBox(child: Text(l.emoji)),
                ),
              Positioned(
                left: px(auto).dx - 16,
                top: px(auto).dy - 16,
                child: Transform.rotate(
                  angle: angulo,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Paleta.marca,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(blurRadius: 6, color: Color(0x55000000))],
                    ),
                    child: const Icon(Icons.navigation, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ]),
          ),
        ),
      );
    });
  }
}

class _PlanoPainter extends CustomPainter {
  _PlanoPainter(this.columnas, this.filas, this.u, this.recorrido);
  final int columnas, filas;
  final double u;
  final List<Offset> recorrido;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFE8EFE3));
    // Manzanas
    final manzana = Paint()..color = const Color(0xFFF5F0E6);
    for (var x = 0; x < columnas - 1; x++) {
      for (var y = 0; y < filas - 1; y++) {
        final r = Rect.fromLTWH((x + .5) * u + u * .12, (y + .5) * u + u * .12, u * .76, u * .76);
        canvas.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(u * .08)), manzana);
      }
    }
    // Calles
    final calle = Paint()
      ..color = Colors.white
      ..strokeWidth = u * .2;
    for (var x = 0; x < columnas; x++) {
      canvas.drawLine(Offset((x + .5) * u, 0), Offset((x + .5) * u, size.height), calle);
    }
    for (var y = 0; y < filas; y++) {
      canvas.drawLine(Offset(0, (y + .5) * u), Offset(size.width, (y + .5) * u), calle);
    }
    // Recorrido hecho
    if (recorrido.length > 1) {
      final path = Path()..moveTo(recorrido.first.dx, recorrido.first.dy);
      for (final p in recorrido.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = Paleta.marca.withValues(alpha: .7)
          ..strokeWidth = u * .1
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(_PlanoPainter old) => old.recorrido != recorrido || old.u != u;
}
