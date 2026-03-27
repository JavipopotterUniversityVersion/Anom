extends Node
class_name TutorialManager

@export var house:HouseManager
@onready var elevator_button:RoomButton = house.elevator
@export var tutorial_end_area:Area3D

func trigger() -> void:
	tutorial_end_area.body_entered.connect(finish_tutorial, CONNECT_ONE_SHOT)
	elevator_button.blocked = true
	start_tutorial()

func start_tutorial():
	await GuideUI.show_message("Hola buenas tardes.", 0.5)
	GuideUI.hide_message()
	
	elevator_button.open_door()
	elevator_button.reset_doors()
	
	await get_tree().create_timer(1).timeout
	await GuideUI.show_message("Observa bien el apartamento y quédate con todos los detalles", 1)

func finish_tutorial(_character):
	elevator_button.blocked = false
	await GuideUI.show_message("Vuelve al ascensor y pulsa el botón para ir al siguiente piso", 1)
	elevator_button.on_interact.connect(func(): GuideUI.hide_message(), CONNECT_ONE_SHOT)
