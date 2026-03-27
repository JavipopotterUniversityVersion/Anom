@tool
extends AnomalyObject
class_name Furniture

@export var colliders:Array[CollisionShape3D]

func enable_colliders():
	for collider:CollisionShape3D in colliders:
		collider.disabled = false

func disable_colliders():
	for collider:CollisionShape3D in colliders:
		collider.disabled = true
