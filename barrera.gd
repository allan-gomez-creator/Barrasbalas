extends StaticBody3D
# La valla de la policía entre dos zonas. Está cerrada hasta que termina la
# oleada que dice "abre_tras_oleada"; ahí desaparece y deja pasar.
# Lunes 23 - Allan: la valla se ve de frente a la cámara (antes era un poste
# azul), tiene una sirena que titila roja y azul, y al abrirse se hunde en el
# piso. La colisión no cambia.

signal se_abrio

# Lunes 23 (tarde): la valla y los conos son del City Kit (Roads) de Kenney (CC0),
# que consiguió Martín. Ver CREDITOS.txt.
const MODELO_VALLA = preload("res://assets/estadio/city-kit-roads/construction-fence.glb")
const MODELO_CONO = preload("res://assets/estadio/city-kit-roads/construction-cone.glb")

@export var abre_tras_oleada = 3
@export var ancho_valla = 1.1      # m que se ve de frente (la colisión sigue igual de delgada)
@export var alto_valla = 1.3
var abierta = false
@onready var letrero = $Letrero

var valla_nueva = null
var sirena = null


func _ready():
	add_to_group("barreras")
	letrero.visible = false
	$Valla.visible = false          # el bloque azul viejo ya no se usa
	$Aviso.visible = false          # la valla nueva ya dice POLICÍA en su placa
	armar_valla()
	await get_tree().process_frame
	var oleadas = get_tree().get_first_node_in_group("oleadas")
	if oleadas and oleadas.has_signal("oleada_termina"):
		oleadas.oleada_termina.connect(_al_terminar_oleada)


func _al_terminar_oleada(n):
	if not abierta and n >= abre_tras_oleada:
		abrir()


func abrir():
	abierta = true
	$Aviso.visible = false
	$CollisionShape3D.set_deferred("disabled", true)
	print(name, ": ¡la policía abrió el paso!")
	se_abrio.emit()
	# La valla se hunde en el piso y la sirena se apaga.
	var t = create_tween()
	t.tween_property(valla_nueva, "position:y", valla_nueva.position.y - alto_valla - 0.2, 0.6) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.tween_callback(valla_nueva.hide)
	letrero.visible = true
	await get_tree().create_timer(3.0).timeout
	letrero.visible = false


# La valla: el modelo de Kenney, una placa amarilla, la sirena encima y dos conos.
# El nodo está a 4 m de alto, así que todo baja 4 m para quedar en el piso.
func armar_valla():
	valla_nueva = Node3D.new()
	valla_nueva.name = "VallaPolicia"
	valla_nueva.position = Vector3(0, -4.0, 0.3)
	add_child(valla_nueva)

	var amarillo = StandardMaterial3D.new()
	amarillo.albedo_color = Color(0.98, 0.8, 0.1)

	# La valla de Kenney mide 0.375 de largo y 0.18 de alto, y viene de lado:
	# se gira 90° para que quede de frente y se estira al ancho y alto que queremos.
	var modelo = MODELO_VALLA.instantiate()
	modelo.rotation_degrees.y = 90
	modelo.scale = Vector3(5.0, alto_valla / 0.179, ancho_valla / 0.375)
	valla_nueva.add_child(modelo)
	# Dos conos a los lados, un poco adelante.
	for lado in [-1, 1]:
		var cono = MODELO_CONO.instantiate()
		cono.scale = Vector3.ONE * 6.0      # 0.094 x 6 = 0.56 m de alto
		cono.position = Vector3(lado * (ancho_valla / 2.0 + 0.35), 0, 0.9)
		valla_nueva.add_child(cono)
	caja(Vector3(ancho_valla - 0.1, 0.32, 0.04), Vector3(0, alto_valla * 0.55 + 0.2, 0.22), amarillo)

	var texto = Label3D.new()
	texto.text = "POLICÍA"
	texto.pixel_size = 0.006
	texto.font_size = 40
	texto.modulate = Color(0.05, 0.05, 0.08)
	texto.outline_size = 0
	texto.position = Vector3(0, alto_valla * 0.55 + 0.2, 0.25)
	valla_nueva.add_child(texto)

	sirena = StandardMaterial3D.new()
	sirena.albedo_color = Color(0.1, 0.1, 0.12)
	sirena.emission_enabled = true
	sirena.emission = Color(1, 0.1, 0.1)
	sirena.emission_energy_multiplier = 3.0
	caja(Vector3(0.22, 0.14, 0.14), Vector3(0, alto_valla + 0.09, 0), sirena)
	# Rojo y azul, cada 0.35 s, mientras la valla esté cerrada.
	var t = create_tween().set_loops()
	t.tween_callback(func(): sirena.emission = Color(1, 0.1, 0.1))
	t.tween_interval(0.35)
	t.tween_callback(func(): sirena.emission = Color(0.15, 0.35, 1))
	t.tween_interval(0.35)
	valla_nueva.tree_exiting.connect(t.kill)


func caja(tamano, posicion, material):
	var m = MeshInstance3D.new()
	var malla = BoxMesh.new()
	malla.size = tamano
	m.mesh = malla
	m.position = posicion
	m.material_override = material
	valla_nueva.add_child(m)
	return m
