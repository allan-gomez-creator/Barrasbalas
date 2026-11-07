class_name LuzJugador
extends OmniLight3D

@export var rango := 5.0     # m: hasta dónde alumbra
@export var altura := 1.2    # m sobre los pies del árbitro


func _ready() -> void:
	position = Vector3(0.0, altura, 0.0)
	omni_range = rango
	omni_attenuation = 2.0       # la que se parece a 1/d²
	print(atenuacion(1.0), " ", atenuacion(2.0), " ", atenuacion(4.0))
	print(blinn_phong(Vector3(0, 1, 0), Vector3(0, 1, 1), Vector3(0, 1, -1), 32.0), " ", snappedf(blinn_phong(Vector3(0, 1, 0), Vector3(0, 1, 1), Vector3(0, 1, 0), 32.0), 0.0001))


static func atenuacion(d: float, exponente: float = 2.0) -> float:
	return 1.0 / pow(maxf(d, 0.0001), exponente)


static func blinn_phong(normal: Vector3, hacia_luz: Vector3, hacia_ojo: Vector3, brillo: float) -> float:
	var n := normal.normalized()
	var l := hacia_luz.normalized()
	var v := hacia_ojo.normalized()
	var h := (l + v).normalized()
	return pow(maxf(0.0, n.dot(h)), brillo)
