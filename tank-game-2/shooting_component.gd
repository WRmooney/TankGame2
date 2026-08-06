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
	instance.position += instance.dir_vector * 20
	instance.damage = get_parent().bullet_damage
	instance.speed = get_parent().bullet_speed
	instance.parent = get_parent()
	primarycontainer.add_child(instance)
	
func secondary_shoot():
	var instance = MINE.instantiate()
	instance.position = get_parent().position
	instance.damage = get_parent().mine_damage
	instance.timer_length = 5
	instance.explosion_radius = get_parent().mine_radius
	instance.parent = get_parent()
	secondarycontainer.add_child(instance)
	
func test_effect():
	var instance = explosion.instantiate()
	instance.position = get_parent().position
	add_child(instance)
