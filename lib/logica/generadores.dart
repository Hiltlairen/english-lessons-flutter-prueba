// ============================================================
// generadores.dart — Lógica pura portada de web/src/lib/
// ============================================================
//   · construirSopa        ← wordsearch.js     (04-sopa-letras)
//   · construirLaberinto   ← wordmaze.js       (15-laberinto-palabras)
//   · generarPiezas        ← sentencePuzzle.js (16-rompecabezas-oracion)
// Mismo criterio que la web: el contenido (palabras, oraciones) viene
// dado; el "dibujo" se arma aquí y siempre es válido.
// ============================================================
import 'dart:math';

import 'package:flutter/painting.dart';

final _azar = Random();

// ════════════════════════════════════════════════════════════
//  SOPA DE LETRAS
// ════════════════════════════════════════════════════════════
class PalabraSopa {
  const PalabraSopa(this.palabra, this.pista);
  final String palabra;
  final String pista;
}

class Colocacion {
  Colocacion(this.palabra, this.pista, this.celdas);
  final String palabra;
  final String pista;
  final List<(int, int)> celdas;
}

class Sopa {
  Sopa(this.grid, this.colocaciones);
  final List<List<String>> grid;
  final List<Colocacion> colocaciones;
}

const _vectores = {
  'horizontal': [(0, 1)],
  'vertical': [(1, 0)],
  'diagonal': [(1, 1), (1, -1)],
};

Sopa construirSopa(List<PalabraSopa> palabras,
    {int filas = 12, int columnas = 12, List<String> direcciones = const ['horizontal', 'vertical', 'diagonal']}) {
  final grid = List.generate(filas, (_) => List<String?>.filled(columnas, null));
  final pool = [for (final d in direcciones) ...?_vectores[d]];
  if (pool.isEmpty) pool.addAll(_vectores['horizontal']!);
  final colocaciones = <Colocacion>[];

  final ordenadas = [...palabras]..sort((a, b) => b.palabra.length - a.palabra.length);
  for (final item in ordenadas) {
    final w = item.palabra.toUpperCase().replaceAll(RegExp('[^A-Z]'), '');
    if (w.isEmpty || w.length > max(filas, columnas)) continue;
    for (var intento = 0; intento < 200; intento++) {
      final (dr, dc) = pool[_azar.nextInt(pool.length)];
      final r0 = _azar.nextInt(filas), c0 = _azar.nextInt(columnas);
      var cabe = true;
      for (var i = 0; i < w.length && cabe; i++) {
        final r = r0 + dr * i, c = c0 + dc * i;
        if (r < 0 || r >= filas || c < 0 || c >= columnas) {
          cabe = false;
        } else if (grid[r][c] != null && grid[r][c] != w[i]) {
          cabe = false;
        }
      }
      if (!cabe) continue;
      final celdas = <(int, int)>[];
      for (var i = 0; i < w.length; i++) {
        grid[r0 + dr * i][c0 + dc * i] = w[i];
        celdas.add((r0 + dr * i, c0 + dc * i));
      }
      colocaciones.add(Colocacion(w, item.pista, celdas));
      break;
    }
  }
  const letras = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  final lleno = [
    for (final fila in grid) [for (final l in fila) l ?? letras[_azar.nextInt(26)]]
  ];
  return Sopa(lleno, colocaciones);
}

// ════════════════════════════════════════════════════════════
//  LABERINTO DE PALABRAS (estilo Helltaker)
// ════════════════════════════════════════════════════════════
// Primero se genera un CAMINO auto-evitante de N casillas: la primera
// es el punto de partida y las siguientes, en orden, las palabras de la
// oración. Como el camino existe por construcción, siempre hay solución.
enum TipoCelda { inicio, objetivo, distractor, obstaculo, vacio }

class NivelLaberinto {
  const NivelLaberinto({required this.oracion, required this.traduccion, required this.palabras, this.distractores = const []});
  final String oracion;
  final String traduccion;
  final List<String> palabras;
  final List<String> distractores;
}

class CeldaPalabra {
  CeldaPalabra(this.fila, this.columna, this.palabra, this.indice);
  final int fila, columna;
  final String palabra;
  final int indice;
}

class MapaLaberinto {
  MapaLaberinto({
    required this.filas,
    required this.columnas,
    required this.inicio,
    required this.tipos,
    required this.objetivos,
    required this.distractores,
    required this.presupuestoPasos,
  });
  final int filas, columnas;
  final (int, int) inicio;
  final List<List<TipoCelda>> tipos;
  final List<CeldaPalabra> objetivos;
  final List<CeldaPalabra> distractores;
  final int presupuestoPasos;
}

const _maxCeldas = 20;

List<(int, int)>? _camino(int filas, int columnas, int n) {
  for (var intento = 0; intento < 500; intento++) {
    var r = _azar.nextInt(filas), c = _azar.nextInt(columnas);
    final camino = [(r, c)];
    final vistas = {(r, c)};
    var atascado = false;
    while (camino.length < n) {
      final libres = [
        for (final (dr, dc) in const [(0, 1), (0, -1), (1, 0), (-1, 0)])
          if (r + dr >= 0 && r + dr < filas && c + dc >= 0 && c + dc < columnas && !vistas.contains((r + dr, c + dc)))
            (r + dr, c + dc)
      ];
      if (libres.isEmpty) {
        atascado = true;
        break;
      }
      (r, c) = libres[_azar.nextInt(libres.length)];
      camino.add((r, c));
      vistas.add((r, c));
    }
    if (!atascado) return camino;
  }
  return null;
}

MapaLaberinto construirLaberinto(NivelLaberinto nivel) {
  final palabras = nivel.palabras;
  final necesarias = min(_maxCeldas, 1 + palabras.length);

  // Tablero más compacto (≤ 20 casillas) donde quepan camino + distractores.
  var filas = 4, columnas = 5, mejor = 1 << 30;
  for (var f = 3; f <= 5; f++) {
    for (var c = 3; c <= 6; c++) {
      final total = f * c;
      if (total > _maxCeldas || total < 1 + palabras.length + nivel.distractores.length) continue;
      if (total < mejor) {
        mejor = total;
        filas = f;
        columnas = c;
      }
    }
  }

  final camino = _camino(filas, columnas, necesarias) ?? _camino(filas, columnas, min(necesarias, filas * columnas)) ?? [(0, 0)];
  final enCamino = camino.toSet();
  final libres = [
    for (var r = 0; r < filas; r++)
      for (var c = 0; c < columnas; c++)
        if (!enCamino.contains((r, c))) (r, c)
  ]..shuffle(_azar);

  final nDist = min(nivel.distractores.length, libres.length);
  final celdasDistractor = libres.sublist(0, nDist);
  final celdasObstaculo = libres.sublist(nDist).where((_) => _azar.nextDouble() < .35).toList();

  final tipos = List.generate(filas, (_) => List.filled(columnas, TipoCelda.vacio));
  tipos[camino[0].$1][camino[0].$2] = TipoCelda.inicio;
  final objetivos = <CeldaPalabra>[];
  for (var i = 1; i < camino.length; i++) {
    final (r, c) = camino[i];
    tipos[r][c] = TipoCelda.objetivo;
    objetivos.add(CeldaPalabra(r, c, palabras[i - 1], i - 1));
  }
  final distractores = <CeldaPalabra>[];
  for (var i = 0; i < celdasDistractor.length; i++) {
    final (r, c) = celdasDistractor[i];
    tipos[r][c] = TipoCelda.distractor;
    distractores.add(CeldaPalabra(r, c, nivel.distractores[i], -1));
  }
  for (final (r, c) in celdasObstaculo) {
    tipos[r][c] = TipoCelda.obstaculo;
  }

  // Pasos justos del camino + un margen chico (25 %, mínimo 1).
  final minimos = objetivos.length;
  return MapaLaberinto(
    filas: filas,
    columnas: columnas,
    inicio: camino[0],
    tipos: tipos,
    objetivos: objetivos,
    distractores: distractores,
    presupuestoPasos: minimos + max(1, (minimos * .25).round()),
  );
}

// ════════════════════════════════════════════════════════════
//  ROMPECABEZAS DE ORACIÓN
// ════════════════════════════════════════════════════════════
// Dos piezas CONSECUTIVAS comparten forma y color en el borde que las
// une. Las formas/colores se repiten en ciclo, así que el patrón ayuda
// pero no delata la respuesta: también hay que mirar la gramática.
class Conector {
  const Conector(this.glifo, this.color);
  final String glifo;
  final Color color;
}

class Pieza {
  Pieza(this.id, this.texto, this.indiceCorrecto, this.izquierdo, this.derecho);
  final String id;
  final String texto;
  final int indiceCorrecto;
  final Conector? izquierdo;
  final Conector? derecho;
}

const _glifos = ['●', '▲', '◆', '★'];
const _colores = [
  Color(0xFFEF8312), Color(0xFF2F6FED), Color(0xFF16A34A),
  Color(0xFFDC2626), Color(0xFF9333EA), Color(0xFF0891B2),
];

List<Pieza> generarPiezas(List<String> enOrden) {
  final n = enOrden.length;
  final conectores = [for (var i = 0; i < max(0, n - 1); i++) Conector(_glifos[i % 4], _colores[i % 6])];
  return [
    for (var i = 0; i < n; i++)
      Pieza('P$i', enOrden[i], i, i > 0 ? conectores[i - 1] : null, i < n - 1 ? conectores[i] : null)
  ];
}
