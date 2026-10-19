extends Area2D

@export var value: float

func _ready() -> void:
	$GPUParticles2D.emitting = true
	$AnimatedSprite2D.play()



func _on_body_entered(body: Node2D) -> void:
	
	if body.is_in_group("player") or body.is_in_group("player_attacks"):
		#body.pick_up_orb(self)
		#$OrbCollected.play()
		queue_free()
	


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_attacks"):
		queue_free()
