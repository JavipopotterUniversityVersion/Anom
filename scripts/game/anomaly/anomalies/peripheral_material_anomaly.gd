extends Anomaly
class_name PeripheralMaterialAnomaly

static func enter_anomaly(house: HouseManager, payload: Dictionary = {}):
	anomaly = house.peripheral_material_object
	(anomaly as PeripheralMaterialAnomalyObject).set_active(true)
	super(house, payload)

static func exit_anomaly(_house: HouseManager):
	(anomaly as PeripheralMaterialAnomalyObject).set_active(false)
	anomaly = null
