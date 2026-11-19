extends Node

signal puntos_cambio(total: int, combo: int)

const ARCHIVO = "user://record.cfg"
const COMBO_MAXIMO = 3.0

@export var probar_con_p = false

var total = 0
var combo = 0
var record = 0
var record_al_empezar = 0
var record_nuevo = false
var energia_antes = -1


func _ready():
	add_to_group("puntaje")
	cargar_record()
	await get_tree().process_frame
	var arbitro = get_tree().get_first_node_in_group("arbitro")
	if arbitro:
		energia_antes = arbitro.energia
		arbitro.energia_cambio.connect(_al_cambiar_energia)
		arbitro.murio.connect(cerrar_partida)
	var oleadas = get_tree().current_scene.find_child("Oleadas", true, false)
	if oleadas and oleadas.has_signal("victoria"):
		oleadas.victoria.connect(cerrar_partida)
	puntos_cambio.emit(total, combo)


func multiplicador():
	return min(1.0 + 0.1 * combo, COMBO_MAXIMO)

func sumar(puntos, posicion):
	var mult = multiplicador()
	var ganados = int(round(puntos * mult))
	total += ganados
	combo += 1
	print("+", ganados, " (×", snappedf(mult, 0.1), ") · total ", total, " · combo ", combo)
	puntos_cambio.emit(total, combo)
	flotar(ganados, mult, posicion)

func bono_victoria(energia):
	total += 500 * energia
	print("bono de victoria: +", 500 * energia, " · total ", total)
	puntos_cambio.emit(total, combo)
	cerrar_partida()
	
func _al_cambiar_energia(valor):
	if valor < energia_antes and combo > 0:
		combo = 0
		print("combo perdido")
		puntos_cambio.emit(total, combo)
	energia_antes = valor

func cerrar_partida():
	if total > record_al_empezar:
		record = total
		record_nuevo = true
		var cfg = ConfigFile.new()
		cfg.set_value("record", "puntos", record)
		cfg.save(ARCHIVO)
		print("¡récord nuevo! ", record)

func cargar_record():
	var cfg = ConfigFile.new()
	if cfg.load(ARCHIVO) == OK:
		record = cfg.get_value("record", "puntos", 0)
	record_al_empezar = record

func flotar(ganados, mult, posicion):
	var texto = Label3D.new()
	texto.text = "+%d" % ganados if mult <= 1.0 else "+%d ×%.1f" % [ganados, mult]
	texto.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	texto.no_depth_test = true
	texto.font_size = 72
	texto.outline_size = 12
	texto.modulate = Color(1, 0.85, 0.2)
	get_tree().current_scene.add_child(texto)
	texto.global_position = posicion + Vector3(0, 1.8, 0)
	var t = texto.create_tween().set_parallel()
	t.tween_property(texto, "global_position:y", texto.global_position.y + 1.0, 1.0)
	t.tween_property(texto, "modulate:a", 0.0, 1.0)
	t.chain().tween_callback(texto.queue_free)

func _unhandled_input(event):
	if probar_con_p and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_P:
		var arbitro = get_tree().get_first_node_in_group("arbitro")
		var donde = arbitro.global_position + Vector3(2, 0, 0) if arbitro else Vector3.ZERO
		sumar(150, donde)
