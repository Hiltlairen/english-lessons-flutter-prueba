// ============================================================
// menu.dart — Menú inicial: elegir qué actividad probar
// ============================================================
// Agrupado en las 5 franjas de dificultad (igual que el panel
// "Crear actividad" del docente).
// ============================================================
import 'package:flutter/material.dart';

import '../actividades/catalogo.dart';
import '../actividades/comun.dart';
import 'actividad.dart';

class MenuPantalla extends StatelessWidget {
  const MenuPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    final franjas = [
      for (final n in nivelesDificultad.keys)
        (n, catalogo.where((a) => a.dificultad == n).toList()..sort((a, b) => a.titulo.compareTo(b.titulo)))
    ].where((f) => f.$2.isNotEmpty);

    return Scaffold(
      backgroundColor: Paleta.fondo,
      body: SafeArea(
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('English Lessons',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Paleta.tinta)),
                const SizedBox(height: 4),
                Text('Modo prueba · ${catalogo.length} actividades con preguntas y respuestas de ejemplo',
                    style: const TextStyle(color: Paleta.suave)),
              ]),
            ),
          ),
          for (final (nivel, actividades) in franjas) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(children: [
                  _Estrellas(nivel),
                  const SizedBox(width: 8),
                  Text('Nivel $nivel · ${nivelesDificultad[nivel]}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Paleta.tinta)),
                ]),
              ),
            ),
            SliverList.builder(
              itemCount: actividades.length,
              itemBuilder: (_, i) => _TarjetaActividad(actividad: actividades[i]),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ]),
      ),
    );
  }
}

class _Estrellas extends StatelessWidget {
  const _Estrellas(this.n);
  final int n;

  @override
  Widget build(BuildContext context) => Row(children: [
        for (var i = 1; i <= 5; i++)
          Icon(Icons.circle, size: 8, color: i <= n ? Paleta.marca : Paleta.linea),
      ]);
}

class _TarjetaActividad extends StatelessWidget {
  const _TarjetaActividad({required this.actividad});
  final Actividad actividad;

  @override
  Widget build(BuildContext context) {
    final a = actividad;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: Paleta.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Paleta.linea, width: 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ActividadPantalla(actividad: a))),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Paleta.selFondo, borderRadius: BorderRadius.circular(14)),
                child: Text(a.icono, style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.titulo, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(a.resumen, style: const TextStyle(color: Paleta.suave, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text('${a.codigo} · ${a.primitiva}',
                      style: const TextStyle(color: Paleta.marca, fontSize: 11, fontWeight: FontWeight.w700)),
                ]),
              ),
              const Icon(Icons.chevron_right, color: Paleta.suave),
            ]),
          ),
        ),
      ),
    );
  }
}
