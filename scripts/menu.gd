extends Node
# Corrección 2 - Martín: menú de inicio de BarrasBalas.
# Atrás se ve el estadio de noche: el árbitro, un tacleador y un lanzador
# en la cancha, y unos hinchas en la tribuna (modelos de Kenney, ver CREDITOS.txt).
# Botones: Jugar, Cómo jugar, Créditos y Salir (Salir no sale en la versión Web).
# Para que el juego arranque aquí, Allan pone escenas/menu.tscn como escena
# principal (Proyecto > Configuración > Run > Main Scene).

const JUEGO = "res://main.tscn"
const PERSONAJE = preload("res://personaje/character-male-a.glb")
const HINCHAS = ["res://personaje/character-male-a.glb", "res://personaje/character-female-b.glb", "res://personaje/character-male-a.glb", "res://personaje/character-female-e.glb",
	"res://personaje/character-male-a.glb", "res://personaje/character-male-d.glb"]
const TRIBUNA = "res://assets/estadio/racing-kit/grandStand.glb"
const ARCHIVO_RECORD = "user://record.cfg"   # el mismo que usa puntaje.gd de Juan Manuel

@onready var botones = $Interfaz/Pantalla/Botones


func _ready():
	get_tree().paused = false
	armar_estadio()
	poner_personaje("res://assets/personajes/colormap_arbitro.png", Vector3(2.6, 0, 0.6), -20.0, "idle")
	poner_personaje("res://assets/personajes/colormap_tacleador.png", Vector3(5.0, 0, 0.0), -55.0, "emote-yes")
	poner_personaje("res://assets/personajes/colormap_lanzador.png", Vector3(7.2, 0, -0.6), -65.0, "holding-right")

	botones.get_node("Jugar").pressed.connect(jugar)
	botones.get_node("ComoJugar").pressed.connect(abrir.bind($Interfaz/Pantalla/PanelComoJugar))
	botones.get_node("Creditos").pressed.connect(abrir.bind($Interfaz/Pantalla/PanelCreditos))
	botones.get_node("Salir").pressed.connect(get_tree().quit)
	botones.get_node("Salir").visible = not OS.has_feature("web")   # en el navegador no se puede cerrar
	$Interfaz/Pantalla/PanelComoJugar/Caja/Volver.pressed.connect(cerrar_paneles)
	$Interfaz/Pantalla/PanelCreditos/Caja/Volver.pressed.connect(cerrar_paneles)
	mostrar_record()
	botones.get_node("Jugar").grab_focus()   # así Enter también sirve para jugar


func jugar():
	get_tree().change_scene_to_file(JUEGO)


func abrir(panel):
	cerrar_paneles()
	panel.visible = true
	botones.visible = false
	panel.get_node("Caja/Volver").grab_focus()


func cerrar_paneles():
	$Interfaz/Pantalla/PanelComoJugar.visible = false
	$Interfaz/Pantalla/PanelCreditos.visible = false
	botones.visible = true
	botones.get_node("Jugar").grab_focus()


func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):   # Esc cierra el panel abierto
		cerrar_paneles()


# Lee el récord que guarda el puntaje. Si todavía no hay, no muestra nada.
func mostrar_record():
	var cfg = ConfigFile.new()
	var etiqueta = $Interfaz/Pantalla/Record
	etiqueta.visible = false
	if cfg.load(ARCHIVO_RECORD) == OK:
		var puntos = cfg.get_value("record", "puntos", 0)
		if puntos > 0:
			etiqueta.text = "Récord: %d puntos" % puntos
			etiqueta.visible = true


# ---------- El estadio de fondo ----------

# Un personaje de Kenney con la camiseta de su textura, repitiendo una animación.
func poner_personaje(textura, posicion, giro, animacion, modelo = PERSONAJE):
	var p = modelo.instantiate()
	p.scale = Vector3.ONE * 2.6           # la misma escala que en el juego
	p.position = posicion
	p.rotation_degrees.y = giro
	$Mundo.add_child(p)
	if textura != "" and ResourceLoader.exists(textura):
		var cuerpo = p.find_child("body-mesh", true, false)
		if cuerpo:
			var ropa = StandardMaterial3D.new()
			ropa.albedo_texture = load(textura)
			ropa.roughness = 1.0
			ropa.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
			cuerpo.set_surface_override_material(0, ropa)
	var anim = p.find_child("AnimationPlayer", true, false)
	if anim and anim.has_animation(animacion):
		anim.get_animation(animacion).loop_mode = Animation.LOOP_LINEAR
		anim.play(animacion)
		anim.seek(randf() * anim.current_animation_length)   # cada uno empieza en otro momento
	return p


func armar_estadio():
	# Cuatro tribunas del Racing Kit detrás de la cancha (5 m de ancho cada una, como en gradas.gd).
	if ResourceLoader.exists(TRIBUNA):
		var modelo = load(TRIBUNA)
		var concreto = StandardMaterial3D.new()
		concreto.albedo_color = Color(0.55, 0.56, 0.6)
		for i in 4:
			var t = modelo.instantiate()
			t.scale = Vector3.ONE * 5.0
			t.position = Vector3(-6.25 + i * 5.0, 0, -0.75)
			$Mundo.add_child(t)
			# Como en gradas.gd de Allan: lo blanco pasa a concreto y las sillas al color de cada barra.
			var sillas = StandardMaterial3D.new()
			sillas.albedo_color = Color(0.78, 0.16, 0.16) if i % 2 == 0 else Color(0.16, 0.52, 0.26)
			for malla in t.find_children("*", "MeshInstance3D", true, false):
				for s in malla.mesh.get_surface_count():
					var mat = malla.mesh.surface_get_material(s)
					var nombre = mat.resource_name if mat else ""
					if nombre == "red":
						malla.set_surface_override_material(s, sillas)
					elif nombre == "grey" or nombre == "_defaultMat":
						malla.set_surface_override_material(s, concreto)
	# Hinchas sentados en la tribuna, con camisetas de las dos barras.
	var camisetas = ["res://assets/personajes/colormap_tacleador.png", "res://assets/personajes/colormap_lanzador.png", ""]
	for i in 14:
		var fila = i % 3
		var x = -7.0 + i * 1.4 + randf_range(-0.3, 0.3)
		# Las sillas van de (z -4.5, y 1.2) en la primera fila a (z -8.4, y 3.1) en la última.
		var z = -4.5 - fila * 1.95
		var y = 1.2 + fila * 0.95
		var modelo_hincha = load(HINCHAS[i % HINCHAS.size()])
		# La camiseta solo le sirve al modelo de camiseta y jean (character-male-a).
		var camiseta = camisetas[i % 3] if HINCHAS[i % HINCHAS.size()].ends_with("male-a.glb") else ""
		var hincha = poner_personaje(camiseta, Vector3(x, y, z), randf_range(-15, 15),
			["emote-yes", "idle", "emote-yes"][i % 3], modelo_hincha)
		hincha.scale = Vector3.ONE * 2.2
