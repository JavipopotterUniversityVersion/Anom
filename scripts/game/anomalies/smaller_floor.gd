extends Anomaly
class_name SmallerFloor

static func enter_anomaly(house:HouseManager):
	anomaly = house.wooden_floor
	
	print("\n" + anomaly.name)
	print(str(anomaly.aabbs) + "\n")
	
	(house.wooden_floor.material as StandardMaterial3D).uv1_scale = Vector3.ONE * 0.2

static func exit_anomaly(house:HouseManager):
	anomaly = null
	(house.wooden_floor.material as StandardMaterial3D).uv1_scale = Vector3.ONE * 0.1
