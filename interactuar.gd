extends Node

@export var tecla: String = "interactuar"  # nombre de la acción del Input Map
@export var alcance: float = 1.5           # metros; lo que esté más lejos no cuenta
@onready var pj = get_parent()

func _physics_process(_delta):
	# just_pressed: verdadero SOLO en el cuadro en que se presiona la tecla
	if Input.is_action_just_pressed(tecla):
		var obj = mas_cercano()
		if obj == null:
			print("nada a menos de ", alcance, " m")
		else:
			var d = snappedf(distancia_a(obj), 0.01)
			print("interactúa con ", obj.name, " a ", d, " m")

# Igual que en el nivel 1, pero solo cuentan los que están DENTRO del alcance
func mas_cercano():
	var mejor = null
	for obj in get_tree().get_nodes_in_group("interactivos"):
		var d = distancia_a(obj)
		# Primero se descarta lo lejano (d <= alcance).
		# De lo que queda, gana el más cercano.
		if d <= alcance and (mejor == null or d < distancia_a(mejor)):
			mejor = obj
	return mejor

func distancia_a(obj):
	var a = Vector2(pj.global_position.x, pj.global_position.z)
	var b = Vector2(obj.global_position.x, obj.global_position.z)
	return a.distance_to(b)
