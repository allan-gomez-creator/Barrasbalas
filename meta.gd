extends Area3D
# Avance 5 - Allan: la meta frente al túnel de camerinos.
# Está apagada toda la partida. Cuando termina la última oleada (la 8), la
# barrera del túnel se abre (barrera.gd) y esta meta se prende: aparece el
# letrero "¡ENTRA A CAMERINOS!" y, cuando el árbitro llega, se gana.
# Las oleadas de Martín esperan esto: ganar() solo cuenta después de la oleada 8.

@export var parpadeo = 0.5   # s que tarda el letrero en apagarse y prenderse

var activa = false
@onready var flecha = $Flecha


func _ready():
	add_to_group("meta")   # así las oleadas saben que hay que esperar al árbitro
	monitoring = false
	flecha.visible = false
	body_entered.connect(_al_entrar)
	await get_tree().process_frame
	var oleadas = get_tree().get_first_node_in_group("oleadas")
	if oleadas and oleadas.has_signal("oleada_termina"):
		oleadas.oleada_termina.connect(_al_terminar_oleada)


func _al_terminar_oleada(n):
	var oleadas = get_tree().get_first_node_in_group("oleadas")
	var ultima = oleadas.get("ultima_oleada") if oleadas else 8
	if n >= ultima:
		activar()


func activar():
	activa = true
	set_deferred("monitoring", true)   # no se puede cambiar justo durante una señal de física
	flecha.visible = true
	# El letrero parpadea para que se note.
	var t = flecha.create_tween().set_loops()
	t.tween_property(flecha, "modulate:a", 0.25, parpadeo)
	t.tween_property(flecha, "modulate:a", 1.0, parpadeo)
	print("Meta: ¡el túnel está abierto!")


func _al_entrar(cuerpo):
	if activa and cuerpo.is_in_group("arbitro"):
		activa = false   # que no gane dos veces
		print("Meta: el árbitro llegó a camerinos")
		get_tree().call_group("oleadas", "ganar")
