extends CharacterBody3D

enum Estado { PATRULLA, PERSEGUIR, AVISO, LANZAR, CIEGO }

@export var objetivo: Node3D
@export var rapidez = 3.2
@export var radio_ver = 5.0
@export var radio_perder = 8.0
# Los que crean las oleadas persiguen desde que nacen y no se rinden.
@export var persigue_siempre = false
@export var puntos: Array[Vector3] = [
	Vector3(5.5, 0, 0), Vector3(2.5, 0, 0)]
@export var vida = 2

@export_group("Tacleo")
@export var radio_tacleo = 1.5       # a esta distancia se prepara para taclear
@export var tiempo_aviso = 0.5       # s agachado antes de lanzarse: el aviso
@export var rapidez_lanzar = 8.0     # m/s durante el lanzamiento
@export var tiempo_lanzar = 0.4      # s que dura el lanzamiento
@export var danio = 1

@onready var anim = $Modelo/AnimationPlayer

var estado = Estado.PATRULLA
var punto = 0
var reloj = 0.0
var lado = 1.0   # hacia dónde se lanza: 1 = derecha, -1 = izquierda

# Violeta = peligro (la paleta del juego): el tacleador se pinta de violeta
# y muestra un "!" mientras avisa y mientras se lanza.
const VIOLETA = Color(0.62, 0.2, 0.95)
var mallas = []
var tinte: StandardMaterial3D
var alerta: Label3D


func _ready():
	add_to_group("barristas")
	preparar_aviso()
	# Si nadie le dijo a quién perseguir (lo creó una oleada), busca al árbitro.
	if objetivo == null:
		objetivo = get_tree().get_first_node_in_group("arbitro")
		persigue_siempre = true
	if persigue_siempre:
		estado = Estado.PERSEGUIR


func _physics_process(delta):
	velocity += get_gravity() * delta
	reloj = maxf(reloj - delta, 0.0)
	if objetivo == null or not is_instance_valid(objetivo):
		frenar()
		move_and_slide()
		return
		# Si el árbitro ya perdió, la barra celebra y deja de taclear.
	if objetivo.get("muerto"):
		frenar()
		anim.play("emote-yes")
		move_and_slide()
		return
	var distancia = global_position.distance_to(objetivo.global_position)
	match estado:
		Estado.PATRULLA:
			if distancia < radio_ver:
				cambiar_a(Estado.PERSEGUIR)
				print(name, " lo vio a ", snappedf(distancia, 0.01), " m")
			ir_a(puntos[punto])
			if global_position.distance_to(puntos[punto]) < 0.3:
				punto = (punto + 1) % puntos.size()
		Estado.PERSEGUIR:
			if distancia > radio_perder and not persigue_siempre:
				cambiar_a(Estado.PATRULLA)
				print(name, " lo perdió a ", snappedf(distancia, 0.01), " m")
			elif distancia < radio_tacleo:
				cambiar_a(Estado.AVISO)
			else:
				ir_a(objetivo.global_position)
		Estado.AVISO:
			# Quieto y agachado: es el tiempo que tiene el árbitro para reaccionar.
			frenar()
			anim.play("crouch")
			if reloj <= 0.001:
				cambiar_a(Estado.LANZAR)
		Estado.LANZAR:
			velocity.x = lado * rapidez_lanzar
			velocity.z = 0.0
			anim.play("sprint")
			if distancia < 1.0 and puede_golpear():
				golpear()
				return
			if reloj <= 0.001:
				print(name, " falló el tacleo")
				cambiar_a(Estado.PERSEGUIR)
		Estado.CIEGO:
			frenar()
			anim.play("emote-no")
			if reloj <= 0.001:
				cambiar_a(Estado.PERSEGUIR if persigue_siempre else Estado.PATRULLA)
	move_and_slide()


func cambiar_a(nuevo):
	estado = nuevo
	marcar_peligro(estado == Estado.AVISO or estado == Estado.LANZAR)
	match estado:
		Estado.AVISO:
			reloj = tiempo_aviso
			print(name, " se prepara para taclear")
		Estado.LANZAR:
			reloj = tiempo_lanzar
			# Se lanza hacia donde está el árbitro EN ESTE MOMENTO.
			lado = 1.0 if objetivo.global_position.x >= global_position.x else -1.0
			basis = Basis.looking_at(Vector3(lado, 0, 0))


func preparar_aviso():
	tinte = StandardMaterial3D.new()
	tinte.albedo_color = Color(VIOLETA, 0.55)
	tinte.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tinte.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mallas = $Modelo.find_children("*", "MeshInstance3D", true, false)
	alerta = Label3D.new()
	alerta.text = "!"
	alerta.font_size = 96
	alerta.outline_size = 16
	alerta.modulate = VIOLETA
	alerta.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	alerta.no_depth_test = true
	alerta.position = Vector3(0, 2.3, 0)
	add_child(alerta)
	marcar_peligro(false)


func marcar_peligro(si):
	for m in mallas:
		m.material_overlay = tinte if si else null
	if alerta:
		alerta.visible = si


# El árbitro no recibe daño si está esquivando o parpadeando:
# en ese caso el tacleador sigue de largo.
func puede_golpear():
	if objetivo.get("esquivando") or objetivo.get("invulnerable") or objetivo.get("muerto"):
		return false
	return objetivo.has_method("recibir_danio")


func golpear():
	print(name, " tacleó al árbitro")
	objetivo.recibir_danio(danio)
	remove_from_group("barristas")   # para que las oleadas no lo cuenten
	queue_free()


# La llama el aerosol del árbitro.
func cegar(segundos):
	cambiar_a(Estado.CIEGO)
	reloj = segundos
	print(name, " cegado ", segundos, " s")


func ir_a(p):
	var hacia = p - global_position
	hacia.y = 0.0
	if hacia.length() < 0.05:
		return
	var dir = hacia.normalized()
	velocity.x = dir.x * rapidez
	velocity.z = dir.z * rapidez
	basis = Basis.looking_at(dir)
	anim.play("walk")


func frenar():
	velocity.x = 0.0
	velocity.z = 0.0


func recibir_golpe(danio_recibido):
	vida -= danio_recibido
	print(name, ": vida ", vida)
	if vida <= 0:
		print(name, " expulsado")
		remove_from_group("barristas")
		queue_free()
