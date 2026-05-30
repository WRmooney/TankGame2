extends CharacterBody2D

@export var max_health: float = 10
@export var health: float = 10
@export var speed: float = 3
@export var max_bullets: int = 5
@export var max_secondary: int = 2
@export var enemy_container: Node

var WUIon = false
var LUIon = false

func _ready() -> void:
	health = max_health
	randomize()
	add_to_group("destroy_on_bullet_collide")
	add_to_group("tanks")
	add_to_group("hurtable")

func hit(damage: float) -> void:
	$health_component.hit(damage)

func _process(delta: float) -> void:
	if enemy_container.get_child_count() <= 0 and not WUIon and not LUIon:
		return
		WUIon = true
		if $WinningUI:
			for UIElement in $WinningUI.get_children():
				print(get_viewport().position.x)
				UIElement.global_position = Vector2(get_viewport().size.x/2 - UIElement.size.x/2,get_viewport().size.y/2 - UIElement.size.y/2)
				UIElement.visible = true
