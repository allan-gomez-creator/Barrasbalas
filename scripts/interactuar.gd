extends Node

@export var tecla: String = "interactuar"
@export var alcance: float = 1.5
@export var tiempo_necesario: float = 1.5  # segundos que hay que mantener la tecla
@onready var pj = get_parent()

var progreso: float = 0.0   # va de 0 a 1
var actual = null           # el objeto con el que se está interactuando

func _physics_process(delta):
	var obj = mas_cercano()

	# Si se soltó la tecla o no hay nada al alcance: todo vuelve a cero
	if not Input.is_action_pressed(tecla) or obj == null:
		progreso = 0.0
		actual = null
		return

	# Si cambió de objeto, el progreso empieza de cero
	if obj != actual:
		actual = obj
		progreso = 0.0

	# Sube delta ÷ tiempo_necesario por cuadro: llega a 1 en tiempo_necesario s
	var antes = progreso
	progreso += delta / tiempo_necesario

	# int(progreso * 4) vale 0, 1, 2 o 3 y cambia al cruzar cada 25 %
	if int(progreso * 4) > int(antes * 4) and progreso < 0.999:
		print(obj.name, ": ", int(progreso * 4) * 25, " %")

	# 0.999 y no 1: sumar 1/90 noventa veces no da exacto 1
	if progreso >= 0.999:
		print("completado: ", obj.name)
		# Si el objeto sabe hacer algo al completarse, se lo pedimos
		if obj.has_method("usar"):
			obj.usar()
		progreso = 0.0

func mas_cercano():
	var mejor = null
	for obj in get_tree().get_nodes_in_group("interactivos"):
		var d = distancia_a(obj)
		if d <= alcance and (mejor == null or d < distancia_a(mejor)):
			mejor = obj
	return mejor

func distancia_a(obj):
	var a = Vector2(pj.global_position.x, pj.global_position.z)
	var b = Vector2(obj.global_position.x, obj.global_position.z)
	return a.distance_to(b)
