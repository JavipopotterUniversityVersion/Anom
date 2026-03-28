extends Node3D
class_name HouseManager

@export var elevator:RoomButton
@export var anomalies:Dictionary[StringName, Script]
@export var furniture:Array[Furniture]
@export var doll:DollAnomalyObject
@export var wooden_floor:AnomalyObject
@export var peripheral_material_object:PeripheralMaterialAnomalyObject

@export var house:Node3D
@export var final:PackedScene

var available_anomalies:Array[StringName]
var current_anomaly

func _ready() -> void:
	reset()

func reset():
	available_anomalies = anomalies.keys()

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
	var selected_anomaly:StringName = available_anomalies.pop_at(anomaly_index)
	var payload := _build_anomaly_payload(selected_anomaly)
	
	_apply_anomaly_sync.rpc(selected_anomaly, payload)

@rpc("authority", "reliable")
func _request_anomalize() -> void:
	if not multiplayer.is_server():
		return
	anomalize()

@rpc("authority", "call_local", "reliable")
func _apply_anomaly_sync(anomaly_name:StringName, payload: Dictionary = {}) -> void:
	if current_anomaly:
		current_anomaly.exit_anomaly(self)

	anomalies[anomaly_name].enter_anomaly(self, payload)
	current_anomaly = anomalies[anomaly_name]

func _build_anomaly_payload(anomaly_name: StringName) -> Dictionary:
	var payload: Dictionary = {}
	if anomaly_name == &"DISSAPEARED_FURNITURE":
		if not furniture.is_empty():
			payload["furniture_index"] = randi_range(0, furniture.size() - 1)
	return payload

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
