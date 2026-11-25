extends Node3D
# Los puntos de aparición se mueven con la cámara: siempre quedan a "distancia"
# metros a la izquierda y a la derecha de lo que se ve, o sea justo por fuera
# de la pantalla. Así los barristas salen cerca del árbitro en cualquier zona.
# Nunca quedan detrás de una barrera cerrada ni fuera del nivel.

@export var distancia = 12.0
@export var minimo = 6.0        # nunca más cerca que esto del árbitro
@export var borde_izq = -15.0
@export var borde_der = 60.0
# Distancia mínima a una barrera cerrada o al borde. Las oleadas corren a cada
# barrista hasta 0.6 m del punto, y el cuerpo mide 0.35 de radio: con menos
# de 1.6 alguno podía nacer DENTRO de la barrera y salir disparado.
@export var margen = 1.6
@onready var izq = $AparicionIzq
@onready var der = $AparicionDer


func _ready():
	# Así los barristas y el agua encuentran este nodo para preguntarle
	# dónde pueden salir.
	add_to_group("zona_juego")


func _physics_process(_delta):
	var cam = get_viewport().get_camera_3d()
	if cam == null:
		return
	var limites = limites_abiertos(cam.global_position.x)
	var x_izq = clampf(cam.global_position.x - distancia, limites.x + margen, limites.y - margen)
	var x_der = clampf(cam.global_position.x + distancia, limites.x + margen, limites.y - margen)
	# Si el árbitro está pegado a una barrera o a un borde, uno de los dos puntos
	# le quedaría encima. En ese caso, los dos puntos se van al lado libre.
	var arbitro = get_tree().get_first_node_in_group("arbitro")
	if arbitro:
		var ax = arbitro.global_position.x
		if absf(x_der - ax) < minimo:
			x_der = x_izq
		elif absf(x_izq - ax) < minimo:
			x_izq = x_der
	acomodar(izq, x_izq)
	acomodar(der, x_der)


# Entre qué x se puede estar: desde la barrera cerrada de la izquierda (o el
# borde) hasta la barrera cerrada de la derecha (o el borde).
func limites_abiertos(x):
	var desde = borde_izq
	var hasta = borde_der
	for b in get_tree().get_nodes_in_group("barreras"):
		if b.abierta:
			continue
		var bx = b.global_position.x
		if bx > x and bx < hasta:
			hasta = bx
		if bx < x and bx > desde:
			desde = bx
	return Vector2(desde, hasta)


# Pone el punto en esa x, parado sobre lo que haya debajo (piso o tribuna).
# El rayo empieza en y = 2 para no caer encima de la valla elevada.
func acomodar(punto, x):
	punto.global_position = Vector3(x, altura_piso(x), 0)


# Altura del piso o de la tribuna que haya en esa x. El rayo empieza en
# y = 2 para no caer encima de la valla elevada.
func altura_piso(x):
	var espacio = get_world_3d().direct_space_state
	var consulta = PhysicsRayQueryParameters3D.create(Vector3(x, 2.0, 0), Vector3(x, -1.0, 0))
	# Si el rayo pega en un personaje (árbitro o barrista), lo ignora y prueba otra vez.
	for intento in 6:
		var golpe = espacio.intersect_ray(consulta)
		if golpe.is_empty():
			break
		if golpe.collider is StaticBody3D:
			return golpe.position.y
		consulta.exclude = consulta.exclude + [golpe.rid]
	return 0.0


# Una x que se vea en pantalla, a una distancia entre dist_min y dist_max del
# árbitro, y del lado de la cancha donde está él (sin cruzar barreras cerradas).
# lado: 1 = a su derecha, -1 = a su izquierda, 0 = cualquiera al azar.
# Si de ese lado no cabe (por ejemplo, está pegado a una barrera), usa el otro.
func x_cerca_del_arbitro(dist_min, dist_max, lado = 0.0):
	var arbitro = get_tree().get_first_node_in_group("arbitro")
	var cam = get_viewport().get_camera_3d()
	if arbitro == null or cam == null:
		return null
	var ax = arbitro.global_position.x
	# La cámara es ortográfica: "size" es lo alto que se ve; lo ancho sale
	# multiplicando por la proporción de la ventana (16:9).
	var medio_ancho = cam.size * 0.5 * get_viewport().get_visible_rect().size.aspect()
	var lim = limites_abiertos(ax)
	var desde = maxf(lim.x + margen, cam.global_position.x - medio_ancho + 1.0)
	var hasta = minf(lim.y - margen, cam.global_position.x + medio_ancho - 1.0)
	if lado == 0.0:
		lado = [-1.0, 1.0].pick_random()
	for intento in 2:
		var x = clampf(ax + lado * randf_range(dist_min, dist_max), desde, hasta)
		if absf(x - ax) >= dist_min * 0.75:
			return x
		lado = -lado   # no cupo: probar del otro lado
	return clampf(ax + lado * dist_min, desde, hasta)
