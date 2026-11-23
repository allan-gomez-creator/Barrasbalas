extends Node3D
# Lunes 23 - Allan: que cada zona del mapa se reconozca.
#  - Un letrero en las gradas al comienzo de cada zona.
#  - Trapos de la barra colgados de las gradas, con los colores de cada zona.
# Solo es decorado: no tiene colisión y no cambia nada del juego.

# Una entrada por zona: dónde va el letrero, sus colores y los trapos.
var zonas = [
	{"x": -4.0, "nombre": "ZONA 1 · CÍRCULO CENTRAL",
	 "color_a": Color(0.8, 0.1, 0.12), "color_b": Color(0.96, 0.96, 0.94),
	 "trapos": [[-11.0, "¡VAMOS LOCAL!"], [6.0, "ÁRBITRO VENDIDO"]]},
	{"x": 18.5, "nombre": "ZONA 2 · RUMBO AL TÚNEL",
	 "color_a": Color(0.1, 0.55, 0.25), "color_b": Color(0.96, 0.96, 0.94),
	 "trapos": [[24.0, "PITO COMPRADO"], [37.0, "¡FUERA EL ÁRBITRO!"]]},
	{"x": 48.5, "nombre": "ZONA 3 · BOCA DEL TÚNEL",
	 "color_a": Color(0.12, 0.25, 0.7), "color_b": Color(0.98, 0.82, 0.12),
	 "trapos": [[51.0, "AL TÚNEL NO LLEGA"]]},
]

const Z_LETRERO = -2.95    # frente de la fila 2 de las gradas
const Z_TRAPO = -3.95      # frente de la fila 3


func _ready():
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
