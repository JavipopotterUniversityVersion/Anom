extends Anomaly

static func enter_anomaly(house:HouseManager):
	anomaly = house.furniture.pick_random()
	
	print("\n" + anomaly.name)
	print(str(anomaly.aabbs) + "\n")
	
	anomaly.disable_colliders()
	anomaly.hide()

static func exit_anomaly(_house:HouseManager):
	if anomaly: 
		anomaly.show()
		anomaly.enable_colliders()
		anomaly = null
	else: printerr("Que cojones? aquí ha pasado algo raro en dissapeared_furniture.gd")
