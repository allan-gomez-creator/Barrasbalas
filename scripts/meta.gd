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
	prender_tunel()
	print("Meta: ¡el túnel está abierto!")


# Lunes 23 - Allan: al abrirse, el túnel se ilumina por dentro con luz cálida
# y el letrero CAMERINOS se pone amarillo, para que se vea a dónde correr.
func prender_tunel():
	var tunel = get_node_or_null("../Tunel")
	if tunel == null:
		return
	var luz = OmniLight3D.new()
	luz.name = "LuzTunel"
	luz.light_color = Color(1.0, 0.78, 0.45)
	luz.light_energy = 0.0
	luz.omni_range = 5.0
	luz.position = Vector3(56.5, 1.6, -1.2)
	tunel.add_child(luz)
	var boca = tunel.get_node_or_null("BocaTunel")
	var mat = null
	if boca:
		mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.1, 0.08, 0.06)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.7, 0.35)
		mat.emission_energy_multiplier = 0.0
		boca.material_override = mat
	var t = create_tween().set_parallel()
	t.tween_property(luz, "light_energy", 3.0, 1.0)
	if mat:
		t.tween_property(mat, "emission_energy_multiplier", 0.6, 1.0)
	var letrero = tunel.get_node_or_null("Letrero")
	if letrero:
		t.tween_property(letrero, "modulate", Color(1, 0.85, 0.2), 1.0)


func _al_entrar(cuerpo):
	if activa and cuerpo.is_in_group("arbitro"):
		activa = false   # que no gane dos veces
		print("Meta: el árbitro llegó a camerinos")
		get_tree().call_group("oleadas", "ganar")
