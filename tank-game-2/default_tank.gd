class_name EnemyTank extends CharacterBody2D

@export var maxhealth: float
@export var speed: int
@export var player: CharacterBody2D
@export var health: float
@export var turn_speed: int
@export var max_bullets: int
@export var fire_rate: float
@export var damage: float
@export var range: int
@export var bounces: int
@export var bullet_speed: float
@export var cursed_tank: bool = false
@export var color: Color

@export var enemy_container: Node

@onready var nav_agent:= $NavigationAgent2D as NavigationAgent2D


var sees_player: bool



func _ready() -> void:
	health = maxhealth
	$Sprite2D.texture = $Sprite2D.texture.duplicate(true)
	$Sprite2D.texture.gradient.colors = [color]
	add_to_group("tanks")
	if not cursed_tank:
		add_to_group("destroy_on_bullet_collide")
		add_to_group("hurtable")

func activate_highlight() -> void:
	$Highlight.visible = true

func hit(damage: float) -> void:
	if cursed_tank:
		return
	else:
		$enemy_health_component.hit(damage)
