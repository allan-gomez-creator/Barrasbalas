extends CharacterBody3D
# Mejora 3 - Martín: el barrista lanzador.
# No camina: se queda en su puesto (una tribuna) y mira hacia el árbitro.
# Su ciclo dura 2 s: 1.5 s quieto y 0.5 s de aviso (violeta con "!"),
# y al terminar el aviso lanza una botella hacia donde está el árbitro.
# Vida 3 (sale con 3 tarjetas), da 100 puntos y el aerosol lo deja sin lanzar.

enum Estado { ESPERA, AVISO, CIEGO }

@export var objetivo: Node3D          # vacío = busca al árbitro por el grupo "arbitro"
@export var vida = 3
@export var puntos = 100              # los que suma al salir expulsado
@export var escena_botella: PackedScene

@export_group("Lanzamiento")
@export var cada_cuanto = 2.0         # s entre una botella y la siguiente (aviso incluido)
@export var tiempo_aviso = 0.5        # s en violeta antes de lanzar
@export var tiempo_vuelo = 1.2        # s que tarda la botella en llegar (oleada 1, según el concepto)
@export var alcance = 14.0            # solo lanza si el árbitro está a menos de esto (m)
@export var altura_mano = 1.6         # de qué altura sale la botella
@export var altura_blanco = 0.9       # a qué altura del árbitro apunta (el pecho)

@onready var anim = $Modelo/AnimationPlayer

var estado = Estado.ESPERA
var reloj = 0.0

# Lo mismo que marcar_peligro() del tacleador: violeta = peligro.
const VIOLETA = Color(0.62, 0.2, 0.95)
var mallas = []
var tinte: StandardMaterial3D
var alerta: Label3D


func _ready():
	add_to_group("barristas")
	add_to_group("lanzadores")
	if escena_botella == null:
		escena_botella = load("res://escenas/botella.tscn")
	if objetivo == null:
		objetivo = get_tree().get_first_node_in_group("arbitro")
	preparar_aviso()
	# Cada lanzador arranca en un momento distinto, para que no tiren todos a la vez.
	reloj = randf_range(0.3, cada_cuanto - tiempo_aviso)
	anim.play("idle")


func _physics_process(delta):
	# No camina: solo la gravedad, para quedarse parado sobre la tribuna.
	velocity.x = 0.0
	velocity.z = 0.0
	velocity += get_gravity() * delta
	move_and_slide()
	reloj = maxf(reloj - delta, 0.0)

	if objetivo == null or not is_instance_valid(objetivo):
		return
	# Si el árbitro ya perdió, celebra y no tira más.
	if objetivo.get("muerto"):
		marcar_peligro(false)
		anim.play("emote-yes")
		return

	mirar_al_arbitro()
	match estado:
		Estado.ESPERA:
			# Vuelve a "idle" cuando termina la animación de lanzar.
			if anim.current_animation != "attack-melee-right" or not anim.is_playing():
				anim.play("idle")
			if reloj <= 0.0 and distancia_al_arbitro() <= alcance:
				cambiar_a(Estado.AVISO)
		Estado.AVISO:
			anim.play("holding-right")   # el brazo arriba, listo para tirar
			if reloj <= 0.0:
				lanzar()
				cambiar_a(Estado.ESPERA)
		Estado.CIEGO:
			anim.play("emote-no")
			if reloj <= 0.0:
				cambiar_a(Estado.ESPERA)


func cambiar_a(nuevo):
	estado = nuevo
	marcar_peligro(estado == Estado.AVISO)
	match estado:
		Estado.AVISO:
			reloj = tiempo_aviso
			print(name, " va a lanzar")
		Estado.ESPERA:
			reloj = cada_cuanto - tiempo_aviso   # 1.5 s + 0.5 s de aviso = 2 s


func lanzar():
	var botella = escena_botella.instantiate()
	botella.lanzador = self
	# La botella va a la escena, no al lanzador: si lo expulsan, la botella sigue.
	var escena = get_tree().current_scene if get_tree().current_scene else get_parent()
	escena.add_child(botella)
	var desde = global_position + Vector3(0, altura_mano, 0)
	var hacia = objetivo.global_position + Vector3(0, altura_blanco, 0)   # donde está AHORA
	botella.lanzar_hacia(desde, hacia, tiempo_vuelo)
	anim.play("attack-melee-right")
	print(name, " lanzó una botella a ", snappedf(desde.distance_to(hacia), 0.1), " m")


func mirar_al_arbitro():
	var lado = 1.0 if objetivo.global_position.x >= global_position.x else -1.0
	basis = Basis.looking_at(Vector3(lado, 0, 0))


func distancia_al_arbitro():
	return global_position.distance_to(objetivo.global_position)


# La llama el aerosol del árbitro. Mientras está ciego no lanza;
# si estaba avisando, se cancela la botella.
func cegar(segundos):
	cambiar_a(Estado.CIEGO)
	reloj = segundos
	print(name, " cegado ", segundos, " s")


# La llaman las tarjetas del árbitro (apuntar.gd).
func recibir_golpe(danio_recibido):
	vida -= danio_recibido
	print(name, ": vida ", vida)
	if vida <= 0:
		print(name, " expulsado")
		remove_from_group("barristas")   # para que las oleadas ya no lo cuenten
		get_tree().call_group("puntaje", "sumar", puntos, global_position)
		queue_free()


# ---------- Aviso en violeta (copiado de la idea del tacleador) ----------

func preparar_aviso():
	tinte = StandardMaterial3D.new()
	tinte.albedo_color = Color(VIOLETA, 0.55)
	tinte.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tinte.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mallas = $Modelo.find_children("*", "MeshInstance3D", true, false)
	alerta = Label3D.new()
	alerta.text = "!"
	alerta.font_size = 96
	alerta.outline_size = 16
	alerta.modulate = VIOLETA
	alerta.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	alerta.no_depth_test = true
	alerta.position = Vector3(0, 2.3, 0)
	add_child(alerta)
	marcar_peligro(false)


func marcar_peligro(si):
	for m in mallas:
		m.material_overlay = tinte if si else null
	if alerta:
		alerta.visible = si
