extends Node2D


var level: int = 1
var lives: int = 3
var level_width: int = 2
var level_height: int = 2
var score: int = 0

var enemies: Array[String] = []

var modes: Array[String] = ["kill", "destroy", "collect"]

var intermission: bool = true

var cur_level: Node2D

const BATTLEFIELD = preload("res://battlefield.tscn")

"""
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
	$EnemySelect.selected.connect(add_enemy)
	
	
	# Initialize game
	start_game()
	
func start_game() -> void:
	# select enemy
	select_enemy()

func select_enemy() -> void:
	$EnemySelect.select()

func add_enemy(enemy_name: String) -> void:
	enemies.append(enemy_name)
	continue_to_level()

func continue_to_level() -> void:
	intermission = false
	if level % 10 == 0:
		boss_transition_screen()
	else:
		level_transition_screen()
	var battlefield = BATTLEFIELD.instantiate()
	battlefield.level_width = level_width
	battlefield.level_height = level_height
	battlefield.ct_enemies = enemies
	
	match (level % 10):
		1: 
			battlefield = set_mode(battlefield, "kill")
		2: 
			battlefield = set_mode(battlefield, "destroy")
		3: 
			battlefield = set_mode(battlefield, "collect")
		4: 
			battlefield = set_mode(battlefield, "kill")
		5: 
			battlefield = set_mode(battlefield, "destroy")
		6: 
			battlefield = set_mode(battlefield, "collect")
		7: 
			battlefield = set_mode(battlefield, "kill")
		8: 
			battlefield = set_mode(battlefield, "destroy")
		9: 
			battlefield = set_mode(battlefield, "collect")
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
	
	return battlefield
	
	

func level_complete() -> void:
	score += cur_level.get_score()
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
			continue_to_level()
		3:
			select_enemy()
		4:
			continue_to_level()
		5:
			select_enemy()
		6:
			level_height += 1
			continue_to_level()
		7:
			select_enemy()
		8:
			continue_to_level()
		9:
			select_enemy()
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
	
func level_transition_screen() -> void:
	$LevelScreen/LevelNumber.text = "Level " + str(level)
	$LevelScreen/LiveCount.text = "Lives: " + str(lives)
	$LevelScreen/ColorRect.size = get_viewport().size
	$LevelScreen.visible = true
	$ObjectiveLayer.visible = false
	get_tree().paused = true
	await get_tree().create_timer(3.0).timeout
	get_tree().paused = false
	$LevelScreen.visible = false
	$ObjectiveLayer.visible = true
	
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
	
