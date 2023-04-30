extends Control

const MAX_LENGTH = 16
var tutorial_already_completed = false

func _ready():
	tutorial_already_completed = JavaScriptBridge.eval("(localStorage.getItem('dlis_tutorial_complete'))")

func _input(event):
	if event is InputEventKey:
		if event.pressed:
			var keycode_string = OS.get_keycode_string(event.key_label)
			if keycode_string == "Backspace" && $Entry.text.length() > 0:
				$Entry.text = $Entry.text.left(-1)
				$sfx_back.play()
				return
			if (keycode_string == "Enter" or keycode_string == "Return") and $Entry.text.length() > 0:
				Variables.player_name = $Entry.text
				if(tutorial_already_completed):
					get_tree().change_scene_to_file("res://Scenes/base.tscn")
				else:
					get_tree().change_scene_to_file("res://Scenes/tutorial.tscn")
				return
			if $Entry.text.length() == MAX_LENGTH:
				$sfx_nope.play()
			elif keycode_string.length() == 1:
				$Entry.text += keycode_string if $Entry.text.length() == 0 else keycode_string.to_lower()
				$sfx_tick.play()
			elif (keycode_string == "Space" || keycode_string == "Spacebar"):
				$Entry.text += " "
