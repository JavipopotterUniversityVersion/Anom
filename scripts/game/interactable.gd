extends Area3D
class_name Interactable
var blocked:bool

func on_can_interact():
	if blocked: return

func on_cant_interact():
	pass

func interact(_character:Character):
	if blocked: return
