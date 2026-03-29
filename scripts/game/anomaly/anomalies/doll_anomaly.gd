extends Anomaly
class_name DollAnomaly

static func enter_anomaly(house:HouseManager, payload: Dictionary = {}):
	anomaly = house.doll
	(anomaly as DollAnomalyObject).active = true
	super(house, payload)

static func exit_anomaly(_house:HouseManager):
	(anomaly as DollAnomalyObject).active = false
