extends CharacterBody2D

@export var max_health: float = 10
@export var health: float = 10
@export var speed: float = 3
@export var max_bullets: int = 5
@export var max_secondary: int = 2
@export var enemy_container: Node
@export var level_threshold: float
@export var xp: float
@export var level: int = 1
@export var mine_radius: float = 2
@export var bullet_speed: int = 200
@export var bullet_damage: float = 1
@export var mine_damage: float = 3

var WUIon = false
var LUIon = false

signal player_died()

func _ready() -> void:
	health = max_health
	randomize()
	add_to_group("destroy_on_bullet_collide")
	add_to_group("tanks")
	add_to_group("hurtable")
	add_to_group("player")

func _enter_tree() -> void:
	$StatsUI.visible = true

func hit(damage: float) -> void:
	$health_component.hit(damage)

func _process(_delta: float) -> void:
	if enemy_container.get_child_count() <= 0 and not LUIon:
		return
	
	# rotate turret top
	var mouse_pos_diff_x = get_viewport().get_mouse_position().x - get_global_transform_with_canvas().get_origin().x
	var mouse_pos_diff_y = get_viewport().get_mouse_position().y - get_global_transform_with_canvas().get_origin().y
	$Turret.rotation = atan2(mouse_pos_diff_y, mouse_pos_diff_x)
	
	

func pick_up_xp(xp_node: Area2D):
	$xp_component.pick_up_xp(xp_node)

func heal(amount: float):
	health += amount
	if health > max_health:
		health = max_health
		
func death() -> void:
	emit_signal("player_died")
