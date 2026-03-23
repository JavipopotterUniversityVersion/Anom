extends Area3D

@export var animation_name:StringName = "open"
@export var animation_player:AnimationPlayer

func _ready() -> void:
	if get_parent().get_meta(&"BLOCKED") == true: return
	body_entered.connect(func(_o): animation_player.play(animation_name), CONNECT_ONE_SHOT)
