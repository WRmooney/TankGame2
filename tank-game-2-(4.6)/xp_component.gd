extends Node

@onready var parent = get_parent()
@onready var UI = $"../StatsUI"
@onready var xp_bar = $"../StatsUI/XPBar"
@onready var lvl_up_txt = $"../StatsUI/LVLUPTXT"
@onready var lvl_up_txt_timer = $"../StatsUI/LVLUPTXT/OnScreenTimer"
@onready var upgrade_comp = $"../UpgradeComponent"
@onready var upgrade_container = $"../UpgradeComponent/UpgradeContainer"
@onready var stackable_presets = $"../UpgradePresets/Stackable"
@onready var permanet_presets = $"../UpgradePresets/Permanent"

func _ready() -> void:
	lvl_up_txt.visible = false

func pick_up_xp(xp_node: Area2D):
	parent.xp += xp_node.value
	if parent.xp >= parent.level_threshold:
		parent.xp -= parent.level_threshold
		parent.level_threshold *= 1.1
		parent.level += 1
		lvl_up_txt.visible = true
		lvl_up_txt_timer.start(5.0)
		spawn_upgrades()
		
func spawn_upgrades() -> void:
	upgrade_comp.visible = true
	get_tree().paused = true
	var upgrades = stackable_presets.get_children()
	var upg_1 = upgrades.pick_random().duplicate()
	var upg_2
	while true:
		upg_2 = upgrades.pick_random().duplicate()
		if upg_2.name.to_lower() != upg_1.name.to_lower():
			break
	var upg_3
	while true:
		upg_3 = upgrades.pick_random().duplicate()
		if upg_3.name.to_lower() != upg_1.name.to_lower() and upg_3.name.to_lower() != upg_2.name.to_lower():
			break
	
	upg_1.offset = Vector2(376,373)
	upg_1.player = parent
	upg_1.script_ref = self
	upg_1.visible = true
	upgrade_container.add_child(upg_1)
	
	upg_2.offset = Vector2(576, 373)
	upg_2.player = parent
	upg_2.script_ref = self
	upg_2.visible = true
	upgrade_container.add_child(upg_2)
	
	upg_3.offset = Vector2(776, 373)
	upg_3.player = parent
	upg_3.script_ref = self
	upg_3.visible = true
	upgrade_container.add_child(upg_3)

func despawn_upgrades() -> void:
	upgrade_comp.visible = false
	for child in upgrade_container.get_children():
		child.queue_free()
	get_tree().paused = false

func _process(delta: float) -> void:
	xp_bar.size.x = get_viewport().size.x * (parent.xp / parent.level_threshold)
	xp_bar.global_position = Vector2(0,0)
	lvl_up_txt.global_position = Vector2(376,24)
	$"../UpgradeComponent/ColorRect".global_position = Vector2(251,224)


func _on_on_screen_timer_timeout() -> void:
	lvl_up_txt.visible = false
