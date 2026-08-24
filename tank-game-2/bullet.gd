extends CharacterBody2D

@export var speed: int
@export var dir_vector = Vector2(0,0).normalized()
@export var parent: Node2D
@export var bounces: int
@export var damage: float

var disabled: bool = false

func _ready() -> void:
	
	if parent:
		if parent.is_in_group("player"):
			add_to_group("player_attacks")
	
	var TRAIL = preload("res://bullet_trail.tscn")
	var instance = TRAIL.instantiate()
	add_child(instance)

func freeze(time: float):
	disabled = true
	$FreezeTimer.start(time)
