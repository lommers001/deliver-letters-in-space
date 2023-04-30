extends Node

var player_name = ""
var highest_score = 0

func _ready():
	SilentWolf.configure({
		"api_key": "API_KEY_HERE",
		"game_id": "GAME_ID_HERE",
		"log_level": 0
	})
	SilentWolf.configure_scores({
		"open_scene_on_close": "res://Scenes/menu.tscn"
	})
