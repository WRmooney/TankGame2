extends Control

var master_bus_index = AudioServer.get_bus_index("Master")

func _on_bgm_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(master_bus_index,linear_to_db(value))


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://endless_survival_mode.tscn")
