extends Node
@export var own_node:Node3D

func _ready() -> void:
	if is_multiplayer_authority():
		own_node.hide()
