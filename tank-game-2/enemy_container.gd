extends Node

@onready var parent = get_parent()
@onready var mode = parent.mode

var kills = 0
var scaling_threshold: int = 15

func _ready() -> void:
	kills = 0
	if mode == "kill":
		scaling_threshold = 15
	else:
		scaling_threshold = 30
	

func enemy_killed() -> void:
	kills += 1
	if kills % scaling_threshold == 0:
		scale_difficulty()
	
func scale_difficulty() -> void:
	#parent.enemy_health *= 1.1
	parent.enemy_spawn_time *= 0.9
	if parent.enemy_spawn_time < 0.5:
		parent.enemy_spawn_time = 0.5
	#parent.enemy_fire_rate *= 0.95
	if parent.enemy_fire_rate < 0.2:
		parent.enemy_fire_rate = 0.2
