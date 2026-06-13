extends Node

func enemy_killed() -> void:
	if get_child_count() == 0:
		queue_free()
		
func _process(delta: float) -> void:
	if get_child_count() == 0:
		queue_free()
