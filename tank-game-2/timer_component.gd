extends Node

@onready var timer = $MineTimer
@onready var parent = get_parent()
@onready var sprite = $"../AnimatedSprite2D"
@onready var explosion = preload("res://mine_explosion.tscn")

var detonate_early = false

func _ready() -> void:
	sprite.frame = 0
	timer.start(parent.timer_length)

func _process(delta: float) -> void:
	if timer.time_left < (timer.wait_time / 3) or detonate_early:
		sprite.play()
	if not detonate_early:
		check_early_detonate()
	 
func check_early_detonate() -> void:
	var bodies = $"../Area2D".get_overlapping_bodies()
	var valid = false
	for body in bodies:
		if body.is_in_group("tanks") and not body.is_in_group("player"):
			valid = true
		elif body.is_in_group("player"):
			valid = false
			break
	if valid:
		detonate_early = true
		timer.start(0.5)

func _on_mine_timer_timeout() -> void:
	var instance = explosion.instantiate()
	instance.position = get_parent().position
	instance.damage = parent.damage
	instance.length = 1
	instance.ex_radius = parent.explosion_radius
	get_tree().current_scene.call_deferred("add_child",instance)
	parent.queue_free()

func hit() -> void:
	_on_mine_timer_timeout()
