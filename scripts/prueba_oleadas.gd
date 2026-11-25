extends Node3D
# Escena de prueba de Martín.
#  - K: expulsa un barrista al azar (para probar que "quedan" baja).
#  - G: llama ganar() en las oleadas, como lo hará la meta del túnel.
#  - con_oleadas = false: apaga las oleadas para probar solo al lanzador
#    puesto a mano, sin que salgan tacleadores.

@export var con_oleadas = false


func _ready():
	if not con_oleadas and has_node("Oleadas"):
		$Oleadas.process_mode = Node.PROCESS_MODE_DISABLED
		print("prueba: oleadas apagadas (con_oleadas = false)")


func _unhandled_input(event):
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_K:
		var barristas = get_tree().get_nodes_in_group("barristas")
		if not barristas.is_empty():
			barristas.pick_random().recibir_golpe(99)
	elif event.keycode == KEY_G:
		get_tree().call_group("oleadas", "ganar")
