extends Area2D

const SPEED = 25

func _process(delta):
	position.y -= SPEED
	if position.y < 0:
		queue_free()
	
	if has_overlapping_areas():
		var areas = get_overlapping_areas()
		areas[0].destroy()
		queue_free()
