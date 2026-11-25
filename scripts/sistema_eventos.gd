extends Node

@export var luz_evento: OmniLight3D
@export var pico_destello := 4.0
@export var k_destello := 15.0

static func decaer(actual: float, base: float, k: float, dt: float) -> float:
	var alpha := 1.0 - exp(-k * dt)
	return actual + (base - actual) * alpha

func _ready() -> void:
	luz_evento.light_energy = 0.0
	_conectar.call_deferred()
	# PRUEBA (borrar al terminar): debe imprimir 0.199
	var e := 4.0
	for i in 30:
		e = decaer(e, 0.0, 6.0, 1.0 / 60.0)
	print(snappedf(e, 0.001))

func _conectar() -> void:
	for d in get_tree().get_nodes_in_group("disparadores"):
		d.evento.connect(_on_evento)

func _on_evento(posicion: Vector3) -> void:
	luz_evento.global_position = posicion + Vector3(0, 1.5, 0)
	luz_evento.light_energy = pico_destello

func _process(delta: float) -> void:
	luz_evento.light_energy = decaer(luz_evento.light_energy, 0.0, k_destello, delta)
