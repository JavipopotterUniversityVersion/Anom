extends Node3D
class_name HouseManager

@export var elevator:RoomButton
@export var anomalies:Array[Script]
@export var available_anomalies:Array[Script]
@export var furniture:Array[Furniture]
@export var doll:DollAnomalyObject
@export var wooden_floor:AnomalyObject

var current_anomaly

func _ready() -> void:
	reset()

func reset():
	available_anomalies = anomalies.duplicate()

func check_anomaly(mark:Decal) -> bool:
	if not current_anomaly: return false
	var is_correct:bool = current_anomaly.check_mark(mark)
	return is_correct

func anomalize():
	if current_anomaly: current_anomaly.exit_anomaly(self)
	var anomaly_index:int = randi_range(0, available_anomalies.size()-1)
	var selected_anomaly:Script = available_anomalies.pop_at(anomaly_index)
	
	if selected_anomaly != null:
		selected_anomaly.enter_anomaly(self)
		
	current_anomaly = selected_anomaly
	if available_anomalies.is_empty(): 
		reset()

func execute_anomaly(anomaly_name:StringName):
	for anomaly:Script in anomalies:
		if anomaly.resource_name == anomaly_name:
			anomaly.enter_anomaly(self)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("anomalize"):
		anomalize()
		print("debug anomaly")
