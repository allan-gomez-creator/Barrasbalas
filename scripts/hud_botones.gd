extends Node
# Corrección 2 - Martín: los botones del HUD.
#   - En la pausa: Seguir, Reiniciar y Menú principal.
#   - En la derrota: Menú principal (el botón Reiniciar ya lo maneja hud.gd).
# No toca hud.gd, que es de Juan Manuel: usa los mismos nodos que él muestra y
# oculta (Pausa y Derrota), y pausa el juego igual que él lo hace con Esc.
# Los botones tienen focus_mode = None: así Espacio (saltar) no los "presiona".

const MENU = "res://escenas/menu.tscn"

@onready var hud = get_parent()


func _ready():
	hud.get_node("Pausa/Opciones/Seguir").pressed.connect(pausar)
	hud.get_node("Pausa/Opciones/Reiniciar").pressed.connect(reiniciar)
	hud.get_node("Pausa/Opciones/Menu").pressed.connect(ir_al_menu)
	hud.get_node("Derrota/Menu").pressed.connect(ir_al_menu)

func _process(_delta):
	var pausa = hud.get_node("Pausa")
	# El fondo oscuro sale junto con el letrero de pausa, sea por Esc o por el botón.
	hud.get_node("FondoPausa").visible = pausa.visible

# Lo mismo que hace hud.gd con la tecla Esc.
func pausar():
	if hud.get("perdio"):
		return
	get_tree().paused = not get_tree().paused
	hud.get_node("Pausa").visible = get_tree().paused


func reiniciar():
	get_tree().paused = false
	get_tree().reload_current_scene()


func ir_al_menu():
	get_tree().paused = false
	if ResourceLoader.exists(MENU):
		get_tree().change_scene_to_file(MENU)
	else:
		push_warning("No encuentro el menú en " + MENU)
