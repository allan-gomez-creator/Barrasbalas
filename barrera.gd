extends StaticBody3D
# La valla de la policía entre dos zonas. Está cerrada hasta que termina la
# oleada que dice "abre_tras_oleada"; ahí desaparece y deja pasar.

@export var abre_tras_oleada = 3
var abierta = false
@onready var letrero = $Letrero


func _ready():
	add_to_group("barreras")
	letrero.visible = false
	await get_tree().process_frame
	var oleadas = get_tree().get_first_node_in_group("oleadas")
	if oleadas and oleadas.has_signal("oleada_termina"):
		oleadas.oleada_termina.connect(_al_terminar_oleada)


func _al_terminar_oleada(n):
	if not abierta and n >= abre_tras_oleada:
		abrir()


func abrir():
	abierta = true
	$Valla.visible = false
	$Aviso.visible = false
	$CollisionShape3D.set_deferred("disabled", true)
	print(name, ": ¡la policía abrió el paso!")
	letrero.visible = true
	await get_tree().create_timer(3.0).timeout
	letrero.visible = false
