extends Node

var whole_time: float

func start(time: float):
	whole_time = time
	$"../../Highlight".visible = true
	$"../../InvincibilityTime".visible = true
	$InvincibilityTimer.start(time)

func _process(delta: float) -> void:
	$"../../InvincibilityTime".texture.width = ($InvincibilityTimer.time_left / whole_time) * 60
	$"../../InvincibilityTime".position.x = 0 - (((whole_time - $InvincibilityTimer.time_left) / whole_time) * 30)

func _on_invincibility_timer_timeout() -> void:
	$"../../Highlight".visible = false
	$"../../InvincibilityTime".visible = false
