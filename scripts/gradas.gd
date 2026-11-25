extends Node3D
# Lunes 23 - Allan: las gradas del estadio con el Racing Kit de Kenney (CC0),
# que consiguió Martín. Ver CREDITOS.txt.
# Las filas grises de antes (Fila1 a Fila6) se esconden y en su lugar se pone una
# fila de tribunas de Kenney a lo largo de todo el estadio:
#  - la estructura blanca se pinta de gris concreto (si no, encandila),
#  - las sillas toman el color de cada zona (rojo, verde, azul),
#  - los hinchas del nodo Publico se sientan sobre las sillas,
#  - y arriba van banderas.
# Es solo decorado: no tiene colisión.

const TRIBUNA = preload("res://assets/estadio/racing-kit/grandStand.glb")
const TRIBUNA_TECHO = preload("res://assets/estadio/racing-kit/grandStandCovered.glb")
const BANDERA_ROJA = preload("res://assets/estadio/racing-kit/flagRed.glb")
const BANDERA_VERDE = preload("res://assets/estadio/racing-kit/flagGreen.glb")

@export var escala = 5.0           # cada tribuna de Kenney mide 1 x 0.9 x 1: x 5 = 5 m de ancho, 4.5 de alto
@export var desde_x = -16.0        # donde empieza la fila de tribunas
@export var hasta_x = 62.0         # donde termina
@export var frente_z = -3.0        # el frente de las tribunas (los letreros de zona van justo delante)
@export var con_techo: Array[int] = [7, 11]   # qué tribunas llevan techo (lejos del marcador y de las torres)
@export var color_concreto = Color(0.55, 0.56, 0.6)

# Las sillas de cada zona: (hasta qué x llega la zona, color).
var colores_zona = [[15.3, Color(0.78, 0.16, 0.16)], [45.3, Color(0.16, 0.52, 0.26)], [999.0, Color(0.18, 0.3, 0.72)]]

# Medidas del modelo de Kenney (sin escalar):
const MODELO_X0 = -0.35            # la tribuna va de x = -0.35 a 0.65
const MODELO_FRENTE_Z = -0.65      # su frente está en z = -0.65
const SILLA_FRENTE = Vector2(-0.75, 0.24)   # (z, y) de la primera fila de sillas
const SILLA_FONDO = Vector2(-1.53, 0.62)    # (z, y) de la última fila

# Banderas arriba de las gradas (x, roja o verde). Lejos de las torres de luz.
var banderas = [[-12.0, "roja"], [-3.0, "roja"], [4.0, "roja"],
	[18.0, "verde"], [25.0, "verde"], [38.0, "verde"],
	[47.0, "roja"], [57.0, "verde"]]

var concreto = null


func _ready():
	for fila in ["Fila1", "Fila2", "Fila3", "Fila4", "Fila5", "Fila6"]:
		var nodo = get_node_or_null(fila)
		if nodo:
			nodo.visible = false
	concreto = StandardMaterial3D.new()
	concreto.albedo_color = color_concreto
	armar_tribunas()
	armar_banderas()
	sentar_hinchas()


func armar_tribunas():
	var i = 0
	var x = desde_x
	while x < hasta_x:
		var modelo = TRIBUNA_TECHO if i in con_techo else TRIBUNA
		var tribuna = modelo.instantiate()
		tribuna.name = "Tribuna%d" % (i + 1)
		tribuna.scale = Vector3.ONE * escala
		tribuna.position = Vector3(x - MODELO_X0 * escala, 0, z_del_modelo(0.0))
		add_child(tribuna)
		pintar(tribuna, color_de_zona(x + escala / 2.0))
		x += escala
		i += 1


# Dónde va el centro del modelo para que su frente quede en frente_z.
func z_del_modelo(_extra):
	return frente_z - MODELO_FRENTE_Z * escala


func color_de_zona(x):
	for z in colores_zona:
		if x < z[0]:
			return z[1]
	return colores_zona[-1][1]


# La estructura blanca pasa a concreto y las sillas rojas al color de la zona.
func pintar(tribuna, color_sillas):
	var sillas = StandardMaterial3D.new()
	sillas.albedo_color = color_sillas
	for malla in tribuna.find_children("*", "MeshInstance3D", true, false):
		for s in malla.mesh.get_surface_count():
			var mat = malla.mesh.surface_get_material(s)
			var nombre = mat.resource_name if mat else ""
			if nombre == "red":
				malla.set_surface_override_material(s, sillas)
			elif nombre == "grey" or nombre == "_defaultMat":
				malla.set_surface_override_material(s, concreto)


func armar_banderas():
	var arriba = 0.9 * escala                  # la parte de arriba de las tribunas
	var fondo = frente_z - 0.9 * escala        # casi al fondo de las tribunas
	for b in banderas:
		var bandera = (BANDERA_ROJA if b[1] == "roja" else BANDERA_VERDE).instantiate()
		bandera.scale = Vector3.ONE * 2.0     # el palo de Kenney mide 1.25: x 2 = 2.5 m
		# En el modelo el palo está en x = -0.33, z = -0.67.
		bandera.position = Vector3(b[0] + 0.66, arriba - 0.1, fondo + 1.34)
		add_child(bandera)


# Los hinchas estaban en las filas grises de antes. Se reparten igual de
# adelante hacia atrás, pero ahora sobre las sillas de las tribunas nuevas.
func sentar_hinchas():
	var publico = get_node_or_null("../Publico")
	if publico == null:
		return
	var hinchas = publico.get_children().filter(func(n): return n is Node3D)
	if hinchas.is_empty():
		return
	var z_min = INF
	var z_max = -INF
	for h in hinchas:
		z_min = minf(z_min, h.position.z)
		z_max = maxf(z_max, h.position.z)
	var centro_z = z_del_modelo(0.0)
	for h in hinchas:
		# t = 0 la fila de adelante, t = 1 la de atrás.
		var t = 0.0 if z_max == z_min else (z_max - h.position.z) / (z_max - z_min)
		var silla = SILLA_FRENTE.lerp(SILLA_FONDO, 0.08 + 0.5 * t)   # filas de abajo y del medio: arriba los tapa la estructura
		h.position.z = centro_z + silla.x * escala
		h.position.y = silla.y * escala + 0.35   # un poco más arriba, para que se les vea el torso
