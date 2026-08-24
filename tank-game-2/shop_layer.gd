extends CanvasLayer

@export var abilitybuttongroup : ButtonGroup

@onready var abilities_container = $AbilityContainer/VBoxContainer

var abilities_dict: Dictionary = {}
var selected_ability: String

func update_abilities():
	abilities_dict = SaveFile.game_data["unlocked_abilities"]
	selected_ability = SaveFile.game_data["selected_ability"]

func _process(delta: float) -> void:
	update_abilities()
	
	for ability in abilities_container.get_children():
		
		# Check if equipped, owned, or not purchased yet, update visual accordingly
		if selected_ability == ability.name: # equipped
			ability.disabled = true
			ability.find_child("AbilityOwned").visible = false
			ability.find_child("AbilityPrice").visible = false
			ability.find_child("AbilityEquipped").visible = true

		elif abilities_dict[ability.name] == true: # owned but not equipped
			ability.disabled = false
			ability.find_child("AbilityOwned").visible = true
			ability.find_child("AbilityPrice").visible = false
			ability.find_child("AbilityEquipped").visible = false
		
		else: # not owned
			ability.disabled = false
			ability.find_child("AbilityOwned").visible = false
			ability.find_child("AbilityPrice").visible = true
			ability.find_child("AbilityEquipped").visible = false
		
		# Check if currently selected
		if ability == abilitybuttongroup.get_pressed_button():
			ability.flat = false
		else:
			ability.flat = true
		
		# Switch button between buy and equip
		if abilitybuttongroup.get_pressed_button() and abilities_dict[abilitybuttongroup.get_pressed_button().name]: # owned, change to equip
			$BuyEquipButton/BuyEquipLabel.text = "Equip"
		else:
			$BuyEquipButton/BuyEquipLabel.text = "Buy"
		
		# toggle buy/equip button based on eligibility
		if not abilitybuttongroup.get_pressed_button():
			$BuyEquipButton.disabled = true
		elif SaveFile.game_data["unlocked_abilities"][abilitybuttongroup.get_pressed_button().name] == false and SaveFile.game_data["tankcoins"] >= int(abilitybuttongroup.get_pressed_button().find_child("AbilityCostLabel").text):
			$BuyEquipButton.disabled = false
		elif SaveFile.game_data["unlocked_abilities"][abilitybuttongroup.get_pressed_button().name] == true and abilitybuttongroup.get_pressed_button().name != selected_ability:
			$BuyEquipButton.disabled = false
		else:
			$BuyEquipButton.disabled = true
		

func _on_buy_equip_button_pressed() -> void:
	if not abilitybuttongroup.get_pressed_button():
		return 
	var selected_button = abilitybuttongroup.get_pressed_button()
	
	if abilities_dict[selected_button.name] == true: # owned, equip
		SaveFile.game_data["selected_ability"] = selected_button.name
	else: # not owned, buy
		var price = int(selected_button.find_child("AbilityCostLabel").text)
		if SaveFile.game_data["tankcoins"] >= price: # purchase
			SaveFile.game_data["tankcoins"] -= price
			SaveFile.game_data["unlocked_abilities"][selected_button.name] = true
			
