extends Node

# El nodo padre es el Personaje (de ahí leemos su posición)
@onready var pj = get_parent()

func _physics_process(_delta):
	# Una de cada 30 veces (cada 0.5 s a 60 fps)
	if Engine.get_physics_frames() % 30 == 0:
		var obj = mas_cercano()
		if obj == null:
			print("no hay nada en el grupo interactivos")
		else:
			var d = snappedf(distancia_a(obj), 0.01)
			print("más cercano: ", obj.name, " a ", d, " m")

# Devuelve el objeto del grupo que está más cerca (o null si no hay ninguno)
func mas_cercano():
	var mejor = null
	for obj in get_tree().get_nodes_in_group("interactivos"):
		if mejor == null or distancia_a(obj) < distancia_a(mejor):
			mejor = obj
	return mejor

# Distancia en el suelo: usa x y z, ignora la altura
func distancia_a(obj):
	var a = Vector2(pj.global_position.x, pj.global_position.z)
	var b = Vector2(obj.global_position.x, obj.global_position.z)
	return a.distance_to(b)
