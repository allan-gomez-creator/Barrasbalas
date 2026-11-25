extends CanvasLayer
# Avance 3 + Mejora 2 - Juan Manuel: HUD, derrota, puntos y combo.
@export var oleadas: Node

var arbitro = null
var tiempo_muerto_restante = 0.0
var perdio = false
var puntaje = null
var combo_antes = 0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	$Derrota.visible = false
	$Pausa.visible = false
	$TiempoMuerto.visible = false
	$Resultado.visible = false
	$Puntos.visible = false
	$Combo.visible = false
	$Derrota/Reiniciar.pressed.connect(reiniciar)
	await get_tree().process_frame
	conectar()

func conectar():
	arbitro = get_tree().get_first_node_in_group("arbitro")
	if arbitro:
		arbitro.energia_cambio.connect(mostrar_energia)
		arbitro.murio.connect(perder)
		$EnergiaBarra.max_value = arbitro.energia_max
		mostrar_energia(arbitro.energia)
		var aerosol = arbitro.get_node_or_null("Aerosol")
		if aerosol:
			aerosol.usos_cambio.connect(mostrar_aerosol)
			mostrar_aerosol(aerosol.usos)
	if oleadas == null:
		oleadas = get_tree().current_scene.find_child("Oleadas", true, false)
	if oleadas:
		oleadas.oleada_empieza.connect(mostrar_oleada)
		oleadas.tiempo_muerto.connect(empezar_tiempo_muerto)
		mostrar_oleada(oleadas.oleada)
		if oleadas.has_signal("victoria"):
			oleadas.victoria.connect(mostrar_victoria)
	puntaje = get_tree().get_first_node_in_group("puntaje")
	if puntaje:
		puntaje.puntos_cambio.connect(mostrar_puntos)
		mostrar_puntos(puntaje.total, puntaje.combo)

func mostrar_energia(valor):
	$EnergiaBarra.value = valor
	$Energia.text = "Energía %d / %d" % [valor, arbitro.energia_max]

func mostrar_puntos(total, combo):
	$Puntos.visible = true
	$Puntos.text = "Puntos %d" % total
	$Combo.visible = combo > 0
	$Combo.text = "Combo ×%.1f" % puntaje.multiplicador()
	if combo > combo_antes:	# el combo subió: el texto crece y se pone amarillo un momento
		$Combo.pivot_offset = $Combo.size / 2
		var t = $Combo.create_tween().set_parallel()
		$Combo.scale = Vector2(1.5, 1.5)
		$Combo.modulate = Color(1, 0.85, 0.2)
		t.tween_property($Combo, "scale", Vector2.ONE, 0.25)
		t.tween_property($Combo, "modulate", Color.WHITE, 0.25)
	combo_antes = combo

# Debajo de la derrota o de la victoria: los puntos y el récord.
func mostrar_resultado():
	if puntaje == null:
		return
	var texto = "Puntos %d   ·   Récord %d" % [puntaje.total, puntaje.record]
	if puntaje.record_nuevo:
		texto += "\n¡Récord nuevo!"
	$Resultado.text = texto
	$Resultado.visible = true

func mostrar_victoria():
	await get_tree().process_frame	# deja que se sume el bono de victoria
	layer = 25	# por encima de la pantalla de victoria de Martín (capa 20)
	$Pausa.visible = false
	mostrar_resultado()

func mostrar_oleada(n):
	$Oleada.text = "Oleada %d" % n

func mostrar_aerosol(usos):
	$Aerosol.text = "Aerosol: %d" % usos

func empezar_tiempo_muerto(segundos):
	tiempo_muerto_restante = segundos
	$TiempoMuerto.visible = true

func _process(delta):
	if get_tree().paused or tiempo_muerto_restante <= 0.0:
		return
	tiempo_muerto_restante -= delta
	$TiempoMuerto.text = "Tiempo muerto: %d" % ceil(tiempo_muerto_restante)
	if tiempo_muerto_restante <= 0.0:
		$TiempoMuerto.visible = false

func perder():
	perdio = true
	get_tree().paused = true
	$Pausa.visible = false
	$Derrota.visible = true
	await get_tree().process_frame	# deja que el puntaje guarde el récord
	mostrar_resultado()

func reiniciar():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _unhandled_input(event):
	if perdio:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
			reiniciar()
		return
	if InputMap.has_action("pausa") and event.is_action_pressed("pausa"):
		get_tree().paused = not get_tree().paused
		$Pausa.visible = get_tree().paused
