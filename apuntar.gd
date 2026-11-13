extends Node

@export var tecla = "disparar"
@export var alcance = 20.0
@export_enum("Personaje", "Centro de la cámara", "Mouse") var desde = 0
@export var danio = 25
@export var cadencia = 0.25
@onready var pj = get_parent()

var origen = Vector3.ZERO	# de dónde sale el rayo
var espera = 0.0
var hacia = Vector3.ZERO	# hasta dónde llega el rayo si no le da a nada


func _physics_process(delta):
	espera -= delta
	if Input.is_action_pressed(tecla) and espera <= 0.001:
		espera = cadencia
		var golpe = lanzar_rayo()
		mostrar_tarjeta(origen, hacia if golpe.is_empty() else golpe.position)
		if golpe.is_empty():
			print("no le dio a nada en ", alcance, " m")
			return
		var d = snappedf(origen.distance_to(golpe.position), 0.01)
		print("le dio a ", golpe.collider.name, " a ", d, " m")
		if golpe.collider.has_method("recibir_golpe"):
			golpe.collider.recibir_golpe(danio)


func lanzar_rayo():
	if desde == 0:	# desde el pecho, hacia donde mira el personaje
		origen = pj.global_position + Vector3(0, 0.8, 0)
		hacia = origen - pj.global_basis.z * alcance
	else:	# desde la cámara, por un punto de la pantalla
		var cam = get_viewport().get_camera_3d()
		var punto = get_viewport().get_visible_rect().size / 2
		if desde == 2:
			punto = get_viewport().get_mouse_position()
		origen = cam.project_ray_origin(punto)
		hacia = origen + cam.project_ray_normal(punto) * alcance
	var consulta = PhysicsRayQueryParameters3D.create(origen, hacia)
	consulta.exclude = [pj.get_rid()]
	return pj.get_world_3d().direct_space_state.intersect_ray(consulta)


# La tarjeta que se ve: un rectángulo amarillo que vuela del pecho del árbitro
# hasta donde pegó el rayo. Es solo para que se vea: el golpe ya lo hizo el rayo.
func mostrar_tarjeta(desde_p, hasta_p):
	var tarjeta = MeshInstance3D.new()
	var malla = BoxMesh.new()
	malla.size = Vector3(0.22, 0.32, 0.03)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.85, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(1, 0.8, 0.1)
	mat.emission_energy_multiplier = 1.5
	malla.material = mat
	tarjeta.mesh = malla
	get_tree().current_scene.add_child(tarjeta)
	tarjeta.global_position = desde_p
	var tiempo = maxf(desde_p.distance_to(hasta_p) / 40.0, 0.05)	# vuela a 40 m/s
	var tween = tarjeta.create_tween()
	tween.tween_property(tarjeta, "global_position", hasta_p, tiempo)
	tween.parallel().tween_property(tarjeta, "rotation:z", TAU * 2, tiempo)
	tween.tween_callback(tarjeta.queue_free)
