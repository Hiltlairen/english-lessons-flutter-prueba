// ============================================================
// catalogo.dart — Las 20 actividades con contenido de PRUEBA
// ============================================================
// Mismo orden y mismos datos de catálogo que
// server/src/domain/activityScenes.js (de menor a mayor dificultad).
// En la app real el contenido lo genera el servidor (IA o generador
// local); aquí cada actividad trae preguntas y respuestas fijas para
// ver cómo funciona su mecánica.
// ============================================================
import 'package:flutter/material.dart';

import '../logica/generadores.dart';
import 'comun.dart';
import 'primitivas/armar_escenario.dart';
import 'primitivas/basquet.dart';
import 'primitivas/cancion.dart';
import 'primitivas/direcciones.dart';
import 'primitivas/emparejar.dart';
import 'primitivas/escribir.dart';
import 'primitivas/impostor.dart';
import 'primitivas/laberinto.dart';
import 'primitivas/libre.dart';
import 'primitivas/ordenar.dart';
import 'primitivas/quiz.dart';
import 'primitivas/sopa.dart';

typedef ConstructorActividad = Widget Function(AlTerminar onFinish, VoidCallback onSalir);

class Actividad {
  const Actividad({
    required this.codigo,
    required this.titulo,
    required this.resumen,
    required this.icono,
    required this.dificultad,
    required this.primitiva,
    required this.construir,
    this.instrucciones,
    this.anuncio,
    this.llamada,
  });

  final String codigo;
  final String titulo;
  final String resumen;
  final String icono;
  final int dificultad;

  /// Nombre de la mecánica que usa (para el menú).
  final String primitiva;
  final String? instrucciones;

  /// 14-anuncios: texto que se lee en voz alta al abrir.
  final String? anuncio;

  /// 12-llamada: nombre de quien llama (cabecera tipo teléfono).
  final String? llamada;
  final ConstructorActividad construir;
}

const nivelesDificultad = {1: 'Básico', 2: 'Elemental', 3: 'Intermedio', 4: 'Avanzado', 5: 'Experto'};

final List<Actividad> catalogo = [
  // ══════════════════ NIVEL 1 · BÁSICO ══════════════════
  Actividad(
    codigo: '01-emparejar',
    titulo: 'Match the words',
    resumen: 'Une cada palabra en inglés con su traducción.',
    icono: '⇄',
    dificultad: 1,
    primitiva: 'Emparejar',
    instrucciones: 'Match each Spanish word with its English translation.',
    construir: (fin, salir) => Emparejar(
      onFinish: fin,
      onSalir: salir,
      izquierda: const [
        CeldaPar('L1', 'gato'), CeldaPar('L2', 'libro'), CeldaPar('L3', 'ventana'),
        CeldaPar('L4', 'manzana'), CeldaPar('L5', 'escuela'), CeldaPar('L6', 'amigo'),
      ],
      derecha: const [
        CeldaPar('R1', 'Cat'), CeldaPar('R2', 'Book'), CeldaPar('R3', 'Window'),
        CeldaPar('R4', 'Apple'), CeldaPar('R5', 'School'), CeldaPar('R6', 'Friend'),
      ],
      pares: const {'L1': 'R1', 'L2': 'R2', 'L3': 'R3', 'L4': 'R4', 'L5': 'R5', 'L6': 'R6'},
    ),
  ),
  Actividad(
    codigo: '04-sopa-letras',
    titulo: 'Word Search',
    resumen: 'Busca las palabras de la lección escondidas en una sopa de letras.',
    icono: '⌗',
    dificultad: 1,
    primitiva: 'Sopa de letras',
    instrucciones: 'Find the English words. The clue is in Spanish.',
    construir: (fin, salir) => SopaLetras(
      onFinish: fin,
      onSalir: salir,
      palabras: const [
        PalabraSopa('CAT', 'gato'), PalabraSopa('DOG', 'perro'), PalabraSopa('HOUSE', 'casa'),
        PalabraSopa('WATER', 'agua'), PalabraSopa('BREAD', 'pan'), PalabraSopa('TABLE', 'mesa'),
        PalabraSopa('RIVER', 'río'), PalabraSopa('MUSIC', 'música'),
      ],
    ),
  ),

  // ══════════════════ NIVEL 2 · ELEMENTAL ══════════════════
  Actividad(
    codigo: '06-diccionario',
    titulo: 'Translate it!',
    resumen: 'Traduce palabras escribiendo la respuesta.',
    icono: '📖',
    dificultad: 2,
    primitiva: 'Escribir',
    instrucciones: 'Write the English word.',
    construir: (fin, salir) => Escribir(
      onFinish: fin,
      onSalir: salir,
      items: const [
        ItemEscribir(prompt: 'perro', respuesta: 'dog', lang: 'es-ES'),
        ItemEscribir(prompt: 'casa', respuesta: 'house', alternativas: ['home'], lang: 'es-ES'),
        ItemEscribir(prompt: 'agua', respuesta: 'water', lang: 'es-ES'),
        ItemEscribir(prompt: 'lápiz', respuesta: 'pencil', lang: 'es-ES'),
        ItemEscribir(prompt: 'fideos', respuesta: 'pasta', alternativas: ['noodles'], lang: 'es-ES'),
      ],
    ),
  ),
  Actividad(
    codigo: '07-direcciones',
    titulo: 'Find the way',
    resumen: 'En un mapa, sigue las indicaciones en inglés para llegar a un lugar.',
    icono: '🚗',
    dificultad: 3,
    primitiva: 'Mapa',
    construir: (fin, salir) => Direcciones(
      onFinish: fin,
      onSalir: salir,
      destino: "Grandma's house",
      motivo: 'Hoy es el cumpleaños de la abuela. Escucha al GPS y elige lo que entendiste.',
      guia: 'GPS',
      llegada: "You have arrived at Grandma's house. Happy birthday, Grandma!",
      ruta: const [Offset(3, 5), Offset(3, 3), Offset(1, 3), Offset(1, 1), Offset(1, .45)],
      lugares: const [
        Lugar('🏦', 3.5, 2.5), Lugar('🌳', .5, 3.5), Lugar('🏠', 1.5, .5),
        Lugar('🏫', 2.5, 4.5), Lugar('⛪', 3.5, .5), Lugar('🏪', .5, 1.5),
      ],
      pasos: const [
        PasoRuta('Go straight for two blocks.', [
          Opcion('Seguir recto dos cuadras', correcta: true, accion: 'recto'),
          Opcion('Girar a la izquierda ahora', accion: 'izquierda'),
          Opcion('Girar a la derecha ahora', accion: 'derecha'),
        ]),
        PasoRuta('Turn left at the bank.', [
          Opcion('Girar a la izquierda en el banco', correcta: true, accion: 'izquierda'),
          Opcion('Girar a la derecha en el banco', accion: 'derecha'),
          Opcion('Seguir recto pasando el banco', accion: 'recto'),
        ]),
        PasoRuta('Turn right at the park.', [
          Opcion('Girar a la derecha en el parque', correcta: true, accion: 'derecha'),
          Opcion('Girar a la izquierda en el parque', accion: 'izquierda'),
          Opcion('Parar en el parque', accion: 'llegar'),
        ]),
        PasoRuta("Go a little further and stop. The house is on your right.", [
          Opcion('Avanzar un poco y parar: la casa está a la derecha', correcta: true, accion: 'llegar'),
          Opcion('Avanzar un poco y parar: la casa está a la izquierda', accion: 'llegar'),
          Opcion('Girar a la derecha y seguir', accion: 'derecha'),
        ]),
      ],
    ),
  ),
  Actividad(
    codigo: '13-pedido',
    titulo: 'Order at the counter',
    resumen: 'Pide en un mostrador eligiendo la frase correcta en cada turno.',
    icono: '🍽️',
    dificultad: 2,
    primitiva: 'Quiz (chat)',
    construir: (fin, salir) => Quiz(
      onFinish: fin,
      onSalir: salir,
      penalizacion: 10,
      etiqueta: 'Pedido',
      icono: '🍽️',
      titulo: 'Elige qué responder',
      interlocutor: '🧑‍🍳',
      contexto: const [
        Turno('Waiter', 'Hi! Welcome to Sunny Café. What can I get you?'),
        Turno('You', '…', mio: true),
        Turno('Waiter', 'Sure. Small, medium or large?'),
        Turno('You', '…', mio: true),
        Turno('Waiter', 'Anything else?'),
        Turno('You', '…', mio: true),
        Turno('Waiter', "That's 6 dollars, please."),
        Turno('You', '…', mio: true),
      ],
      items: const [
        ItemQuiz(enunciado: '¿Qué dices?', hasta: 1, opciones: [
          Opcion("I'd like an orange juice, please.", correcta: true),
          Opcion('I am an orange juice.'),
          Opcion('Give orange juice me.'),
        ]),
        ItemQuiz(enunciado: '¿Qué dices?', hasta: 3, opciones: [
          Opcion('A medium one, please.', correcta: true),
          Opcion('Yes, I do.'),
          Opcion('At three o\'clock.'),
        ]),
        ItemQuiz(enunciado: '¿Qué dices?', hasta: 5, opciones: [
          Opcion('Yes, a chicken sandwich, please.', correcta: true),
          Opcion('No, I am not hungry yesterday.'),
          Opcion('Anything else, please.'),
        ]),
        ItemQuiz(enunciado: '¿Qué dices?', hasta: 7, opciones: [
          Opcion('Here you are. Thank you!', correcta: true),
          Opcion("You're welcome, six dollars."),
          Opcion('Goodbye, please.'),
        ]),
      ],
    ),
  ),
  Actividad(
    codigo: '17-emparejar-imagenes',
    titulo: 'Picture match',
    resumen: 'Une cada imagen con su palabra.',
    icono: '🖼️',
    dificultad: 2,
    primitiva: 'Emparejar (imágenes)',
    construir: (fin, salir) => Emparejar(
      onFinish: fin,
      onSalir: salir,
      izquierda: const [
        CeldaPar('L1', 'Dog', imagen: '🐶'), CeldaPar('L2', 'Chair'),
        CeldaPar('L3', 'Apple', imagen: '🍎'), CeldaPar('L4', 'Phone'),
        CeldaPar('L5', 'Plant', imagen: '🪴'), CeldaPar('L6', 'Mother'),
      ],
      derecha: const [
        CeldaPar('R1', 'perro'), CeldaPar('R2', 'silla'), CeldaPar('R3', 'manzana'),
        CeldaPar('R4', 'teléfono'), CeldaPar('R5', 'planta'), CeldaPar('R6', 'madre'),
      ],
      pares: const {'L1': 'R1', 'L2': 'R2', 'L3': 'R3', 'L4': 'R4', 'L5': 'R5', 'L6': 'R6'},
    ),
  ),
  Actividad(
    codigo: '19-impostor',
    titulo: 'Find the impostor',
    resumen: 'Encuentra la única tarjeta mal traducida entre seis.',
    icono: '🕵️',
    dificultad: 2,
    primitiva: 'Impostor',
    construir: (fin, salir) => Impostor(
      onFinish: fin,
      onSalir: salir,
      rondas: const [
        [
          Tarjeta('🐱', 'Cat', 'gato'), Tarjeta('🐶', 'Dog', 'perro'), Tarjeta('📚', 'Book', 'libro'),
          Tarjeta('💧', 'Water', 'agua'), Tarjeta('🏠', 'House', 'casa'),
          Tarjeta('🍎', 'Apple', 'pan', correcta: false),
        ],
        [
          Tarjeta('🪑', 'Chair', 'silla'), Tarjeta('🪟', 'Window', 'ventana'), Tarjeta('✏️', 'Pencil', 'lápiz'),
          Tarjeta('🎵', 'Music', 'música'), Tarjeta('🌊', 'River', 'mesa', correcta: false),
          Tarjeta('📱', 'Phone', 'teléfono'),
        ],
        [
          Tarjeta('🍞', 'Bread', 'pan'), Tarjeta('🏫', 'School', 'escuela'),
          Tarjeta('🌷', 'Garden', 'jardín'), Tarjeta('👩', 'Mother', 'padre', correcta: false),
          Tarjeta('🪴', 'Plant', 'planta'), Tarjeta('🧑‍🤝‍🧑', 'Friend', 'amigo'),
        ],
      ],
    ),
  ),
  Actividad(
    codigo: '20-basquetbol',
    titulo: 'Shoot the hoop',
    resumen: 'Lanza al aro eligiendo la traducción correcta entre tres opciones.',
    icono: '🏀',
    dificultad: 2,
    primitiva: 'Básquet',
    instrucciones: 'Shoot from the spot with the right translation.',
    construir: (fin, salir) => Basquet(
      onFinish: fin,
      onSalir: salir,
      tiros: const [
        Tiro('perro', [Opcion('Dog', correcta: true), Opcion('Cat'), Opcion('Bird')]),
        Tiro('ventana', [Opcion('Window', correcta: true), Opcion('Door'), Opcion('Wall')]),
        Tiro('manzana', [Opcion('Apple', correcta: true), Opcion('Orange'), Opcion('Bread')]),
        Tiro('escuela', [Opcion('School', correcta: true), Opcion('Church'), Opcion('Shop')]),
        Tiro('río', [Opcion('River', correcta: true), Opcion('Road'), Opcion('Rain')]),
      ],
    ),
  ),

  // ══════════════════ NIVEL 3 · INTERMEDIO ══════════════════
  Actividad(
    codigo: '02-conversacion-completar',
    titulo: 'Complete the conversation',
    resumen: 'Completa una conversación eligiendo la frase que falta en cada hueco.',
    icono: '💬',
    dificultad: 3,
    primitiva: 'Quiz (chat)',
    construir: (fin, salir) => Quiz(
      onFinish: fin,
      onSalir: salir,
      penalizacion: 10,
      etiqueta: 'Nuevo patrón',
      titulo: 'Escoge la palabra que falta',
      interlocutor: '👦🏽',
      contexto: const [
        Turno('Leo', 'Hi! How are you today?'),
        Turno('You', "I'm … , thanks. And you?", mio: true),
        Turno('Leo', "Great! What are you doing this weekend?"),
        Turno('You', "I'm going … the cinema with my sister.", mio: true),
        Turno('Leo', 'Cool! What movie?'),
        Turno('You', 'A comedy. Do you … to come?', mio: true),
      ],
      items: const [
        ItemQuiz(enunciado: "I'm _____ , thanks. And you?", hasta: 1, opciones: [
          Opcion('fine', correcta: true), Opcion('fifteen'), Opcion('friend'),
        ]),
        ItemQuiz(enunciado: "I'm going _____ the cinema with my sister.", hasta: 3, opciones: [
          Opcion('to', correcta: true), Opcion('in'), Opcion('at'),
        ]),
        ItemQuiz(enunciado: 'A comedy. Do you _____ to come?', hasta: 5, opciones: [
          Opcion('want', correcta: true), Opcion('wants'), Opcion('wanting'),
        ]),
      ],
    ),
  ),
  Actividad(
    codigo: '03-conversation-selection',
    titulo: 'Pick the right answer',
    resumen: 'Elige la respuesta adecuada en cada turno de un diálogo cara a cara.',
    icono: '🗣️',
    dificultad: 3,
    primitiva: 'Quiz (chat)',
    construir: (fin, salir) => Quiz(
      onFinish: fin,
      onSalir: salir,
      penalizacion: 10,
      etiqueta: 'Conversación',
      icono: '💬',
      titulo: 'Elige la mejor respuesta',
      interlocutor: '👩🏻',
      contexto: const [
        Turno('Anna', 'Excuse me, is this the bus stop for downtown?'),
        Turno('Anna', 'Thank you! Do you know what time the next bus comes?'),
        Turno('Anna', 'Oh, I see. Is it far to walk?'),
      ],
      items: const [
        ItemQuiz(enunciado: '¿Qué respondes?', hasta: 1, opciones: [
          Opcion('Yes, it is. The number 5 goes downtown.', correcta: true),
          Opcion('Yes, I am a bus.'),
          Opcion('No, thank you. I am fine.'),
        ]),
        ItemQuiz(enunciado: '¿Qué respondes?', hasta: 2, opciones: [
          Opcion('In about ten minutes.', correcta: true),
          Opcion('It is blue.'),
          Opcion('Ten years old.'),
        ]),
        ItemQuiz(enunciado: '¿Qué respondes?', hasta: 3, opciones: [
          Opcion('Not really, about fifteen minutes on foot.', correcta: true),
          Opcion('Yes, I like walking dogs.'),
          Opcion('It is at the bus.'),
        ]),
      ],
    ),
  ),
  Actividad(
    codigo: '08-inflexion',
    titulo: 'Change the word!',
    resumen: 'Cambia la forma de la palabra (plural, pasado, -ing…) siguiendo una regla.',
    icono: '◈',
    dificultad: 3,
    primitiva: 'Escribir',
    construir: (fin, salir) => Escribir(
      onFinish: fin,
      onSalir: salir,
      etiqueta: 'Nuevo patrón',
      icono: '◈',
      titulo: 'Completa la forma correcta',
      items: const [
        ItemEscribir(prompt: 'Plural: box', respuesta: 'boxes', regla: 'Plural con -es', pista: 'Termina en -x: agrega -es.'),
        ItemEscribir(prompt: 'Past simple: play', respuesta: 'played', regla: 'Pasado regular (-ed)'),
        ItemEscribir(prompt: 'She _____ (go) to school every day.', respuesta: 'goes', regla: 'Presente simple (3ª persona)', pista: 'he / she / it → -s o -es.'),
        ItemEscribir(prompt: 'They are _____ (run) in the park.', respuesta: 'running', regla: 'Gerundio (-ing)', pista: 'Consonante + vocal + consonante: se dobla la última.'),
        ItemEscribir(prompt: 'Plural: baby', respuesta: 'babies', regla: 'Plural con -ies', pista: 'Consonante + y → -ies.'),
      ],
    ),
  ),
  Actividad(
    codigo: '11-indicaciones',
    titulo: 'Give directions',
    resumen: 'Ordena los pasos para explicarle a un turista cómo llegar a un lugar.',
    icono: '🧭',
    dificultad: 3,
    primitiva: 'Ordenar',
    instrucciones: 'A tourist asks: "How do I get to the museum?" Put the steps in order.',
    construir: (fin, salir) => Ordenar(
      onFinish: fin,
      onSalir: salir,
      pasos: const [
        Paso('P1', 'Go out of the hotel.'),
        Paso('P2', 'Turn right.'),
        Paso('P3', 'Go straight for two blocks.'),
        Paso('P4', 'Turn left at the pharmacy.'),
        Paso('P5', "The museum is on your right."),
      ],
      ordenCorrecto: const ['P1', 'P2', 'P3', 'P4', 'P5'],
    ),
  ),
  Actividad(
    codigo: '14-anuncios',
    titulo: 'Listen and choose',
    resumen: 'Escucha un anuncio (estación, aeropuerto…) y responde preguntas.',
    icono: '📢',
    dificultad: 3,
    primitiva: 'Quiz (panel) + voz',
    anuncio: 'Attention, please. The train to Oruro will leave from platform three at ten thirty. '
        'Passengers to Oruro, please go to platform three. The train is ten minutes late.',
    construir: (fin, salir) => Quiz(
      onFinish: fin,
      onSalir: salir,
      penalizacion: 10,
      formato: FormatoQuiz.panel,
      etiqueta: 'Escucha',
      icono: '🔊',
      titulo: 'Escucha y responde',
      items: const [
        ItemQuiz(enunciado: 'Where is the train going?', opciones: [
          Opcion('To Oruro', correcta: true), Opcion('To Cochabamba'), Opcion('To Potosí'),
        ]),
        ItemQuiz(enunciado: 'Which platform?', opciones: [
          Opcion('Platform three', correcta: true), Opcion('Platform two'), Opcion('Platform ten'),
        ]),
        ItemQuiz(enunciado: 'What time does it leave?', opciones: [
          Opcion('At 10:30', correcta: true), Opcion('At 3:10'), Opcion('At 10:13'),
        ]),
        ItemQuiz(enunciado: 'Is the train on time?', opciones: [
          Opcion('No, it is ten minutes late.', correcta: true),
          Opcion('Yes, it is on time.'),
          Opcion('No, it is cancelled.'),
        ]),
      ],
    ),
  ),
  Actividad(
    codigo: '18-armar-escenario',
    titulo: 'Set the scene',
    resumen: 'Coloca cada objeto en su lugar de la escena y descarta los que no van.',
    icono: '🏠',
    dificultad: 3,
    primitiva: 'Armar escenario',
    construir: (fin, salir) => ArmarEscenario(
      onFinish: fin,
      onSalir: salir,
      nombre: 'the bedroom',
      emoji: '🛏️',
      zonas: const [Zona('cama', 'On the bed', '🛏️'), Zona('escritorio', 'On the desk', '🗄️'), Zona('armario', 'In the wardrobe', '🚪')],
      objetos: const [
        Objeto('o1', 'Pillow', '🛌', zonaCorrecta: 'cama'),
        Objeto('o2', 'Lamp', '💡', zonaCorrecta: 'escritorio'),
        Objeto('o3', 'Shirt', '👕', zonaCorrecta: 'armario'),
        Objeto('o4', 'Laptop', '💻', zonaCorrecta: 'escritorio'),
        Objeto('o5', 'Fish', '🐟'),
        Objeto('o6', 'Car tire', '🛞'),
      ],
    ),
  ),

  // ══════════════════ NIVEL 4 · AVANZADO ══════════════════
  Actividad(
    codigo: '09-describir',
    titulo: 'What do you see?',
    resumen: 'Mira una escena y elige la descripción correcta de lo que ve.',
    icono: '🖼️',
    dificultad: 4,
    primitiva: 'Quiz',
    construir: (fin, salir) => Quiz(
      onFinish: fin,
      onSalir: salir,
      penalizacion: 10,
      etiqueta: 'Describe',
      icono: '🖼️',
      items: const [
        ItemQuiz(enunciado: '👧🏽⚽🌳☀️', opciones: [
          Opcion('A girl is playing football in the park.', correcta: true),
          Opcion('A boy is swimming in the sea.'),
          Opcion('A girl is sleeping in her bed.'),
        ]),
        ItemQuiz(enunciado: '👨‍🍳🍝🔥', opciones: [
          Opcion('A man is cooking pasta.', correcta: true),
          Opcion('A man is eating a pizza at a restaurant.'),
          Opcion('A woman is washing the dishes.'),
        ]),
        ItemQuiz(enunciado: '🧑‍🤝‍🧑🌧️☂️', opciones: [
          Opcion('Two friends are walking in the rain with an umbrella.', correcta: true),
          Opcion('Two friends are sunbathing on the beach.'),
          Opcion('A man is reading under a tree.'),
        ]),
      ],
    ),
  ),
  Actividad(
    codigo: '10-canciones',
    titulo: 'Fill in the lyrics!',
    resumen: 'Escucha una canción y escribe las palabras que faltan en la letra.',
    icono: '🎤',
    dificultad: 4,
    primitiva: 'Letra con huecos',
    construir: (fin, salir) => Cancion(
      onFinish: fin,
      onSalir: salir,
      titulo: 'Morning in the City (canción de prueba)',
      versos: const [
        [Parte.texto('The '), Parte.hueco('sun'), Parte.texto(' is coming up again,')],
        [Parte.texto('I '), Parte.hueco('open'), Parte.texto(' up my window wide,')],
        [Parte.texto('I call my '), Parte.hueco('friend'), Parte.texto(' and then')],
        [Parte.texto('we '), Parte.hueco('walk'), Parte.texto(' along the river side.')],
        [Parte.texto('Oh, the city '), Parte.hueco('sings'), Parte.texto(' to me,')],
        [Parte.texto("it's the only place I want to "), Parte.hueco('be'), Parte.texto('.')],
      ],
    ),
  ),
  Actividad(
    codigo: '12-llamada',
    titulo: 'Answer the call',
    resumen: 'Contesta una llamada y responde por turnos a quien habla.',
    icono: '📞',
    dificultad: 4,
    primitiva: 'Quiz (chat)',
    llamada: 'Aunt Mary',
    construir: (fin, salir) => Quiz(
      onFinish: fin,
      onSalir: salir,
      penalizacion: 10,
      etiqueta: 'Llamada',
      icono: '📞',
      titulo: 'Elige qué responder',
      interlocutor: '👵🏼',
      contexto: const [
        Turno('Aunt Mary', 'Hello? Is that you, sweetheart?'),
        Turno('You', '…', mio: true),
        Turno('Aunt Mary', "I'm calling about Sunday. Can you come to lunch?"),
        Turno('You', '…', mio: true),
        Turno('Aunt Mary', 'Wonderful! Can you bring some bread?'),
        Turno('You', '…', mio: true),
      ],
      items: const [
        ItemQuiz(enunciado: '¿Qué dices?', hasta: 1, opciones: [
          Opcion("Hi, Aunt Mary! Yes, it's me.", correcta: true),
          Opcion('Goodbye, Aunt Mary.'),
          Opcion('I am Sunday.'),
        ]),
        ItemQuiz(enunciado: '¿Qué dices?', hasta: 3, opciones: [
          Opcion("Sure, I'd love to. What time?", correcta: true),
          Opcion('Yes, I ate lunch yesterday.'),
          Opcion('No, I am a lunch.'),
        ]),
        ItemQuiz(enunciado: '¿Qué dices?', hasta: 5, opciones: [
          Opcion('Of course. See you on Sunday!', correcta: true),
          Opcion('Bread is very tall.'),
          Opcion("No, I don't have a phone."),
        ]),
      ],
    ),
  ),
  Actividad(
    codigo: '16-rompecabezas-oracion',
    titulo: 'Sentence jigsaw',
    resumen: 'Arma oraciones encajando las palabras como piezas de rompecabezas.',
    icono: '🧩',
    dificultad: 4,
    primitiva: 'Rompecabezas',
    construir: (fin, salir) => Rompecabezas(
      onFinish: fin,
      onSalir: salir,
      oraciones: const [
        OracionPuzzle(
          oracion: 'My brother plays the guitar.',
          traduccion: 'Mi hermano toca la guitarra.',
          piezas: ['My', 'brother', 'plays', 'the', 'guitar.'],
        ),
        OracionPuzzle(
          oracion: 'We are going to the beach tomorrow.',
          traduccion: 'Mañana vamos a ir a la playa.',
          piezas: ['We', 'are going', 'to', 'the beach', 'tomorrow.'],
        ),
        OracionPuzzle(
          oracion: 'Did you finish your homework?',
          traduccion: '¿Terminaste tu tarea?',
          piezas: ['Did', 'you', 'finish', 'your', 'homework?'],
        ),
      ],
    ),
  ),

  // ══════════════════ NIVEL 5 · EXPERTO ══════════════════
  Actividad(
    codigo: '05-redaccion',
    titulo: 'My Writing',
    resumen: 'Escribe un texto corto según una situación; la IA lo evalúa y el docente confirma la nota.',
    icono: '✍️',
    dificultad: 5,
    primitiva: 'Producción libre',
    construir: (fin, salir) => Libre(
      onFinish: fin,
      onSalir: salir,
      contexto: 'Estás en la cafetería esperando a un amigo que llega tarde.',
      consigna: 'Write a message to your friend. Tell him where you are, what you are doing and ask when he will arrive.',
      minimo: 30,
      criterios: const [Criterio('Encaja en la situación', 50), Criterio('Escritura correcta', 50)],
    ),
  ),
  Actividad(
    codigo: '15-laberinto-palabras',
    titulo: 'Word Maze',
    resumen: 'Recorre una cuadrícula pisando las palabras en el orden correcto de la oración.',
    icono: '🗼',
    dificultad: 5,
    primitiva: 'Laberinto',
    construir: (fin, salir) => Laberinto(
      onFinish: fin,
      onSalir: salir,
      niveles: const [
        NivelLaberinto(
          oracion: 'I like green apples',
          traduccion: 'Me gustan las manzanas verdes',
          palabras: ['I', 'like', 'green', 'apples'],
          distractores: ['likes', 'apple'],
        ),
        NivelLaberinto(
          oracion: 'She is reading a book',
          traduccion: 'Ella está leyendo un libro',
          palabras: ['She', 'is', 'reading', 'a', 'book'],
          distractores: ['are', 'read'],
        ),
        NivelLaberinto(
          oracion: 'We went to the market',
          traduccion: 'Fuimos al mercado',
          palabras: ['We', 'went', 'to', 'the', 'market'],
          distractores: ['go', 'in', 'a'],
        ),
      ],
    ),
  ),
];
