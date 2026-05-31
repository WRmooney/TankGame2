extends CharacterBody2D

@export var maxhealth: float
@export var speed: int
@export var player: CharacterBody2D
@export var health: float
@export var turn_speed: int
@export var max_bullets: int
@export var fire_rate: float
@export var damage: float

@export var enemy_container: Node

@onready var nav_agent:= $NavigationAgent2D as NavigationAgent2D


var sees_player: bool


func _ready() -> void:
	health = maxhealth
	add_to_group("destroy_on_bullet_collide")
	add_to_group("tanks")
	add_to_group("hurtable")

func hit(damage: float) -> void:
	$enemy_health_component.hit(damage)
