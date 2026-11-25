extends Node2D

@onready var parent = get_parent()
@onready var nav_agent := $"../NavigationAgent2D" as NavigationAgent2D

func _physics_process(delta: float) -> void:
	if parent.disabled or parent.frozen:
		return
	var dir = to_local(nav_agent.get_next_path_position()).normalized()
	
	if nav_agent.avoidance_enabled:
		nav_agent.set_velocity(dir)
	else:
		_on_navigation_agent_2d_velocity_computed(dir)


func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	if parent.disabled:
		return
	if $"../enemy_shooting_component/BulletContainer".get_child_count() != 0:
		parent.velocity = Vector2(0,0)
		parent.knock_back_vector = Vector2(0,0)
		parent.knock_back_scalar = 0
	else:
		parent.velocity = safe_velocity.normalized() * parent.speed
	
	if parent.knock_back_vector != Vector2(0,0) and $"../enemy_shooting_component/BulletContainer".get_child_count() == 0:
		parent.velocity += parent.knock_back_vector * parent.knock_back_scalar
		parent.knock_back_scalar -= 10
		if parent.knock_back_scalar <= 0:
			parent.knock_back_scalar = 0
			parent.knock_back_vector = Vector2(0,0)
	
	parent.move_and_slide()
