extends Node

@export var house:HouseManager
@onready var elevator_button:RoomButton = house.elevator

func _ready() -> void:
	elevator_button.blocked = true
	start_tutorial()

func start_tutorial():
	await GuideUI.show_message("Hola buenas tardes.", 0.5)
	await GuideUI.show_message("Sean bienvenidos", 0.5)
	await GuideUI.show_message("No pregunten por que, pero el mundo ha caído", 0.5)
	GuideUI.hide_message()
	
	elevator_button.open_door()

func finish_tutorial():
	elevator_button.blocked = false
