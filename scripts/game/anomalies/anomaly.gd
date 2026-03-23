class_name Anomaly
static var anomaly:Node3D

static func enter_anomaly(_house:HouseManager):
	pass

static func exit_anomaly(_house:HouseManager):
	pass

static func check_mark(mark: Decal) -> bool:
	var size := mark.size
	var local_pos := mark.to_local(anomaly.global_position)
	var is_correct:bool = abs(local_pos.x) <= size.x and abs(local_pos.y) <= size.y and abs(local_pos.z) <= size.z
	print("ANOMALY IS: " + str(is_correct))
	return is_correct
