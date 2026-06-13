extends Node2D

@onready var parent = get_parent()
@onready var player = get_parent().player
@onready var speed = get_parent().speed

var in_attack: bool = false
var target_pos: Vector2

func _ready() -> void:
	$Cooldown.start(3)


func _process(delta: float) -> void:
	if in_attack:
		var dir = atan2(target_pos.y - parent.position.y, target_pos.x - parent.position.x)
		parent.velocity = Vector2(1,0).rotated(dir).normalized() * speed
		parent.move_and_slide()
		if parent.position.distance_to(target_pos) < 5:
			in_attack = false
			$Cooldown.start(parent.fire_rate / 2 + randf_range(0.0, 0.5))
		
		# SPINNNNNN
		$"../Sprite2D".rotate(deg_to_rad(7))
	else:
		# SPINNNNNNN
		$"../Sprite2D".rotate(deg_to_rad(3))
		



func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.hit(parent.damage)


func _on_cooldown_timeout() -> void:
	$LineContainer.rotation = atan2(player.position.y - parent.position.y, player.position.x - parent.position.x)
	$LineContainer.visible = true
	target_pos = parent.position + Vector2(parent.range,0).rotated($LineContainer.rotation)
	
	$Windup.start(parent.fire_rate)


func _on_windup_timeout() -> void:
	$LineContainer.visible = false
	in_attack = true
