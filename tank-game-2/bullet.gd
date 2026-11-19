extends CharacterBody2D

@export var speed: int
@export var dir_vector = Vector2(0,0).normalized()
@export var parent: Node2D
@export var bounces: int
@export var damage: float
@export var homing: bool = false

var disabled: bool = false

@onready var homing_timer = $HomingAbility/HomingTimer
@onready var homing_area = $HomingAbility/HomingZone
@onready var homing_ray = $HomingAbility/HomingSightCheck
@onready var homing_sprite = $HomingAbility/HomingSprite

@onready var orb_area = $HomingAbility/OrbZone

func _ready() -> void:
	
	if parent:
		if parent.is_in_group("player"):
			add_to_group("player_attacks")
	if homing:
		homing_timer.start(0.5)
		homing_sprite.visible = true
		
	var TRAIL = preload("res://bullet_trail.tscn")
	var instance = TRAIL.instantiate()
	add_child(instance)
	
	

func freeze(time: float):
	disabled = true
	$FreezeTimer.start(time)

func _on_homing_timer_timeout() -> void:
	# Prioritize Orb Collection
	var orb_bodies = orb_area.get_overlapping_areas()
	var closest_orb
	var closest_orb_dist = 99999
	var closest_orb_dir
	for body in orb_bodies:
		if body.is_in_group("orbs"):
			# check with raycast
			homing_ray.target_position = Vector2(body.position.x-global_position.x,body.position.y-global_position.y)
			homing_ray.force_raycast_update()
			if not homing_ray.is_colliding(): # no walls between
				if position.distance_to(body.position) < closest_orb_dist:
					closest_orb = body
					closest_orb_dist = position.distance_to(body.position)
					closest_orb_dir = Vector2(body.position.x-global_position.x,body.position.y-global_position.y)
	
	# Home onto nearest enemy
	var bodies = homing_area.get_overlapping_bodies()
	var closest_enemy
	var closest_enemy_dist = 99999
	var closest_enemy_dir
	for body in bodies:
		if body.is_in_group("hurtable") and not body.is_in_group("player"):
			# check with raycast
			homing_ray.target_position = Vector2(body.position.x-global_position.x,body.position.y-global_position.y)
			homing_ray.force_raycast_update()
			if not homing_ray.is_colliding(): # no walls between
				# Check for disabled CTs
				if body.is_in_group("cursed_tanks"):
					if body.disabled:
						continue
				
				if position.distance_to(body.position) < closest_enemy_dist:
					closest_enemy = body
					closest_enemy_dist = position.distance_to(body.position)
					closest_enemy_dir = Vector2(body.position.x-global_position.x,body.position.y-global_position.y)
	if closest_orb:
		dir_vector = closest_orb_dir
		speed *= 1.1
		homing_timer.one_shot = false
		homing_timer.start(0.1)
	elif closest_enemy:
		dir_vector = closest_enemy_dir
		speed *= 5
		homing_timer.one_shot = true
	else:
		homing_timer.start(0.1)
