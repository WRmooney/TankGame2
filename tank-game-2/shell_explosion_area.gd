extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body is TileMapLayer:
		pass
	elif body.is_in_group("player"):
		body.hit(get_parent().damage)
	elif body.is_in_group("bullets"):
		body.queue_free()
