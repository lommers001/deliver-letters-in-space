extends Area2D

const ANIM_SPEED = 2
const PREVIEW_SPEED = 4
const MIN_PREVIEW_SCALER = 0.2
const MAX_PREVIEW_SCALER = 0.8
const SCALE_TIMER_BASE = -0.3
const SCALE_TIMER_DESTRUCTION = 1.0

var row
var column
var controller
var is_dying = false
var is_matching = false
var is_shifting_down = false
var position_to_shift_to = 0
var scale_timer = SCALE_TIMER_BASE
var preview_scale_timer = MIN_PREVIEW_SCALER
var delay = 1.0
var pitch = 1.0
var original_letter = ""
var is_previewing = false
var already_changed = false

func _ready():
	controller = get_parent().get_parent()

func _process(delta):
	if is_dying:
		if delay > 0.0:
			delay -= delta
			is_previewing = false
			$Sprite/Label.scale = Vector2.ONE
			preview_scale_timer = 0.24
			if delay <= 0.0 and is_matching:
				$Sprite/Label.add_theme_color_override("font_color", Color.LIGHT_GREEN)
				$Sprite/Label.z_index = 2
				$sfx_match.pitch_scale = pitch
				$sfx_match.play()
			elif delay <= 0.0:
				$Sprite/Label.add_theme_color_override("font_color", Color.DARK_GRAY)
				$sfx_destroy.play()
		elif is_matching:
			scale_timer += delta * ANIM_SPEED
			if scale_timer > 0.3:
				$Sprite.scale.x -= scale_timer
				$Sprite.scale.y -= scale_timer
			else:
				$Sprite/Label.scale.x -= scale_timer
				$Sprite/Label.scale.y -= scale_timer
			if scale_timer > 0.4:
				queue_free()
		else:
			if scale_timer == SCALE_TIMER_DESTRUCTION:
				$GPUParticles2D.restart()
			scale_timer -= delta * ANIM_SPEED * 1.5
			if scale_timer > 0.1:
				$Sprite.scale.x = scale_timer
				$Sprite.scale.y = scale_timer
				$Sprite.rotation = (1.0 - (scale_timer * 2))
			else:
				drop_letter($Sprite/Label.text)
				queue_free()
	if is_shifting_down:
		position.y += 1
		if position.y >= position_to_shift_to:
			position.y = position_to_shift_to
			is_shifting_down = false
	if is_previewing and preview_scale_timer < MAX_PREVIEW_SCALER:
		$Sprite/PreviewLabel.scale.x = preview_scale_timer
		$Sprite/PreviewLabel.scale.y = preview_scale_timer
		$Sprite/Label.scale.x = (1.0 + MIN_PREVIEW_SCALER) - preview_scale_timer
		$Sprite/Label.scale.y = (1.0 + MIN_PREVIEW_SCALER)  - preview_scale_timer
		preview_scale_timer += delta * PREVIEW_SPEED
	elif !is_previewing and preview_scale_timer > MIN_PREVIEW_SCALER and !is_dying:
		$Sprite/PreviewLabel.scale.x = preview_scale_timer
		$Sprite/PreviewLabel.scale.y = preview_scale_timer
		$Sprite/Label.scale.x = (1.0 + MIN_PREVIEW_SCALER)  - preview_scale_timer
		$Sprite/Label.scale.y = (1.0 + MIN_PREVIEW_SCALER)  - preview_scale_timer
		preview_scale_timer -= delta * PREVIEW_SPEED
	
	$Sprite.modulate = Color.WHITE if row == (controller.ENEMY_ROW_COUNT - 1) else Color.DARK_GRAY
	$Sprite/PreviewLabel.visible = is_previewing or preview_scale_timer > 0.25
	if is_dying and is_matching:
		$Sprite.frame = 3
	elif is_dying:
		$Sprite.frame = 2
	elif is_previewing:
		$Sprite.frame = 1
	else:
		$Sprite.frame = 0

func set_text_value(str):
	$Sprite/Label.text = str
	original_letter = str
	controller.enemy_grid[row][column] = str
	if !already_changed:
		controller.letters_before_wildcard -= 1
	already_changed = true
	controller.check_for_matches()

func move_down(factor):
	if row + factor >= 5 or is_dying:
		return
	is_shifting_down = true
	position_to_shift_to = position.y + controller.ROW_SEPERATION * factor
	if(row == 0):
		controller.enemy_grid[row][column] = '-'
	row += factor
	controller.enemy_grid[row][column] = $Sprite/Label.text

func drop_letter(letter):
	var new_letter = controller.letter_obj.instantiate()
	new_letter.position = get_parent().position + position
	new_letter.get_node("Label").text = letter
	get_tree().root.add_child(new_letter)

func destroy():
	if is_dying:
		return
	controller.remove_entire_row()
	controller.add_letter_to_player()

func preview(letter):
	if is_dying:
		return
	if !is_previewing:
		$sfx_highlight.play()
	$Sprite/PreviewLabel.text = letter
	is_previewing = true

func undo_preview():
	if is_dying:
		return
	$Sprite/PreviewLabel.text = original_letter
	is_previewing = false

func match_remove(index, length):
	if is_dying:
		return
	if(is_previewing):
		undo_preview()
	is_dying = true
	is_matching = true
	delay = 0.05 * ((column - index) + 1)
	pitch = 0.6 + (float(column - index) * 0.1) + (float(length) * 0.1)

func erase_remove():
	if is_dying:
		return
	if(is_previewing):
		undo_preview()
	is_dying = true
	scale_timer = SCALE_TIMER_DESTRUCTION
	delay = 0.04 * (column + 1)
