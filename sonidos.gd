extends Node
# Mejora 3 - Martín: los sonidos del juego.
# No toca los scripts de nadie: solo escucha señales y variables que ya existen.
#  - Pito: cuando empieza cada oleada (señal oleada_empieza de las oleadas)
#    y tres pitazos al ganar (señal victoria).
#  - Golpe: cuando la energía del árbitro baja (señal energia_cambio).
#  - Puntos: cuando sube el puntaje (variable "puntos" del nodo del grupo "puntaje").
#    ⚠️ Si en el script de Juan Manuel la variable se llama distinto, cambiar
#    solo la palabra "puntos" en _process().
# Los sonidos están en la carpeta sonidos/ (hechos por código, sin derechos de
# nadie). Para usar otros, por ejemplo los de Kenney (CC0), se reemplaza el
# archivo con el mismo nombre o se arrastra otro al Stream de cada nodo.

var arbitro = null
var puntaje = null
var energia_antes = -1
var puntos_antes = 0


func _ready():
	add_to_group("sonidos")
	process_mode = Node.PROCESS_MODE_ALWAYS   # para que el pitazo final suene con el juego en pausa
	# Se espera un cuadro: así ya existen las oleadas, el árbitro y el puntaje.
	await get_tree().process_frame
	conectar()


func conectar():
	var oleadas = get_tree().get_first_node_in_group("oleadas")
	if oleadas:
		oleadas.oleada_empieza.connect(func(_n): $Pito.play())
		if oleadas.has_signal("victoria"):
			oleadas.victoria.connect(pitazo_final)
		# La oleada 1 empieza antes de que este nodo alcance a conectarse:
		# si acaba de empezar, el primer pito se toca aquí.
		if oleadas.get("fase") == 0 and oleadas.get("tiempo") != null and oleadas.get("tiempo") < 0.5:
			$Pito.play()
	arbitro = get_tree().get_first_node_in_group("arbitro")
	if arbitro and arbitro.has_signal("energia_cambio"):
		energia_antes = arbitro.get("energia") if arbitro.get("energia") != null else -1
		arbitro.energia_cambio.connect(_al_cambiar_energia)
	puntaje = get_tree().get_first_node_in_group("puntaje")
	if puntaje and puntaje.get("puntos") != null:
		puntos_antes = puntaje.get("puntos")
	print("sonidos: oleadas ", oleadas != null, " · árbitro ", arbitro != null, " · puntaje ", puntaje != null)


func _al_cambiar_energia(valor):
	if energia_antes >= 0 and valor < energia_antes:
		$Golpe.play()   # solo cuando baja; cuando el agua cura, no suena
	energia_antes = valor


func _process(_delta):
	if puntaje == null or not is_instance_valid(puntaje):
		return
	var puntos = puntaje.get("puntos")
	if puntos != null and puntos > puntos_antes:
		$Puntos.play()
	if puntos != null:
		puntos_antes = puntos


func pitazo_final():
	for i in 3:
		$Pito.play()
		await get_tree().create_timer(0.6, true).timeout   # true: corre aunque el juego esté en pausa
