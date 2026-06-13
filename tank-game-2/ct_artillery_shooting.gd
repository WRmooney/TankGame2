extends Node

const SHELL = preload("res://shell.tscn")

func _ready() -> void:
	$ShootingTimer.start(randf_range(4.0,6.0))



func _on_shooting_timer_timeout() -> void:
	var instance = SHELL.instantiate()
	instance.position = get_parent().position
	instance.player = get_parent().player
	get_battlefield().bullet_container.add_child(instance)
	$ShootingTimer.start(randf_range(8.0,12.0))


func get_battlefield() -> Node2D:
	var par = get_parent()
	while par and par is not Battlefield:
		par = par.get_parent()
	return par
