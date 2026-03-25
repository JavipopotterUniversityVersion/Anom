class_name Anomaly
static var anomaly:AnomalyObject

static func enter_anomaly(_house:HouseManager):
	pass

static func exit_anomaly(_house:HouseManager):
	pass

static func check_mark(mark: Decal) -> bool:
	var mark_aabb := mark.get_aabb()
	var anomaly_aabb = anomaly.aabbs
	
	print(mark_aabb)
	return mark_aabb.intersects(anomaly_aabb)
