extends Anomaly
class_name DollAnomaly

static func enter_anomaly(house:HouseManager):
	anomaly = house.doll
	(anomaly as DollAnomalyObject).active = true
	super(house)

static func exit_anomaly(_house:HouseManager):
	(anomaly as DollAnomalyObject).active = false
