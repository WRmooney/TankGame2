extends Node

var curse_pool = []

@export var enemies = []

var curse_groups: Dictionary = {
	"artillery":["Larger Shells","Faster Shells"],
	"railgun":["Lasting Lasers","Wide Lasers"],
	"heli":["Faster Heli","Longer Blades"],
	"blitzer":["Farther Dash","Quicker Dash"],
	
	
}

var descriptions: Dictionary = {
	"Larger Shells":"Artillery shells have a slightly larger blast radius.",
	"Faster Shells":"Artillery fire rate is slightly increased.",
	"Lasting Lasers":"Railgun lasers last slightly longer.",
	"Wide Lasers":"Railgun laser width is slightly increased.",
	"Faster Heli":"Heli speed is slightly increased.",
	"Longer Blades":"Heli blades become slightly longer.",
	"Farther Dash":"Blitzer dashes slightly farther.",
	"Quicker Dash":"Blitzer dash cooldown is slightly decreased."
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

signal CurseSelected(enemy_name: String)

func _ready() -> void:
	turn_off_selections()
	
func select() -> void:
	# activate visibility
	turn_on_selections()
	# fill curse pool
	fill_curse_pool()
	
	title1.text = curse_pool.pick_random()
	update_desc(desc1, title1)
	
	title2.text = curse_pool.pick_random()
	update_desc(desc2, title2)
	
	title3.text = curse_pool.pick_random()
	update_desc(desc3, title3)


func _on_choice_1_pressed() -> void:
	emit_signal("CurseSelected", title1.text)
	turn_off_selections()


func _on_choice_2_pressed() -> void:
	emit_signal("CurseSelected", title2.text)
	turn_off_selections()


func _on_choice_3_pressed() -> void:
	emit_signal("CurseSelected", title3.text)
	turn_off_selections()
	
func turn_on_selections() -> void:
	for child in selections.get_children():
		child.visible = true
		
func turn_off_selections() -> void:
	for child in selections.get_children():
		child.visible = false

func update_desc(desc_to_update: Label, title: Label):
	desc_to_update.text = descriptions[title.text]

func fill_curse_pool() -> void:
	curse_pool = []
	for curse_group in curse_groups.keys():
		if curse_group in enemies or curse_group == "global":
			curse_pool.append_array(curse_groups[curse_group])
	
	
