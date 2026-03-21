extends Node3D

func _ready() -> void:
	var head = get_node("head") as MeshInstance3D
	var mat = preload("res://materials/umi_head_mat.tres")
	head.mesh.surface_set_material(0, mat)
