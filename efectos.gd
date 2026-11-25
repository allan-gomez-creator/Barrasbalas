extends Node3D
# Correccion 1 - Martín: efectos visuales de los golpes (VFX).
# Va en main.tscn y en el grupo "efectos". Los demás lo llaman con una línea,
# sin tocar este script, por ejemplo:
#     get_tree().call_group("efectos", "golpe", posicion)
#
#   golpe(posicion)         una tarjeta le pega a un barrista   (Allan, apuntar.gd)
#   expulsion(posicion)     un barrista sale expulsado          (Allan y Juan Manuel)
#   tacleo(posicion)        al árbitro le quitan energía        (Juan Manuel, personaje.gd)
#   botella_rota(posicion)  la botella o la bengala choca       (Juan Manuel, botella.gd)
#
# Cada efecto crea partículas que se lanzan una sola vez y se borran solas.
# Los sprites son del Particle Pack de Kenney (CC0), en assets/kenney_particle_pack/.
# Son blancos: aquí se pintan del color de cada efecto.
# Se usa CPUParticles3D porque el juego va con el renderizador Compatibility
# (el que sirve para exportar a la Web).

const CARPETA = "res://assets/kenney_particle_pack/"

const AMARILLO = Color(1.0, 0.85, 0.3)      # el mismo amarillo tarjeta del halo del árbitro
const ROJO = Color(0.9, 0.12, 0.12)
const VERDE_VIDRIO = Color(0.35, 0.8, 0.45)

var mallas = {}   # nombre del sprite → QuadMesh con su material (se crean una sola vez)


func _ready():
	add_to_group("efectos")


# ---------- Las 4 funciones que llaman los demás ----------

# Una tarjeta le pega a un barrista: destello amarillo pequeño y un tajo.
func golpe(posicion):
	chispazo(posicion, "star_06", 10, AMARILLO, 0.4, 2.0, 4.0, 0.4, 0.8, 0.0)
	chispazo(posicion, "scratch_01", 1, Color.WHITE, 0.25, 0.0, 0.0, 1.1, 1.1, 0.0)


# Un barrista sale expulsado: nube de humo, estrellas y la tarjeta roja que sube.
func expulsion(posicion):
	chispazo(posicion, "smoke_05", 12, Color(0.9, 0.9, 0.9), 0.9, 1.0, 2.5, 0.9, 1.6, 1.0)
	chispazo(posicion, "star_01", 8, AMARILLO, 0.5, 2.5, 5.0, 0.5, 0.9, 0.0)
	tarjeta_roja(posicion)


# Al árbitro le quitan energía: polvo y chispas rojas.
func tacleo(posicion):
	chispazo(posicion, "dirt_01", 12, Color(0.75, 0.6, 0.4), 0.6, 2.0, 4.0, 0.5, 0.9, -6.0)
	chispazo(posicion, "star_04", 8, ROJO, 0.45, 3.0, 5.0, 0.5, 0.8, 0.0)


# La botella choca: pedazos de vidrio verde que caen.
func botella_rota(posicion):
	chispazo(posicion, "dirt_02", 16, VERDE_VIDRIO, 0.7, 2.0, 4.5, 0.25, 0.5, -12.0)
	chispazo(posicion, "star_04", 4, Color.WHITE, 0.3, 1.0, 2.0, 0.5, 0.7, 0.0)


# ---------- Cómo se arma cada efecto ----------

# cantidad: cuántas partículas · vida: segundos que duran
# rapidez: entre qué velocidades salen (m/s) · tamano: entre qué tamaños (m)
# gravedad: m/s² hacia arriba (+) o hacia abajo (−)
func chispazo(posicion, sprite, cantidad, color, vida, rapidez_min, rapidez_max, tamano_min, tamano_max, gravedad):
	var p = CPUParticles3D.new()
	p.mesh = malla(sprite)
	p.amount = cantidad
	p.lifetime = vida
	p.one_shot = true
	p.explosiveness = 1.0               # todas salen al mismo tiempo
	p.local_coords = false
	p.direction = Vector3.UP
	p.spread = 180.0                    # en todas las direcciones
	p.initial_velocity_min = rapidez_min
	p.initial_velocity_max = rapidez_max
	p.gravity = Vector3(0, gravedad, 0)
	p.damping_min = 2.0                 # frenan un poco, para que no salgan disparadas
	p.damping_max = 4.0
	p.scale_amount_min = tamano_min
	p.scale_amount_max = tamano_max
	p.angle_min = 0.0                   # cada una sale girada distinto
	p.angle_max = 360.0
	# Color: se mantiene hasta el 60 % de su vida y luego se vuelve transparente.
	var degradado = Gradient.new()
	degradado.set_color(0, color)
	degradado.set_color(1, Color(color, 0.0))
	degradado.add_point(0.6, color)
	p.color_ramp = degradado
	# Primero apagada y en su lugar; si no, alcanza a salir en el centro del mapa.
	p.emitting = false
	add_child(p)
	p.global_position = posicion
	p.restart()                         # ahora sí: sale todo de una vez
	# Se borra sola cuando terminan todas las partículas.
	get_tree().create_timer(vida + 0.3, false).timeout.connect(p.queue_free)


# Un cuadrado plano con el sprite, que siempre mira a la cámara.
func malla(sprite):
	if mallas.has(sprite):
		return mallas[sprite]
	var material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.vertex_color_use_as_albedo = true    # así toma el color de cada efecto
	var ruta = CARPETA + sprite + ".png"
	if ResourceLoader.exists(ruta):
		material.albedo_texture = load(ruta)
	var quad = QuadMesh.new()
	quad.material = material
	mallas[sprite] = quad
	return quad


# La tarjeta roja del árbitro: aparece sobre el barrista, sube 1.2 m y se desvanece.
func tarjeta_roja(posicion):
	var material = StandardMaterial3D.new()
	material.albedo_color = ROJO
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var quad = QuadMesh.new()
	quad.size = Vector2(0.32, 0.45)
	quad.material = material
	var tarjeta = MeshInstance3D.new()
	tarjeta.mesh = quad
	add_child(tarjeta)
	tarjeta.global_position = posicion + Vector3(0, 0.6, 0)
	var animacion = create_tween().set_parallel(true)
	animacion.tween_property(tarjeta, "global_position", tarjeta.global_position + Vector3(0, 1.2, 0), 0.9) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	animacion.tween_property(material, "albedo_color:a", 0.0, 0.9).set_delay(0.3)
	animacion.chain().tween_callback(tarjeta.queue_free)
