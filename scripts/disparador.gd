extends Area3D
 
signal evento(posicion: Vector3)
 
@export var que_representa := "golpe"
@export var tecla := KEY_H
 
func _ready() -> void:
	add_to_group("disparadores")
	body_entered.connect(_on_body_entered)
 
func _on_body_entered(_body: Node3D) -> void:
	evento.emit(global_position)
 
func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == tecla:
		evento.emit(global_position)
