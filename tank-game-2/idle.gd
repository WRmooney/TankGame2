extends Node

@onready var nav_agent := $"../../NavigationAgent2D" as NavigationAgent2D
@onready var parent = $"../.."

signal transition_state(new_state_name: String)

func enter() -> void:
	await get_tree().process_frame
	get_new_target()
	
func exit() -> void:
	print("exiting idle state")

func on_process() -> void:
	if parent.sees_player:
		print("sees player, switching to attack state")
		emit_signal("transition_state", "attack")

func pathing_timer_timeout() -> void:
	nav_agent.target_position = nav_agent.target_position

func get_new_target() -> void:
	var map = get_viewport().get_world_2d().navigation_map
	nav_agent.target_position = NavigationServer2D.map_get_random_point(map, 1, true)
	if nav_agent.target_position.x == 0.0 and nav_agent.target_position.y == 0.0:
		await get_tree().create_timer(0.01).timeout
		get_new_target()

func target_reached() -> void:
	get_new_target()
	
