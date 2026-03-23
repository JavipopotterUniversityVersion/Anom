extends Node3D
## Script for a room button that closes (and later reopens) a door using an AnimationPlayer.
##
## Node structure expected:
##   RoomButton (Node3D, this script)
##   └── InteractIcon (Label3D)  ← shows the E-key prompt
##
## The button can only be pressed when ALL players are inside the sala Area3D.
## When pressed, it plays the close animation on the AnimationPlayer and, after
## reopen_delay seconds, automatically plays the open animation.
##
## How the interaction prompt works:
##   - Each frame, a ray is cast from the active camera into the scene.
##   - If the ray hits the button Area3D and the camera is within
##     interaction_distance, the InteractIcon Label3D is shown facing the camera.
##   - Pressing the "interact" action (E) while the icon is visible triggers the door.

## Area3D representing the room. ALL player bodies must be inside this area
## before the button can be activated.
@export var sala: Area3D

## Area3D used as the button's interaction hitbox.
## Must have at least one CollisionShape3D child.
@export var button: Area3D

## AnimationPlayer that controls the door.
@export var animation_player: AnimationPlayer

## Name of the animation that closes the door.
@export var close_animation: StringName = "close"

## Name of the animation that opens the door.
@export var open_animation: StringName = "open"

## Seconds to wait after the door closes before it automatically reopens.
@export var reopen_delay: float = 5.0

## Maximum camera-to-button distance (in metres) for the interaction prompt to appear.
@export var interaction_distance: float = 3.0

## Node3D container that holds all player CharacterBody3D instances.
## Assign this in the editor (usually the "PlayersContainer" node inside the Level scene).
@export var players_container: Node3D

@onready var _interact_icon: Label3D = $InteractIcon

## Dictionary<Node, bool> — O(1) membership test for sala occupants.
var _players_in_sala: Dictionary = {}

## Prevents re-triggering while the door sequence is running.
var _door_busy: bool = false

## Cached reference to the local player Character (lazily populated).
var _local_player_cache: Character = null


func _ready() -> void:
	if sala:
		sala.body_entered.connect(_on_body_entered_sala)
		sala.body_exited.connect(_on_body_exited_sala)
	_interact_icon.hide()


# ---------------------------------------------------------------------------
# Sala player tracking
# ---------------------------------------------------------------------------

func _on_body_entered_sala(body: Node3D) -> void:
	if body is Character:
		_players_in_sala[body] = true


func _on_body_exited_sala(body: Node3D) -> void:
	_players_in_sala.erase(body)


## Returns true when every Character in players_container is inside the sala.
func _all_players_in_sala() -> bool:
	if not players_container:
		return false
	var total := 0
	for child in players_container.get_children():
		if child is Character:
			total += 1
			if not _players_in_sala.has(child):
				return false
	return total > 0


# ---------------------------------------------------------------------------
# Per-frame: raycast + icon + input
# ---------------------------------------------------------------------------

## Returns the local player Character, using a cached reference after first lookup.
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


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if not camera:
		_interact_icon.hide()
		return

	# Cast a ray from the camera forward up to interaction_distance.
	var from := camera.global_position
	var to := from + (-camera.global_transform.basis.z) * interaction_distance

	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true

	# Exclude the local player's own body so it does not block the ray.
	var local_player := _get_local_player()
	if local_player:
		query.exclude = [local_player.get_rid()]

	var result := space_state.intersect_ray(query)

	var hits_button := result.has("collider") and result["collider"] == button

	if hits_button:
		_interact_icon.show()
		# Billboard mode on the Label3D already keeps it facing the camera,
		# but look_at is called explicitly to satisfy the "faces the player" requirement.
		_interact_icon.look_at(camera.global_position, Vector3.UP)

		if Input.is_action_just_pressed("interact") and not _door_busy:
			if _all_players_in_sala():
				# Send activation request to the server.
				_request_activate.rpc_id(1)
	else:
		_interact_icon.hide()


# ---------------------------------------------------------------------------
# Networked door activation
# ---------------------------------------------------------------------------

## Called on the server by a client that wants to activate the button.
@rpc("any_peer", "reliable")
func _request_activate() -> void:
	if not multiplayer.is_server():
		return
	if _door_busy:
		return
	# Re-validate on the server so that no client can bypass the room check.
	if not _all_players_in_sala():
		return
	_door_busy = true
	# Broadcast door sequence to all peers (including the server itself).
	_activate_door.rpc()


## Plays the close animation on all peers, waits, then reopens.
@rpc("call_local", "reliable")
func _activate_door() -> void:
	if not animation_player:
		return
	animation_player.play(close_animation)
	await get_tree().create_timer(reopen_delay).timeout
	if not is_inside_tree():
		return
	animation_player.play(open_animation)
	# Only the server clears the busy flag so that the next press is accepted.
	if multiplayer.is_server():
		_door_busy = false

