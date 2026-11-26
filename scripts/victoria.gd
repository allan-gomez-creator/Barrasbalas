extends CanvasLayer
# Martín: pantalla de victoria. La crea ganar() de las oleadas cuando el árbitro
# entra al túnel (Mejora 3). El juego queda en pausa; con R, Enter o el botón
# se vuelve a empezar.
# Mejora 3: además muestra los puntos y el récord, que lleva el puntaje de
# Juan Manuel. ⚠️ Lee las variables "puntos", "record" y "record_nuevo" del
# nodo del grupo "puntaje": si en su script se llaman distinto, cambiar aquí
# solo esos tres nombres (función mostrar_puntos).


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS   # para que funcione con el juego en pausa
	$Fondo/Caja/OtraVez.pressed.connect(reiniciar)
	# Corrección 2: botón para volver al menú de inicio.
	if has_node("Fondo/Caja/Menu"):
		$Fondo/Caja/Menu.pressed.connect(ir_al_menu)


func mostrar(energia, tiempo_texto, oleadas):
	$Fondo/Caja/Detalle.text = "Sobreviviste a las %d oleadas\nEnergía %d / 5   ·   Tiempo %s" % [
		oleadas, energia, tiempo_texto]
	mostrar_puntos()


# Agrega una línea con los puntos (ya con el bono de victoria) y el récord.
# Si no hay puntaje en la escena, la pantalla queda como antes.
func mostrar_puntos():
	var puntaje = get_tree().get_first_node_in_group("puntaje")
	if puntaje == null or puntaje.get("total") == null:
		return
	var texto = "Puntos %d" % puntaje.get("total")
	if puntaje.get("record") != null:
		texto += "   ·   Récord %d" % puntaje.get("record")
	if puntaje.get("record_nuevo"):
		texto += "\n¡Récord nuevo!"
	var linea = Label.new()
	linea.name = "Puntos"
	linea.text = texto
	linea.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	linea.add_theme_font_size_override("font_size", 28)
	linea.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	$Fondo/Caja.add_child(linea)
	$Fondo/Caja.move_child(linea, 2)   # debajo del detalle, encima del botón


func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R or event.keycode == KEY_ENTER:
			reiniciar()


func reiniciar():
	get_tree().paused = false
	queue_free()   # la pantalla vive en la raíz, fuera de la escena: hay que quitarla a mano
	get_tree().reload_current_scene()


# Corrección 2: vuelve al menú de inicio (escenas/menu.tscn).
func ir_al_menu():
	get_tree().paused = false
	queue_free()   # igual que al reiniciar: la pantalla vive fuera de la escena
	get_tree().change_scene_to_file("res://escenas/menu.tscn")
