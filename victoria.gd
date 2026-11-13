extends CanvasLayer
# Avance 3 - Martín: pantalla de victoria. La crean las oleadas al terminar la oleada 8.
# El juego queda en pausa; con R, Enter o el botón se vuelve a empezar.


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS   # para que funcione con el juego en pausa
	$Fondo/Caja/OtraVez.pressed.connect(reiniciar)


func mostrar(energia, tiempo_texto, oleadas):
	$Fondo/Caja/Detalle.text = "Sobreviviste a las %d oleadas\nEnergía %d / 5   ·   Tiempo %s" % [
		oleadas, energia, tiempo_texto]


func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R or event.keycode == KEY_ENTER:
			reiniciar()


func reiniciar():
	get_tree().paused = false
	queue_free()   # la pantalla vive en la raíz, fuera de la escena: hay que quitarla a mano
	get_tree().reload_current_scene()
