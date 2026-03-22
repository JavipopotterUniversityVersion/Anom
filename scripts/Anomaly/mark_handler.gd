extends Node
@export var mark:Decal
@export var ray:RayCast3D

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("mark"):
		if ray.is_colliding():
			mark.global_position = ray.get_collision_point()
			mark.look_at(ray.get_collision_point() - ray.get_collision_normal())
