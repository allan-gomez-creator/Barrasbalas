extends Node3D
# Lunes 23 - Allan: que cada zona del mapa se reconozca.
#  - Un letrero en las gradas al comienzo de cada zona.
#  - Trapos de la barra colgados de las gradas, con los colores de cada zona.
# Solo es decorado: no tiene colisión y no cambia nada del juego.

# Una entrada por zona: dónde va el letrero, sus colores y los trapos.
var zonas = [
	{"x": -4.0, "nombre": "ZONA 1 · CÍRCULO CENTRAL",
	 "color_a": Color(0.8, 0.1, 0.12), "color_b": Color(0.96, 0.96, 0.94),
	 "trapos": [[-1.5, "¡VAMOS LOCAL!"], [6.0, "ÁRBITRO VENDIDO"]]},
	{"x": 18.5, "nombre": "ZONA 2 · RUMBO AL TÚNEL",
	 "color_a": Color(0.1, 0.55, 0.25), "color_b": Color(0.96, 0.96, 0.94),
	 "trapos": [[24.0, "PITO COMPRADO"], [37.0, "¡FUERA EL ÁRBITRO!"]]},
	{"x": 48.5, "nombre": "ZONA 3 · BOCA DEL TÚNEL",
	 "color_a": Color(0.12, 0.25, 0.7), "color_b": Color(0.98, 0.82, 0.12),
	 "trapos": [[51.0, "AL TÚNEL NO LLEGA"]]},
]

const Z_LETRERO = -2.93    # justo delante del frente de las tribunas

# Lunes 23 (tarde): el arco es del "Soccer Field" de OpenGameArt (CC0), que
# consiguió Martín. El archivo trae toda una cancha; aquí solo se usa un arco.
const MODELO_CANCHA = preload("res://assets/estadio/soccer-field/Soccer Field.fbx")
@export var arco_x = -10.5       # dónde va el arco (detrás de la tribuna izquierda, zona 1)
@export var escala_arco = 2.35   # el arco viene de 1.04 de alto: x 2.35 = 2.44 m, el alto real
const Z_TRAPO = -2.96      # colgados del frente de las tribunas


func _ready():
	arco()
	for zona in zonas:
		letrero(zona)
		for trapo_info in zona["trapos"]:
			trapo(trapo_info[0], trapo_info[1], zona["color_a"], zona["color_b"])


func letrero(zona):
	var tablero = caja(Vector3(4.4, 0.5, 0.06), Vector3(zona["x"], 1.15, Z_LETRERO), Color(0.08, 0.08, 0.1))
	tablero.name = "Letrero" + str(zonas.find(zona) + 1)
	var franja = caja(Vector3(4.4, 0.06, 0.07), Vector3(zona["x"], 0.92, Z_LETRERO), zona["color_a"])
	franja.name = "Franja" + str(zonas.find(zona) + 1)
	var texto = Label3D.new()
	texto.text = zona["nombre"]
	texto.pixel_size = 0.006
	texto.font_size = 48
	texto.outline_size = 0
	texto.modulate = Color(0.98, 0.98, 0.95)
	texto.position = Vector3(zona["x"], 1.16, Z_LETRERO + 0.04)
	add_child(texto)


# Un trapo de dos franjas con un mensaje, colgado del frente de las gradas.
func trapo(x, mensaje, color_a, color_b):
	var y = 1.85
	caja(Vector3(3.2, 0.38, 0.03), Vector3(x, y + 0.19, Z_TRAPO), color_a)
	caja(Vector3(3.2, 0.38, 0.03), Vector3(x, y - 0.19, Z_TRAPO), color_b)
	var texto = Label3D.new()
	texto.text = mensaje
	texto.pixel_size = 0.006
	texto.font_size = 56
	texto.outline_size = 10
	texto.modulate = Color(0.08, 0.08, 0.1) if color_b.v > 0.8 else Color(1, 1, 1)
	texto.outline_modulate = color_b
	texto.position = Vector3(x, y, Z_TRAPO + 0.03)
	add_child(texto)


func caja(tamano, posicion, color):
	var m = MeshInstance3D.new()
	var malla = BoxMesh.new()
	malla.size = tamano
	m.mesh = malla
	m.position = posicion
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	m.material_override = mat
	add_child(m)
	return m


# Del modelo de la cancha se deja solo un arco. Las otras mallas se vacían en vez
# de borrarse, porque en el modelo el arco cuelga de la malla de la cancha.
func arco():
	var cancha = MODELO_CANCHA.instantiate()
	for malla in cancha.find_children("*", "MeshInstance3D", true, false):
		if malla.name != "Soccer Goal":
			malla.mesh = null
	var nodo = Node3D.new()
	nodo.name = "Arco"
	add_child(nodo)
	nodo.add_child(cancha)
	# En el modelo el arco está en x = -11.41, z = 0, con la boca mirando a +x.
	cancha.position = Vector3(11.41, 0, 0)
	nodo.scale = Vector3.ONE * escala_arco
	nodo.rotation_degrees.y = -90          # la boca del arco mira a la cámara
	nodo.position = Vector3(arco_x, 0, -0.9)
