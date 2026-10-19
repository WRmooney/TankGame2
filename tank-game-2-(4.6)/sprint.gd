extends Node

func start(time: float):
	$SprintTimer.start(time)
	$"../../movement_component".speed_mult = 2.0




func _on_sprint_timer_timeout() -> void:
	$"../../movement_component".speed_mult = 1.0
