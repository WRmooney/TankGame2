extends Area2D


func _on_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	if body is TileMapLayer:
		var coords = body.get_coords_for_body_rid(body_rid)
		var tile_id = body.get_cell_source_id(coords)
		if tile_id == 3:
			body.set_cell(coords,0, Vector2(randi_range(0,2),0))
	elif body.is_in_group("cursed_tanks"):
		return
	elif body.is_in_group("hurtable"):
		body.hit(get_parent().damage)
	elif body.is_in_group("bullets"):
		body.queue_free()
