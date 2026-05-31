extends Area2D

@export var value: float

func _ready() -> void:
	$GPUParticles2D.emitting = true

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.heal(value)
		queue_free()
