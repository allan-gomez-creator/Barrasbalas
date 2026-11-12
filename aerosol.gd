extends Node
# Avance 2 - Juan Manuel: aerosol con clic derecho.
signal usos_cambio(valor: int)	# la escucha el HUD (Avance 3)

@export var tecla = "aerosol"
@export var usos_por_oleada = 2
@export var alcance = 9.0	# m: lo que se ve en pantalla
@export var segundos_ciego = 3.0
@onready var pj = get_parent()

var usos = 2


func _ready():
	usos = usos_por_oleada


func _physics_process(_delta):
	if Input.is_action_just_pressed(tecla) and not pj.muerto:
		usar()


func usar():
	if usos <= 0:
		print("aerosol vacío")
		return
	usos -= 1
	var cegados = 0
	for barrista in get_tree().get_nodes_in_group("barristas"):
		var d = barrista.global_position.distance_to(pj.global_position)
		if d <= alcance and barrista.has_method("cegar"):
			barrista.cegar(segundos_ciego)
			cegados += 1
	print("aerosol: ", cegados, " cegados · quedan ", usos)
	usos_cambio.emit(usos)


func recargar():
	usos = usos_por_oleada
	print("aerosol recargado: ", usos)
	usos_cambio.emit(usos)
