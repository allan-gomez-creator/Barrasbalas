class_name SistemaSol
extends Node
# Tarea A - Barrasbalas: el coordinador de la luz principal.
# Tiene un CicloDia, le pide las cuentas y las aplica al Sol y al ambiente.
# Avisa una sola vez cuando cae la noche (y cuando vuelve el dia) con la senal cambio_noche.

signal cambio_noche(es_noche: bool)

@export var sol: DirectionalLight3D
@export var entorno: WorldEnvironment
@export var energia_sol := 1.5
@export var azimut := 150.0	# grados en Y: de tarde el sol queda del lado de la camara y las sombras caen hacia el tunel (+X)
@export var ambiente_dia := 1.0
@export var ambiente_noche := 0.15
@onready var ciclo: CicloDia = $CicloDia

var era_noche := false


func _ready() -> void:
	aplicar_hora()
	era_noche = CicloDia.factor_sol(ciclo.hora) <= 0.0


func _process(delta: float) -> void:
	ciclo.avanzar(delta)
	aplicar_hora()
	var es_noche := CicloDia.factor_sol(ciclo.hora) <= 0.0
	if es_noche != era_noche:
		era_noche = es_noche
		cambio_noche.emit(es_noche)


func aplicar_hora() -> void:
	var h := ciclo.hora
	var f := CicloDia.factor_sol(h)
	sol.rotation_degrees = Vector3(-CicloDia.elevacion(h), azimut, 0.0)	# X negativa: el sol sube
	sol.light_energy = energia_sol * f
	sol.light_color = CicloDia.color_sol(h)
	entorno.environment.ambient_light_energy = lerpf(ambiente_noche, ambiente_dia, f)


# Nivel 3: Lambert a mano.
static func lambert(normal: Vector3, hacia_luz: Vector3) -> float:
	var n := normal.normalized()
	var l := hacia_luz.normalized()
	return maxf(0.0, n.dot(l))


# Prediccion del canal rojo de una superficie horizontal (normal (0, 1, 0)).
func prediccion_piso() -> float:
	var hacia_luz := sol.global_transform.basis.z	# la luz viaja hacia -Z: la luz esta hacia +Z
	return sol.light_energy * sol.light_color.r * lambert(Vector3.UP, hacia_luz)
