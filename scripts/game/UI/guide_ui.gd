extends CanvasLayer
@onready var animation:AnimationPlayer = $animation
@onready var guide_text:Label = $guide_panel/guide_text
@export var time_between_chars:float = 0.01
var opened:bool = false

var stop:bool = false:
	get():
		if stop: 
			stop = false
			return true
		else: return false

func show_message(text:String, wait_time:float):
	stop = false
	guide_text.visible_characters = 0
	
	if not opened:
		animation.play(&"ShowGuide")
		opened = true
		
	guide_text.text = text
	
	while(guide_text.visible_characters < guide_text.text.length()):
		guide_text.visible_characters += 1
		await get_tree().create_timer(time_between_chars).timeout
		if stop: break
	
	await get_tree().create_timer(wait_time).timeout

func hide_message():
	opened = false
	animation.play(&"HideGuide")
	stop = true
