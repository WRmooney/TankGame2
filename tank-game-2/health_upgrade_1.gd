extends CanvasLayer

@export var player: CharacterBody2D
@export var script_ref: Node


func _on_button_pressed() -> void:
	if player:
		var added_hp = ceil(player.max_health * 0.2)
		player.max_health += added_hp
		player.health += added_hp
		
		script_ref.despawn_upgrades()
