extends Node3D
class_name AnomalyObject

var aabbs:AABB

func _ready() -> void:
	aabbs = get_aabbs()

func get_aabbs() -> AABB:
	var aabb:AABB
	if has_method("get_aabb"): aabb = call("get_aabb")
	for child in get_children(true):
		if child.has_method("get_aabb"):
			var child_aabb = child.get_aabb()
			aabb.merge(child_aabb)
	aabb.position = aabb.position + global_position
	return aabb

func _process(_delta: float) -> void:
	var aabb := get_aabbs()
	DebugDraw3D.draw_aabb(aabb, Color.ROSY_BROWN)
