class_name Anomaly
static var anomaly:AnomalyObject

static func enter_anomaly(_house:HouseManager, _payload: Dictionary = {}):
	print("\n" + anomaly.name)
	print(str(anomaly.get_aabb()) + "\n")

static func exit_anomaly(_house:HouseManager):
	pass

static func check_mark(mark: Decal) -> bool:
	var mark_aabb := mark.get_aabb()
	var anomaly_aabb = anomaly.get_aabb()
	mark_aabb.position = mark_aabb.position + mark.global_position
	
	print(mark_aabb)
	
	var is_correct := mark_aabb.intersects(anomaly_aabb)
	mark.hide()
	return is_correct
