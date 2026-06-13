class_name Battlefield
extends Node2D

const PLAYER = preload("res://player_tank.tscn")
const ENEMY = preload("res://default_tank.tscn")

const ORB = preload("res://orb.tscn")
const BASE = preload("res://enemy_base.tscn")

const RAILGUN = preload("res://ct_railgun.tscn")
const ARTILLERY = preload("res://ct_artillery.tscn")
const HELI = preload("res://ct_heli.tscn")
const BLITZER = preload("res://ct_blitzer.tscn")

@onready var presets = $MapGenerationPresets
@onready var tilemap = $TileMapLayer
@onready var enemy_container = $Enemy_Container
@onready var orblayer = $OrbLayer
@onready var orb_count = $CounterContainer/OrbsCollected/OrbCount
@onready var orbs_collected = $CounterContainer/OrbsCollected
@onready var bases_destroyed = $CounterContainer/BasesDestroyed
@onready var base_count = $CounterContainer/BasesDestroyed/BaseCount
@onready var bullet_container = $BulletContainer
@onready var enemies_killed = $CounterContainer/EnemiesKilled
@onready var kill_count = $CounterContainer/EnemiesKilled/KillCount

@export var level_width: int = 6
@export var level_height: int = 6

@export var player_maxhealth: float
@export var player_speed: float
@export var player_max_bullets: int
@export var player_max_secondary: int

@export var spawn_cap: int

@export var mode: String

@export var orb_percent: float
@export var extra_base_num: int = 0

var ct_enemies: Array[String] = []
var spawn_tile = Vector2i(0,0)

var enemy_spawn_time = 5
var enemy_health = 1
var enemy_fire_rate = 1
var enemy_damage = 1

var orb_max: int = -1
var base_max: int = -1
var kill_max: int = 10

signal level_complete()
signal player_died()

func _ready() -> void:
	generate_level(level_width,level_height)
	tilemap.update_internals()
	spawn_player()
	match mode:
		"collect":
			orbs_collected.visible = true
			spawn_orbs()
		"destroy":
			bases_destroyed.visible = true
			spawn_bases()
		"kill":
			enemies_killed.visible = true
	spawn_ct_enemies()
	$EnemySpawnTimer.start(3)


func _enter_tree() -> void:
	$CounterContainer.visible = true
	
func _process(delta: float) -> void:
	match mode:
		"collect":
			orb_count.text = str(orb_max - $OrbContainer.get_child_count()) + " / " + str(orb_max)
			orb_count.global_position = Vector2(get_viewport().size.x / 2 - 100, get_viewport().size.y - 100)
			if $OrbContainer.get_child_count() == 0:
				
				emit_signal("level_complete")
		"destroy":
			base_count.text = str(base_max - $BaseContainer.get_child_count()) + " / " + str(base_max)
			base_count.global_position = Vector2(get_viewport().size.x / 2 - 100, get_viewport().size.y - 100)
			if $BaseContainer.get_child_count() == 0:
				emit_signal("level_complete")
		"kill":
			kill_count.text = str(enemy_container.kills) + " / " + str(kill_max)
			kill_count.global_position = Vector2(get_viewport().size.x / 2 - 100, get_viewport().size.y - 100)
			if enemy_container.kills == kill_max:
				emit_signal("level_complete")
	
func print_map(tile: Vector2i) -> void:
	for i in range(10*level_height):
		var line = ""
		for j in range(10*level_width): # true if floor, false otherwise
			line += (str("0" if tilemap.get_cell_source_id(Vector2i(j,i)) == 2 and tilemap.get_cell_atlas_coords(Vector2(j,i)) == Vector2i(0,0) else "1") + (" " if Vector2i(j,i) != tile else "<"))
		print(line)
	
func generate_level(width_chunks: int, height_chunks: int) -> void: # chunk dimensions are 10x10
	# generate maze to base chunks off of, in order to prevent chunks from being cut off
	var maze = generate_maze(level_width, level_height)
	# fill area with chunks
	for chunk_x in range(width_chunks):
		for chunk_y in range(height_chunks):
			place_random_chunk(chunk_x, chunk_y, maze)

			
	# create outline
	create_outline(width_chunks, height_chunks)
	
	# prevent navigation bugs
	var cur_used = tilemap.get_used_cells()
	while true:
		for x_val in range(width_chunks * 10 - 1):
			for y_val in range(height_chunks * 10 - 1):
				# floor tiles are 2, wall tiles are changed to 0
				var cur: int = tilemap.get_cell_source_id(Vector2(x_val, y_val)) if tilemap.get_cell_atlas_coords(Vector2(x_val, y_val)) == Vector2i(0,0) else 0
				var right: int = tilemap.get_cell_source_id(Vector2(x_val + 1, y_val)) if tilemap.get_cell_atlas_coords(Vector2(x_val + 1, y_val)) == Vector2i(0,0) else 0
				var down: int = tilemap.get_cell_source_id(Vector2(x_val, y_val + 1)) if tilemap.get_cell_atlas_coords(Vector2(x_val, y_val + 1)) == Vector2i(0,0) else 0
				var diag: int = tilemap.get_cell_source_id(Vector2(x_val + 1, y_val + 1)) if tilemap.get_cell_atlas_coords(Vector2(x_val + 1, y_val + 1)) == Vector2i(0,0) else 0
				var pattern: Array[int] = [cur, right, down, diag]
				
				if not is_valid(pattern):
					tilemap.set_cell(Vector2(x_val, y_val), 2, Vector2(0,1))
					tilemap.set_cell(Vector2(x_val + 1, y_val), 2, Vector2(0,1))
					tilemap.set_cell(Vector2(x_val, y_val + 1), 2, Vector2(0,1))
					tilemap.set_cell(Vector2(x_val + 1, y_val + 1), 2, Vector2(0,1))
		if cur_used == tilemap.get_used_cells():
			break
		else:
			cur_used = tilemap.get_used_cells()
	
func place_random_chunk(chunk_x: int, chunk_y: int, mazeref):
	var maze_walls_dict = mazeref[Vector2i(chunk_x, chunk_y)]
	var open_wall_indexes = []
	var dirs = ["N", "E", "S", "W"]
	for i in range(4):
		if not maze_walls_dict[dirs[i]]:
			open_wall_indexes.append(i)
	var used_cells: Array[Vector2i]
	var orb_cells: Array[Vector2i]
	var chunk: TileMapLayer
	var needs_2_walls = randi_range(0,1)
	
	# get valid chunk based on the maze walls
	while true:
		chunk = presets.get_children().pick_random()
		used_cells = chunk.get_used_cells()
		orb_cells = chunk.get_child(0).get_used_cells()
		
		# check direction availability, remove placeholders
		var walls = [false, false, false, false]
		if Vector2i(-2,-3) in used_cells:
			walls[0] = true
			used_cells.erase(Vector2i(-2, -3))
		if Vector2i(-1,-2) in used_cells:
			walls[1] = true
			used_cells.erase(Vector2i(-1, -2))
		if Vector2i(-2,-1) in used_cells:
			walls[2] = true
			used_cells.erase(Vector2i(-2, -1))
		if Vector2i(-3,-2) in used_cells:
			walls[3] = true
			used_cells.erase(Vector2i(-3, -2))
		
		# open_wall_indexes is the sides which must be open in the maze
		# walls is the sides of the current chunk
		# valid becomes false if and only if the current chunk
		# has a closed wall where there should be an open wall
		# basically, checks what sides should be open in the current chunk
		# and only breaks the loop if those sides are open
		var valid = true
		if len(open_wall_indexes) == 2 and walls.count(false) != 2 and needs_2_walls == 1: # 2 sided maze sections must have 2 sided chunks half the time
			valid = false
		for open_side in open_wall_indexes:
			if walls[open_side]:
				valid = false
		if valid:
			break
	
	for cell_pos in used_cells:
		var src_id = chunk.get_cell_source_id(cell_pos)
		var atlas_pos = chunk.get_cell_atlas_coords(cell_pos)
		var alt_id = chunk.get_cell_alternative_tile(cell_pos)
		tilemap.set_cell(cell_pos + Vector2i(chunk_x*10, chunk_y*10),src_id, atlas_pos, alt_id)
	
	if mode == "collect": # spawn orbs
		for cell_pos in orb_cells:
			orblayer.set_cell(cell_pos + Vector2i(chunk_x*10, chunk_y*10), 0, Vector2i(0,0))

func create_outline(width_chunks: int, height_chunks: int):
	for x_val in range(width_chunks * 10):
		tilemap.set_cell(Vector2(x_val, -1), 2, Vector2(0,1))
		tilemap.set_cell(Vector2(x_val, height_chunks * 10), 2, Vector2(0,1))
	for y_val in range(height_chunks * 10):
		tilemap.set_cell(Vector2(-1, y_val), 2, Vector2(0,1))
		tilemap.set_cell(Vector2(width_chunks*10, y_val), 2, Vector2(0,1))
	tilemap.set_cell(Vector2(-1,-1), 2, Vector2(0,1))
	tilemap.set_cell(Vector2(width_chunks*10,-1), 2, Vector2(0,1))
	tilemap.set_cell(Vector2(-1,height_chunks*10), 2, Vector2(0,1))
	tilemap.set_cell(Vector2(width_chunks*10,height_chunks*10), 2, Vector2(0,1))

func is_valid(pattern: Array[int]):
	if pattern.count(0) == 2 and pattern.count(4) == 0: # Exactly 2 walls and no diagonals
		if (pattern[0] == 0 and pattern[3] == 0) or (pattern[1] == 0 and pattern[2] == 0):
			return false # exactly 2 walls diagonal from each other
	if pattern.count(2) == 2 and pattern.count(4) != 2: # Exactly 2 floors
		if (pattern[0] == 2 and pattern[3] == 2) or (pattern[1] == 2 and pattern[2] == 2):
			return false # exactly 2 floors diagonal from each other
	return true

func generate_maze(maze_width: int, maze_height: int) -> Dictionary:
	var width = maze_width
	var height = maze_height
	
	var grid = {}
	for x in range(width):
		for y in range(height):
			grid[Vector2i(x,y)] = {"N": true, "S": true, "E": true, "W": true}
	
	var visited = []
	var stack = []
	
	var directions = {
		"N": [0, -1, "S"],
		"S": [0, 1, "N"],
		"E": [1, 0, "W"],
		"W": [-1, 0, "E"]
	}
	
	var current_cell = Vector2i(0,0)
	visited.append(current_cell)
	stack.append(current_cell)
	
	while stack:
		var x = current_cell.x
		var y = current_cell.y
		var unvisited_neighbors = []
		
		for dir in directions:
			var value = directions[dir]
			var neighbor = Vector2i(x + value[0], y + value[1])
			
			if (neighbor in grid) and (neighbor not in visited):
				unvisited_neighbors.append({"coords": neighbor, "dir": dir}) # opposite dir
				
		if unvisited_neighbors:
			var rand_neighbor = unvisited_neighbors.pick_random()
			
			grid[current_cell][rand_neighbor["dir"]] = false
			grid[rand_neighbor["coords"]][directions[rand_neighbor["dir"]][2]] = false
			
			visited.append(rand_neighbor["coords"])
			stack.append(rand_neighbor["coords"])
			current_cell = rand_neighbor["coords"]
		else:
			current_cell = stack.pop_back()
	return grid
	
func spawn_orbs() -> void:
	var orb_cells = orblayer.get_used_cells()
	var num_to_remove = len(orb_cells) - orb_percent * len(orb_cells)
	for i in range(num_to_remove):
		orb_cells.erase(orb_cells.pick_random())
	for cell_pos in orb_cells:
		if tilemap.get_cell_source_id(cell_pos) == 2 and tilemap.get_cell_atlas_coords(cell_pos) == Vector2i(0,0):
			var instance = ORB.instantiate()
			instance.position = Vector2(cell_pos.x * 64 + 32, cell_pos.y * 64 + 32)
			$OrbContainer.add_child(instance)
	orb_max = $OrbContainer.get_child_count()

func spawn_bases() -> void:
	var base_positions = []
	base_max = ceil(level_height * level_width / 10.0) + extra_base_num
	while len(base_positions) < base_max:
		# Pick random chunk
		var chunk_to_spawn = Vector2i(randi_range(0, level_width-1), randi_range(0, level_height-1))
		if chunk_to_spawn in base_positions or is_in_player_chunk(chunk_to_spawn):
			continue
		base_positions.append(chunk_to_spawn)
		var top_corner_pos = chunk_to_spawn*10
		# replace chunk with base
		for i in range(10):
			tilemap.set_cell(top_corner_pos +Vector2i(i,0),2,Vector2i(0,0))
			tilemap.set_cell(top_corner_pos +Vector2i(i,9),2,Vector2i(0,0))
			tilemap.set_cell(top_corner_pos +Vector2i(0,i),2,Vector2i(0,0))
			tilemap.set_cell(top_corner_pos +Vector2i(9,i),2,Vector2i(0,0))
		
		for i in range(8):
			tilemap.set_cell(top_corner_pos +Vector2i(i+1,1),1,Vector2i(0,0))
			tilemap.set_cell(top_corner_pos +Vector2i(i+1,8),1,Vector2i(0,0))
			tilemap.set_cell(top_corner_pos +Vector2i(1,i+1),1,Vector2i(0,0))
			tilemap.set_cell(top_corner_pos +Vector2i(8,i+1),1,Vector2i(0,0))

		for i in range(6):
			tilemap.set_cell(top_corner_pos +Vector2i(i+2,2),2,Vector2i(0,0))
			tilemap.set_cell(top_corner_pos +Vector2i(i+2,7),2,Vector2i(0,0))
			tilemap.set_cell(top_corner_pos +Vector2i(2,i+2),2,Vector2i(0,0))
			tilemap.set_cell(top_corner_pos +Vector2i(7,i+2),2,Vector2i(0,0))
		for i in range(4):
			tilemap.set_cell(top_corner_pos +Vector2i(i+3,3),1,Vector2i(0,0))
			tilemap.set_cell(top_corner_pos +Vector2i(i+3,6),1,Vector2i(0,0))
			tilemap.set_cell(top_corner_pos +Vector2i(3,i+3),1,Vector2i(0,0))
			tilemap.set_cell(top_corner_pos +Vector2i(6,i+3),1,Vector2i(0,0))
		tilemap.set_cell(top_corner_pos +Vector2i(4,4),2,Vector2i(0,0))
		tilemap.set_cell(top_corner_pos +Vector2i(4,5),2,Vector2i(0,0))
		tilemap.set_cell(top_corner_pos +Vector2i(5,4),2,Vector2i(0,0))
		tilemap.set_cell(top_corner_pos +Vector2i(5,5),2,Vector2i(0,0))

		
	# spawn enemies and add node
	for base_pos in base_positions:
		var base_node = BASE.instantiate()
		var top_corner_pos = base_pos*10
		var enemy_spawns = [Vector2(4,2),Vector2(5,2),Vector2(2,4),Vector2(2,5),Vector2(4,7),Vector2(5,7),Vector2(7,4),Vector2(7,5),Vector2(4,4),Vector2(4,5),Vector2(5,4),Vector2(5,5)]
		for enemy_pos in enemy_spawns:
			var instance = ENEMY.instantiate()
			#player,pos,enemy_container
			instance.position = Vector2((top_corner_pos.x * 64 + enemy_pos.x * 64) + 32,(top_corner_pos.y * 64 + enemy_pos.y * 64) + 32)
			instance.player = $Player_tank
			instance.enemy_container = base_node
			instance.activate_highlight()
			base_node.add_child(instance)
		$BaseContainer.add_child(base_node)

func is_in_player_chunk(chunk_to_check: Vector2i):
	var player_chunk = Vector2i(floor(spawn_tile.x/10.0), floor(spawn_tile.y/10))
	if player_chunk == chunk_to_check:
		return true
	return false
	
func spawn_player() -> void:
	var instance = PLAYER.instantiate()
	tilemap.update_internals()
	while true:
		var tile = Vector2i(randi_range(1,level_width*10), randi_range(1, level_height*10)+1)
		if tilemap.get_cell_source_id(tile) == 2 and tilemap.get_cell_atlas_coords(tile) == Vector2i(0,0):
			instance.position = Vector2(tile.x * 64 + 32, tile.y * 64 + 32)
			spawn_tile = tile
			#print_map(tile)
			break
			
	instance.max_health = player_maxhealth
	instance.speed = player_speed
	instance.max_bullets = player_max_bullets
	instance.max_secondary = player_max_secondary
	instance.enemy_container = enemy_container
	instance.xp = 0
	instance.level_threshold = 6
	instance.player_died.connect(death)
	add_child(instance)

func death() -> void:
	emit_signal("player_died")

func spawn_ct_enemies() -> void:
	print(ct_enemies)
	for enemy in ct_enemies:
		match enemy:
			"artillery":
				var instance = ARTILLERY.instantiate()
				tilemap.update_internals()
				#while true:
				var player = get_child(get_children().find(CharacterBody2D))
				var player_tile = tilemap.local_to_map(to_local(player.position + Vector2(randi_range(300,800),0).rotated(randf_range(0,2*PI))))
				while tilemap.get_cell_source_id(player_tile) != 2 or tilemap.get_cell_atlas_coords(player_tile) != Vector2i(0,0):
					player_tile = tilemap.local_to_map(to_local(player.position + Vector2(randi_range(300,800),0).rotated(randf_range(0,2*PI))))
				instance.position = Vector2(player_tile.x * 64 + 32, player_tile.y * 64 + 32)
				instance.player = $Player_tank
				instance.enemy_container = enemy_container
				enemy_container.add_child(instance)
			"railgun":
				var instance = RAILGUN.instantiate()
				tilemap.update_internals()
				#while true:
				var player = get_child(get_children().find(CharacterBody2D))
				var player_tile = tilemap.local_to_map(to_local(player.position + Vector2(randi_range(300,800),0).rotated(randf_range(0,2*PI))))
				while tilemap.get_cell_source_id(player_tile) != 2 or tilemap.get_cell_atlas_coords(player_tile) != Vector2i(0,0):
					player_tile = tilemap.local_to_map(to_local(player.position + Vector2(randi_range(300,800),0).rotated(randf_range(0,2*PI))))
				instance.position = Vector2(player_tile.x * 64 + 32, player_tile.y * 64 + 32)
				instance.player = $Player_tank
				instance.enemy_container = enemy_container
				enemy_container.add_child(instance)
			"heli":
				var instance = HELI.instantiate()
				tilemap.update_internals()
				#while true:
				var player = get_child(get_children().find(CharacterBody2D))
				var player_tile = tilemap.local_to_map(to_local(player.position + Vector2(randi_range(300,800),0).rotated(randf_range(0,2*PI))))
				while tilemap.get_cell_source_id(player_tile) != 2 or tilemap.get_cell_atlas_coords(player_tile) != Vector2i(0,0):
					player_tile = tilemap.local_to_map(to_local(player.position + Vector2(randi_range(300,800),0).rotated(randf_range(0,2*PI))))
				instance.position = Vector2(player_tile.x * 64 + 32, player_tile.y * 64 + 32)
				instance.player = $Player_tank
				instance.enemy_container = enemy_container
				enemy_container.add_child(instance)
			"blitzer":
				var instance = BLITZER.instantiate()
				tilemap.update_internals()
				#while true:
				var player = get_child(get_children().find(CharacterBody2D))
				var player_tile = tilemap.local_to_map(to_local(player.position + Vector2(randi_range(300,800),0).rotated(randf_range(0,2*PI))))
				while tilemap.get_cell_source_id(player_tile) != 2 or tilemap.get_cell_atlas_coords(player_tile) != Vector2i(0,0):
					player_tile = tilemap.local_to_map(to_local(player.position + Vector2(randi_range(300,800),0).rotated(randf_range(0,2*PI))))
				instance.position = Vector2(player_tile.x * 64 + 32, player_tile.y * 64 + 32)
				instance.player = $Player_tank
				instance.enemy_container = enemy_container
				enemy_container.add_child(instance)

func _on_enemy_spawn_timer_timeout() -> void:
	if enemy_container.get_child_count() >= spawn_cap:
		$EnemySpawnTimer.start(enemy_spawn_time)
		return
	var instance = ENEMY.instantiate()
	tilemap.update_internals()
	#while true:
	var player = get_child(get_children().find(CharacterBody2D))
	var player_tile = tilemap.local_to_map(to_local(player.position + Vector2(randi_range(500,800),0).rotated(randf_range(0,2*PI))))
	var attempts = 0
	while tilemap.get_cell_source_id(player_tile) != 2 or tilemap.get_cell_atlas_coords(player_tile) != Vector2i(0,0):
		attempts += 1
		if attempts > 100:
			return
		player_tile = tilemap.local_to_map(to_local(player.position + Vector2(randi_range(500,800),0).rotated(randf_range(0,2*PI))))
	
	instance.position = Vector2(player_tile.x * 64 + 32, player_tile.y * 64 + 32)
	instance.maxhealth = enemy_health
	instance.speed = 50
	instance.player = $Player_tank
	instance.turn_speed = 20
	instance.max_bullets = 5
	instance.fire_rate = enemy_fire_rate
	instance.damage = enemy_damage
	instance.enemy_container = enemy_container
	enemy_container.add_child(instance)
	if mode == "kill":
		$EnemySpawnTimer.start(enemy_spawn_time)
	else:
		$EnemySpawnTimer.start(enemy_spawn_time * 2)

func pause_on_complete() -> void:
	$Player_tank.process_mode = Node.PROCESS_MODE_DISABLED
	enemy_container.process_mode = Node.PROCESS_MODE_DISABLED

func get_score() -> int:
	match mode:
		"kill":
			return enemy_container.kills
		"destroy":
			return (base_max - $BaseContainer.get_child_count()) * 20 + ceil(enemy_container.kills / 4.0)
		"collect":
			return (orb_max - $OrbContainer.get_child_count()) + ceil(enemy_container.kills / 4.0)
		_:
			return 0
		
		
		
		
		
