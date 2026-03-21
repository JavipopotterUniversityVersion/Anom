class_name Anomaly

static func enter_anomaly(house:HouseManager):
	house.main_door.hide()

static func exit_anomaly(house:HouseManager):
	house.main_door.show()
