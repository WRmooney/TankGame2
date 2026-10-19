extends Node

@onready var parent = get_parent()
@onready var healthbar = $HealthBar
@onready var bullet_cont = $"../enemy_shooting_component/BulletContainer"

const explosion = preload("res://enemy_explosion.tscn")
const XP = preload("res://xp.tscn")
const HP = preload("res://health_pack.tscn")

var hbsize = 50

func _ready() -> void:
	if parent.maxhealth > 1:
		healthbar.visible = true

func _process(delta: float) -> void:
	healthbar.size.x = 50 * (parent.health / parent.maxhealth)
	healthbar.position = parent.position + Vector2(-25, 20)

func hit(damage: float):
	parent.health -= damage
	if parent.health <= 0:
		# create explosion
		var instance = explosion.instantiate()
		instance.position = get_parent().position
		get_battlefield().bullet_container.add_child(instance)
		# Add live bullets to global bullet container to prevent them from disappearing
		if bullet_cont.get_child_count() != 0:
			for bullet in bullet_cont.get_children():
				get_battlefield().bullet_container.add_child(bullet)
				bullet.tankref = get_battlefield().bullet_container
		"""
		# drop xp or other
		var drop_chance = randi_range(1,1000)
		var drop
		if drop_chance <= 250: # health drop -> 25%
			drop = HP.instantiate()
			drop.position = get_parent().position
			drop.value = parent.player.max_health * 0.1
			
		get_tree().current_scene.add_child(drop)
		
		var xp = XP.instantiate()
		xp.position = get_parent().position
		xp.value = 2
		get_tree().current_scene.add_child(xp)
		"""
		
		# delete enemy and add to kill count
		parent.enemy_container.enemy_killed()
		parent.queue_free()

func get_battlefield() -> Node2D:
	var par = get_parent()
	while par and par is not Battlefield:
		par = par.get_parent()
	return par
