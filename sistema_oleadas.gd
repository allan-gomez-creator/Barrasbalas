extends Node
# Oleadas versión 1 (Avance 1, lunes 9).
# Saca barristas por oleadas: 5 + 3 × n, en grupos de 3 cada 3 s,
# cada uno en un Marker3D del grupo "apariciones" escogido al azar.
# La oleada termina cuando ya salieron todos y no queda ninguno, o a los 75 s.

signal oleada_empieza(n)
signal oleada_termina(n)
signal tiempo_muerto(segundos)   # se usa desde el jueves (tiempo muerto de 10 s)

@export var escena_enemigo: PackedScene   # aquí se arrastra tacleador.tscn
@export var oleada = 1
@export var por_grupo = 3
@export var cada_grupo = 3.0      # segundos entre grupos
@export var duracion_max = 75.0   # segundos que dura una oleada como máximo

var total = 0          # cuántos barristas trae esta oleada
var salieron = 0       # cuántos han salido ya
var tiempo = 0.0       # segundos desde que empezó la oleada
var reloj_grupo = 0.0
var reloj_revisar = 0.0
var activa = false


func _ready():
	empezar_oleada()


func empezar_oleada():
	total = 5 + 3 * oleada
	salieron = 0
	tiempo = 0.0
	reloj_grupo = cada_grupo   # así el primer grupo sale de una vez
	reloj_revisar = 0.0
	activa = true
	print("oleada ", oleada, " empieza: ", total, " barristas")
	oleada_empieza.emit(oleada)


func _process(delta):
	if not activa:
		return
	tiempo += delta
	if tiempo >= duracion_max:
		terminar_oleada()
		return

	reloj_grupo += delta
	if salieron < total and reloj_grupo >= cada_grupo:
		reloj_grupo = 0.0
		sacar_grupo()

	reloj_revisar += delta
	if reloj_revisar >= 1.0:
		reloj_revisar = 0.0
		revisar()


func sacar_grupo():
	var puntos = get_tree().get_nodes_in_group("apariciones")
	if puntos.is_empty():
		push_warning("No hay Marker3D en el grupo 'apariciones'")
		return
	var cuantos = min(por_grupo, total - salieron)
	for i in cuantos:
		var punto = puntos.pick_random()
		var enemigo = escena_enemigo.instantiate()
		enemigo.name = "Barrista_%d_%d" % [oleada, salieron + 1]   # oleada_número
		enemigo.add_to_group("barristas")
		# Respaldo: si el enemigo no tiene a quién perseguir, se le da el árbitro.
		if "objetivo" in enemigo and enemigo.objetivo == null:
			enemigo.objetivo = get_tree().get_first_node_in_group("arbitro")
		# 2.5D: que no se salga del plano.
		if enemigo is CharacterBody3D:
			enemigo.axis_lock_linear_z = true
		add_child(enemigo)
		# Un poco corridos para que los del mismo punto no salgan encimados.
		enemigo.global_position = punto.global_position + Vector3(randf_range(-0.6, 0.6), 0, 0)
		salieron += 1
	print("salieron ", salieron, " de ", total)


func revisar():
	var quedan = get_tree().get_nodes_in_group("barristas").size()
	print("quedan ", quedan)
	if salieron == total and quedan == 0:
		terminar_oleada()


func terminar_oleada():
	activa = false
	print("oleada ", oleada, " termina a los ", snappedf(tiempo, 0.1), " s")
	oleada_termina.emit(oleada)
	oleada += 1
	empezar_oleada()   # desde el jueves aquí va el tiempo muerto de 10 s
