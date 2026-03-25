extends Area3D

@export var animation_name:StringName = "open"
@export var animation_player:AnimationPlayer

func _ready() -> void:
	if get_parent().get_meta(&"BLOCKED") == true: return

func reset():
	if not body_entered.is_connected(on_body_entered):
		body_entered.connect(on_body_entered, CONNECT_ONE_SHOT)

func on_body_entered(_o):
	animation_player.play(animation_name)
	
