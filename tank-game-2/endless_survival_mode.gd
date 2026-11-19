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
var pausable: bool = false
var cur_level: Node2D

# Timers/Level Transition Vars
@onready var timers = $Timers

@onready var win_timer = $Timers/WinTimer
@onready var death_timer = $Timers/DeathTimer
@onready var game_over_timer = $Timers/GameOverTimer
@onready var level_load_timer = $Timers/LevelLoadingTimer

var cur_timer_name: String = "None"
var cur_timer: Timer = win_timer

var input_press_delay = false

@export var level_load_time: float = 5.0


const BATTLEFIELD = preload("res://battlefield.tscn")

"""
REPLACE WAIT TIMES WITH TIMERS!!! PLEASE!!!! DONT BE STUPID DUMBASS IDIOT!!!


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

func _process(float) -> void:
	#print(cur_timer_name)
	# Check early transition end (spacebar)
	if cur_timer_name != "None":
		if Input.get_action_strength("TransitionSkip") and not input_press_delay:
			cur_timer.stop()
			input_press_delay = true
			cur_timer_name = "None"
			cur_timer.timeout.emit()
		elif not Input.get_action_strength("TransitionSkip") and input_press_delay:
			input_press_delay = false
			
	# Add pausing (later)
	if Input.get_action_strength("Pause") and pausable:
		pause()

func start_game() -> void:
	# select enemy
	select_enemy()

func select_enemy() -> void:
	pausable = false
	$EnemySelect.select()

func select_curse() -> void:
	pausable = false
	$CurseSelect.enemies = enemies
	$CurseSelect.select()

func add_enemy(enemy_name: String) -> void:
	pausable = false
	enemies.append(enemy_name)
	continue_to_level()

func add_curse(curse_name: String) -> void:
	pausable = false
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
				battlefield.extra_base_num = 1
		"collect":
			$ObjectiveLayer/ObjectiveLabel.text = "Collect the Orbs!"
			if random:
				battlefield.orb_percent = 0.9
		"golf":
			$ObjectiveLayer/ObjectiveLabel.text = "Push the Balls into the Hole!"
			if random:
				print("Replace this: set_mode golf")
	
	return battlefield

func level_complete() -> void:
	score += cur_level.get_score()
	SaveFile.game_data["tankcoins"] += ceil(level / 10.0)
	cur_level.pause_on_complete()
	show_win_screen()
	
func go_to_intermission() -> void:
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
		game_over_screen()
	else:
		death_screen()
		
func delete_level() -> void:
	# get instance
	#print("deleting level")
	for child in get_children():
		if child is Battlefield:
			child.queue_free()
			pausable = false

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
	$WinScreen.visible = true
	if level % 5 == 0:
		$WinScreen/ExtraLife.visible = true
		lives += 1
	cur_timer_name = "WinTimer"
	cur_timer = win_timer
	cur_timer.start(3.0)
	pausable = false
	#print("Show win screen")
	
func show_win_screen_end() -> void:
	$WinScreen/ExtraLife.visible = false
	$WinScreen.visible = false
	$ObjectiveLayer.visible = false
	#print("end win screen")
	go_to_intermission()
	
func boss_transition_screen() -> void:
	$TankCoinLayer.visible = true
	$TankCoinLayer/TankCoinCount.text = str(int(SaveFile.game_data["tankcoins"]))
	$BossScreen/LevelNumber.text = "Level " + str(level)
	$BossScreen/LiveCount.text = "Lives: " + str(lives)
	$BossScreen/ColorRect.size = get_viewport().size
	$BossScreen.visible = true
	$ObjectiveLayer.visible = false
	cur_timer_name = "LevelLoadingTimer"
	cur_timer = level_load_timer
	cur_timer.start(level_load_time)
	pausable = false

func boss_transition_end() -> void:
	$BossScreen.visible = false
	$ObjectiveLayer.visible = true
	$TankCoinLayer.visible = false
	
func level_transition_screen() -> void:
	# scientists reveal the hi
	var chance = randi_range(1,30)
	print(chance)
	if chance == 17:
		$Hi.visible = true
	
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
	cur_timer_name = "LevelLoadingTimer"
	cur_timer = level_load_timer
	cur_timer.start(level_load_time)
	pausable = false
	#print("level transition screen")

func level_transition_end() -> void:
	# the hi
	$Hi.visible = false
	
	$LevelScreen/EventText.visible = false
	$LevelScreen.visible = false
	$ObjectiveLayer.visible = true
	$TankCoinLayer.visible = false
	pausable = true
	#print("level transition end")

func death_screen() -> void:
	$DeathScreen.visible = true
	cur_timer_name = "DeathTimer"
	cur_timer = death_timer
	cur_timer.start(level_load_time)
	pausable = false
	#print("death screen")
	
func death_screen_end() -> void:
	$DeathScreen.visible = false
	$ObjectiveLayer.visible = false
	#print("death screen end")
	delete_level()
	continue_to_level()
	
func game_over_screen() -> void:
	$GameOverScreen/ScoreLabel.text = "Final Score: " + str(score)
	$GameOverScreen.visible = true
	cur_timer_name = "GameOverTimer"
	cur_timer = game_over_timer
	cur_timer.start(1.5)
	pausable = false
	#print("game over screen")
	
func game_over_screen_popup() -> void:
	$GameOverScreen/RestartButton.visible = true
	#print("game over popup")

func _on_restart_button_pressed() -> void:
	$GameOverScreen/RestartButton.visible = false
	$GameOverScreen.visible = false
	$ObjectiveLayer.visible = false
	delete_level()
	reset_game()

# Pause/Unpause

func pause() -> void:
	cur_level.process_mode = Node.PROCESS_MODE_DISABLED
	$PauseMenu.visible = true
	pausable = false

func unpause() -> void:
	$PauseMenu.visible = false
	cur_level.process_mode = Node.PROCESS_MODE_INHERIT
	pausable = true

func exit_to_menu() -> void:
	$PauseMenu.visible = false
	delete_level()
	pausable = false
	get_tree().change_scene_to_file("res://main_menu.tscn")

# Timer timeouts

func _on_win_timer_timeout() -> void:
	show_win_screen_end()

func _on_death_timer_timeout() -> void:
	death_screen_end()
	

func _on_game_over_timer_timeout() -> void:
	game_over_screen_popup()
	

func _on_level_loading_timer_timeout() -> void:
	if level % 10 == 0:
		boss_transition_end()
	else:
		level_transition_end()
	
func _on_resume_pressed() -> void:
	unpause()

func _on_exit_pressed() -> void:
	exit_to_menu()
