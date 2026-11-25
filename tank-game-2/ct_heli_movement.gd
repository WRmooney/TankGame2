extends Node2D

@onready var parent = get_parent()
@onready var player = get_parent().player
@onready var speed = get_parent().speed

@onready var blades = $"../HeliBlades"

func _process(delta: float) -> void:
	if parent.disabled or parent.frozen:
		parent.velocity = Vector2(0,0)
		return
	var dir_to_player = atan2(player.position.y - parent.position.y, player.position.x - parent.position.x)
	parent.velocity = Vector2(1,0).rotated(dir_to_player).normalized() * speed
	blades.rotate(deg_to_rad(8))
	
	if parent.knock_back_vector != Vector2(0,0):
		parent.velocity += parent.knock_back_vector * parent.knock_back_scalar
		parent.knock_back_scalar -= 10
		blades.rotate(deg_to_rad(7))
		if parent.knock_back_scalar <= 0:
			parent.knock_back_scalar = 0
			parent.knock_back_vector = Vector2(0,0)
	
	parent.move_and_slide()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if parent.disabled:
		return
	if body.is_in_group("player"):
		body.hit(parent.damage)
	elif body.is_in_group("mines"):
		body.hit(parent.damage)
