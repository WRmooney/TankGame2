extends Node

@onready var parent = get_parent()

var kills = 0

func _ready() -> void:
	kills = 0
	
	
func enemy_killed() -> void:
	kills += 1
	print("kills: " + str(kills))
	if kills % 10 == 0:
		scale_difficulty()
	
func scale_difficulty() -> void:
	print("scaling diff")
	parent.enemy_health *= 1.5
	parent.enemy_spawn_time *= 0.9
	if parent.enemy_spawn_time < 0.5:
		parent.enemy_spawn_time = 0.5
	parent.enemy_fire_rate *= 0.95
	if parent.enemy_fire_rate < 0.2:
		parent.enemy_fire_rate = 0.2
