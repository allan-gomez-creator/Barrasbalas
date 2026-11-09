extends CharacterBody3D

enum Estado { PATRULLA, PERSEGUIR }

@export var objetivo: Node3D
@export var rapidez = 3.2
@export var radio_ver = 5.0
@export var radio_perder = 8.0
# Los que crean las oleadas persiguen desde que nacen y no se rinden.
@export var persigue_siempre = false
@export var puntos: Array[Vector3] = [
	Vector3(5.5, 0, 0), Vector3(2.5, 0, 0)]
@onready var anim = $Modelo/AnimationPlayer

var estado = Estado.PATRULLA
var punto = 0


func _ready():
	add_to_group("barristas")
	# Si nadie le dijo a quién perseguir (lo creó una oleada), busca al árbitro.
	if objetivo == null:
		objetivo = get_tree().get_first_node_in_group("arbitro")
		persigue_siempre = true
	if persigue_siempre:
		estado = Estado.PERSEGUIR


func _physics_process(delta):
	velocity += get_gravity() * delta
	if objetivo == null:
		move_and_slide()
		return
	var distancia = global_position.distance_to(objetivo.global_position)
	match estado:
		Estado.PATRULLA:
			if distancia < radio_ver:
				estado = Estado.PERSEGUIR
				print("lo vio a ", snappedf(distancia, 0.01), " m")
			ir_a(puntos[punto])
			if global_position.distance_to(puntos[punto]) < 0.3:
				punto = (punto + 1) % puntos.size()
		Estado.PERSEGUIR:
			if distancia > radio_perder and not persigue_siempre:
				estado = Estado.PATRULLA
				print("lo perdió a ", snappedf(distancia, 0.01), " m")
			ir_a(objetivo.global_position)
	move_and_slide()


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


@export var vida = 2


func recibir_golpe(danio):
	vida -= danio
	print(name, ": vida ", vida)
	if vida <= 0:
		print(name, " expulsado")
		queue_free()
