extends CharacterBody3D
# Árbitro de mentiras, solo para probar las oleadas sin depender de personaje.gd.
# A/D para moverse. Tiene lo mismo que el de verdad: energía, curar,
# recibir_danio y recargar_aerosol.

var energia = 3   # empieza en 3 para que se note cuando el agua cura
var energia_max = 5


func _physics_process(delta):
	velocity += get_gravity() * delta
	velocity.x = Input.get_axis("move_left", "move_right") * 4.0
	move_and_slide()


func recibir_danio(cantidad):
	energia = max(energia - cantidad, 0)
	print("árbitro de prueba: energía ", energia)


func curar(cantidad):
	energia = min(energia + cantidad, energia_max)
	print("árbitro de prueba: energía ", energia)


func recargar_aerosol():
	print("árbitro de prueba: aerosol recargado")
