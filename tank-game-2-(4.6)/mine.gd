extends CharacterBody2D

@export var timer_length: float
@export var explosion_radius: float
@export var damage: float
@export var parent: CharacterBody2D

var disabled = false
var ignore_parent = true

func _ready() -> void:
	$Area2D/CollisionShape2D.scale = Vector2(explosion_radius, explosion_radius)
	$NavigationObstacle2D.radius = 25.0 * explosion_radius

	add_to_group("hurtable")
	add_to_group("destroy_on_bullet_collide")
	
func hit(damage: float):
	$timer_component.hit()

func freeze(time: float):
	disabled = true
	$timer_component.pause(time)
