extends Node3D
class_name HouseManager

@export var elevator:RoomButton
@export var anomalies:Array[Script]
@export var available_anomalies:Array[Script]
@export var furniture:Array[Furniture]
@export var doll:DollAnomalyObject
@export var wooden_floor:AnomalyObject

@export var house:Node3D
@export var final:PackedScene

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
	if not multiplayer.is_server():
		return

	if available_anomalies.is_empty():
		reset()

	var anomaly_index:int = randi_range(0, available_anomalies.size() - 1)
	var selected_anomaly:Script = available_anomalies.pop_at(anomaly_index)
	if selected_anomaly == null:
		return

	var payload := _build_anomaly_payload(selected_anomaly)
	_apply_anomaly_sync.rpc(selected_anomaly.resource_name, payload)

	if available_anomalies.is_empty():
		reset()

@rpc("authority", "reliable")
func _request_anomalize() -> void:
	if not multiplayer.is_server():
		return
	anomalize()

@rpc("authority", "call_local", "reliable")
func _apply_anomaly_sync(anomaly_name: StringName, payload: Dictionary = {}) -> void:
	var selected_anomaly := _get_anomaly_script_by_name(anomaly_name)
	if selected_anomaly == null:
		push_warning("Anomaly not found: " + str(anomaly_name))
		return

	if current_anomaly:
		current_anomaly.exit_anomaly(self)

	selected_anomaly.enter_anomaly(self, payload)
	current_anomaly = selected_anomaly

func _build_anomaly_payload(anomaly_script: Script) -> Dictionary:
	var payload: Dictionary = {}
	var script_ref:Script = load("res://scripts/game/anomalies/dissapeared_furniture.gd")
	if anomaly_script and anomaly_script.resource_name == script_ref.resource_name:
		if not furniture.is_empty():
			payload["furniture_index"] = randi_range(0, furniture.size() - 1)
	return payload

func _get_anomaly_script_by_name(anomaly_name: StringName) -> Script:
	for anomaly:Script in anomalies:
		if anomaly.resource_name == anomaly_name:
			return anomaly
	return null

func execute_anomaly(anomaly_name:StringName):
	_apply_anomaly_sync(anomaly_name, {})

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("anomalize"):
		if multiplayer.is_server():
			anomalize()
		else:
			_request_anomalize.rpc_id(1)
	elif event.is_action_pressed("end_game"):
		end()

func end():
	house.queue_free()
	var final_obj = final.instantiate()
	
	elevator.door = final_obj.get_node("props/main_door")
	elevator.blocked = true 
	elevator.open_door()
	
	final_obj.position = Vector3.ZERO
	add_child(final_obj)
