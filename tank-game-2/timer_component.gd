extends Node

@onready var timer = $MineTimer
@onready var parent = get_parent()
@onready var sprite = $"../AnimatedSprite2D"
@onready var explosion = preload("res://mine_explosion.tscn")

func _ready() -> void:
	sprite.frame = 0
	timer.start(parent.timer_length)

func _process(delta: float) -> void:
	if timer.time_left < (timer.wait_time / 3):
		sprite.play()

func _on_mine_timer_timeout() -> void:
	var instance = explosion.instantiate()
	instance.position = get_parent().position
	instance.damage = parent.damage
	instance.length = 1
	get_tree().current_scene.call_deferred("add_child",instance)
	parent.queue_free()

func hit() -> void:
	_on_mine_timer_timeout()
