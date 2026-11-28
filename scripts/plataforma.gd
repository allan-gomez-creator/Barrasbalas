extends StaticBody3D
# Corrección 3 - Allan: que las plataformas se vean y no se confundan con la tribuna.
# Antes eran cajas blancas que flotaban y se perdían contra la pared blanca.
# Ahora: cuerpo oscuro, franja de peligro amarilla y negra al frente,
# borde amarillo arriba (brilla un poco de noche) y dos patas hasta el piso.
# Va en Valla1 y Valla2 con todo, y en las tribunas bajas solo con el borde
# (con_franja = false). No cambia la colisión.

@export var color_cuerpo = Color(0.16, 0.19, 0.27)
@export var color_borde = Color(1.0, 0.78, 0.1)
@export var brillo_borde = 0.6
@export var alto_franja = 0.22
@export var con_franja = true
@export var con_patas = true

var ancho = 3.0
var alto = 0.4
var fondo = 4.0

func _ready():
	var malla_inst = get_node_or_null("MeshInstance3D")
	if malla_inst and malla_inst.mesh is BoxMesh:
		ancho = malla_inst.mesh.size.x
		alto = malla_inst.mesh.size.y
		fondo = malla_inst.mesh.size.z
		var cuerpo = StandardMaterial3D.new()
		cuerpo.albedo_color = color_cuerpo
		cuerpo.roughness = 0.8
		malla_inst.set_surface_override_material(0, cuerpo)
	if con_franja:
		armar_franja()
	armar_borde()
	if con_patas:
		armar_patas()

# Franja amarilla y negra en diagonal, en la cara que mira a la cámara.
func armar_franja():
	var img = Image.create(64, 16, false, Image.FORMAT_RGB8)
	for x in 64:
		for y in 16:
			var amarillo = ((x + y) / 8) % 2 == 0
			img.set_pixel(x, y, color_borde if amarillo else Color(0.08, 0.08, 0.08))
	var tex = ImageTexture.create_from_image(img)
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.uv1_scale = Vector3(ancho / 1.0, 1, 1)
	var caja = BoxMesh.new()
	caja.size = Vector3(ancho, alto_franja, 0.02)
	var franja = MeshInstance3D.new()
	franja.name = "Franja"
	franja.mesh = caja
	franja.material_override = mat
	franja.position = Vector3(0, alto / 2 - alto_franja / 2, fondo / 2 + 0.011)
	add_child(franja)

# Borde amarillo arriba, al frente: marca dónde se pisa.
func armar_borde():
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color_borde
	mat.emission_enabled = true
	mat.emission = color_borde
	mat.emission_energy_multiplier = brillo_borde
	var caja = BoxMesh.new()
	caja.size = Vector3(ancho + 0.04, 0.05, 0.12)
	var borde = MeshInstance3D.new()
	borde.name = "Borde"
	borde.mesh = caja
	borde.material_override = mat
	borde.position = Vector3(0, alto / 2 + 0.02, fondo / 2 - 0.05)
	add_child(borde)

# Dos patas hasta el piso, para que no parezca que flota.
func armar_patas():
	var piso_local = -global_position.y
	var largo = (-alto / 2) - piso_local
	if largo <= 0.05:
		return
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color_cuerpo.darkened(0.3)
	for lado in [-1, 1]:
		var caja = BoxMesh.new()
		caja.size = Vector3(0.18, largo, 0.18)
		var pata = MeshInstance3D.new()
		pata.name = "Pata"
		pata.mesh = caja
		pata.material_override = mat
		pata.position = Vector3(lado * (ancho / 2 - 0.3), -alto / 2 - largo / 2, fondo / 2 - 0.4)
		add_child(pata)
