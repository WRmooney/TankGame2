extends CharacterBody2D

@export var player: CharacterBody2D

var following: bool = true
var disabled: bool = false
var size_mod: float = 0.0

const SHELL_EXPLOSION = preload("res://shell_explosion.tscn")

func _ready() -> void:
	$FollowingSprite.scale = Vector2(1 + size_mod, 1 + size_mod)
	$StoppedSprite.scale = Vector2(1 + size_mod, 1 + size_mod)
	$FollowTimer.start(5)

func freeze(time: float):
	disabled = true
	$FreezeTimer.start(time)
	if following:
		$FollowTimer.paused = true
	else:
		$ExplosionTimer.paused = true

func _process(delta: float) -> void:
	if disabled:
		velocity = Vector2.ZERO
		return
	if following:
		if position.distance_to(player.position) > 10:
			var dir_to_player = atan2(player.position.y - position.y, player.position.x - position.x)
			velocity = Vector2(1,0).rotated(dir_to_player).normalized() * 500
			move_and_slide()
		else:
			position = player.position


func _on_follow_timer_timeout() -> void:
	following = false
	$FollowingSprite.visible = false
	$StoppedSprite.visible = true
	$ExplosionTimer.start(1.5)


func _on_explosion_timer_timeout() -> void:
	var instance = SHELL_EXPLOSION.instantiate()
	instance.position = position
	instance.length = 1.5
	instance.ex_radius = ($CollisionShape2D.shape.radius / 30.0) * (1 + size_mod)
	get_battlefield().bullet_container.call_deferred("add_child",instance)
	queue_free()

func get_battlefield() -> Node2D:
	var par = get_parent()
	while par and par is not Battlefield:
		par = par.get_parent()
	return par


func _on_freeze_timer_timeout() -> void:
	disabled = false
	if following:
		$FollowTimer.paused = false
	else:
		$ExplosionTimer.paused = false
