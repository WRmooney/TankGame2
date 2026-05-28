extends Node

@onready var parent = get_parent()
@onready var healthbar = $HealthBar

const explosion = preload("res://enemy_explosion.tscn")

var hbsize = 50

func _process(delta: float) -> void:
	healthbar.size.x = 50 * (parent.health / parent.maxhealth)
	healthbar.position = parent.position + Vector2(-25, 20)

func hit(damage: float):
	parent.health -= damage
	if parent.health <= 0:
		var instance = explosion.instantiate()
		instance.position = get_parent().position
		get_tree().current_scene.add_child(instance)
		
		parent.queue_free()
