class_name CicloDia
extends Node
# Tarea A - Barrasbalas: el reloj de la zona A (la banda de la cancha, camino al tunel).
# Lleva la hora y hace las cuentas del sol. No toca ninguna luz: eso lo hace SistemaSol.

const NARANJA := Color(1.0, 0.5, 0.25)	# el color bajo de la paleta: atardecer en el estadio

@export var hora := 16.0	# h, al empezar (el partido termina a las 16 h)
@export var duracion_dia := 1440.0	# s reales que dura un dia de 24 h (60 s por hora de juego)
@export var pausado := false


func avanzar(dt: float) -> void:
	if not pausado:
		hora = fposmod(hora + 24.0 * dt / duracion_dia, 24.0)	# horas de juego en dt segundos


static func elevacion(h: float) -> float:
	return (h - 6.0) * 15.0	# 6 h -> 0 grados, 12 h -> 90, 18 h -> 180


static func factor_sol(h: float) -> float:
	return maxf(0.0, sin(deg_to_rad(elevacion(h))))	# el seno de la elevacion (en radianes)


static func color_sol(h: float) -> Color:
	return NARANJA.lerp(Color.WHITE, factor_sol(h))
