extends CharacterBody2D

@export var timer_length: float
@export var explosion_radius: float
@export var damage: float
@export var parent: CharacterBody2D

var ignore_parent = true

func _ready() -> void:
	add_to_group("hurtable")
	add_to_group("destroy_on_bullet_collide")
	
func hit(damage: float):
	$timer_component.hit()
