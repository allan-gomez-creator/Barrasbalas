extends Node3D
# El público de las gradas: solo decorado. Cada hincha repite una animación
# que no es de ataque, empezando en un momento distinto para que no se muevan igual.

@export var animaciones: Array[String] = ["idle", "emote-yes", "idle", "sit"]


func _ready():
	var i = 0
	for anim in find_children("AnimationPlayer", "AnimationPlayer", true, false):
		var nombre = animaciones[i % animaciones.size()]
		if anim.has_animation(nombre):
			anim.get_animation(nombre).loop_mode = Animation.LOOP_LINEAR
			anim.play(nombre)
			anim.seek(randf() * anim.current_animation_length)
		i += 1
