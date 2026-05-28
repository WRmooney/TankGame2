extends Node

@onready var raycast : RayCast2D = $"../RayCast2D"
@onready var parent = get_parent()
@onready var player = get_parent().player

func _ready() -> void:
	raycast.force_raycast_update()

func can_see_player():
	if not player:
		return false
	var rel_pos = player.position - parent.position
	raycast.target_position = rel_pos
	
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider == player:
			return true
	return false
	
