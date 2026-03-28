extends Anomaly
class_name DissapearedFurnitureAnomaly

static func enter_anomaly(house:HouseManager, payload: Dictionary = {}):
	if house.furniture.is_empty():
		anomaly = null
		return

	var furniture_index: int = int(payload.get("furniture_index", -1))
	if furniture_index >= 0 and furniture_index < house.furniture.size():
		anomaly = house.furniture[furniture_index]
	else:
		anomaly = house.furniture.pick_random()

	anomaly.disable_colliders()
	anomaly.hide()
	super(house, payload)

static func exit_anomaly(_house:HouseManager):
	if anomaly: 
		anomaly.show()
		anomaly.enable_colliders()
		anomaly = null
	else: printerr("Que cojones? aquí ha pasado algo raro en dissapeared_furniture.gd")
