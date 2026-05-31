extends Node

@onready var parent = get_parent()
@onready var healthbar = $HealthBar

const explosion = preload("res://enemy_explosion.tscn")
const XP = preload("res://xp.tscn")
const HP = preload("res://health_pack.tscn")

var hbsize = 50

func _process(delta: float) -> void:
	healthbar.size.x = 50 * (parent.health / parent.maxhealth)
	healthbar.position = parent.position + Vector2(-25, 20)

func hit(damage: float):
	parent.health -= damage
	if parent.health <= 0:
		# create explosion
		var instance = explosion.instantiate()
		instance.position = get_parent().position
		get_tree().current_scene.add_child(instance)
		
		# drop xp or other
		var drop_chance = randi_range(1,1000)
		var drop
		if drop_chance <= 250: # health drop -> 25%
			drop = HP.instantiate()
			drop.position = get_parent().position
			drop.value = parent.player.max_health * 0.1
			
		get_tree().current_scene.add_child(drop)
		
		var xp = XP.instantiate()
		xp.position = get_parent().position
		xp.value = 2
		get_tree().current_scene.add_child(xp)
		
		# delete enemy and add to kill count
		parent.enemy_container.enemy_killed()
		parent.queue_free()
