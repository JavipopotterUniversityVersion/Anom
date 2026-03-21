extends Node3D
class_name AnimationHandler

var children:Array[MeshFrames]

func _ready() -> void:
	for child:MeshFrames in get_children(): 
		children.push_back(child)
		child.on_frame_changed.connect(func(value): turn_off_others(value, child))

func turn_off_others(value:int, other:MeshFrames):
	if value == -1: return
	
	for child in children:
		if child.frame != -1 and child != other:
			child.frame = -1
