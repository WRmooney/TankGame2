extends Node

@onready var area = $FlashbangArea

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func freeze_enemies(time: float, freeze_bullets: bool, effect_name: String):
	var enemies = area.get_overlapping_bodies()
	for enemy in enemies:
		if enemy.is_in_group("hurtable") and not enemy.is_in_group("player"):
			enemy.freeze(time, freeze_bullets, effect_name)
