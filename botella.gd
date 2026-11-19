extends Area3D
# Mejora 3 - Martín: la botella que tira el lanzador.
# Va en línea recta hacia donde ESTABA el árbitro cuando se la lanzaron
# (no lo persigue): si el árbitro se mueve a tiempo, la esquiva.
#  - Si toca al árbitro: le quita 1 de energía y desaparece.
#  - Si el árbitro está esquivando o parpadeando, la botella sigue de largo.
#  - Si choca contra el piso o una pared, se rompe (desaparece).
#  - Si no toca nada, desaparece a los 3 s.

@export var danio = 1
@export var vida_maxima = 3.0     # s antes de desaparecer si no tocó nada
@export var giro = 10.0           # rad/s, solo para que se vea que va dando vueltas

var velocidad = Vector3.ZERO      # m/s; la pone el lanzador con lanzar_hacia()
var tiempo = 0.0
var lanzador = null               # quién la tiró, para no pegarle a él mismo


# La llama el lanzador justo después de crearla.
# desde: dónde sale (la mano del lanzador) · hacia: dónde estaba el árbitro
# segundos: cuánto debe tardar en llegar (1.2 s en la oleada 1, según el concepto)
func lanzar_hacia(desde, hacia, segundos):
	global_position = desde
	var camino = hacia - desde
	camino.z = 0.0   # 2.5D: la botella no se sale del plano del juego
	velocidad = camino / segundos   # rapidez = distancia ÷ tiempo, así siempre tarda lo mismo
	if camino.length() > 0.01:
		look_at(global_position + camino, Vector3.UP)


func _ready():
	body_entered.connect(_al_tocar)


func _physics_process(delta):
	global_position += velocidad * delta
	rotate_object_local(Vector3.RIGHT, giro * delta)
	tiempo += delta
	if tiempo >= vida_maxima:
		queue_free()


func _al_tocar(cuerpo):
	if cuerpo == lanzador or cuerpo.is_in_group("barristas"):
		return   # no se rompe contra los barristas
	if cuerpo.is_in_group("arbitro"):
		# Esquivando o parpadeando después de un golpe: pasa de largo, como el tacleo.
		if cuerpo.get("esquivando") or cuerpo.get("invulnerable") or cuerpo.get("muerto"):
			return
		if cuerpo.has_method("recibir_danio"):
			print("la botella le dio al árbitro")
			cuerpo.recibir_danio(danio)
		queue_free()
		return
	if cuerpo is StaticBody3D:
		queue_free()   # se rompió contra el piso, una tribuna o una pared
