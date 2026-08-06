extends Node

@onready var parent = get_parent()

func apply_curses(curses: Array[String]) -> void:
	for curse in curses:
		match curse:
			"Larger Shells":
				$"../enemy_shooting_component".blast_size_mod += 0.075
				continue
			"Faster Shells":
				$"../enemy_shooting_component".fire_rate_mod *= 0.95
				continue
			"Wide Lasers":
				$"../enemy_shooting_component".laser_width_mod += 0.40
				continue
			"Lasting Lasers":
				$"../enemy_shooting_component".laser_duration_mod += 0.2
				continue
			"Faster Heli":
				$"../enemy_movement_component".speed += 5
				continue
			"Longer Blades":
				$"../HeliBlades".apply_scale(Vector2(1.2,1.2))
				$"../enemy_movement_component/Area2D/CollisionShape2D".apply_scale(Vector2(1.2,1.2))
				continue
			"Farther Dash":
				parent.range += 30
				continue
			"Quicker Dash":
				$"../enemy_movement_component".dash_cooldown_mod *= 0.90
				continue
				
				
