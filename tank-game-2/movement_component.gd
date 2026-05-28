extends Node

var speed = 0
var x_vel = 0
var y_vel = 0

func _process(delta: float) -> void:
	speed = get_parent().speed
	process_movement_input()
	
func process_movement_input():
	var input = Vector2.ZERO
	input.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	input.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	input = input.normalized()
	$"..".velocity = input*speed
	$"..".move_and_slide()
