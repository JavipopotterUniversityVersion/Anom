extends Node3D
class_name HouseManager

@export var anomalies:Array[Script]
@export var furniture:Array[Node3D]

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

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("anomalize"):
		anomalize()
		print("debug anomaly")
