extends Node

var tankref = Node2D

@onready var parent = get_parent()

const BULLET = preload("res://bullet.tscn")

func _ready() -> void:
	add_to_group("bullets")
	add_to_group("destroy_on_bullet_collide")
	tankref = get_parent().parent
	parent.add_collision_exception_with(tankref)

func _physics_process(delta: float) -> void:
	var cur_speed = parent.speed
	var vector = parent.dir_vector.normalized()
	
	# Move bullet
	var collision = parent.move_and_collide(vector * cur_speed * delta)
	$"../PredictionObstacle".change_pos(vector, cur_speed, delta)


	if collision:
		var collider = collision.get_collider()

		# Bounce off walls
		if collider.is_in_group("bounceable") and parent.bounces > 0:
			parent.dir_vector = vector.bounce(collision.get_normal()).normalized()
			parent.bounces -= 1
			parent.remove_collision_exception_with(tankref)
			if parent.test_move(parent.transform, Vector2.ZERO, tankref):
				parent.queue_free()

		elif collider.is_in_group("hurtable"):
			collider.hit(parent.damage)
			parent.queue_free()

		elif collider.is_in_group("destroy_on_bullet_collide") or parent.bounces <= 0:
			parent.queue_free()
