extends Node3D
# Lunes 23 - Allan: la luz del estadio.
# El partido empieza a las 4 p. m. y el CicloDia de Juan Manuel avanza 1 hora
# por minuto, así que a mitad de partida ya es de noche. Este nodo:
#  - arma las torres de iluminación detrás de las gradas,
#  - las prende una por una cuando empieza a oscurecer (y las apaga si amanece),
#  - y oscurece el cielo con la hora.
# Solo LEE la hora del SistemaSol: no toca sus scripts.

@export var torres_x: Array[float] = [-8.0, 12.0, 32.0, 52.0]   # dónde va cada torre
@export var prender_bajo = 0.35        # se prenden cuando el sol baja de este factor (0 = noche, 1 = mediodía)
@export var energia_reflector = 5.0
@export var energia_general = 0.9   # la luz pareja que deja ver a los barristas de noche
@export var segundos_entre_torres = 0.5
@export var cielo_dia_arriba = Color(0.36, 0.52, 0.78)
@export var cielo_dia_horizonte = Color(0.66, 0.7, 0.78)
@export var cielo_noche_arriba = Color(0.01, 0.02, 0.06)
@export var cielo_noche_horizonte = Color(0.07, 0.08, 0.15)

const ALTO_TORRE = 4.8     # m: el panel queda justo encima de las gradas, en la parte de arriba de la pantalla
const Z_TORRE = -9.0       # m: detrás de la última fila de gradas

var sistema_sol = null
var cielo = null
var prendidas = false
var paneles = []           # material emisivo de cada panel
var reflectores = []       # SpotLight3D de cada torre
var luz_general = null     # una luz de frente, como el conjunto de todos los reflectores


func _ready():
	add_to_group("luces_estadio")
	for x in torres_x:
		armar_torre(x)
	luz_general = DirectionalLight3D.new()
	luz_general.name = "LuzGeneral"
	luz_general.light_color = Color(0.95, 0.96, 1.0)
	luz_general.light_energy = 0.0
	luz_general.shadow_enabled = false
	add_child(luz_general)
	# Desde arriba y desde el lado de la cámara, apuntando a la cancha.
	luz_general.rotation_degrees = Vector3(-50, 0, 0)
	await get_tree().process_frame
	var escena = get_tree().current_scene
	sistema_sol = escena.get_node_or_null("SistemaSol")
	var entorno = escena.get_node_or_null("WorldEnvironment")
	if entorno and entorno.environment and entorno.environment.sky:
		cielo = entorno.environment.sky.sky_material
	if sistema_sol == null:
		print("LucesEstadio: no encontré el SistemaSol, las torres quedan apagadas")


func _process(_delta):
	if sistema_sol == null:
		return
	var f = CicloDia.factor_sol(sistema_sol.ciclo.hora)   # 1 = mediodía, 0 = noche
	var dia = clampf(f / 0.5, 0.0, 1.0)                   # el cielo ya está "de día" desde la mitad
	if cielo is ProceduralSkyMaterial:
		cielo.sky_top_color = cielo_noche_arriba.lerp(cielo_dia_arriba, dia)
		cielo.sky_horizon_color = cielo_noche_horizonte.lerp(cielo_dia_horizonte, dia)
		cielo.ground_horizon_color = cielo.sky_horizon_color
	if not prendidas and f < prender_bajo:
		prender()
	elif prendidas and f > prender_bajo + 0.05:
		apagar()


# Una torre: el poste, el panel de luces y el reflector que apunta a la cancha.
func armar_torre(x):
	var torre = Node3D.new()
	torre.name = "Torre%d" % (paneles.size() + 1)
	torre.position = Vector3(x, 0, Z_TORRE)
	add_child(torre)

	var poste = MeshInstance3D.new()
	var malla_poste = BoxMesh.new()
	malla_poste.size = Vector3(0.35, ALTO_TORRE, 0.35)
	poste.mesh = malla_poste
	poste.position.y = ALTO_TORRE / 2.0
	var gris = StandardMaterial3D.new()
	gris.albedo_color = Color(0.35, 0.36, 0.4)
	poste.material_override = gris
	torre.add_child(poste)

	var panel = MeshInstance3D.new()
	var malla_panel = BoxMesh.new()
	malla_panel.size = Vector3(2.6, 1.3, 0.3)
	panel.mesh = malla_panel
	panel.position.y = ALTO_TORRE + 0.4
	var luz = StandardMaterial3D.new()
	luz.albedo_color = Color(0.25, 0.25, 0.28)
	luz.emission_enabled = true
	luz.emission = Color(1.0, 0.96, 0.85)
	luz.emission_energy_multiplier = 0.0      # apagada
	panel.material_override = luz
	torre.add_child(panel)
	paneles.append(luz)

	var reflector = SpotLight3D.new()
	reflector.position = Vector3(0, ALTO_TORRE, 0.5)
	reflector.light_color = Color(1.0, 0.96, 0.88)
	reflector.light_energy = 0.0
	reflector.spot_range = 30.0
	reflector.spot_angle = 55.0
	reflector.spot_attenuation = 0.3
	torre.add_child(reflector)
	# Que apunte a la cancha, un poco adelante de la torre.
	reflector.look_at(Vector3(x, 0, 1.0), Vector3.UP)
	reflectores.append(reflector)


func prender():
	prendidas = true
	print("LucesEstadio: se prenden las torres")
	for i in paneles.size():
		var t = create_tween()
		t.tween_interval(i * segundos_entre_torres)
		# un parpadeo corto, como las lámpara de estadio cuando arrancan
		t.tween_callback(poner_torre.bind(i, 0.4))
		t.tween_interval(0.08)
		t.tween_callback(poner_torre.bind(i, 0.0))
		t.tween_interval(0.08)
		t.tween_callback(poner_torre.bind(i, 1.0))


func apagar():
	prendidas = false
	for i in paneles.size():
		poner_torre(i, 0.0)


func poner_torre(i, cuanto):
	paneles[i].emission_energy_multiplier = 2.0 * cuanto
	reflectores[i].light_energy = energia_reflector * cuanto
	# La luz general sube a medida que se prenden las torres.
	var prendidas_ya = 0.0
	for r in reflectores:
		prendidas_ya += r.light_energy / energia_reflector
	luz_general.light_energy = energia_general * prendidas_ya / reflectores.size()
