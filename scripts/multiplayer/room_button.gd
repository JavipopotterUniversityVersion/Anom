extends Interactable
@export var room: Area3D
@export var door: Node3D
@export var doors:Array[Node3D]
@export var close_animation: StringName = "close"
@export var open_animation: StringName = "open"
@export var reopen_delay: float = 1.0
@onready var _interact_icon: Label3D = $InteractIcon
@onready var players_container: Node3D = get_tree().get_first_node_in_group(&"PLAYERS_CONTAINER")
@export var house_manager:HouseManager

var _players_in_room: Dictionary = {}
var _door_busy: bool = false
var _local_player_cache: Character = null

func _ready() -> void:
	if room:
		room.body_entered.connect(_on_body_entered_room)
		room.body_exited.connect(_on_body_exited_room)
	_interact_icon.hide()

func _on_body_entered_room(body: Node3D) -> void:
	if body is Character:
		_players_in_room[body] = true

func _on_body_exited_room(body: Node3D) -> void:
	_players_in_room.erase(body)

func _all_players_in_room() -> bool:
	if not players_container:
		return false
	var total := 0
	for child in players_container.get_children():
		if child is Character:
			total += 1
			if not _players_in_room.has(child):
				return false
	return total > 0

func _get_local_player() -> Character:
	if _local_player_cache and is_instance_valid(_local_player_cache):
		return _local_player_cache
	if not players_container:
		return null
	var local_id := multiplayer.get_unique_id()
	var node := players_container.get_node_or_null(str(local_id))
	if node is Character:
		_local_player_cache = node as Character
		return _local_player_cache
	return null

func interact(character:Character):
	if blocked: return
	var is_correct:bool = house_manager.check_anomaly(character.mark)
	
	if is_correct: print("NEXT FLOOR!")
	else:  print("WRONG ONE")
	
	_request_activate()

func on_cant_interact():
	_interact_icon.hide()

func on_can_interact():
	if blocked: return
	_interact_icon.show()

@rpc("any_peer", "reliable")
func _request_activate() -> void:
	if not multiplayer.is_server():
		return
	if _door_busy:
		return
	if not _all_players_in_room():
		return
	_door_busy = true
	_activate_door.rpc()

@rpc("call_local", "reliable")
func _activate_door() -> void:
	var animation_player:AnimationPlayer
	
	for o_door in doors:
		animation_player = o_door.get_node("AnimationPlayer")
		animation_player.play(close_animation)
		o_door.get_node("trigger_area").reset()
		
	animation_player = door.get_node("AnimationPlayer")
	animation_player.play(close_animation)
	
	await get_tree().create_timer(reopen_delay).timeout
	house_manager.anomalize()
	if not is_inside_tree():
		return
	animation_player.play(open_animation)
	if multiplayer.is_server():
		_door_busy = false
