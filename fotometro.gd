extends Node
# Herramienta del nivel 3 de la tarea A (no se califica): mide el pixel del piso
# y lo compara con la prediccion de Lambert de SistemaSol.

@export var sistema: SistemaSol
@export var camara: Camera3D
@export var superficie: MeshInstance3D	# la superficie que se mide
@export var punto := Vector3(-4, 0, 2)
@export var horas: Array[float] = [16.0, 17.0, 17.5]

var i := 0
var espera := 0


func _ready() -> void:
	var env := sistema.entorno.environment	# modo laboratorio
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.BLACK
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var mate := StandardMaterial3D.new()
	mate.roughness = 1.0
	mate.metallic_specular = 0.0
	mate.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT	# Godot usa Burley por defecto; para comparar con Lambert puro
	superficie.material_override = mate
	sistema.ciclo.pausado = true
	sistema.ciclo.hora = horas[0]


func _process(_delta: float) -> void:
	espera += 1
	if espera < 10:	# unos frames para que el render se ponga al dia
		return
	espera = 0
	var px := camara.unproject_position(punto)
	var imagen := get_viewport().get_texture().get_image()
	var color := imagen.get_pixel(int(px.x), int(px.y))
	print("hora %.1f	medido %.3f	predicho %.3f" % [sistema.ciclo.hora, color.srgb_to_linear().r, sistema.prediccion_piso()])
	i += 1
	if i < horas.size():
		sistema.ciclo.hora = horas[i]
	else:
		set_process(false)
