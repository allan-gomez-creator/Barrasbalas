extends Area3D
# Botella de agua del tiempo muerto: si la toca el árbitro, le cura 1 y desaparece.

@export var cura = 1
@export var giro = 1.5        # vueltas por segundo, para que se note
@export var flota = 0.15      # cuánto sube y baja, en metros

var base_y = 0.0
var t = 0.0


func _ready():
	base_y = position.y
	body_entered.connect(_al_tocar)


func _process(delta):
	t += delta
	rotate_y(TAU * giro * delta / 4.0)
	position.y = base_y + sin(t * 3.0) * flota


func _al_tocar(cuerpo):
	if cuerpo.is_in_group("arbitro") and cuerpo.has_method("curar"):
		cuerpo.curar(cura)
		print("tomó agua")
		queue_free()
