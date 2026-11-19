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
@onready var primarytimer = $PrimaryShootReplenish
@onready var secondarytimer = $SecondaryShootReplenish

@onready var ammolabel = $"../StatsUI/AmmoLabel"
@onready var ammolabel2 = $"../StatsUI/AmmoLabel2"
@onready var bullet_rect = $"../StatsUI/AmmoLabel/PrimaryCooldown"
@onready var mine_rect = $"../StatsUI/AmmoLabel2/SecondaryCooldown"

var cur_bullets = 0
var cur_secondary = 0
var homing: bool = false

var no_cur_special_flag = true # start with no cur special


func _ready() -> void:
	cur_bullets = get_parent().max_bullets
	cur_secondary = get_parent().max_secondary
	start_special_cooldown()
	
func _process(delta: float) -> void:
	# check for cur_special
	if no_cur_special_flag:
		if get_parent().cur_special != "None":
			no_cur_special_flag = false
			apply_special_icon()
			start_special_cooldown()
			
	
	if not specialshootcooldown.is_stopped(): # timer is active, show countdown
		if not specialcooldownlabel.visible:
			specialcooldownlabel.visible = true # make timer visible
		specialcooldownlabel.text = str(int(ceil(specialshootcooldown.time_left))) # update time on label
	
	# Bullet/Mine "reloading"
	if primarytimer.is_stopped() and not (cur_bullets < get_parent().max_bullets):
		bullet_rect.size.x = 0
	elif primarytimer.is_stopped() and (cur_bullets < get_parent().max_bullets): # start cooldown
		primarytimer.start(0.75)
	elif not primarytimer.is_stopped(): # Show 
		bullet_rect.size.x = ((primarytimer.wait_time - primarytimer.time_left) / primarytimer.wait_time) * 223.0
	
	if secondarytimer.is_stopped() and not (cur_secondary < get_parent().max_secondary):
		mine_rect.size.x = 0
	elif secondarytimer.is_stopped() and (cur_secondary < get_parent().max_secondary): # start cooldown
		secondarytimer.start(2.0)
	elif not secondarytimer.is_stopped(): # Show 
		mine_rect.size.x = ((secondarytimer.wait_time - secondarytimer.time_left) / secondarytimer.wait_time) * 223.0
	
	ammolabel.text = "Bullets (LMB): " + str(cur_bullets)
	ammolabel.global_position = Vector2(50,50)
	ammolabel2.text = "Mines (RMB): " + str(cur_secondary)
	ammolabel2.global_position = Vector2(50,100)
	
	
func _input(event):
	if get_parent().health <= 0:
		return
	var max_bullets = get_parent().max_bullets
	var max_secondaries = get_parent().max_secondary
	if event.is_action_pressed("PrimaryShoot") and cur_bullets > 0:
		primary_shoot()
	elif event.is_action_pressed("SecondaryShoot") and cur_secondary > 0:
		secondary_shoot()
	elif event.is_action_pressed("SpecialShoot") and specialshootcooldown.is_stopped():
		special_shoot()
		
func primary_shoot():
	if get_parent().disabled:
		return
	cur_bullets -= 1
	var mouse_pos_diff_x = get_viewport().get_mouse_position().x - get_parent().get_global_transform_with_canvas().get_origin().x
	var mouse_pos_diff_y = get_viewport().get_mouse_position().y - get_parent().get_global_transform_with_canvas().get_origin().y
	var instance = BULLET.instantiate()
	instance.position = get_parent().position
	instance.dir_vector = Vector2(mouse_pos_diff_x, mouse_pos_diff_y).normalized()
	instance.position += instance.dir_vector * 20
	instance.damage = get_parent().bullet_damage
	instance.speed = get_parent().bullet_speed
	instance.parent = get_parent()
	instance.homing = homing
	primarycontainer.add_child(instance)
	
func secondary_shoot():
	if get_parent().disabled:
		return
	cur_secondary -= 1
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
			get_battlefield().freeze_enemies(5.0, true, "Josh Buster")
			get_parent().freeze(5.0, true)
			$"../Camera2D".start_shake(5.0,5.0)
			start_special_cooldown()
		"Invincibility":
			$"../health_component".start_invincibility(10)
			$Invincibility.start(10)
			start_special_cooldown()
		"Sprint":
			$Sprint.start(10)
			start_special_cooldown()
		"Flashbang":
			$Flashbang/FlashbangLight.emitting = true
			$Flashbang.freeze_enemies(10.0, false, "Flashbang")
			$"../Camera2D".start_shake(2.0, 0.3)
			start_special_cooldown()
		"Homing":
			homing = true
			$Homing/HomingTimer.start(10)
			start_special_cooldown()

func start_special_cooldown(value_override: int = -1):
	if value_override > 0:
		specialshootcooldown.start(value_override)
		return
		
	if no_cur_special_flag:
		return
	
	match get_parent().cur_special:
		"Josh Buster":
			specialshootcooldown.start(135)
		"Invincibility":
			specialshootcooldown.start(90)
		"Sprint":
			specialshootcooldown.start(45)
		"Flashbang":
			specialshootcooldown.start(60)
		"Homing":
			specialshootcooldown.start(60)
		_:
			pass

func test_effect():
	var instance = explosion.instantiate()
	instance.position = get_parent().position
	add_child(instance)

func apply_special_icon() -> void:
	match get_parent().cur_special:
		"Josh Buster":
			specialicon.texture = load("res://Icons/JoshbusterIcon.png")
		"Invincibility":
			specialicon.texture = load("res://Icons/InvincibilityIcon.png")
		"Sprint":
			specialicon.texture = load("res://Icons/DashAbilityIcon.png")
		"Flashbang":
			specialicon.texture = load("res://Icons/FlashbangIcon.png")
		"Homing":
			specialicon.texture = load("res://Icons/HomingIcon.png")


func _on_special_shoot_cooldown_timeout() -> void:
	specialcooldownlabel.visible = false

func get_battlefield() -> Node2D:
	var par = get_parent()
	while par and par is not Battlefield:
		par = par.get_parent()
	return par

func _on_primary_shoot_replenish_timeout() -> void:
	cur_bullets += 1

func _on_secondary_shoot_replenish_timeout() -> void:
	cur_secondary += 1

func _on_homing_timer_timeout() -> void:
	homing = false
