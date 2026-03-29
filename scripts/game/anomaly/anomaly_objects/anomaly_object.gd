@tool
extends Node3D
class_name AnomalyObject

@export var shapes: Array[CollisionShape3D]
@export var debug: bool = true

func get_aabb() -> AABB:
	var aabb := AABB()
	var first := true
	for shape in shapes:
		if shape == null or shape.shape == null:
			continue
		var local_aabb: AABB = shape.shape.get_debug_mesh().get_aabb()
		var world_aabb: AABB = shape.global_transform * local_aabb
		if first:
			aabb = world_aabb
			first = false
		else:
			aabb = aabb.merge(world_aabb)
	return aabb

func _process(_delta: float) -> void:
	if not debug or not Engine.is_editor_hint(): return
	DebugDraw3D.draw_aabb(get_aabb(), Color.ROSY_BROWN)
