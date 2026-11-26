extends CharacterBody3D
# Corrección 2 - Juan Manuel: la lechuza del Metropolitano (el enemigo aéreo).
# - Vuela a 4 m de alto, de lado a lado, siguiendo al árbitro.
# - Cada 4 s chilla, se pinta de violeta 0.5 s (el aviso) y se lanza en picada
#   al punto donde estaba el árbitro. Una sombra en el piso marca ese punto.
# - Si lo alcanza, le quita 1 de energía. Con el esquive (Shift) se le escapa.
# - Con 2 tarjetas se asusta y se va volando: 200 puntos y el efecto de expulsión.
# - El aerosol la deja ciega: mientras está ciega no se lanza.
# Va en los grupos "barristas" (así la cuentan las oleadas y la ciega el aerosol)
# y "aereos" (así las oleadas saben que ya hay una volando).
# El modelo (cubos, como los demás personajes) y la caja de choque se arman
# aquí mismo, por código: en la escena solo va el nodo Lechuza con este script.

enum Estado { VOLAR, AVISO, PICADA, SUBIR, CIEGA, ASUSTADA }

@export var objetivo: Node3D          # vacío = busca al árbitro por el grupo "arbitro"
@export var vida = 2                  # 2 tarjetas
@export var puntos = 200
@export var danio = 1

@export_group("Vuelo")
@export var altura = 5.0              # m sobre el piso de la cancha
@export var ancho = 3.0               # m a cada lado del árbitro en el vaivén
@export var vaiven = 3.0              # s que tarda en ir de un lado al otro
@export var rapidez = 6.0             # m/s volando normal

@export_group("Picada")
@export var cada_cuanto = 4.0         # s entre un chillido y el siguiente (aviso incluido)
@export var tiempo_aviso = 0.5        # s en violeta antes de lanzarse
@export var rapidez_picada = 11.0     # m/s bajando
@export var radio_golpe = 0.9         # m entre la lechuza y el pecho del árbitro para golpearlo

@export_group("Tamaño")
@export var tamano = 1.0              # 1 = 1 m de alto, más o menos
@export var caja = Vector3(0.8, 0.8, 0.8)   # la caja donde le pegan las tarjetas (más grande que el cuerpo, a propósito)

const VIOLETA = Color(0.62, 0.2, 0.95)
# Los colores de la lechuza de Martín.
const BLANCO = Color(0.97, 0.96, 0.92)
const DORADO = Color(0.85, 0.66, 0.38)
const BORDE = Color(0.78, 0.58, 0.36)
const OJO = Color(0.05, 0.04, 0.04)
const PICO = Color(0.92, 0.82, 0.72)
const PATA = Color(0.75, 0.62, 0.55)

var estado = Estado.VOLAR
var reloj = 0.0
var t = 0.0                # para el vaivén
var punto = Vector3.ZERO   # a dónde va la picada (el pecho del árbitro cuando chilló)
var golpeo = false         # para que cada picada pegue una sola vez
var modelo: Node3D
var ala_i: Node3D
var ala_d: Node3D
var aleteo = "volar"       # volar, picada o asustada
var mallas = []
var tinte: StandardMaterial3D
var alerta: Label3D
var sombra: MeshInstance3D
var chillido: AudioStreamPlayer


func _ready():
	add_to_group("barristas")
	add_to_group("aereos")
	if objetivo == null:
		objetivo = get_tree().get_first_node_in_group("arbitro")
	# Capa 2: las tarjetas le pegan, pero el árbitro y los tacleadores no chocan con ella.
	collision_layer = 2
	collision_mask = 0
	armar_modelo()
	armar_caja()
	preparar_aviso()
	preparar_sombra()
	preparar_chillido()
	reloj = cada_cuanto


func _process(delta):
	aletear(delta)


func _physics_process(delta):
	reloj -= delta
	if objetivo == null or not is_instance_valid(objetivo):
		return
	match estado:
		Estado.VOLAR:
			volar(delta)
			# Si el árbitro ya perdió, solo vuela.
			if reloj <= 0.0 and not objetivo.get("muerto"):
				cambiar_a(Estado.AVISO)
		Estado.AVISO:
			# Se queda quieta en el aire, en violeta, mientras la sombra marca el punto.
			if reloj <= 0.0:
				cambiar_a(Estado.PICADA)
		Estado.PICADA:
			var hacia = punto - global_position
			var paso = rapidez_picada * delta
			if hacia.length() <= paso:
				global_position = punto
				revisar_golpe()
				cambiar_a(Estado.SUBIR)
			else:
				global_position += hacia.normalized() * paso
				revisar_golpe()
		Estado.SUBIR:
			# Sube derecho; el vaivén la vuelve a poner sobre el árbitro.
			var arriba = Vector3(global_position.x, altura, 0)
			global_position = global_position.move_toward(arriba, rapidez * delta)
			if global_position.y >= altura - 0.1:
				cambiar_a(Estado.VOLAR)
		Estado.CIEGA:
			volar(delta)
			if reloj <= 0.0:
				cambiar_a(Estado.VOLAR)


func cambiar_a(nuevo):
	estado = nuevo
	marcar_peligro(estado == Estado.AVISO or estado == Estado.PICADA)
	sombra.visible = estado == Estado.AVISO or estado == Estado.PICADA
	match estado:
		Estado.VOLAR:
			reloj = cada_cuanto - tiempo_aviso   # 3.5 s volando + 0.5 s de aviso = 4 s
			aleteo = "volar"
		Estado.AVISO:
			reloj = tiempo_aviso
			punto = objetivo.global_position + Vector3(0, 0.9, 0)   # el pecho, donde está AHORA
			punto.z = 0.0
			sombra.global_position = Vector3(punto.x, piso_debajo(punto), 0)
			chillar()
			print(name, " chilló: va a lanzarse")
		Estado.PICADA:
			golpeo = false
			aleteo = "picada"
		Estado.SUBIR:
			aleteo = "volar"
		Estado.CIEGA:
			aleteo = "asustada"


# Va de lado a lado sobre el árbitro, a 4 m de alto.
func volar(delta):
	t += delta
	var x = objetivo.global_position.x + sin(t * PI / vaiven) * ancho
	var meta = Vector3(x, altura, 0)
	global_position = global_position.move_toward(meta, rapidez * delta)


func revisar_golpe():
	if golpeo:
		return
	var pecho = objetivo.global_position + Vector3(0, 0.9, 0)
	if global_position.distance_to(pecho) > radio_golpe:
		return
	golpeo = true
	# recibir_danio() ya no hace nada si el árbitro está esquivando o parpadeando.
	if objetivo.get("esquivando"):
		print(name, ": se le escapó con el esquive")
	elif objetivo.has_method("recibir_danio"):
		print(name, " alcanzó al árbitro")
		objetivo.recibir_danio(danio)
	cambiar_a(Estado.SUBIR)


# La llama el aerosol del árbitro. Mientras está ciega no se lanza;
# si estaba en picada, la cancela y vuelve a subir.
func cegar(segundos):
	if estado == Estado.ASUSTADA:
		return
	cambiar_a(Estado.CIEGA)
	reloj = segundos
	print(name, " cegada ", segundos, " s")


# La llaman las tarjetas del árbitro (apuntar.gd).
func recibir_golpe(danio_recibido):
	if estado == Estado.ASUSTADA:
		return
	vida -= danio_recibido
	print(name, ": vida ", vida)
	if vida <= 0:
		asustarse()


# Con 2 tarjetas se asusta: suma los puntos y se va volando hacia arriba.
func asustarse():
	print(name, " se asustó y se fue")
	cambiar_a(Estado.ASUSTADA)
	remove_from_group("barristas")   # para que las oleadas ya no la cuenten
	remove_from_group("aereos")
	collision_layer = 0              # las tarjetas ya no le pegan
	get_tree().call_group("puntaje", "sumar", puntos, global_position)
	get_tree().call_group("efectos", "expulsion", global_position)
	chillar()
	aleteo = "asustada"
	var lado = 1.0 if global_position.x >= objetivo.global_position.x else -1.0
	var tween = create_tween()
	tween.tween_property(self, "global_position", global_position + Vector3(lado * 12.0, 10.0, 0), 1.5)
	tween.tween_callback(queue_free)


# ---------- El modelo: cubos, como los demás personajes ----------

# Un solo cubo (cuerpo y cabeza a la vez) con la cara, los ojos, el pico, las alas y las patas.
# La cara mira a la cámara (+Z). El centro del cubo queda en el origen.
func armar_modelo():
	modelo = Node3D.new()
	modelo.name = "Cubos"
	modelo.scale = Vector3.ONE * tamano
	add_child(modelo)
	cubo(modelo, Vector3(0.6, 0.6, 0.6), Vector3(0, 0, 0), DORADO)             # el cubo
	cubo(modelo, Vector3(0.5, 0.36, 0.02), Vector3(0, 0.08, 0.305), BORDE)     # borde de la cara
	cubo(modelo, Vector3(0.44, 0.3, 0.02), Vector3(0, 0.08, 0.315), BLANCO)    # cara
	cubo(modelo, Vector3(0.36, 0.2, 0.02), Vector3(0, -0.18, 0.305), BLANCO)   # pecho
	cubo(modelo, Vector3(0.1, 0.1, 0.02), Vector3(-0.11, 0.11, 0.33), OJO)     # ojos
	cubo(modelo, Vector3(0.1, 0.1, 0.02), Vector3(0.11, 0.11, 0.33), OJO)
	cubo(modelo, Vector3(0.07, 0.1, 0.06), Vector3(0, 0.0, 0.34), PICO)        # pico
	cubo(modelo, Vector3(0.1, 0.1, 0.1), Vector3(-0.2, 0.33, 0), BORDE)        # orejitas
	cubo(modelo, Vector3(0.1, 0.1, 0.1), Vector3(0.2, 0.33, 0), BORDE)
	cubo(modelo, Vector3(0.08, 0.14, 0.08), Vector3(-0.14, -0.37, 0.05), PATA) # patas
	cubo(modelo, Vector3(0.08, 0.14, 0.08), Vector3(0.14, -0.37, 0.05), PATA)
	cubo(modelo, Vector3(0.14, 0.04, 0.14), Vector3(-0.14, -0.45, 0.09), PATA) # garras
	cubo(modelo, Vector3(0.14, 0.04, 0.14), Vector3(0.14, -0.45, 0.09), PATA)
	# Las alas giran desde el borde del cubo: por eso cada una va dentro de su propio nodo.
	ala_i = Node3D.new()
	ala_i.position = Vector3(-0.3, 0.05, 0)
	modelo.add_child(ala_i)
	cubo(ala_i, Vector3(0.4, 0.08, 0.4), Vector3(-0.2, 0, 0), DORADO)
	cubo(ala_i, Vector3(0.14, 0.06, 0.34), Vector3(-0.46, 0, 0), BORDE)       # punta
	ala_d = Node3D.new()
	ala_d.position = Vector3(0.3, 0.05, 0)
	modelo.add_child(ala_d)
	cubo(ala_d, Vector3(0.4, 0.08, 0.4), Vector3(0.2, 0, 0), DORADO)
	cubo(ala_d, Vector3(0.14, 0.06, 0.34), Vector3(0.46, 0, 0), BORDE)
func cubo(padre, medida, posicion, color):
	var malla = BoxMesh.new()
	malla.size = medida
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	malla.material = mat
	var m = MeshInstance3D.new()
	m.mesh = malla
	m.position = posicion
	padre.add_child(m)
	return m


# Las alas suben y bajan. En picada van pegadas hacia arriba; asustada aletea rápido.
func aletear(delta):
	if ala_i == null:
		return
	var angulo = 0.0
	match aleteo:
		"volar":
			angulo = sin(Time.get_ticks_msec() / 1000.0 * 12.0) * 0.6
		"picada":
			angulo = 1.1
		"asustada":
			angulo = sin(Time.get_ticks_msec() / 1000.0 * 30.0) * 0.8
	ala_i.rotation.z = lerp_angle(ala_i.rotation.z, -angulo, minf(1.0, 20.0 * delta))
	ala_d.rotation.z = lerp_angle(ala_d.rotation.z, angulo, minf(1.0, 20.0 * delta))


# La caja de choque: si la escena ya trae un CollisionShape3D lo usa, si no, lo crea.
func armar_caja():
	var forma = null
	for hijo in get_children():
		if hijo is CollisionShape3D:
			forma = hijo
	if forma == null:
		forma = CollisionShape3D.new()
		add_child(forma)
	var box = BoxShape3D.new()
	box.size = caja * tamano
	forma.shape = box
	forma.position = Vector3.ZERO   # centrada en el cubo

# ---------- El aviso: violeta, "!" y chillido ----------

func preparar_aviso():
	tinte = StandardMaterial3D.new()
	tinte.albedo_color = Color(VIOLETA, 0.55)
	tinte.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tinte.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mallas = modelo.find_children("*", "MeshInstance3D", true, false)
	alerta = Label3D.new()
	alerta.text = "!"
	alerta.font_size = 96
	alerta.outline_size = 16
	alerta.modulate = VIOLETA
	alerta.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	alerta.no_depth_test = true
	alerta.position = Vector3(0, 0.9 * tamano, 0)
	add_child(alerta)
	marcar_peligro(false)


func marcar_peligro(si):
	for m in mallas:
		m.material_overlay = tinte if si else null
	if alerta:
		alerta.visible = si


# El chillido: el pito del árbitro más agudo (no hay sonido de lechuza en el proyecto).
func preparar_chillido():
	chillido = AudioStreamPlayer.new()
	if ResourceLoader.exists("res://sonidos/pito.wav"):
		chillido.stream = load("res://sonidos/pito.wav")
	chillido.pitch_scale = 1.8
	chillido.volume_db = -6.0
	add_child(chillido)


func chillar():
	if chillido.stream:
		chillido.play()


# ---------- La sombra en el piso ----------

# Un disco oscuro y plano. Va con top_level para que no se mueva con la lechuza:
# se queda en el punto donde va a caer.
func preparar_sombra():
	sombra = MeshInstance3D.new()
	var disco = CylinderMesh.new()
	disco.top_radius = 0.8
	disco.bottom_radius = 0.8
	disco.height = 0.02
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0, 0, 0, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	disco.material = mat
	sombra.mesh = disco
	sombra.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sombra.top_level = true
	sombra.visible = false
	add_child(sombra)


# La altura del piso debajo de un punto (cancha o tribuna), con un rayo hacia abajo.
func piso_debajo(p):
	var consulta = PhysicsRayQueryParameters3D.create(p + Vector3(0, 0.5, 0), p - Vector3(0, 10, 0))
	consulta.exclude = [get_rid(), objetivo.get_rid()]
	var golpe = get_world_3d().direct_space_state.intersect_ray(consulta)
	if golpe.is_empty():
		return objetivo.global_position.y + 0.02
	return golpe.position.y + 0.02
