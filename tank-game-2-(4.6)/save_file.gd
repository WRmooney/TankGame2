extends Node

var game_data: Dictionary = {
	"tankcoins":0,
	"unlocked_abilities":{
		"Sprint": false,
		"Josh Buster": true,
		"Invincibility": false
	},
	"selected_ability":"Josh Buster"
}

var default_save: Dictionary = {
	"tankcoins":0,
	"unlocked_abilities":{
		"Sprint": true,
		"Josh Buster": false,
		"Invincibility": false
	},
	"selected_ability":"Josh Buster"
}

func _ready() -> void:
	game_data = load_game()

func save_game():
	print("saving data")
	var file := FileAccess.open("user://save_data.JSON", FileAccess.WRITE)

	
	file.store_string(JSON.stringify(game_data,"\t"))
	file.close()

func load_game():
	var file := FileAccess.open("user://save_data.JSON", FileAccess.READ)
	if file == null:
		print("no file")
		return default_save
	
	var json_obj = JSON.new()
	var parse_err = json_obj.parse(file.get_as_text())
	print(json_obj.get_data())
	return json_obj.get_data()
	
