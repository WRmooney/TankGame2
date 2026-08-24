extends Node

const BULLET = preload("res://bullet.tscn")
const MINE = preload("res://mine.tscn")
const explosion = preload("res://mine_explosion.tscn")
const JOSHBUSTER = preload("res://josh_buster_de.tscn")
@onready var primarycontainer = $"../PrimaryContainer"
@onready var secondarycontainer = $"../SecondaryContainer"
@onready var specialcontainer = $"../SpecialContainer"
@onready var specialshootcooldown = $SpecialShootCooldown
@onready var specialicon = $SpecialCooldownUI/Container/Icon
@onready var specialcooldownlabel = $SpecialCooldownUI/Container/Icon/CooldownLabel

func _ready() -> void:
	start_special_cooldown()
	
func _process(delta: float) -> void:
	if not specialshootcooldown.is_stopped(): # timer is active, show countdown
		if not specialcooldownlabel.visible:
			specialcooldownlabel.visible = true # make timer visible
		specialcooldownlabel.text = str(int(ceil(specialshootcooldown.time_left))) # update time on label

func _input(event):
	if get_parent().health <= 0:
		return
	var cur_bullets = primarycontainer.get_child_count()
	var max_bullets = get_parent().max_bullets
	var cur_secondaries = secondarycontainer.get_child_count()
	var max_secondaries = get_parent().max_secondary
	if event.is_action_pressed("PrimaryShoot") and cur_bullets < max_bullets:
		primary_shoot()
	elif event.is_action_pressed("SecondaryShoot") and cur_secondaries < max_secondaries:
		secondary_shoot()
	elif event.is_action_pressed("SpecialShoot") and specialshootcooldown.is_stopped():
		special_shoot()
		
func primary_shoot():
	if get_parent().disabled:
		return
	var mouse_pos_diff_x = get_viewport().get_mouse_position().x - get_parent().get_global_transform_with_canvas().get_origin().x
	var mouse_pos_diff_y = get_viewport().get_mouse_position().y - get_parent().get_global_transform_with_canvas().get_origin().y
	var instance = BULLET.instantiate()
	instance.position = get_parent().position
	instance.dir_vector = Vector2(mouse_pos_diff_x, mouse_pos_diff_y).normalized()
	instance.position += instance.dir_vector * 20
	instance.damage = get_parent().bullet_damage
	instance.speed = get_parent().bullet_speed
	instance.parent = get_parent()
	primarycontainer.add_child(instance)
	
func secondary_shoot():
	if get_parent().disabled:
		return
	var instance = MINE.instantiate()
	instance.position = get_parent().position
	instance.damage = get_parent().mine_damage
	instance.timer_length = 5
	instance.explosion_radius = get_parent().mine_radius
	instance.parent = get_parent()
	secondarycontainer.add_child(instance)
	
func special_shoot():
	match get_parent().cur_special:
		"Josh Buster":
			var instance = JOSHBUSTER.instantiate()
			instance.position = get_parent().position
			specialcontainer.add_child(instance)
			get_battlefield().freeze_enemies(5.0, true)
			get_parent().freeze(5.0, true)
			start_special_cooldown()
		"Invincibility":
			$"../health_component".start_invincibility(10)
			$Invincibility.start(10)
			start_special_cooldown()
		"Sprint":
			$Sprint.start(10)
			start_special_cooldown()

func start_special_cooldown():
	match get_parent().cur_special:
		"Josh Buster":
			specialshootcooldown.start(135)
		"Invincibility":
			specialshootcooldown.start(10)
		"Sprint":
			specialshootcooldown.start(45)
		_:
			pass

func test_effect():
	var instance = explosion.instantiate()
	instance.position = get_parent().position
	add_child(instance)


func _on_special_shoot_cooldown_timeout() -> void:
	specialcooldownlabel.visible = false

func get_battlefield() -> Node2D:
	var par = get_parent()
	while par and par is not Battlefield:
		par = par.get_parent()
	return par
