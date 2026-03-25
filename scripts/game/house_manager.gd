extends Node3D
class_name HouseManager

@export var anomalies:Array[Script]
@export var furniture:Array[Furniture]
@export var wooden_floor:AnomalyObject

var current_anomaly

func _ready() -> void:
	anomalize()

func check_anomaly(mark:Decal) -> bool:
	var is_correct:bool = current_anomaly.check_mark(mark)
	return is_correct

func anomalize():
	if current_anomaly: current_anomaly.exit_anomaly(self)
	var selected_anomaly = anomalies.pick_random()
	selected_anomaly.enter_anomaly(self)
	current_anomaly = selected_anomaly

func execute_anomaly(anomaly_name:StringName):
	for anomaly:Script in anomalies:
		if anomaly.resource_name == anomaly_name:
			anomaly.enter_anomaly(self)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("anomalize"):
		anomalize()
		print("debug anomaly")
