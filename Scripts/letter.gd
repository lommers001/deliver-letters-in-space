extends Area2D

var state = 0
var player
var enemy
var is_wildcard = false

const FALLING_SPEED = 6
const SHOOTING_SPEED = 25

func _ready():
	pass

func _process(delta):
	if state == 0:
		position.y += FALLING_SPEED
		if has_overlapping_areas():
			player = get_overlapping_areas()[0]
			if not "attached_letter" in player:
				return
			add_to_player()
			$sfx_select.play()
			return
	
	if state == 1:
		position = player.position + Vector2(0, 10)
		
		if Input.is_action_just_pressed("transmutate"):
			if $Label.text == '?':
				$sfx_wildcard_not_set.play()
				return
			var controller = get_tree().root.get_node("Base")
			if controller == null:
				controller = get_tree().root.get_node("Tutorial")
			if !controller.can_shoot:
				return
			$sfx_fire.play()
			controller.can_shoot = false
			player.attached_letter = null
			state = 2
			if controller.is_tutorial:
				if controller.tutorial_step == 5:
					controller.set_tutorial_step(6)
				if controller.tutorial_step == 6 and is_wildcard:
					controller.set_tutorial_step(7)
			$Label.remove_theme_color_override("font_color")
			set_collision_layer_value(1, true)
			set_collision_mask_value(1, true)
			set_collision_layer_value(2, false)
			set_collision_mask_value(2, false)
			return
		if position.y > 1000:
			queue_free()
	
	if state == 2:
		position.y -= SHOOTING_SPEED
		if has_overlapping_areas():
			enemy = player.last_col
			if enemy == null:
				enemy = get_overlapping_areas()[0]
			enemy.set_text_value($Label.text)
			queue_free()
		if position.y < 0:
			queue_free()
		monitoring = true

func _input(event):
	if event is InputEventKey:
		if event.pressed and state == 1 and is_wildcard:
			var keycode_string = OS.get_keycode_string(event.key_label)
			if keycode_string.length() > 1 or keycode_string not in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
				return
			$Label.text = OS.get_keycode_string(event.key_label).to_lower()
			$sfx_select.play()

func add_to_player():
	if player.attached_letter != null:
		player.attached_letter.queue_free()
	player.attached_letter = self
	state = 1
	$Label.add_theme_color_override("font_color", Color.BLACK)
	monitoring = false
