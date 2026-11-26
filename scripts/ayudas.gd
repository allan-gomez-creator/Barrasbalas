extends CanvasLayer
# Corrección 2 - Juan Manuel: las ayudas (powerups).
# En cada tiempo muerto muestra 3 ayudas al azar y el jugador escoge 1 (clic o teclas 1, 2, 3).
# Cada ayuda cambia un número que ya existe en el árbitro o en sus nodos, sin tocar sus scripts.

@export var probar_con_y = false	# Y abre las ayudas sin esperar el tiempo muerto. Desmarcar antes del commit

const AYUDAS = [
	{"id": "aerosol", "nombre": "Aerosol", "efecto": "+2 usos de aerosol"},
	{"id": "tarjeta", "nombre": "Tarjeta roja", "efecto": "+1 de daño por tarjeta"},
	{"id": "guayos", "nombre": "Guayos nuevos", "efecto": "+15 % de velocidad"},
	{"id": "fisica", "nombre": "Preparación física", "efecto": "+1 de energía máxima"},
	{"id": "aire", "nombre": "Segundo aire", "efecto": "Esquive 0.4 s más rápido"},
]
const AEROSOL_MAXIMO = 4
const RECARGA_MINIMA = 0.6
const VECES_MAXIMAS = {"tarjeta": 2, "guayos": 2, "fisica": 2}	# cuántas veces se puede escoger cada una

var arbitro = null
var opciones = []	# las 3 ayudas que se están mostrando
var botones = []
var escogidas = {}	# cuántas veces se ha escogido cada ayuda en esta partida


func _ready():
	layer = 10	# encima del juego, debajo de la derrota y la victoria
	construir()
	visible = false
	await get_tree().process_frame	# espera a que el árbitro y las oleadas estén listos
	arbitro = get_tree().get_first_node_in_group("arbitro")
	var oleadas = get_tree().get_first_node_in_group("oleadas")
	if oleadas:
		oleadas.tiempo_muerto.connect(func(_segundos): mostrar())
		oleadas.oleada_empieza.connect(func(_n): visible = false)	# si no escogió, se cierra


# Arma la ventana: un título y 3 botones en fila, en el centro de la pantalla.
func construir():
	var centro = CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE	# fuera de los botones, el clic sigue disparando
	add_child(centro)
	var panel = PanelContainer.new()
	if ResourceLoader.exists("res://escenas/tema.tres"):
		panel.theme = load("res://escenas/tema.tres")	# la fuente y los botones de Martín
	centro.add_child(panel)
	var caja = VBoxContainer.new()
	caja.add_theme_constant_override("separation", 12)
	panel.add_child(caja)
	var titulo = Label.new()
	titulo.text = "Tiempo muerto: escoge una ayuda (1, 2, 3)"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(titulo)
	var fila = HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	caja.add_child(fila)
	for i in 3:
		var boton = Button.new()
		boton.custom_minimum_size = Vector2(240, 90)
		boton.focus_mode = Control.FOCUS_NONE	# para que Espacio no lo presione
		boton.pressed.connect(escoger.bind(i))
		fila.add_child(boton)
		botones.append(boton)


func mostrar():
	if arbitro == null or arbitro.muerto:
		return
	var posibles = []
	for ayuda in AYUDAS:
		if disponible(ayuda.id):
			posibles.append(ayuda)
	posibles.shuffle()
	opciones = posibles.slice(0, 3)
	for i in 3:
		botones[i].visible = i < opciones.size()
		if i < opciones.size():
			botones[i].text = "%d. %s\n%s" % [i + 1, opciones[i].nombre, opciones[i].efecto]
	visible = opciones.size() > 0


# Una ayuda no sale si su nodo no está, si ya llegó a su límite o si ya se escogió 2 veces.
func disponible(id):
	if escogidas.get(id, 0) >= VECES_MAXIMAS.get(id, 99):
		return false
	match id:
		"aerosol":
			var aerosol = arbitro.get_node_or_null("Aerosol")
			return aerosol != null and aerosol.usos_por_oleada < AEROSOL_MAXIMO
		"tarjeta":
			return arbitro.get_node_or_null("Apuntar") != null
		"aire":
			var esquive = arbitro.get_node_or_null("Esquive")
			return esquive != null and esquive.recarga > RECARGA_MINIMA
	return true	# guayos y preparación física siempre se pueden


func escoger(i):
	if not visible or i >= opciones.size():
		return
	aplicar(opciones[i].id)
	escogidas[opciones[i].id] = escogidas.get(opciones[i].id, 0) + 1
	print("ayuda escogida: ", opciones[i].nombre)
	visible = false


func aplicar(id):
	match id:
		"aerosol":
			var aerosol = arbitro.get_node("Aerosol")
			aerosol.usos_por_oleada = min(aerosol.usos_por_oleada + 2, AEROSOL_MAXIMO)
			aerosol.recargar()	# llena los usos ya y avisa al HUD
		"tarjeta":
			arbitro.get_node("Apuntar").danio += 1
		"guayos":
			arbitro.speed *= 1.15
		"fisica":
			arbitro.energia_max += 1
			arbitro.energia += 1
			arbitro.energia_cambio.emit(arbitro.energia)	# para que el HUD se actualice
		"aire":
			var esquive = arbitro.get_node("Esquive")
			esquive.recarga = max(esquive.recarga - 0.4, RECARGA_MINIMA)


func _unhandled_input(event):
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if visible:
		if event.keycode == KEY_1:
			escoger(0)
		elif event.keycode == KEY_2:
			escoger(1)
		elif event.keycode == KEY_3:
			escoger(2)
	elif probar_con_y and event.keycode == KEY_Y:
		mostrar()
		
