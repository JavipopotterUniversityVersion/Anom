@tool
extends AnomalyObject
class_name DollAnomalyObject

@export var skeleton: Skeleton3D
@export var bone_idx: int = 0
var active: bool
var current_player: Node3D

func _process(delta: float) -> void:
	super(delta)
	if Engine.is_editor_hint() or not active: return
	if current_player == null:
		current_player = get_tree().get_first_node_in_group(&"PLAYER")
		return

	var to_player := skeleton.to_local(current_player.global_position)
	to_player.y = 0.0
	to_player = to_player.normalized()
	var rot := Quaternion(Vector3.FORWARD, to_player)
	skeleton.set_bone_pose_rotation(bone_idx, rot)
