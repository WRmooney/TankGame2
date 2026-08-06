extends CharacterBody2D

@export var speed: int
@export var dir_vector = Vector2(0,0).normalized()
@export var parent: Node2D
@export var bounces: int
@export var damage: float

func _ready() -> void:
	var TRAIL = preload("res://bullet_trail.tscn")
	var instance = TRAIL.instantiate()
	add_child(instance)
