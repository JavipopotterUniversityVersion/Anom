@tool
extends AnomalyObject
class_name PeripheralMaterialAnomalyObject

@export var target_mesh: MeshInstance3D
@export var screen_notifier: VisibleOnScreenNotifier3D
@export var look_material: Material
@export var peripheral_material: Material
@export var active: bool = false

func _ready() -> void:
	if screen_notifier:
		screen_notifier.screen_entered.connect(_on_screen_entered)
		screen_notifier.screen_exited.connect(_on_screen_exited)

func set_active(value: bool) -> void:
	active = value

func _on_screen_entered() -> void:
	if not active: return
	target_mesh.material_override = look_material

func _on_screen_exited() -> void:
	if not active: return
	target_mesh.material_override = peripheral_material
