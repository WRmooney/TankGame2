extends Node2D

@onready var parent = get_parent()
@onready var nav_agent := $"../NavigationAgent2D" as NavigationAgent2D

func _physics_process(delta: float) -> void:
	var dir = to_local(nav_agent.get_next_path_position()).normalized()
	 
	if nav_agent.avoidance_enabled:
		nav_agent.set_velocity(dir)
	else:
		_on_navigation_agent_2d_velocity_computed(dir)


func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	parent.velocity = safe_velocity.normalized() * parent.speed
	parent.move_and_slide()
