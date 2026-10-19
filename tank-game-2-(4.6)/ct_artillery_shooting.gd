extends Node

const SHELL = preload("res://shell.tscn")

func _ready() -> void:
	$ShootingTimer.start(randf_range(4.0,6.0))

var blast_size_mod = 0.0
var fire_rate_mod = 1.0

func _on_shooting_timer_timeout() -> void:
	if get_parent().disabled:
		$ShootingTimer.start(randf_range(8.0 * fire_rate_mod,12.0 * fire_rate_mod))
		return
	var instance = SHELL.instantiate()
	instance.position = get_parent().position
	instance.player = get_parent().player
	instance.size_mod = blast_size_mod
	get_battlefield().bullet_container.add_child(instance)
	$ShootingTimer.start(randf_range(8.0 * fire_rate_mod,12.0 * fire_rate_mod))


func get_battlefield() -> Node2D:
	var par = get_parent()
	while par and par is not Battlefield:
		par = par.get_parent()
	return par
