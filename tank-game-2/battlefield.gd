extends Node2D

const PLAYER = preload("res://player_tank.tscn")
const ENEMY = preload("res://default_tank.tscn")

@onready var presets = $MapGenerationPresets
@onready var tilemap = $TileMapLayer
@onready var enemy_container = $Enemy_Container

@export var level_width = 10
@export var level_height = 10

@export var player_maxhealth: float
@export var player_speed: float
@export var player_max_bullets: int
@export var player_max_secondary: int



func _ready() -> void:
	generate_level(10,10)
	tilemap.update_internals()
	spawn_player()
	$EnemySpawnTimer.start(3)
	
	
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
		for x_val in range(width_chunks * level_width - 1):
			for y_val in range(height_chunks * level_height - 1):
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
	var chunk: TileMapLayer
	
	# get valid chunk based on the maze walls
	while true:
		chunk = presets.get_children().pick_random()
		used_cells = chunk.get_used_cells()
		
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

func create_outline(width_chunks: int, height_chunks: int):
	for x_val in range(width_chunks * level_width):
		tilemap.set_cell(Vector2(x_val, -1), 2, Vector2(0,1))
		tilemap.set_cell(Vector2(x_val, height_chunks * level_height), 2, Vector2(0,1))
	for y_val in range(height_chunks * level_width):
		tilemap.set_cell(Vector2(-1, y_val), 2, Vector2(0,1))
		tilemap.set_cell(Vector2(width_chunks*level_width, y_val), 2, Vector2(0,1))
	tilemap.set_cell(Vector2(-1,-1), 2, Vector2(0,1))
	tilemap.set_cell(Vector2(width_chunks*level_width,-1), 2, Vector2(0,1))
	tilemap.set_cell(Vector2(-1,height_chunks*level_height), 2, Vector2(0,1))
	tilemap.set_cell(Vector2(width_chunks*level_width,height_chunks*level_height), 2, Vector2(0,1))

func is_valid(pattern: Array[int]):
	if pattern.count(0) == 2 and pattern.count(4) == 0: # Exactly 2 walls and no diagonals
		if (pattern[0] == 0 and pattern[3] == 0) or (pattern[1] == 0 and pattern[2] == 0):
			return false # exactly 2 walls diagonal from each other
	if pattern.count(2) == 2 and pattern.count(4) == 0: # Exactly 2 floors
		if (pattern[0] == 2 and pattern[3] == 2) or (pattern[1] == 2 and pattern[2] == 2):
			return false # exactly 2 floors diagonal from each other
	return true

func generate_maze(maze_width: int, maze_height: int):
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
	
func spawn_player() -> void:
	var instance = PLAYER.instantiate()
	while true:
		var chunk_x = randi_range(1,level_width)
		var chunk_y = randi_range(1,level_height)
		instance.position = NavigationServer2D.map_get_closest_point(get_viewport().get_world_2d().navigation_map, Vector2(chunk_x*10*64 - 32, chunk_y*10*64 - 32))
		if (instance.position.x == 0.0 and instance.position.y == 0.0):
			await get_tree().create_timer(0.001).timeout
			continue
		else:
			break
			
	instance.max_health = player_maxhealth
	instance.speed = player_speed
	instance.max_bullets = player_max_bullets
	instance.max_secondary = player_max_secondary
	instance.enemy_container = enemy_container
	add_child(instance)


func _on_enemy_spawn_timer_timeout() -> void:
	var instance = ENEMY.instantiate()
	while true:
		var chunk_x = randi_range(1,level_width)
		var chunk_y = randi_range(1,level_height)
		instance.position = NavigationServer2D.map_get_closest_point(get_viewport().get_world_2d().navigation_map, Vector2(chunk_x*10*64 - 32, chunk_y*10*64 - 32))
		if (instance.position.x == 0.0 and instance.position.y == 0.0):
			await get_tree().create_timer(0.001).timeout
			continue
		else:
			break
	instance.maxhealth = 3
	instance.speed = 100
	instance.player = $Player_tank
	instance.turn_speed = 10
	instance.max_bullets = 5
	enemy_container.add_child(instance)
	$EnemySpawnTimer.start(5)
