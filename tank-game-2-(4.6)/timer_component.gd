extends Node

@onready var timer = $MineTimer
@onready var parent = get_parent()
@onready var sprite = $"../AnimatedSprite2D"
@onready var explosion = preload("res://mine_explosion.tscn")

var detonate_early = false
var been_hit = false

func _ready() -> void:
	sprite.frame = 0
	timer.start(parent.timer_length)
	

func pause(time:float):
	$MineTimer.paused = true
	sprite.pause()
	$PauseTimer.start(time)

func _process(delta: float) -> void:
	if timer.time_left < (timer.wait_time / 3) or detonate_early:
		sprite.play()
	if not detonate_early:
		check_early_detonate()
	 
func check_early_detonate() -> void:
	var bodies = $"../Area2D".get_overlapping_bodies()
	var valid = false
	for body in bodies:
		if body is EnemyTank:
			if not body.cursed_tank:
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
	get_battlefield().bullet_container.call_deferred("add_child",instance)
	parent.queue_free()

func hit() -> void:
	if parent.disabled:
		been_hit = true
	_on_mine_timer_timeout()

func get_battlefield() -> Node2D:
	var par = get_parent()
	while par and par is not Battlefield:
		par = par.get_parent()
	return par


func _on_pause_timer_timeout() -> void:
	if been_hit:
		_on_mine_timer_timeout()
	$MineTimer.paused = false
	parent.disabled = false
	
