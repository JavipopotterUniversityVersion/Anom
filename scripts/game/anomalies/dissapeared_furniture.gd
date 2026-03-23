extends Anomaly

static func enter_anomaly(house:HouseManager):
	anomaly = house.furniture.pick_random()
	anomaly.hide()

static func exit_anomaly(_house:HouseManager):
	if anomaly: 
		anomaly.show()
		anomaly = null
	else: printerr("Que cojones? aquí ha pasado algo raro en dissapeared_furniture.gd")
