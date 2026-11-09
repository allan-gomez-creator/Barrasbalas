extends Node3D
# Solo para probar las oleadas. Con la K se expulsa un barrista al azar,
# para ver que "quedan" baja y que la oleada termina cuando llega a 0.

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_K:
		var barristas = get_tree().get_nodes_in_group("barristas")
		if not barristas.is_empty():
			barristas.pick_random().recibir_golpe(99)
