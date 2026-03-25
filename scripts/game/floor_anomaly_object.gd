@tool
extends AnomalyObject
class_name FloorAnomalyObject

func get_aabbs() -> AABB:
	var aabb:AABB
	aabb.size = get("size")/2
	aabb.position = global_position - get("size")/2
	return aabb
