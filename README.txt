# ⚽ BarrasBalas

**Acción 2.5D de supervivencia por oleadas en un estadio de fútbol colombiano.**
El partido terminó, el resultado no le gustó a nadie y la barra invadió la cancha. Tú eres el árbitro.

> 🚧 **En desarrollo.** La primera versión jugable ya está completa: nivel, enemigos, oleadas, puntaje y condición de victoria. Ahora estamos en la fase de arte, efectos y contenido nuevo.

---

## 🎬 La premisa

Tras un partido lleno de decisiones polémicas, el pitazo final desata el caos: los barristas invaden el campo y el único objetivo de todo el estadio es el **árbitro central**. Atrapado en medio de la cancha y con la energía al límite, tiene que abrirse paso hasta el **túnel de camerinos** antes de que la turba lo alcance.

Su única defensa: **tarjetas, reflejos y un aerosol**.

**Barras** (bravas) + **Balas**: un shooter con humor que convierte la cultura del fútbol colombiano en un juego de acción.

---

## 🕹️ Gameplay

- **8 oleadas** de barristas que crecen en número y presión a medida que avanzas por las tres zonas del estadio.
- **Dispara tarjetas** apuntando con el mouse y **esquiva** con impulsos rápidos.
- **Tiempo muerto** entre oleadas: la policía hace retroceder a la barra, se recarga el aerosol y aparece agua para recuperar energía.
- Al despejar la última oleada se abre el túnel: **llega a camerinos y ganas**.
- **Puntos, combos y récord** guardado para volver a intentarlo.

### Enemigos

| Barrista | Comportamiento |
|---|---|
| **Tacleador** | Te persigue sin descanso y salta tribunas y obstáculos para alcanzarte. |
| **Lanzador** | Se planta en la tribuna, avisa con un "!" y te lanza botellas. |

### Controles

| Acción | Teclado / mouse |
|---|---|
| Moverse | `A` `D` / flechas |
| Saltar | `Espacio` |
| Apuntar y disparar tarjeta | Mouse + clic izquierdo |
| Aerosol (ciega 3 s, 2 usos por oleada) | Clic derecho |
| Esquivar | `Shift` |
| Rodar | `Q` |
| Hacer ruido (atrae barristas cercanos) | `R` |
| Interactuar | Mantener `E` |
| Pausa | `Esc` |

---

## 🎯 Referentes

| Juego | Qué tomamos |
|---|---|
| **Contra** | La acción lateral y el ritmo de avanzar disparando. |
| **DOOM (2016)** | El frenesí y premiar la agresividad: limpiar rápido acorta la oleada. |
| **Enter the Gungeon** | Proyectiles legibles y la esquiva como habilidad central. |

---

## 🛣️ Hoja de ruta

- [x] Nivel completo en tres zonas con túnel final
- [x] Dos tipos de barrista y sistema de oleadas con dificultad progresiva
- [x] HUD, puntaje, combos, récord y pantallas de victoria y derrota
- [x] Estadio con tribunas, público, iluminación y cánticos
- [ ] Enemigo aéreo
- [ ] Power-ups entre oleadas
- [ ] Efectos visuales de impacto y pulido de arte
- [ ] Jefe final: *el capo de la barra*
- [ ] Publicación en itch.io

---

## 🛠️ Correrlo desde el código

```bash
git clone https://github.com/allan-gomez-creator/Barrasbalas.git
```

1. Abre [Godot 4.7](https://godotengine.org/download) (versión estándar) → **Importar** → `project.godot`.
2. Presiona **F5**. La escena principal es `main.tscn`.

---

## 👥 Equipo

| | Rol | En el juego |
|---|---|---|
| **Allan Gómez** | Narrativa, diseño de niveles e integración | Mundo y mapa del estadio, tacleador, disparo y meta del túnel |
| **Juan Manuel Benítez Skolik** | Programación de gameplay | Movimiento del árbitro, aerosol, esquive, HUD, puntos y combos |
| **Martín Bonilla Cuéllar** | Enemigos, audio y sistemas | Lanzador, oleadas del nivel completo, sonido y pantalla de victoria |

Cada integrante desarrolla en su propia rama y los cambios entran a `main` mediante pull request.

---

## 📜 Créditos

Assets **CC0**: personajes y piezas del estadio de [Kenney](https://www.kenney.nl) y arco de [Soccer Field](https://opengameart.org/content/soccer-field) (tiko479). Detalle en [`CREDITOS.txt`](CREDITOS.txt).
