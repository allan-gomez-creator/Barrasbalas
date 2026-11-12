extends Node
# Oleadas versión 2 (Avance 2, jueves 12).
# - Oleada n: 5 + 3 × n barristas, en grupos de 3, cada uno en un Marker3D
#   del grupo "apariciones" escogido al azar.
# - Termina cuando ya salieron todos y no queda ninguno, o a los 75 s.
# - Tiempo muerto de 10 s entre oleadas: la policía hace retroceder a la barra
#   (los que quedan se van), se recarga el aerosol y sale una botella de agua.
# - Dificultad: cada oleada los grupos salen 0.2 s más seguido (mínimo 1.6 s)
#   y los tacleadores corren × 1.05.
# - Límite: nunca más de 11 barristas vivos a la vez. Si ya hay 11, espera.

signal oleada_empieza(n)
signal oleada_termina(n)
signal tiempo_muerto(segundos)

@export var escena_enemigo: PackedScene   # aquí se arrastra tacleador.tscn
@export var escena_agua: PackedScene      # aquí se arrastra agua.tscn
@export var oleada = 1

@export_group("Oleada")
@export var por_grupo = 3
@export var duracion_max = 75.0      # segundos que dura una oleada como máximo
@export var max_vivos = 11           # barristas vivos a la vez, como máximo

@export_group("Dificultad")
@export var cada_grupo_inicial = 3.0 # segundos entre grupos en la oleada 1
@export var baja_por_oleada = 0.2    # cuánto se acorta por oleada
@export var cada_grupo_minimo = 1.6
@export var aumento_rapidez = 1.05   # la rapidez de los tacleadores se multiplica por esto cada oleada

@export_group("Tiempo muerto")
@export var duracion_descanso = 10.0
@export var agua_x_min = -5.5        # el agua sale al azar entre las columnas 4 y 15 (Taller 5)
@export var agua_x_max = 5.5
@export var agua_y = 0.5

enum Fase { OLEADA, DESCANSO }
var fase = Fase.OLEADA

var total = 0          # cuántos barristas trae esta oleada
var salieron = 0       # cuántos han salido ya
var tiempo = 0.0       # segundos desde que empezó la oleada o el descanso
var cada_grupo = 3.0   # segundos entre grupos en esta oleada
var rapidez_extra = 1.0
var reloj_grupo = 0.0
var reloj_revisar = 0.0
var agua_actual = null
var avise_sin_puntos = false


func _ready():
	add_to_group("oleadas")   # así el HUD encuentra este nodo
	# Respaldo: si en el Inspector quedaron vacíos, se cargan solos.
	if escena_enemigo == null:
		push_warning("Oleadas: 'Escena Enemigo' estaba vacío, uso res://tacleador.tscn")
		escena_enemigo = load("res://tacleador.tscn")
	if escena_agua == null and ResourceLoader.exists("res://agua.tscn"):
		push_warning("Oleadas: 'Escena Agua' estaba vacío, uso res://agua.tscn")
		escena_agua = load("res://agua.tscn")
	if get_tree().get_first_node_in_group("arbitro") == null:
		push_warning("Oleadas: no hay ningún nodo en el grupo 'arbitro'; los barristas no van a tener a quién perseguir")
	empezar_oleada()


# ---------- Oleada ----------

func empezar_oleada():
	fase = Fase.OLEADA
	total = 5 + 3 * oleada
	salieron = 0
	tiempo = 0.0
	cada_grupo = max(cada_grupo_inicial - baja_por_oleada * (oleada - 1), cada_grupo_minimo)
	rapidez_extra = pow(aumento_rapidez, oleada - 1)
	reloj_grupo = cada_grupo   # así el primer grupo sale de una vez
	reloj_revisar = 0.0
	if is_instance_valid(agua_actual):
		agua_actual.queue_free()   # si nadie tomó el agua, se la llevan
	print("oleada ", oleada, " empieza: ", total, " barristas, grupos cada ",
		snappedf(cada_grupo, 0.1), " s, rapidez x", snappedf(rapidez_extra, 0.01))
	oleada_empieza.emit(oleada)


func _process(delta):
	tiempo += delta
	if fase == Fase.DESCANSO:
		if tiempo >= duracion_descanso:
			oleada += 1
			empezar_oleada()
		return

	if tiempo >= duracion_max:
		terminar_oleada()
		return

	reloj_grupo += delta
	if salieron < total and reloj_grupo >= cada_grupo:
		if sacar_grupo() > 0:
			reloj_grupo = 0.0
		# Si no salió nadie (ya hay 11 vivos), el reloj sigue cumplido
		# y el grupo sale apenas haya espacio.

	reloj_revisar += delta
	if reloj_revisar >= 1.0:
		reloj_revisar = 0.0
		revisar()


func sacar_grupo():
	var puntos = get_tree().get_nodes_in_group("apariciones")
	if puntos.is_empty():
		if not avise_sin_puntos:
			avise_sin_puntos = true
			push_warning("Oleadas: no hay ningún Marker3D en el grupo 'apariciones'; no puede salir nadie")
		return 0
	var vivos = get_tree().get_nodes_in_group("barristas").size()
	var cuantos = min(por_grupo, total - salieron, max_vivos - vivos)
	if cuantos <= 0:
		return 0
	for i in cuantos:
		var punto = puntos.pick_random()
		var enemigo = escena_enemigo.instantiate()
		enemigo.name = "Barrista_%d_%d" % [oleada, salieron + 1]   # oleada_número
		enemigo.add_to_group("barristas")
		enemigo.set("persigue_siempre", true)   # que vaya directo por el árbitro
		# Respaldo para el tacleador viejo, que no busca al árbitro solo.
		if "objetivo" in enemigo and enemigo.objetivo == null:
			enemigo.objetivo = get_tree().get_first_node_in_group("arbitro")
		if "rapidez" in enemigo:
			enemigo.rapidez *= rapidez_extra
		if enemigo is CharacterBody3D:
			enemigo.axis_lock_linear_z = true    # 2.5D: que no se salga del plano
		add_child(enemigo)
		# Un poco corridos para que los del mismo punto no salgan encimados.
		enemigo.global_position = punto.global_position + Vector3(randf_range(-0.6, 0.6), 0, 0)
		salieron += 1
	print("salieron ", salieron, " de ", total, " (vivos: ", vivos + cuantos, ")")
	return cuantos


func revisar():
	var quedan = get_tree().get_nodes_in_group("barristas").size()
	print("quedan ", quedan)
	if salieron == total and quedan == 0:
		terminar_oleada()


func terminar_oleada():
	print("oleada ", oleada, " termina a los ", snappedf(tiempo, 0.1), " s")
	oleada_termina.emit(oleada)
	empezar_descanso()


# ---------- Tiempo muerto ----------

func empezar_descanso():
	fase = Fase.DESCANSO
	tiempo = 0.0
	# La policía hace retroceder a la barra: los que quedaron se van.
	for b in get_tree().get_nodes_in_group("barristas"):
		b.remove_from_group("barristas")
		b.queue_free()
	var arbitro = get_tree().get_first_node_in_group("arbitro")
	if arbitro and arbitro.has_method("recargar_aerosol"):
		arbitro.recargar_aerosol()
	sacar_agua()
	print("tiempo muerto: ", duracion_descanso, " s")
	tiempo_muerto.emit(duracion_descanso)


func sacar_agua():
	if escena_agua == null:
		return
	agua_actual = escena_agua.instantiate()
	var x = randf_range(agua_x_min, agua_x_max)
	agua_actual.position = Vector3(x, agua_y, 0)   # antes de add_child, para que flote desde ahí
	add_child(agua_actual)
	print("salió el agua en x = ", snappedf(x, 0.1))
