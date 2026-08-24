extends Control

var tankcoins: int = 0

func _ready() -> void:
	tankcoins = SaveFile.game_data["tankcoins"]
	
func _process(delta: float) -> void:
	tankcoins = SaveFile.game_data["tankcoins"]
	$TankCoinCount.text = str(int(SaveFile.game_data["tankcoins"]))
	



var unlocked_abilities: Dictionary ={
	"Sprint": false,
	"Josh Buster": true,
	"Invincibility": false
}
var selected_ability: String = "Josh Buster"

var master_bus_index = AudioServer.get_bus_index("Master")

func _on_bgm_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(master_bus_index,linear_to_db(value))


func _on_play_button_pressed() -> void:
	SaveFile.save_game()
	get_tree().change_scene_to_file("res://endless_survival_mode.tscn")


func _on_shop_button_pressed() -> void:
	$MainMenuLayer.visible = false
	$ShopLayer.visible = true


func _on_shop_back_button_pressed() -> void:
	$MainMenuLayer.visible = true
	$ShopLayer.visible = false


func _on_test_button_pressed() -> void:
	pass
	#SaveFile.game_data["unlocked_abilities"]["Sprint"] = false
	#SaveFile.game_data["selected_ability"] = "Josh Buster"
	
	#SaveFile.game_data["tankcoins"] += 10
	
	
