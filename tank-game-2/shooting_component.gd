extends Node

const BULLET = preload("res://bullet.tscn")
const MINE = preload("res://mine.tscn")
const explosion = preload("res://mine_explosion.tscn")
@onready var primarycontainer = $"../PrimaryContainer"
@onready var secondarycontainer = $"../SecondaryContainer"

func _input(event):
	if get_parent().health <= 0:
		return
	var cur_bullets = primarycontainer.get_child_count()
	var max_bullets = get_parent().max_bullets
	var cur_secondaries = secondarycontainer.get_child_count()
	var max_secondaries = get_parent().max_secondary
	if event.is_action_pressed("PrimaryShoot") and cur_bullets < max_bullets:
		primary_shoot()
	elif event.is_action_pressed("SecondaryShoot") and cur_secondaries < max_secondaries:
		secondary_shoot()
		
func primary_shoot():
	var mouse_pos_diff_x = get_viewport().get_mouse_position().x - get_parent().get_global_transform_with_canvas().get_origin().x
	var mouse_pos_diff_y = get_viewport().get_mouse_position().y - get_parent().get_global_transform_with_canvas().get_origin().y
	var instance = BULLET.instantiate()
	instance.position = get_parent().position
	instance.dir_vector = Vector2(mouse_pos_diff_x, mouse_pos_diff_y).normalized()
	instance.damage = 1
	instance.parent = get_parent()
	primarycontainer.add_child(instance)
	
func secondary_shoot():
	var instance = MINE.instantiate()
	instance.position = get_parent().position
	instance.damage = 5
	instance.timer_length = 5
	instance.parent = get_parent()
	secondarycontainer.add_child(instance)
	
func test_effect():
	var instance = explosion.instantiate()
	instance.position = get_parent().position
	add_child(instance)
