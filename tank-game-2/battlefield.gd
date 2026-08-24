class_name Battlefield
extends Node2D

const PLAYER = preload("res://player_tank.tscn")
const ENEMY = preload("res://default_tank.tscn")

const ORB = preload("res://orb.tscn")
const BASE = preload("res://enemy_base.tscn")

const GOLFHOLE = preload("res://golf_hole.tscn")
const GOLFBALL = preload("res://golf_ball.tscn")

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
@onready var balls_scored = $CounterContainer/BallsScored
@onready var score_count = $CounterContainer/BallsScored/ScoreCount

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

var curses: Array[String] = []

var event: String = "none"

var ct_enemies: Array[String] = []
var spawn_tile = Vector2i(0,0)

var enemy_spawn_time = 5
var enemy_health = 1
var enemy_fire_rate = 1
var enemy_damage = 1

var orb_max: int = -1
var base_max: int = -1
var kill_max: int = 10
var balls_to_spawn: int = 0

var base_chunks: Array[Vector2i] = []

var enemies_frozen = false

signal level_complete()
signal player_died()

func _ready() -> void:
	base_max = ceil(level_height * level_width / 10.0) + extra_base_num
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
		"golf":
			balls_scored.visible = true
			spawn_golf()
	spawn_ct_enemies()
	if event == "Nearsighted":
		$ScreenEffectsEvents.apply_nearsight()
	elif event == "Farsighted":
		$ScreenEffectsEvents.apply_farsight()
	elif event == "Snow":
		$ScreenEffectsEvents.apply_snow()
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
			if enemy_container.kills >= kill_max:
				emit_signal("level_complete")
		"golf":
			score_count.text = str(balls_to_spawn - $GolfContainer/BallContainer.get_child_count()) + " / " + str(balls_to_spawn)
			score_count.global_position = Vector2(get_viewport().size.x / 2 - 100, get_viewport().size.y - 100)
			if $GolfContainer/BallContainer.get_child_count() == 0:
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
	base_chunks = []
	if mode == "destroy":
		while len(base_chunks) < base_max:
			var base_to_add = Vector2i(randi_range(0,width_chunks-1),randi_range(0,height_chunks-1))
			if base_to_add not in base_chunks:
				base_chunks.append(base_to_add)
			else:
				continue
	# fill area with chunks
	for chunk_x in range(width_chunks):
		for chunk_y in range(height_chunks):
			if Vector2i(chunk_x,chunk_y) in base_chunks:
				fill_with_floor(chunk_x, chunk_y)
			else:
				place_random_chunk(chunk_x, chunk_y, maze)

			
	# create outline
	create_outline(width_chunks, height_chunks)
	
	# prevent navigation bugs
	var cur_used = tilemap.get_used_cells()
	var added_tiles = []
	while true:
		for x_val in range(width_chunks * 10 - 1):
			for y_val in range(height_chunks * 10 - 1):
				# floor tiles are 2, wall tiles are changed to 0
				var cur: int = tilemap.get_cell_source_id(Vector2(x_val, y_val))
				var right: int = tilemap.get_cell_source_id(Vector2(x_val + 1, y_val))
				var down: int = tilemap.get_cell_source_id(Vector2(x_val, y_val + 1))
				var diag: int = tilemap.get_cell_source_id(Vector2(x_val + 1, y_val + 1))
				var pattern: Array[int] = [cur, right, down, diag]
				if not is_valid(pattern):
					added_tiles.append(Vector2(x_val, y_val))
					added_tiles.append(Vector2(x_val + 1, y_val))
					added_tiles.append(Vector2(x_val, y_val + 1))
					added_tiles.append(Vector2(x_val + 1, y_val + 1))
		if cur_used == tilemap.get_used_cells():
			break
		else:
			cur_used = tilemap.get_used_cells()
	tilemap.set_cells_terrain_connect(added_tiles,0,0)
	
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
	
	var wall_cells_to_paint: Array[Vector2i] = []
	var diagonals_to_paint: Array[Vector2i] = []
	var cracked_tiles_to_add: Array[Vector2i] = []
	var floors_to_add: Array[Vector2i] = []
	
	for cell_pos in used_cells:
		var src_id = chunk.get_cell_source_id(cell_pos)
		var atlas_pos = chunk.get_cell_atlas_coords(cell_pos)
		var alt_id = chunk.get_cell_alternative_tile(cell_pos)
		
		tilemap.set_cell(cell_pos + Vector2i(chunk_x * 10, chunk_y * 10),src_id,atlas_pos,alt_id)
		
		"""
		if src_id == 4:
			print(chunk.name)
			print(cell_pos)
			print(src_id)
			print(alt_id)
		
		
		#0 = regular, bottom left
		#12288 = top right
		#24576 = bottom right
		#20480 = top left
		
		
		if src_id == 2 and atlas_pos == Vector2i(0,0):
			#src_id = 0
			floors_to_add.append(cell_pos)
		elif src_id == 2 and atlas_pos == Vector2i(0,1):
			#src_id = 1
			wall_cells_to_paint.append(cell_pos)
		elif src_id == 1:
			#src_id = 3
			cracked_tiles_to_add.append(cell_pos)
		elif src_id == 4:
			#src_id = 2
			wall_cells_to_paint.append(cell_pos)
			diagonals_to_paint.append(cell_pos)
		
	
		
		
	#tilemap.set_cell(cell_pos + Vector2i(chunk_x*10, chunk_y*10),src_id, atlas_pos, alt_id)
	var global_wall_coords = []
	for coord in wall_cells_to_paint:
		global_wall_coords.append(coord + Vector2i(chunk_x*10, chunk_y*10))

	tilemap.set_cells_terrain_connect(global_wall_coords, 0, 0) # add walls
	for cell_pos in floors_to_add: # add floors
		tilemap.set_cell(cell_pos + Vector2i(chunk_x*10, chunk_y*10),0, Vector2i(randi_range(0,2),0))
	for diagonal_pos in diagonals_to_paint: # add diagonals manually turned
		match chunk.get_cell_alternative_tile(diagonal_pos):
			0: # bottom left
				if are_walls_or_diagonals(chunk, diagonal_pos, [Vector2i(-1,0), Vector2i(-1,1),Vector2i(0,1)]):
					tilemap.set_cell(diagonal_pos + Vector2i(chunk_x*10, chunk_y*10),2,Vector2i(0,0))
				elif are_walls_or_diagonals(chunk, diagonal_pos, [Vector2i(-1,0), Vector2i(0,1)]):
					tilemap.set_cell(diagonal_pos + Vector2i(chunk_x*10, chunk_y*10),2,Vector2i(1,0))
				elif are_walls_or_diagonals(chunk, diagonal_pos, [Vector2i(0,1)]):
					tilemap.set_cell(diagonal_pos + Vector2i(chunk_x*10, chunk_y*10),2,Vector2i(2,0))
				elif are_walls_or_diagonals(chunk,diagonal_pos, [Vector2i(-1,0)]):
					tilemap.set_cell(diagonal_pos + Vector2i(chunk_x*10, chunk_y*10),2,Vector2i(3,0))
			12288: # top right
				if are_walls_or_diagonals(chunk, diagonal_pos, [Vector2i(1,0), Vector2i(1,-1),Vector2i(0,-1)]):
					tilemap.set_cell(diagonal_pos + Vector2i(chunk_x*10, chunk_y*10),2,Vector2i(0,3))
				elif are_walls_or_diagonals(chunk, diagonal_pos, [Vector2i(1,0), Vector2i(0,-1)]):
					tilemap.set_cell(diagonal_pos + Vector2i(chunk_x*10, chunk_y*10),2,Vector2i(1,3))
				elif are_walls_or_diagonals(chunk, diagonal_pos, [Vector2i(0,-1)]):
					tilemap.set_cell(diagonal_pos + Vector2i(chunk_x*10, chunk_y*10),2,Vector2i(2,3))
				elif are_walls_or_diagonals(chunk,diagonal_pos, [Vector2i(1,0)]):
					tilemap.set_cell(diagonal_pos + Vector2i(chunk_x*10, chunk_y*10),2,Vector2i(3,3))
			20480: # top left
				if are_walls_or_diagonals(chunk, diagonal_pos, [Vector2i(-1,0), Vector2i(-1,-1),Vector2i(0,-1)]):
					tilemap.set_cell(diagonal_pos + Vector2i(chunk_x*10, chunk_y*10),2,Vector2i(0,2))
				elif are_walls_or_diagonals(chunk, diagonal_pos, [Vector2i(-1,0), Vector2i(0,-1)]):
					tilemap.set_cell(diagonal_pos + Vector2i(chunk_x*10, chunk_y*10),2,Vector2i(1,2))
				elif are_walls_or_diagonals(chunk, diagonal_pos, [Vector2i(0,-1)]):
					tilemap.set_cell(diagonal_pos + Vector2i(chunk_x*10, chunk_y*10),2,Vector2i(2,2))
				elif are_walls_or_diagonals(chunk,diagonal_pos, [Vector2i(-0,0)]):
					tilemap.set_cell(diagonal_pos + Vector2i(chunk_x*10, chunk_y*10),2,Vector2i(3,2))
			24576: # bottom right
				if are_walls_or_diagonals(chunk, diagonal_pos, [Vector2i(1,0), Vector2i(1,1),Vector2i(0,1)]):
					tilemap.set_cell(diagonal_pos + Vector2i(chunk_x*10, chunk_y*10),2,Vector2i(1,1))
				elif are_walls_or_diagonals(chunk, diagonal_pos, [Vector2i(1,0), Vector2i(0,1)]):
					tilemap.set_cell(diagonal_pos + Vector2i(chunk_x*10, chunk_y*10),2,Vector2i(2,1))
				elif are_walls_or_diagonals(chunk, diagonal_pos, [Vector2i(0,1)]):
					tilemap.set_cell(diagonal_pos + Vector2i(chunk_x*10, chunk_y*10),2,Vector2i(3,1))
				elif are_walls_or_diagonals(chunk,diagonal_pos, [Vector2i(1,0)]):
					tilemap.set_cell(diagonal_pos + Vector2i(chunk_x*10, chunk_y*10),2,Vector2i(0,1))
	print(cracked_tiles_to_add)
	for cracked_pos in cracked_tiles_to_add: # add crates
		tilemap.set_cell(cracked_pos + Vector2i(chunk_x*10, chunk_y*10),3, Vector2i(0,0))
	"""
	
	#tilemap.set_cells_terrain_connect()
	
	if mode == "collect": # spawn orbs
		for cell_pos in orb_cells:
			orblayer.set_cell(cell_pos + Vector2i(chunk_x*10, chunk_y*10), 0, Vector2i(0,0))

func fill_with_floor(chunk_x: int, chunk_y: int):
	for i in range(10):
		for j in range(10):
			tilemap.set_cell(Vector2i(chunk_x*10 + i, chunk_y*10 + j),0,Vector2i(randi_range(0,2),0))

func are_walls_or_diagonals(chunk, diagonal_pos, rel_coords_to_check) -> bool:
	for coord in rel_coords_to_check:
		if chunk.get_cell_source_id(diagonal_pos) != 2 and chunk.get_cell_source_id(diagonal_pos) != 4:
			return false
		elif chunk.get_cell_source_id(diagonal_pos) == 2 and chunk.get_cell_atlas_pos(diagonal_pos) == Vector2i(0,0):
			return false
	return true

func create_outline(width_chunks: int, height_chunks: int):
	for x_val in range(width_chunks * 10):
		tilemap.set_cell(Vector2(x_val, -1), 1, Vector2(1,0))
		tilemap.set_cell(Vector2(x_val, height_chunks * 10), 1, Vector2(1,0))
	for y_val in range(height_chunks * 10):
		tilemap.set_cell(Vector2(-1, y_val), 1, Vector2(3,5))
		tilemap.set_cell(Vector2(width_chunks*10, y_val), 1, Vector2(3,5))
	tilemap.set_cell(Vector2(-1,-1), 1, Vector2(5,7))
	tilemap.set_cell(Vector2(width_chunks*10,-1), 1, Vector2(0,8))
	tilemap.set_cell(Vector2(-1,height_chunks*10), 1, Vector2(5,6))
	tilemap.set_cell(Vector2(width_chunks*10,height_chunks*10), 1, Vector2(0,7))
	
func is_valid(pattern: Array[int]):
	if pattern.count(1) == 2 and pattern.count(2) == 0: # Exactly 2 walls and no diagonals
		if (pattern[0] == 1 and pattern[3] == 1) or (pattern[1] == 1 and pattern[2] == 1):
			return false # exactly 2 walls diagonal from each other
	if pattern.count(0) == 2 and pattern.count(2) != 2: # Exactly 2 floors
		if (pattern[0] == 0 and pattern[3] == 0) or (pattern[1] == 0 and pattern[2] == 0):
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
	for base_pos in base_chunks:
		# Pick random chunk
		var top_corner_pos = base_pos*10
		# replace chunk with base
		for i in range(10):
			tilemap.set_cell(top_corner_pos +Vector2i(i,0),0,Vector2i(randi_range(0,2),0))
			tilemap.set_cell(top_corner_pos +Vector2i(i,9),0,Vector2i(randi_range(0,2),0))
			tilemap.set_cell(top_corner_pos +Vector2i(0,i),0,Vector2i(randi_range(0,2),0))
			tilemap.set_cell(top_corner_pos +Vector2i(9,i),0,Vector2i(randi_range(0,2),0))
		
		for i in range(8):
			tilemap.set_cell(top_corner_pos +Vector2i(i+1,1),3,Vector2i(0,0))
			tilemap.set_cell(top_corner_pos +Vector2i(i+1,8),3,Vector2i(0,0))
			tilemap.set_cell(top_corner_pos +Vector2i(1,i+1),3,Vector2i(0,0))
			tilemap.set_cell(top_corner_pos +Vector2i(8,i+1),3,Vector2i(0,0))

		for i in range(6):
			tilemap.set_cell(top_corner_pos +Vector2i(i+2,2),0,Vector2i(randi_range(0,2),0))
			tilemap.set_cell(top_corner_pos +Vector2i(i+2,7),0,Vector2i(randi_range(0,2),0))
			tilemap.set_cell(top_corner_pos +Vector2i(2,i+2),0,Vector2i(randi_range(0,2),0))
			tilemap.set_cell(top_corner_pos +Vector2i(7,i+2),0,Vector2i(randi_range(0,2),0))
		for i in range(4):
			tilemap.set_cell(top_corner_pos +Vector2i(i+3,3),3,Vector2i(0,0))
			tilemap.set_cell(top_corner_pos +Vector2i(i+3,6),3,Vector2i(0,0))
			tilemap.set_cell(top_corner_pos +Vector2i(3,i+3),3,Vector2i(0,0))
			tilemap.set_cell(top_corner_pos +Vector2i(6,i+3),3,Vector2i(0,0))
		tilemap.set_cell(top_corner_pos +Vector2i(4,4),0,Vector2i(randi_range(0,2),0))
		tilemap.set_cell(top_corner_pos +Vector2i(4,5),0,Vector2i(randi_range(0,2),0))
		tilemap.set_cell(top_corner_pos +Vector2i(5,4),0,Vector2i(randi_range(0,2),0))
		tilemap.set_cell(top_corner_pos +Vector2i(5,5),0,Vector2i(randi_range(0,2),0))

		
	# spawn enemies and add node
	for base_pos in base_chunks:
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

func spawn_golf() -> void:
	#spawn hole
	var open_cells = tilemap.get_used_cells_by_id(0)
	open_cells.erase(spawn_tile)
	var hole_spawn = open_cells.pick_random()
	open_cells.erase(hole_spawn)
	
	var instance = GOLFHOLE.instantiate()
	instance.position = Vector2(hole_spawn.x * 64 + 32, hole_spawn.y * 64 + 32)
	$GolfContainer.add_child(instance)
	
	# spawn balls
	balls_to_spawn = ceil((level_width + level_height) / 2)
	for i in range(balls_to_spawn):
		var ball_spawn = open_cells.pick_random()
		var ball_instance = GOLFBALL.instantiate()
		ball_instance.position = Vector2(ball_spawn.x * 64 + 32, ball_spawn.y * 64 + 32)
		$GolfContainer/BallContainer.add_child(ball_instance)


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
		if tilemap.get_cell_source_id(tile) == 0:
			instance.position = Vector2(tile.x * 64 + 32, tile.y * 64 + 32)
			spawn_tile = tile
			#print_map(tile)
			break
			
	instance.max_health = player_maxhealth
	instance.speed = player_speed
	if event == "Low Ammo":
		instance.max_bullets = 5
		instance.max_secondary = 2
	else:
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
	print(curses)
	var open_cells = tilemap.get_used_cells_by_id(0)
	open_cells.erase(spawn_tile)
	for enemy in ct_enemies:
		match enemy:
			"artillery":
				var instance = ARTILLERY.instantiate()
				tilemap.update_internals()
				#while true:
				var player = get_child(get_children().find(CharacterBody2D))
				var player_tile = open_cells.pick_random()
				open_cells.erase(player_tile)
				instance.position = Vector2(player_tile.x * 64 + 32, player_tile.y * 64 + 32)
				instance.player = $Player_tank
				instance.enemy_container = enemy_container
				instance.curses = curses
				enemy_container.add_child(instance)
				
			"railgun":
				var instance = RAILGUN.instantiate()
				tilemap.update_internals()
				#while true:
				var player = get_child(get_children().find(CharacterBody2D))
				var player_tile = open_cells.pick_random()
				open_cells.erase(player_tile)
				instance.position = Vector2(player_tile.x * 64 + 32, player_tile.y * 64 + 32)
				instance.player = $Player_tank
				instance.enemy_container = enemy_container
				instance.curses = curses
				enemy_container.add_child(instance)
			"heli":
				var instance = HELI.instantiate()
				tilemap.update_internals()
				#while true:
				var player = get_child(get_children().find(CharacterBody2D))
				var player_tile = open_cells.pick_random()
				open_cells.erase(player_tile)
				instance.position = Vector2(player_tile.x * 64 + 32, player_tile.y * 64 + 32)
				instance.player = $Player_tank
				instance.enemy_container = enemy_container
				instance.curses = curses
				enemy_container.add_child(instance)
			"blitzer":
				var instance = BLITZER.instantiate()
				tilemap.update_internals()
				#while true:
				var player = get_child(get_children().find(CharacterBody2D))
				var player_tile = open_cells.pick_random()
				open_cells.erase(player_tile)
				instance.position = Vector2(player_tile.x * 64 + 32, player_tile.y * 64 + 32)
				instance.player = $Player_tank
				instance.enemy_container = enemy_container
				instance.curses = curses
				enemy_container.add_child(instance)


func freeze_enemies(time:float,freeze_bullets:bool=false):
	enemies_frozen = true
	$FreezeTimer.start(time)
	for bullet in $BulletContainer.get_children():
		if bullet is not GPUParticles2D:
			bullet.freeze(time)
	$Enemy_Container.freeze_enemies(time,freeze_bullets)

func _on_enemy_spawn_timer_timeout() -> void:
	if enemies_frozen:
		$EnemySpawnTimer.start(enemy_spawn_time)
		return
	if enemy_container.get_child_count() >= spawn_cap:
		$EnemySpawnTimer.start(enemy_spawn_time)
		return
	var instance = ENEMY.instantiate()
	tilemap.update_internals()
	#while true:
	var player = get_child(get_children().find(CharacterBody2D))
	var player_tile = tilemap.local_to_map(to_local(player.position + Vector2(randi_range(300,800),0).rotated(randf_range(0,2*PI))))
	var attempts = 0
	while tilemap.get_cell_source_id(player_tile) != 0:
		attempts += 1
		if attempts > 100:
			return
		player_tile = tilemap.local_to_map(to_local(player.position + Vector2(randi_range(300,800),0).rotated(randf_range(0,2*PI))))
	
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
	elif mode == "destroy":
		$EnemySpawnTimer.start(enemy_spawn_time * 2)
	elif mode == "collect":
		$EnemySpawnTimer.start(1) # CHANGE BACKKK
	elif mode == "golf":
		$EnemySpawnTimer.start(enemy_spawn_time * 5)

func pause_on_complete() -> void:
	$Player_tank.process_mode = Node.PROCESS_MODE_DISABLED
	enemy_container.process_mode = Node.PROCESS_MODE_DISABLED

func get_score() -> int:
	match mode:
		"kill":
			return enemy_container.kills * 10
		"destroy":
			return (base_max - $BaseContainer.get_child_count()) * 50 + ceil(enemy_container.kills * 3)
		"collect":
			return (orb_max - $OrbContainer.get_child_count()) + ceil(enemy_container.kills * 3)
		"golf":
			return (balls_to_spawn - $GolfContainer/BallContainer.get_child_count()) * 30 + ceil(enemy_container.kills * 3)
		_:
			return 0



func _on_freeze_timer_timeout() -> void:
	enemies_frozen = false
