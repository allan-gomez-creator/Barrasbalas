extends Node3D
# Martín: escena para probar los efectos sin jugar (F6).
#   1 = golpe   2 = expulsión   3 = tacleo   4 = botella rota   Espacio = los 4
# Se llaman igual que en el juego: por el grupo "efectos", con call_group.

const NOMBRES = ["golpe", "expulsion", "tacleo", "botella_rota"]
const LUGARES = [Vector3(-4.5, 1.0, 0), Vector3(-1.5, 1.0, 0), Vector3(1.5, 1.0, 0), Vector3(4.5, 1.0, 0)]


func _ready():
	print("Prueba de efectos: 1 golpe · 2 expulsión · 3 tacleo · 4 botella · Espacio = todos")


func _unhandled_input(event):
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_1: lanzar(0)
		KEY_2: lanzar(1)
		KEY_3: lanzar(2)
		KEY_4: lanzar(3)
		KEY_SPACE:
			for i in 4:
				lanzar(i)


func lanzar(i):
	get_tree().call_group("efectos", NOMBRES[i], LUGARES[i])
	print("efecto: ", NOMBRES[i])
