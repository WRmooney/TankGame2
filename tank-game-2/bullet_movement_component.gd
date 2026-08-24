extends Node

var tankref = Node2D

@onready var parent = get_parent()
var temp_boost = 30

const BULLET = preload("res://bullet.tscn")

func _ready() -> void:
	add_to_group("bullets")
	add_to_group("destroy_on_bullet_collide")
	tankref = get_parent().parent
	if tankref:
		parent.add_collision_exception_with(tankref)
		if tankref.is_in_group("player"):
			for attack in get_tree().get_nodes_in_group("player_attacks"):
				if attack.is_in_group("bullets"):
					attack.add_collision_exception_with(parent)
	$TempBoost.start(0.2)
	

func _physics_process(delta: float) -> void:
	var cur_speed = parent.speed
	var vector = parent.dir_vector.normalized()
	if parent.disabled:
		vector = Vector2.ZERO
	
	# Move bullet
	var collision = parent.move_and_collide(vector * (cur_speed + temp_boost) * delta)
	$"../PredictionObstacle".change_pos(vector, cur_speed, delta)


	if collision:
		var collider = collision.get_collider()

		# Bounce off walls
		if collider.is_in_group("bounceable") and parent.bounces > 0:
			parent.dir_vector = vector.bounce(collision.get_normal()).normalized()
			parent.bounces -= 1
			if tankref:
				parent.remove_collision_exception_with(tankref)
				if tankref.is_in_group("player"):
					for attack in get_tree().get_nodes_in_group("player_attacks"):
						if attack.is_in_group("bullets"):
							parent.remove_collision_exception_with(attack)
			if parent.test_move(parent.transform, Vector2.ZERO, tankref):
				parent.queue_free()

		elif collider.is_in_group("hurtable"):
			collider.hit(parent.damage)
			parent.queue_free()

		elif collider.is_in_group("ball"):
			collider.hit(parent)
			parent.queue_free()
		
		elif collider.is_in_group("destroy_on_bullet_collide") and collider.is_in_group("bullets"):
			collider.queue_free()
			parent.queue_free()
		
		elif collider.is_in_group("destroy_on_bullet_collide") or parent.bounces <= 0:
			parent.queue_free()
		

func _on_temp_boost_timeout() -> void:
	temp_boost = 0
