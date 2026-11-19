extends CharacterBody3D

enum Estado { PATRULLA, PERSEGUIR, AVISO, LANZAR, CIEGO }

@export var objetivo: Node3D
@export var rapidez = 3.2
@export var radio_ver = 5.0
@export var radio_perder = 8.0
# Los que crean las oleadas persiguen desde que nacen y no se rinden.
@export var persigue_siempre = false
@export var puntos: Array[Vector3] = [
	Vector3(5.5, 0, 0), Vector3(2.5, 0, 0)]
@export var vida = 2
@export var puntos_expulsion = 150   # los que da al salir expulsado (los suma el puntaje)
# Si choca contra una tribuna mientras persigue, salta para subirse.
@export var fuerza_salto = 5.0

@export_group("Tribuna")
# Los que crean las oleadas bajan saltando desde las gradas del fondo.
@export var entra_por_tribuna = true
# Probabilidad de bajar por las gradas (0.5 = la mitad). Los demás aparecen
# en los puntos de los lados, justo fuera de la pantalla, como al principio.
@export_range(0.0, 1.0) var prob_tribuna = 0.5
@export var tiempo_escalon = 0.18    # s por escalón al bajar o subir las gradas
@export var bajar_cerca_min = 3.5    # baja a esta distancia del árbitro, como mínimo...
@export var bajar_cerca_max = 8.0    # ...y como máximo (siempre dentro de la pantalla)

@export_group("Tacleo")
@export var radio_tacleo = 1.5       # a esta distancia se prepara para taclear
@export var tiempo_aviso = 0.5       # s agachado antes de lanzarse: el aviso
@export var rapidez_lanzar = 8.0     # m/s durante el lanzamiento
@export var tiempo_lanzar = 0.4      # s que dura el lanzamiento
@export var danio = 1

@onready var anim = $Modelo/AnimationPlayer

var estado = Estado.PATRULLA
var punto = 0
var reloj = 0.0
var lado = 1.0   # hacia dónde se lanza: 1 = derecha, -1 = izquierda

# Violeta = peligro (la paleta del juego): el tacleador se pinta de violeta
# y muestra un "!" mientras avisa y mientras se lanza.
const VIOLETA = Color(0.62, 0.2, 0.95)
var mallas = []
var tinte: StandardMaterial3D
var alerta: Label3D

# Mientras baja de la tribuna o rodea una barrera, se mueve con un Tween
# (sin física ni colisión) y no persigue.
var en_tribuna = false
var reloj_barrera = 0.0
# Escalones de las gradas: (altura de arriba, z). La fila 1 está pegada al muro.
const ESCALONES = [Vector2(2.25, -4.5), Vector2(1.5, -3.5), Vector2(0.75, -2.5)]
const SALTITO = 0.3   # cuánto sube en cada brinco de escalón


func _ready():
	add_to_group("barristas")
	preparar_aviso()
	# Si nadie le dijo a quién perseguir (lo creó una oleada), busca al árbitro.
	if objetivo == null:
		objetivo = get_tree().get_first_node_in_group("arbitro")
		persigue_siempre = true
	if persigue_siempre:
		estado = Estado.PERSEGUIR
		if entra_por_tribuna and randf() < prob_tribuna:
			# Las oleadas le ponen la posición DESPUÉS de add_child, así que
			# esperamos a que termine este frame para saber a dónde debe llegar.
			en_tribuna = true
			bajar_de_tribuna.call_deferred()


func _physics_process(delta):
	if en_tribuna:
		return
	velocity += get_gravity() * delta
	reloj = maxf(reloj - delta, 0.0)
	if objetivo == null or not is_instance_valid(objetivo):
		frenar()
		move_and_slide()
		return
		# Si el árbitro ya perdió, la barra celebra y deja de taclear.
	if objetivo.get("muerto"):
		frenar()
		anim.play("emote-yes")
		move_and_slide()
		return
	var distancia = global_position.distance_to(objetivo.global_position)
	match estado:
		Estado.PATRULLA:
			if distancia < radio_ver:
				cambiar_a(Estado.PERSEGUIR)
				print(name, " lo vio a ", snappedf(distancia, 0.01), " m")
			ir_a(puntos[punto])
			if global_position.distance_to(puntos[punto]) < 0.3:
				punto = (punto + 1) % puntos.size()
		Estado.PERSEGUIR:
			if distancia > radio_perder and not persigue_siempre:
				cambiar_a(Estado.PATRULLA)
				print(name, " lo perdió a ", snappedf(distancia, 0.01), " m")
			elif distancia < radio_tacleo:
				cambiar_a(Estado.AVISO)
			else:
				ir_a(objetivo.global_position)
				saltar_si_choca()
				revisar_barrera(delta)
		Estado.AVISO:
			# Quieto y agachado: es el tiempo que tiene el árbitro para reaccionar.
			frenar()
			anim.play("crouch")
			if reloj <= 0.001:
				cambiar_a(Estado.LANZAR)
		Estado.LANZAR:
			velocity.x = lado * rapidez_lanzar
			velocity.z = 0.0
			anim.play("sprint")
			if distancia < 1.0 and puede_golpear():
				golpear()
				return
			if reloj <= 0.001:
				print(name, " falló el tacleo")
				cambiar_a(Estado.PERSEGUIR)
		Estado.CIEGO:
			frenar()
			anim.play("emote-no")
			if reloj <= 0.001:
				cambiar_a(Estado.PERSEGUIR if persigue_siempre else Estado.PATRULLA)
	move_and_slide()


func cambiar_a(nuevo):
	estado = nuevo
	marcar_peligro(estado == Estado.AVISO or estado == Estado.LANZAR)
	match estado:
		Estado.AVISO:
			reloj = tiempo_aviso
			print(name, " se prepara para taclear")
		Estado.LANZAR:
			reloj = tiempo_lanzar
			# Se lanza hacia donde está el árbitro EN ESTE MOMENTO.
			lado = 1.0 if objetivo.global_position.x >= global_position.x else -1.0
			basis = Basis.looking_at(Vector3(lado, 0, 0))


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


# El árbitro no recibe daño si está esquivando o parpadeando:
# en ese caso el tacleador sigue de largo.
func puede_golpear():
	if objetivo.get("esquivando") or objetivo.get("invulnerable") or objetivo.get("muerto"):
		return false
	return objetivo.has_method("recibir_danio")


func golpear():
	print(name, " tacleó al árbitro")
	objetivo.recibir_danio(danio)
	remove_from_group("barristas")   # para que las oleadas no lo cuenten
	queue_free()


# La llama el aerosol del árbitro.
func cegar(segundos):
	cambiar_a(Estado.CIEGO)
	reloj = segundos
	print(name, " cegado ", segundos, " s")


func ir_a(p):
	var hacia = p - global_position
	hacia.y = 0.0
	if hacia.length() < 0.05:
		return
	var dir = hacia.normalized()
	velocity.x = dir.x * rapidez
	velocity.z = dir.z * rapidez
	basis = Basis.looking_at(dir)
	anim.play("walk")


# Revisa contra qué chocó en el último move_and_slide(). Si chocó de frente
# contra algo quieto (un StaticBody3D, como el borde de una tribuna) y está en
# el piso, salta para subirse. Si choca contra el árbitro u otro barrista
# (que no son StaticBody3D), no salta: así no brincan cuando se amontonan.
func saltar_si_choca():
	if not is_on_floor():
		return
	for i in get_slide_collision_count():
		var choque = get_slide_collision(i)
		if choque.get_collider() is StaticBody3D and absf(choque.get_normal().y) < 0.3:
			velocity.y = fuerza_salto
			anim.play("jump")
			return


func frenar():
	velocity.x = 0.0
	velocity.z = 0.0


func recibir_golpe(danio_recibido):
	vida -= danio_recibido
	print(name, ": vida ", vida)
	if vida <= 0:
		print(name, " expulsado")
		get_tree().call_group("puntaje", "sumar", puntos_expulsion, global_position)
		remove_from_group("barristas")
		queue_free()


# ---------- Tribuna ----------

# Aparece arriba en las gradas (entre el público), en una fila al azar, y
# baja brincando escalón por escalón hasta la cancha. Baja en una x que se
# vea en pantalla, cerca del árbitro, del mismo lado por donde lo mandó la
# oleada (así se mantiene que cada grupo llega por un lado).
func bajar_de_tribuna():
	var x = global_position.x
	var y_final = global_position.y
	var zona = get_tree().get_first_node_in_group("zona_juego")
	if zona and objetivo:
		var lado = 1.0 if x >= objetivo.global_position.x else -1.0
		var cerca = zona.x_cerca_del_arbitro(bajar_cerca_min, bajar_cerca_max, lado)
		if cerca != null:
			x = cerca
			y_final = zona.altura_piso(x)
	# Fila de salida al azar: la fila k está a 0.75·k de alto y en z = -1.5 - k.
	var fila = randi_range(3, 5)
	sin_colision(true)
	var desde = Vector3(x, 0.75 * fila, -1.5 - fila)
	global_position = desde
	basis = Basis.looking_at(Vector3(0, 0, 1))   # mirando hacia la cancha
	anim.play("jump")
	var t = create_tween()
	t.tween_interval(randf_range(0.0, 0.6))   # cada uno arranca a su ritmo, no todos a la vez
	for k in range(fila - 1, 0, -1):
		var escalon = Vector3(x, 0.75 * k, -1.5 - k)
		brincar(t, desde, escalon)
		desde = escalon
	# Último salto: por encima del muro hasta la cancha.
	brincar(t, desde, Vector3(x, 1.4, -1.2))
	t.tween_property(self, "global_position", Vector3(x, y_final, 0.0), tiempo_escalon)
	t.tween_callback(salir_de_tribuna)


# Un brinco de un punto a otro: sube un poquito a mitad de camino y cae.
func brincar(t, a, b):
	var mitad = (a + b) / 2.0 + Vector3(0, SALTITO, 0)
	t.tween_property(self, "global_position", mitad, tiempo_escalon / 2.0)
	t.tween_property(self, "global_position", b, tiempo_escalon / 2.0)


# Si una barrera cerrada queda entre él y el árbitro, la rodea por las gradas:
# sube los escalones, camina por detrás de la valla y baja del otro lado.
func revisar_barrera(delta):
	reloj_barrera -= delta
	if reloj_barrera > 0.0:
		return
	reloj_barrera = 0.5   # no hace falta revisar en cada frame
	var b = barrera_en_medio()
	if b:
		rodear(b)


func barrera_en_medio():
	var yo = global_position.x
	var el = objetivo.global_position.x
	for b in get_tree().get_nodes_in_group("barreras"):
		if b.get("abierta"):
			continue
		var bx = b.global_position.x
		if (bx - yo) * (bx - el) < 0.0:   # signos distintos = la barrera está en medio
			return b
	return null


func rodear(barrera):
	print(name, " rodea la barrera por la tribuna")
	en_tribuna = true
	marcar_peligro(false)
	sin_colision(true)
	var x = global_position.x
	var lado_destino = 1.0 if objetivo.global_position.x > barrera.global_position.x else -1.0
	var x_final = barrera.global_position.x + lado_destino * 1.8
	var arriba = ESCALONES[1]   # camina por la fila 2
	var t = create_tween()
	# Subir: muro y luego escalones.
	t.tween_callback(anim.play.bind("jump"))
	t.tween_property(self, "global_position", Vector3(x, 1.4, -1.2), tiempo_escalon)
	t.tween_property(self, "global_position", Vector3(x, ESCALONES[2].x, ESCALONES[2].y), tiempo_escalon)
	t.tween_property(self, "global_position", Vector3(x, arriba.x, arriba.y), tiempo_escalon)
	# Caminar por detrás de la barrera.
	t.tween_callback(caminar_hacia.bind(lado_destino))
	t.tween_property(self, "global_position", Vector3(x_final, arriba.x, arriba.y),
		absf(x_final - x) / rapidez)
	# Bajar del otro lado. Queda un poco en el aire y la gravedad lo pone en
	# el piso o en la tribuna que haya ahí.
	t.tween_property(self, "global_position", Vector3(x_final, ESCALONES[2].x, ESCALONES[2].y), tiempo_escalon)
	t.tween_callback(anim.play.bind("jump"))
	t.tween_property(self, "global_position", Vector3(x_final, 1.6, -1.2), tiempo_escalon)
	t.tween_property(self, "global_position", Vector3(x_final, 1.6, 0.0), tiempo_escalon)
	t.tween_callback(salir_de_tribuna)


func caminar_hacia(lado_x):
	anim.play("walk")
	basis = Basis.looking_at(Vector3(lado_x, 0, 0))


func salir_de_tribuna():
	global_position.z = 0.0
	velocity = Vector3.ZERO
	sin_colision(false)
	en_tribuna = false
	reloj_barrera = 0.5


func sin_colision(si):
	$CollisionShape3D.set_deferred("disabled", si)
