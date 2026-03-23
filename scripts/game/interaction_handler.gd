extends RayCast3D
@export var character:Character
var current_interactable:Interactable

func _process(_delta: float) -> void:
	if is_colliding():
		if get_collider() is Interactable:
			if current_interactable != get_collider():
				if current_interactable: current_interactable.on_cant_interact()
				current_interactable = get_collider()
				current_interactable.on_can_interact()
	elif current_interactable:
		current_interactable.on_cant_interact()
		current_interactable = null

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"interact"):
		if current_interactable:
			current_interactable.interact(character)
