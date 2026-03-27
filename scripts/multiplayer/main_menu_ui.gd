extends Control
class_name MainMenuUI

signal host_pressed(nickname: String, skin: String)
signal join_pressed(nickname: String, skin: String, address: String)
signal quit_pressed

@onready var skin_input: LineEdit = $MainContainer/MainMenu/Option2/SkinInput
@onready var nick_input: LineEdit = $MainContainer/MainMenu/Option1/NickInput
@onready var address_input: LineEdit = $MainContainer/MainMenu/Option3/AddressInput

@export var tutorial_manager:TutorialManager

func _on_host_pressed():
	var nickname = nick_input.text.strip_edges()
	
	Network.player_info.get_or_add("character", get_character())
	Network.player_info["character"] = get_character()
	
	host_pressed.emit(nickname)
	tutorial_manager.trigger()

func _on_join_pressed():
	var nickname = nick_input.text.strip_edges()
	var address = address_input.text.strip_edges()
	
	Network.player_info.get_or_add("character", get_character())
	Network.player_info["character"] = get_character()
	
	join_pressed.emit(nickname, address)
	tutorial_manager.trigger()

func _on_quit_pressed():
	quit_pressed.emit()

func show_menu():
	show()

func hide_menu():
	hide()

func is_menu_visible() -> bool:
	return visible

func get_nickname() -> String:
	return nick_input.text.strip_edges()

func get_character() -> String:
	var character:String = skin_input.text.strip_edges().to_lower()
	if not GlobalData.CHARACTERS.has(character): character = "Umi"
	return character

func get_address() -> String:
	return address_input.text.strip_edges()
