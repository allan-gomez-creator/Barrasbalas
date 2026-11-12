extends OmniLight3D

@export var energia_base := 2.5
@export var amplitud := 0.3
@export var velocidad := 4.0
@export var semilla := 7

var ruido := FastNoiseLite.new()
var t := 0.0

static func energia(base: float, amp: float, r: float) -> float:
	return maxf(0.0, base * (1.0 + amp * r))

func _ready() -> void:
	ruido.seed = semilla
	ruido.frequency = 1.0
	# PRUEBA (borrar al terminar): debe imprimir 2.6 y 1.4
	print(energia(2.0, 0.3, 1.0), " ", energia(2.0, 0.3, -1.0))

func _process(delta: float) -> void:
	t += delta
	light_energy = energia(energia_base, amplitud, ruido.get_noise_1d(t * velocidad))
