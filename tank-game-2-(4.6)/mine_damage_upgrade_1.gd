extends CanvasLayer

@export var player: CharacterBody2D
@export var script_ref: Node

func _on_button_pressed() -> void:
	if player:
		player.mine_damage += 2
		
		script_ref.despawn_upgrades()
