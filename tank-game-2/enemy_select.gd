extends Node

var enemy_pool = ["Artillery", "Railgun", "Heli", "Blitzer"]

var descriptions: Dictionary = {
	"Artillery": "Launches an explosive shell which follows you periodically before exploding",
	"Railgun": "Fires a laser that ricochets off of walls",
	"Heli": "Flies towards you above the walls, the blades kill on contact",
	"Blitzer": "Dashes towards you in a straight line, killing on contact"
}

@onready var selections = $Selections
@onready var choice1 = $Selections/C1/Choice1
@onready var title1 = $Selections/C1/Choice1/Title
@onready var desc1 = $Selections/C1/Choice1/Description
@onready var choice2 = $Selections/C2/Choice2
@onready var title2= $Selections/C2/Choice2/Title
@onready var desc2 = $Selections/C2/Choice2/Description
@onready var choice3 = $Selections/C3/Choice3
@onready var title3 = $Selections/C3/Choice3/Title
@onready var desc3 = $Selections/C3/Choice3/Description

signal selected(enemy_name: String)

func _ready() -> void:
	turn_off_selections()
	
func select() -> void:
	# activate visibility
	turn_on_selections()
	title1.text = enemy_pool.pick_random()
	update_desc(desc1, title1)
	
	title2.text = enemy_pool.pick_random()
	update_desc(desc2, title2)
	
	title3.text = enemy_pool.pick_random()
	update_desc(desc3, title3)


func _on_choice_1_pressed() -> void:
	emit_signal("selected", title1.text.to_lower())
	turn_off_selections()


func _on_choice_2_pressed() -> void:
	emit_signal("selected", title2.text.to_lower())
	turn_off_selections()


func _on_choice_3_pressed() -> void:
	emit_signal("selected", title3.text.to_lower())
	turn_off_selections()
	
func turn_on_selections() -> void:
	for child in selections.get_children():
		child.visible = true
		
func turn_off_selections() -> void:
	for child in selections.get_children():
		child.visible = false

func update_desc(desc_to_update: Label, title: Label):
	desc_to_update.text = descriptions[title.text]
	
	
	
	
