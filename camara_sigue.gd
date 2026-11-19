extends Camera3D
# La cámara sigue al árbitro solo de lado (en x), suave, sin mostrar lo que hay
# más allá de los bordes del nivel. La altura y la inclinación no cambian.
# Cuando al árbitro le quitan energía, la cámara tiembla un momento.

@export var suavidad = 6.0          # más alto = sigue más pegado al árbitro
@export var limite_izq = -6.1       # x mínima del centro de la cámara (borde izquierdo del nivel + media pantalla)
@export var limite_der = 51.1       # x máxima del centro de la cámara (borde derecho del nivel - media pantalla)
@export var duracion_temblor = 0.2  # s
@export var fuerza_temblor = 0.15   # m

var arbitro = null
var energia_antes = -1
var temblor = 0.0
var x_suave = 0.0


func _ready():
	x_suave = position.x
	await get_tree().process_frame
	arbitro = get_tree().get_first_node_in_group("arbitro")
	if arbitro and arbitro.has_signal("energia_cambio"):
		energia_antes = arbitro.energia
		arbitro.energia_cambio.connect(_al_cambiar_energia)


func _process(delta):
	if arbitro == null or not is_instance_valid(arbitro):
		return
	var objetivo = clampf(arbitro.global_position.x, limite_izq, limite_der)
	# Se acerca un poco cada cuadro: así se mueve suave y no a saltos.
	x_suave = lerpf(x_suave, objetivo, 1.0 - exp(-suavidad * delta))
	position.x = x_suave
	if temblor > 0.0:
		temblor -= delta
		position.x += randf_range(-fuerza_temblor, fuerza_temblor)
		h_offset = randf_range(-fuerza_temblor, fuerza_temblor)
		v_offset = randf_range(-fuerza_temblor, fuerza_temblor)
	else:
		h_offset = 0.0
		v_offset = 0.0


func _al_cambiar_energia(valor):
	if valor < energia_antes:
		temblar()
	energia_antes = valor


func temblar():
	temblor = duracion_temblor
