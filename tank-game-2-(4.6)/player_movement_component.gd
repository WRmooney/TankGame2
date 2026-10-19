extends Node

var speed = 0
var speed_mult = 1.0
var x_vel = 0
var y_vel = 0

func _physics_process(_delta: float) -> void:
	if get_parent().health <= 0:
		return
	speed = get_parent().speed
	process_movement_input()
	
	# push golfball
	for i in get_parent().get_slide_collision_count():
		var c = get_parent().get_slide_collision(i)
		if c.get_collider().is_in_group("ball"):
			var push_force = (15.0 * get_parent().velocity.length() / speed) + 10
			c.get_collider().apply_central_impulse(-c.get_normal() * push_force)
	
func process_movement_input():
	var input = Vector2.ZERO
	input.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	input.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	input = input.normalized()
	if get_parent().disabled:
		$"..".velocity = Vector2.ZERO
	else:
		$"..".velocity = input*speed * speed_mult
	$"..".move_and_slide()
	
	
