extends Node2D


var level: int = 1
var lives: int = 3
var level_width: int = 2
var level_height: int = 2
var score: int = 0

@export var enemies: Array[String] = []
var curses: Array[String] = []

var modes: Array[String] = ["kill", "destroy", "collect","golf"]
var events: Array[String] = ["Nearsighted","Farsighted","Low Ammo","Snow"] # Sawblades, idk what else bruh
var cur_event: String = "none"

var intermission: bool = true

var cur_level: Node2D

const BATTLEFIELD = preload("res://battlefield.tscn")

"""
GOLF MODE?????

LEVEL ORDER:
1: Kill Enemies (100?)
2: Destroy Bases
3: Collect Orbs
4: Kill
5: Destroy
6: Collect
7: Kill
8: Destroy
9: Collect
0: Bossfight

INTERMISSIONS:
1: Enemy
2: Curse
3: Enemy
4: Upgrade
5: Enemy
6: Curse
7: Enemy
8: Upgrade
9: Curse
10: Greater Curse

for now, it will be this:
level order is the same, but intermissions are:

1: Enemy
2: Map Scale
3: Enemy
4: Map Scale
etc...
"""

func _ready() -> void:
	# Connect signals to selections
	$EnemySelect.EnemySelected.connect(add_enemy)
	$CurseSelect.CurseSelected.connect(add_curse)
	
	# Initialize game
	start_game()
	
func start_game() -> void:
	# select enemy
	select_enemy()

func select_enemy() -> void:
	$EnemySelect.select()

func select_curse() -> void:
	$CurseSelect.enemies = enemies
	$CurseSelect.select()

func add_enemy(enemy_name: String) -> void:
	enemies.append(enemy_name)
	continue_to_level()

func add_curse(curse_name: String) -> void:
	curses.append(curse_name)
	continue_to_level()

func continue_to_level() -> void:
	intermission = false
	cur_event = "none"
	if level % 10 == 0:
		boss_transition_screen()
	else:
		var event_chance = randi_range(1,5)
		#print(event_chance)
		if event_chance == 1:
			cur_event = events.pick_random()
		level_transition_screen()
	var battlefield = BATTLEFIELD.instantiate()
	battlefield.event = cur_event
	battlefield.level_width = level_width
	battlefield.level_height = level_height
	battlefield.ct_enemies = enemies
	battlefield.curses = curses
	
	match (level % 10):
		1: 
			battlefield = set_mode(battlefield, "kill")
		2: 
			battlefield = set_mode(battlefield, "destroy")
		3: 
			battlefield = set_mode(battlefield, "collect")
		4: 
			battlefield = set_mode(battlefield, "golf")
		5: 
			battlefield = set_mode(battlefield, "kill")
		6: 
			battlefield = set_mode(battlefield, "destroy")
		7: 
			battlefield = set_mode(battlefield, "collect")
		8: 
			battlefield = set_mode(battlefield, "golf")
		9: 
			battlefield = set_mode(battlefield, "kill")
		0: 
			battlefield = set_mode(battlefield, "random")
		
	# connect signals to battlefield
	battlefield.level_complete.connect(level_complete)
	battlefield.player_died.connect(player_died)
	cur_level = battlefield
	add_child(battlefield)
	
func set_mode(battlefield: Node2D, mode: String) -> Node2D:
	var random = false
	if mode == "random":
		random = true
		mode = modes.pick_random()
	battlefield.mode = mode
	match mode:
		"kill":
			$ObjectiveLayer/ObjectiveLabel.text = "Kill the Enemies!"
			battlefield.kill_max = floor(level / 1.5) + 4
			if random:
				battlefield.kill_max *= 2
		"destroy":
			$ObjectiveLayer/ObjectiveLabel.text = "Eliminate All Enemy Bases!"
			if random:
				battlefield.extra_base_num = 3
				battlefield.level_width += 1
				battlefield.level_height += 1
		"collect":
			$ObjectiveLayer/ObjectiveLabel.text = "Collect All Orbs!"
			if random:
				battlefield.orb_percent = 1.0
				battlefield.level_width += 1
				battlefield.level_height += 1
		"golf":
			$ObjectiveLayer/ObjectiveLabel.text = "Push the Balls into the Hole!"
			if random:
				battlefield.level_width += 1
				battlefield.level_height += 1
	
	return battlefield
	
	

func level_complete() -> void:
	score += cur_level.get_score()
	SaveFile.game_data["tankcoins"] += ceil(level / 10.0)
	cur_level.pause_on_complete()
	await show_win_screen()
	delete_level()
	if intermission:
		return
	intermission = true
	level += 1
	# do selection
	# start next level
	match level % 10:
		1:
			select_enemy()
		2:
			level_width += 1
			select_curse()
		3:
			select_curse()
		4:
			select_enemy()
		5:
			select_curse()
		6:
			level_height += 1
			select_curse()
		7:
			select_enemy()
		8:
			select_curse()
		9:
			select_curse()
		0:
			continue_to_level() #BOSS!!!

func player_died() -> void:
	score += cur_level.get_score()
	lives -= 1
	if lives == 0:
		await game_over_screen()
		delete_level()
		reset_game()
	else:
		await death_screen()
		delete_level()
		continue_to_level()
		
func delete_level() -> void:
	# get instance
	for child in get_children():
		if child is Battlefield:
			child.queue_free()

func reset_game() -> void:
	level = 1
	lives = 3
	level_width = 2
	level_height = 2
	score = 0
	
	enemies = []
	
	intermission = true
	start_game()

func get_save_data(data:Dictionary):
	pass

# UI FUNCTIONS

func show_win_screen() -> void:
	cur_level.process_mode =Node.PROCESS_MODE_DISABLED
	$WinScreen.visible = true
	if level % 5 == 0:
		$WinScreen/ExtraLife.visible = true
		lives += 1
	await get_tree().create_timer(3.0).timeout
	$WinScreen/ExtraLife.visible = false
	$WinScreen.visible = false
	$ObjectiveLayer.visible = false
	
func boss_transition_screen() -> void:
	$TankCoinLayer.visible = true
	$TankCoinLayer/TankCoinCount.text = str(int(SaveFile.game_data["tankcoins"]))
	$BossScreen/LevelNumber.text = "Level " + str(level)
	$BossScreen/LiveCount.text = "Lives: " + str(lives)
	$BossScreen/ColorRect.size = get_viewport().size
	$BossScreen.visible = true
	$ObjectiveLayer.visible = false
	get_tree().paused = true
	await get_tree().create_timer(3.0).timeout
	get_tree().paused = false
	$BossScreen.visible = false
	$ObjectiveLayer.visible = true
	$TankCoinLayer.visible = false
	
func level_transition_screen() -> void:
	$LevelScreen/LevelNumber.text = "Level " + str(level)
	$LevelScreen/LiveCount.text = "Lives: " + str(lives)
	$LevelScreen/ColorRect.size = get_viewport().size
	$TankCoinLayer.visible = true
	$TankCoinLayer/TankCoinCount.text = str(int(SaveFile.game_data["tankcoins"]))
	if cur_event != "none":
		$LevelScreen/EventText.text = "Special Event: " + cur_event
		$LevelScreen/EventText.visible = true
	$LevelScreen.visible = true
	$ObjectiveLayer.visible = false
	get_tree().paused = true
	await get_tree().create_timer(3.0).timeout
	get_tree().paused = false
	$LevelScreen/EventText.visible = false
	$LevelScreen.visible = false
	$ObjectiveLayer.visible = true
	$TankCoinLayer.visible = false
	
func death_screen() -> void:
	cur_level.process_mode =Node.PROCESS_MODE_DISABLED
	$DeathScreen.visible = true
	await get_tree().create_timer(2.0).timeout
	$DeathScreen.visible = false
	$ObjectiveLayer.visible = false
	
func game_over_screen() -> void:
	cur_level.process_mode =Node.PROCESS_MODE_DISABLED
	$GameOverScreen/ScoreLabel.text = "Final Score: " + str(score)
	$GameOverScreen.visible = true
	await get_tree().create_timer(2.0).timeout
	$GameOverScreen/RestartButton.visible = true
	await $GameOverScreen/RestartButton.pressed
	$GameOverScreen/RestartButton.visible = false
	$GameOverScreen.visible = false
	$ObjectiveLayer.visible = false
	
