@tool
extends Node3D
class_name MeshFrames

signal on_frame_changed

@export var frame:int:
	set(new_frame):
		frame = new_frame
		on_frame_changed.emit(new_frame)
	get():
		return frame

func _ready() -> void:
	frame = -1
	frame_changed(-1)
	on_frame_changed.connect(frame_changed)

func _exit_tree() -> void:
	on_frame_changed.disconnect(frame_changed)

func frame_changed(new_frame:int):
	for child:Node3D in get_children():
		child.visible = child.get_index() == new_frame
