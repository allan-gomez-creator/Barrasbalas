extends Node
# Oleadas versión 3 (Avance 3, viernes 13).
# - Oleada n: 5 + 3 × n barristas, en grupos de 5. Cada grupo sale entero por
#   un lado (izquierda o derecha, alternando) desde un Marker3D del grupo
#   "apariciones". En la oleada 1 hay 3 s para ubicarse antes del primer grupo.
# - Termina cuando ya salieron todos y no queda ninguno, o a los 75 s.
# - Tiempo muerto de 10 s entre oleadas: la policía hace retroceder a la barra
#   (los que quedan se van), se recarga el aerosol y sale una botella de agua.
# - Dificultad: cada oleada los grupos salen 0.2 s más seguido (mínimo 1.6 s)
#   y los tacleadores corren × 1.05. Desde la oleada 6 tienen +1 de vida, para
#   que la presión suba en la zona 2 y llegue al máximo en la oleada 8.
# - Límite: nunca más de 11 barristas vivos a la vez. Si ya hay 11, espera.
# - Los números del balance salen de 30 partidas simuladas por ajuste
#   (ver "BarrasBalas — Balance y errores del Avance 3").
# - Victoria: al terminar la oleada 8 el árbitro llega a camerinos.
#   (El capo de la barra queda para después del 20 de noviembre.)
# - Si el árbitro pierde, las oleadas se detienen.
# - Balance: al final de cada oleada escribe en la Salida un RESUMEN con la
#   duración, la energía y los tacleos recibidos, y al final la tabla completa.

signal oleada_empieza(n)
signal oleada_termina(n)
signal tiempo_muerto(segundos)
signal victoria

@export var escena_enemigo: PackedScene   # aquí se arrastra tacleador.tscn
@export var escena_agua: PackedScene      # aquí se arrastra agua.tscn
@export var escena_victoria: PackedScene  # aquí se arrastra victoria.tscn
@export var oleada = 1
@export var ultima_oleada = 8
@export var espera_inicial = 3.0     # s antes del primer grupo de la oleada 1, para ubicarse

@export_group("Oleada")
@export var por_grupo = 5            # antes 3: con 3 nadie alcanzaba al árbitro
@export var duracion_max = 75.0      # segundos que dura una oleada como máximo
@export var max_vivos = 11           # barristas vivos a la vez, como máximo

@export_group("Dificultad")
@export var cada_grupo_inicial = 3.0 # segundos entre grupos en la oleada 1
@export var baja_por_oleada = 0.2    # cuánto se acorta por oleada
@export var cada_grupo_minimo = 1.6
@export var aumento_rapidez = 1.05   # la rapidez de los tacleadores se multiplica por esto cada oleada
@export var grupo_de_un_lado = true  # cada grupo sale entero por un lado, y el siguiente por el otro
@export var vida_extra_desde = 6     # desde esta oleada los barristas tienen +1 de vida (0 = nunca)

@export_group("Tiempo muerto")
@export var duracion_descanso = 10.0
@export var agua_x_min = -5.5        # el agua sale al azar entre las columnas 4 y 15 (Taller 5)
@export var agua_x_max = 5.5
@export var agua_y = 0.5

enum Fase { OLEADA, DESCANSO, FIN }
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
var quedan_antes = -1
var grupos_salidos = 0

# Para el balance
var arbitro = null
var tiempo_partida = 0.0
var energia_inicio = 0
var energia_previa = 0
var golpes = 0
var historial = []     # un resumen por oleada


func _ready():
	add_to_group("oleadas")   # así el HUD encuentra este nodo
	# Respaldo: si en el Inspector quedaron vacíos, se cargan solos.
	if escena_enemigo == null:
		push_warning("Oleadas: 'Escena Enemigo' estaba vacío, uso res://tacleador.tscn")
		escena_enemigo = load("res://tacleador.tscn")
	if escena_agua == null and ResourceLoader.exists("res://agua.tscn"):
		push_warning("Oleadas: 'Escena Agua' estaba vacío, uso res://agua.tscn")
		escena_agua = load("res://agua.tscn")
	if escena_victoria == null and ResourceLoader.exists("res://victoria.tscn"):
		escena_victoria = load("res://victoria.tscn")
	arbitro = get_tree().get_first_node_in_group("arbitro")
	if arbitro == null:
		push_warning("Oleadas: no hay ningún nodo en el grupo 'arbitro'; los barristas no van a tener a quién perseguir")
	else:
		if arbitro.has_signal("murio"):
			arbitro.murio.connect(_al_perder)
		if arbitro.has_signal("energia_cambio"):
			arbitro.energia_cambio.connect(_al_cambiar_energia)
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
	if oleada == 1:
		reloj_grupo = cada_grupo - espera_inicial   # en la primera, el árbitro tiene unos segundos para ubicarse
	reloj_revisar = 0.0
	quedan_antes = -1
	golpes = 0
	energia_inicio = energia_actual()
	energia_previa = energia_inicio
	if is_instance_valid(agua_actual):
		agua_actual.queue_free()   # si nadie tomó el agua, se la llevan
	print("oleada ", oleada, " de ", ultima_oleada, " empieza: ", total, " barristas, grupos cada ",
		snappedf(cada_grupo, 0.1), " s, rapidez x", snappedf(rapidez_extra, 0.01))
	oleada_empieza.emit(oleada)


func _process(delta):
	if fase == Fase.FIN:
		return
	tiempo += delta
	tiempo_partida += delta
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
	var izq = puntos.filter(func(m): return m.global_position.x < 0)
	var der = puntos.filter(func(m): return m.global_position.x >= 0)
	for i in cuantos:
		var punto = puntos.pick_random()
		if grupo_de_un_lado and not izq.is_empty() and not der.is_empty():
			punto = (izq if grupos_salidos % 2 == 0 else der).pick_random()
		var enemigo = escena_enemigo.instantiate()
		enemigo.name = "Barrista_%d_%d" % [oleada, salieron + 1]   # oleada_número
		enemigo.add_to_group("barristas")
		enemigo.set("persigue_siempre", true)   # que vaya directo por el árbitro
		# Respaldo para el tacleador viejo, que no busca al árbitro solo.
		if "objetivo" in enemigo and enemigo.objetivo == null:
			enemigo.objetivo = arbitro
		if "rapidez" in enemigo:
			enemigo.rapidez *= rapidez_extra
		if vida_extra_desde > 0 and oleada >= vida_extra_desde and "vida" in enemigo:
			enemigo.vida += 1
		if enemigo is CharacterBody3D:
			enemigo.axis_lock_linear_z = true    # 2.5D: que no se salga del plano
		add_child(enemigo)
		# Un poco corridos para que los del mismo punto no salgan encimados.
		enemigo.global_position = punto.global_position + Vector3(randf_range(-0.6, 0.6), 0, 0)
		salieron += 1
	grupos_salidos += 1
	print("salieron ", salieron, " de ", total, " (vivos: ", vivos + cuantos, ")")
	return cuantos


func revisar():
	var quedan = get_tree().get_nodes_in_group("barristas").size()
	if quedan != quedan_antes:   # solo cuando cambia, para no llenar la Salida
		quedan_antes = quedan
		print("quedan ", quedan)
	if salieron == total and quedan == 0:
		terminar_oleada()


func terminar_oleada():
	var por_tiempo = tiempo >= duracion_max
	var resumen = {
		"oleada": oleada,
		"barristas": total,
		"segundos": snappedf(tiempo, 0.1),
		"por_tiempo": por_tiempo,
		"energia_antes": energia_inicio,
		"energia_despues": energia_actual(),
		"golpes": golpes,
	}
	historial.append(resumen)
	print("RESUMEN oleada %d: duró %.1f s%s · energía %d → %d · tacleos recibidos %d" % [
		oleada, tiempo, " (se acabó el tiempo)" if por_tiempo else "",
		energia_inicio, energia_actual(), golpes])
	oleada_termina.emit(oleada)
	if oleada >= ultima_oleada:
		ganar()
	else:
		empezar_descanso()


# ---------- Tiempo muerto ----------

func empezar_descanso():
	fase = Fase.DESCANSO
	tiempo = 0.0
	sacar_barristas()   # la policía hace retroceder a la barra: los que quedaron se van
	if arbitro and arbitro.has_method("recargar_aerosol"):
		arbitro.recargar_aerosol()
	sacar_agua()
	print("tiempo muerto: ", duracion_descanso, " s")
	tiempo_muerto.emit(duracion_descanso)


func sacar_barristas():
	for b in get_tree().get_nodes_in_group("barristas"):
		b.remove_from_group("barristas")
		b.queue_free()


func sacar_agua():
	if escena_agua == null:
		return
	agua_actual = escena_agua.instantiate()
	var x = randf_range(agua_x_min, agua_x_max)
	agua_actual.position = Vector3(x, agua_y, 0)   # antes de add_child, para que flote desde ahí
	add_child(agua_actual)
	print("salió el agua en x = ", snappedf(x, 0.1))


# ---------- Final ----------

func ganar():
	fase = Fase.FIN
	sacar_barristas()
	print("¡Llegaste a camerinos! Energía ", energia_actual(), " · tiempo total ", texto_tiempo(tiempo_partida))
	imprimir_tabla("GANÓ")
	victoria.emit()
	if escena_victoria:
		var pantalla = escena_victoria.instantiate()
		get_tree().root.add_child(pantalla)
		if pantalla.has_method("mostrar"):
			pantalla.mostrar(energia_actual(), texto_tiempo(tiempo_partida), ultima_oleada)
	get_tree().paused = true


func _al_perder():
	if fase == Fase.FIN:
		return
	fase = Fase.FIN
	print("Perdió en la oleada %d, a los %.1f s de la oleada (%s de partida)" % [
		oleada, tiempo, texto_tiempo(tiempo_partida)])
	historial.append({"oleada": oleada, "barristas": total, "segundos": snappedf(tiempo, 0.1),
		"por_tiempo": false, "energia_antes": energia_inicio, "energia_despues": 0,
		"golpes": golpes, "perdio": true})
	imprimir_tabla("PERDIÓ")


func _al_cambiar_energia(valor):
	if valor < energia_previa:
		golpes += energia_previa - valor
	energia_previa = valor


func energia_actual():
	if arbitro and "energia" in arbitro:
		return arbitro.energia
	return 0


func texto_tiempo(segundos):
	return "%d:%02d" % [int(segundos) / 60, int(segundos) % 60]


func imprimir_tabla(resultado):
	print("===== BALANCE (", resultado, ") =====")
	print("oleada | barristas | duración | energía | tacleos")
	for r in historial:
		print("%6d | %9d | %6.1f s%s | %d → %d | %d%s" % [r.oleada, r.barristas, r.segundos,
			"*" if r.por_tiempo else " ", r.energia_antes, r.energia_despues, r.golpes,
			"  ← perdió aquí" if r.get("perdio", false) else ""])
	print("(* = la oleada se acabó por los 75 s)")
