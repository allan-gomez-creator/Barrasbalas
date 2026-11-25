extends Node
# Avance 2 - Juan Manuel: esquive con Shift.
enum Estado { LISTO, ACTIVO, RECARGA }

@export var tecla = "esquivar"
@export var rapidez = 12.0	# m/s extra durante el esquive
@export var duracion = 0.3	# s que dura el impulso
@export var recarga = 1.5	# s de espera para volver a usarlo
@onready var pj = get_parent()

var estado = Estado.LISTO
var tiempo = 0.0


func _physics_process(delta):
	tiempo -= delta
	match estado:
		Estado.LISTO:
			if Input.is_action_just_pressed(tecla) and not pj.muerto:
				empezar()
		Estado.ACTIVO:
			if tiempo <= 0.001:	# 0.001 y no 0: restar 1/60 no da exacto
				terminar()
		Estado.RECARGA:
			if tiempo <= 0.001:
				estado = Estado.LISTO


func empezar():
	estado = Estado.ACTIVO
	tiempo = duracion
	var lado = -1.0 if pj.rotation.y > 0 else 1.0	# el personaje mira a +X con rotation.y = -90°
	pj.empuje = Vector3(rapidez * lado, 0, 0)
	pj.esquivando = true
	pj.accion = "sprint"
	print("esquive")


func terminar():
	estado = Estado.RECARGA
	tiempo = recarga
	pj.empuje = Vector3.ZERO
	pj.esquivando = false
	pj.accion = ""
