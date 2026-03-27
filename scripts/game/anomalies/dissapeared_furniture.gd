extends Anomaly
class_name DissapearedFurnitureAnomaly

static func enter_anomaly(house:HouseManager):
	anomaly = house.furniture.pick_random()
	anomaly.disable_colliders()
	anomaly.hide()
	super(house)

static func exit_anomaly(_house:HouseManager):
	if anomaly: 
		anomaly.show()
		anomaly.enable_colliders()
		anomaly = null
	else: printerr("Que cojones? aquí ha pasado algo raro en dissapeared_furniture.gd")
