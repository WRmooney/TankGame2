extends Node

@onready var player = get_parent().player
@onready var parent = get_parent()
@onready var turret = $"../Turret"
@onready var timer = $TurretTurningTimer

const BULLET = preload("res://bullet.tscn")

var attacking = false
var rand_angle = 1

func _ready() -> void:
	$ShootingTimer.start(parent.fire_rate)

func _process(delta: float) -> void:
	if parent.sees_player:
		if not timer.is_stopped():
			timer.stop()
		turn_to_player()
	else:
		if timer.is_stopped():
			rand_angle = 0
			timer.start(randf_range(1.0,5.0))
		turn_in_dir(rand_angle)

func turn_to_player() -> void:
	var goal_angle = rad_to_deg(atan2(player.position.y-parent.position.y,player.position.x-parent.position.x))
	var cur_angle = turret.rotation_degrees
	
	
	if cur_angle > goal_angle:
		if cur_angle - goal_angle > 180:
			goal_angle += 360
	elif cur_angle < goal_angle:
		if cur_angle - goal_angle > 180:
			goal_angle -= 360
	
	if cur_angle > 360:
		turret.rotation_degrees -= 360
	elif cur_angle < 0:
		turret.rotation_degrees += 360
		
	for i in range(parent.turn_speed):
		if turret.rotation_degrees < goal_angle and absf(turret.rotation_degrees - goal_angle) > 1:
			turret.rotation_degrees += 0.02
			
		elif turret.rotation_degrees > goal_angle and absf(turret.rotation_degrees - goal_angle) > 1:
			turret.rotation_degrees -= 0.02
			
	
func turn_in_dir(dir: int) -> void:
	if dir == 0 or parent.disabled:
		return
	for i in range(parent.turn_speed):
		if dir < 0:
			turret.rotation_degrees += 0.02
		elif dir > 0:
			turret.rotation_degrees -= 0.02

func _on_turret_turning_timer_timeout() -> void:
	var dir = randi_range(-1,1)
	rand_angle = dir
	timer.start(randf_range(1.0,5.0))
	
func _on_shooting_timer_timeout() -> void:
	if parent.disabled:
		timer.start(parent.fire_rate)
		return
	var ang_to_player = rad_to_deg(atan2(player.position.y-parent.position.y,player.position.x-parent.position.x))
	if ang_to_player < 0:
		ang_to_player += 360
	
	if parent.sees_player and absf(ang_to_player - turret.rotation_degrees) < 3:
		var shoot_chance = randi_range(1,4)
		var ang_offset = deg_to_rad(randf_range(-5,5))
		if shoot_chance <= 3:
			var instance = BULLET.instantiate()
			instance.position = parent.position
			instance.dir_vector = Vector2(cos(turret.rotation), sin(turret.rotation)).normalized().rotated(ang_offset)
			instance.damage = parent.damage
			instance.parent = parent
			get_battlefield().bullet_container.add_child(instance)
	elif not parent.sees_player:
		pass
		"""
		var shoot_chance = randi_range(1,20)
		var ang_offset = deg_to_rad(randf_range(-5,5))
		if shoot_chance == 1 and $BulletContainer.get_child_count() < parent.max_bullets:
			var instance = BULLET.instantiate()
			instance.position = parent.position
			instance.dir_vector = Vector2(cos(turret.rotation), sin(turret.rotation)).normalized().rotated(ang_offset)
			instance.damage = parent.damage
			instance.parent = parent
			instance.bounces = parent.bounces
			instance.speed = parent.bullet_speed
			$BulletContainer.add_child(instance)
		"""
	timer.start(parent.fire_rate)
			
func get_battlefield() -> Node2D:
	var par = get_parent()
	while par and par is not Battlefield:
		par = par.get_parent()
	return par
			
