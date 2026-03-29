extends Anomaly
class_name AnomalyFurniture

static func enter_anomaly(house:HouseManager, payload: Dictionary = {}):
	if house.anomaly_furniture.is_empty():
		anomaly = null
		return

	var anomaly_furniture_index: int = int(payload.get("anomaly_furniture_index", -1))
	if anomaly_furniture_index >= 0 and anomaly_furniture_index < house.anomaly_furniture.size():
		anomaly = house.anomaly_furniture[anomaly_furniture_index]
	else:
		anomaly = house.anomaly_furniture.pick_random()

	anomaly.enable_colliders()
	anomaly.show()
	super(house, payload)

static func exit_anomaly(_house:HouseManager):
	if anomaly: 
		anomaly.hide()
		anomaly.disable_colliders()
		anomaly = null
	else: printerr("Que cojones? aquí ha pasado algo raro en dissapeared_anomaly_furniture.gd")
