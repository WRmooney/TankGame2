extends Node

signal transition_state(new_state_name: String)

@onready var nav_agent := $"../../NavigationAgent2D" as NavigationAgent2D
@onready var parent = $"../.."
@onready var player = $"../..".player


var search_radius: int
var last_seen_location: Vector2

func enter() -> void:
	$SearchTime.start()
	search_radius = 100
	last_seen_location = nav_agent.target_position
	
func exit() -> void:
	print("exiting search state")
	
func on_process() -> void:
	if not player:
		emit_signal("transition_state", "idle")
		return
	if parent.sees_player:
		print("found player again, switching to attack state")
		emit_signal("transition_state", "attack")
	
func pathing_timer_timeout() -> void:
	nav_agent.target_position = nav_agent.target_position
	
func get_new_target() -> void:
	var map = get_viewport().get_world_2d().navigation_map
	var dev_angle = randf_range(0,360)
	var deviance = Vector2(search_radius, 0).rotated(deg_to_rad(dev_angle))
	nav_agent.target_position = NavigationServer2D.map_get_closest_point(map, last_seen_location + deviance)
	if (nav_agent.target_position.x == 0.0 and nav_agent.target_position.y == 0.0):
		await get_tree().create_timer(0.001).timeout
		get_new_target()
		
func target_reached() -> void:
	search_radius += 50
	get_new_target()


func _on_search_time_timeout() -> void:
	emit_signal("transition_state", "idle")
