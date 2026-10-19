extends Node

@onready var player = get_parent().player
@onready var parent = get_parent()
@onready var turret = $"../Turret"
@onready var timer = $TurretTurningTimer
@onready var raycast = $Ricochet

const LASER = preload("res://laser.tscn")

var attacking = false
var rand_angle = 1
var can_shoot: bool = false

var laser_width_mod: float = 1.0
var laser_duration_mod: float = 1.0

func _ready() -> void:
	$ShootingTimer.start(parent.fire_rate)
	raycast.add_exception(parent)

func _physics_process(delta: float) -> void:
	if parent.disabled:
		return
	if timer.is_stopped():
		rand_angle = 0
		timer.start(randf_range(1.0,5.0))
	if $"../enemy_shooting_component/BulletContainer".get_child_count() == 0:
		turn_in_dir(rand_angle)
	
	if can_shoot:
		check_angles()
	
	
	
func check_angles() -> void:
	var ang_to_check = turret.rotation_degrees
	if hits_player(ang_to_check) and can_shoot:
		shoot(ang_to_check)
			
func hits_player(ang_to_check: float) -> bool: #angle in degrees
	var hits = false
	var max_loop = 10
	
	$Line2D.clear_points()
	
	var cur_origin = parent.position
	var cur_direction = Vector2(1,0).rotated(deg_to_rad(ang_to_check)).normalized()
	$Line2D.add_point(cur_origin)
	var bounces = 0
	while bounces <= parent.bounces and max_loop > 0:
		max_loop -= 1
		raycast.position = cur_origin
		raycast.target_position = cur_direction * 5000.0
		raycast.force_raycast_update()
		
		if raycast.is_colliding():
			
			var hit_point = raycast.get_collision_point()
			var hit_normal = raycast.get_collision_normal()
			var collider = raycast.get_collider()
			$Line2D.add_point(hit_point)
			if collider and collider.is_in_group("bounceable"):
				cur_origin = hit_point + (hit_normal * 0.01)
				cur_direction = cur_direction.bounce(hit_normal)
				bounces += 1
			elif collider and collider.is_in_group("player"):
				hits = true
				raycast.add_exception(collider)
				cur_origin = hit_point
			elif collider:
				raycast.add_exception(collider)
			else:
				continue
		else:
			cur_origin = cur_origin + cur_direction*5000.0
	return hits
	
func turn_in_dir(dir: int) -> void:
	if parent.disabled:
		return
	for i in range(parent.turn_speed):
		if dir <= 0:
			turret.rotation_degrees += 0.02
		elif dir > 0:
			turret.rotation_degrees -= 0.02

func _on_turret_turning_timer_timeout() -> void:
	var dir = randi_range(0,1)
	rand_angle = dir
	timer.start(randf_range(1.0,5.0))
	
func _on_shooting_timer_timeout() -> void:
	if not can_shoot:
		if $"../enemy_shooting_component/BulletContainer".get_child_count() == 0:
			can_shoot = true
			raycast.clear_exceptions()
			raycast.add_exception(parent)
		$ShootingTimer.start(parent.fire_rate)

func shoot(angle: float) -> void:
	if parent.disabled:
		return
	if not can_shoot:
		return
	can_shoot = false
	var instance = LASER.instantiate()
	instance.line_points = $Line2D.points
	instance.wait_time = 1.25
	instance.duration = .5 * laser_duration_mod
	instance.width = 4 * laser_width_mod
	#instance.damage = parent.damage
	#instance.parent = parent
	$BulletContainer.add_child(instance)
	$ShootingTimer.start(parent.fire_rate)
			
func get_battlefield() -> Node2D:
	var par = get_parent()
	while par and par is not Battlefield:
		par = par.get_parent()
	return par
