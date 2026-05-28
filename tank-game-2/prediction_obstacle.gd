extends NavigationObstacle2D

func change_pos(vector: Vector2, speed: float, delta: float) -> void:
	var new_vertices = PackedVector2Array ([
		vector * 400 * delta * 50,
		vector * 400 * delta * -5 + vector.rotated(deg_to_rad(90))*30,
		vector * 400 * delta * -5 + vector.rotated(deg_to_rad(-90))*30
	])
	
	vertices = new_vertices
