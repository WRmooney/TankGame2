extends Node

@onready var nav_agent := $"../../NavigationAgent2D" as NavigationAgent2D
@onready var parent = $"../.."
@onready var player = $"../..".player

signal transition_state(new_state_name: String)

func enter() -> void:
	await get_tree().process_frame
	get_new_target()
	
func exit() -> void:
	pass
	#print("exiting attack state")

func on_process() -> void:
	pass

func pathing_timer_timeout() -> void:
	get_new_target()

func get_new_target() -> void:
	if not player:
		emit_signal("transition_state", "idle")
		return
	# path to player if within distance and in LOS
	if parent.sees_player:
		$LostPlayer.stop()
		nav_agent.target_position = player.position + Vector2(200,0).rotated(randf_range(-180,180))
	# path to where player was last seen
	else:
		if $LostPlayer.is_stopped():
			$LostPlayer.start()
		nav_agent.target_position = player.position

func target_reached() -> void:
	get_new_target()
	

func _on_lost_player_timeout() -> void:
	emit_signal("transition_state","search")
