extends Area2D

const MAX_COOLDOWN = 60
const COOLDOWN_SPEED = 3
const MP_X_LIMIT = 1

var mp
var bullet = preload("res://Objects/bullet.tscn")
var controller
var enemy_list
var cooldown = 0
var attached_letter = null
var last_col = null
var y_limit = 0
var trails = []
var trail_positions = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
var trail_indexes = [1, 3, 4]

# Called when the node enters the scene tree for the first time.
func _ready():
	enemy_list = get_parent().get_node("Enemies")
	controller = get_parent()
	trails = $Sprite.get_children()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position = controller.mouse_position
	
	if controller.mouse_position.x - MP_X_LIMIT > controller.last_mouse_position.x:
		$Sprite.frame = 2
	elif controller.mouse_position.x + MP_X_LIMIT < controller.last_mouse_position.x:
		$Sprite.frame = 1
	else:
		$Sprite.frame = 0
	
	trail_positions.push_front(controller.last_mouse_position)
	trail_positions.pop_back()
	var i = 0
	for trail in trails:
		trail.frame = $Sprite.frame
		trail.position = trail_positions[trail_indexes[i]] - position
		i += 1
	
	y_limit = enemy_list.position.y - position.y + 165
	
	$Line2D.set_point_position(1, Vector2(0, y_limit))
	$Line2D.visible = controller.can_shoot
	$RayCast2D.target_position.y = (y_limit - 50)
	
	if controller.can_shoot:
		var col = $RayCast2D.get_collider()
		var is_same = false
		if $RayCast2D.is_colliding() and "column" in col:
			is_same = last_col != null and col.column == last_col.column
			col.preview(attached_letter.get_node("Label").text)
			if !is_same:
				if last_col != null:
					last_col.undo_preview()
				last_col = col
		elif last_col != null:
			if "preview" in last_col:
				last_col.undo_preview()
			last_col = null
	
	if Input.is_action_just_pressed("shoot") and cooldown <= 0:
		$sfx_destroy.play()
		var new_bullet = bullet.instantiate()
		new_bullet.position = position
		get_tree().root.add_child(new_bullet)
		cooldown = MAX_COOLDOWN
		$CooldownBar.color = Color.DARK_RED
		if controller.is_tutorial and controller.tutorial_step == 4:
			controller.set_tutorial_step(5)
	
	if cooldown > 0:
		cooldown -= delta * COOLDOWN_SPEED
		$CooldownBar.size.x = MAX_COOLDOWN - cooldown
	else:
		$CooldownBar.color = Color.WHITE
		$CooldownBar.size.x = MAX_COOLDOWN

func destroy():
	$Sprite.visible = false
	$CooldownBar.visible = false
	$sfx_game_over.play()
	$GPUParticles2D.restart()
	if attached_letter != null:
		attached_letter.visible = false
	if last_col != null:
		last_col.undo_preview()
