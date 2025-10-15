extends Node

@export var wfc_constraints: WFCResource
@export var grid_map: GridMap
@export var grid_size: Vector3i


enum CheckDirections { up, down, left, right, forward, back }
var propogate_check_directions: Dictionary[CheckDirections, Vector3i]= {
	CheckDirections.up: Vector3i.UP,
	CheckDirections.down: Vector3i.DOWN,
	CheckDirections.left: Vector3i.LEFT,
	CheckDirections.right: Vector3i.RIGHT,
	CheckDirections.forward: Vector3i.FORWARD,
	CheckDirections.back: Vector3i.BACK,
}


# position of tile along with array of available tiles
var tiles: Dictionary[Vector3i, Array] = {}
var smallest_collapse_size: int = 1000
var smallest_collapses: Array[Vector3i]
var max_iter: int = 200
var iter: int = 0


func _on_button_pressed() -> void:
	wfc()
	create_visual()


#region WFC
func wfc() -> void:
	tiles.clear()
	iter = 0
	initialize()
	
	var start_tile: String = "start"
	var start_rand_pos: Vector3i = random_vector3i(grid_size)
	tiles[start_rand_pos] = [start_tile]
	
	propogate(start_rand_pos)
	
	collapse_wave_function()


func initialize() -> void:
	var array_of_available_tiles = wfc_constraints.rules.keys()
	array_of_available_tiles.append("Empty")
	for x in range(grid_size.x):
		for z in range(grid_size.z):
			for y in range(grid_size.y):
				tiles[Vector3i(x, y, z)] =  array_of_available_tiles.duplicate()


func collapse_wave_function() -> void:
	var fully_collapsed: bool = false
	
	while !fully_collapsed:
		iter += 1
		
		if iter > max_iter:
			printerr("Didn't collapse after ", max_iter, " iterations.")
			print("Tiles uncolapesed count: ", count_uncollapsed())
			return
		
		update_smallest_collapses()
		
		if smallest_collapses.is_empty():
			print("Fully collapsed after ", iter, " iterations")
			fully_collapsed = true
			continue
		
		
		# gets random lowest entropy cell
		var rand_int = randi_range(0, smallest_collapses.size() - 1)
		var lowest_entropy_cell: Vector3i = smallest_collapses[rand_int]
		
		
		
		collapse(lowest_entropy_cell)
		propogate(lowest_entropy_cell)
	
	print(tiles)


func update_smallest_collapses() -> void:
	#smallest_collapses.clear()
	#smallest_collapse_size = 1000
	#
	#for direction in CheckDirections.values():
		#var pos: Vector3i = propogate_check_directions[direction] + index
		#
		#if pos.x < 0 or pos.x >= grid_size.x: continue
		#if pos.y < 0 or pos.y >= grid_size.y: continue
		#if pos.z < 0 or pos.z >= grid_size.z: continue
		#
		#var tile_count = tiles[pos].size()
		#
		#
		#if tile_count < smallest_collapse_size:
			#smallest_collapse_size = tile_count
			#smallest_collapses = [pos]
		#elif tile_count == smallest_collapse_size:
			#smallest_collapses.append(pos)
	
	
	
	
	smallest_collapses.clear()
	smallest_collapse_size = 10000
	
	for pos in tiles.keys():
		var tile_count = tiles[pos].size()
		
		# Skip already collapsed tiles (size == 1)
		
		if tile_count <= 1:
			continue
			
		if tile_count < smallest_collapse_size:
			smallest_collapse_size = tile_count
			smallest_collapses = [pos]
		elif tile_count == smallest_collapse_size:
			smallest_collapses.append(pos)



func propogate(index: Vector3i) -> void:
	var queue: Array[Vector3i] = [index]
	var visited: Dictionary = {}
	
	while !queue.is_empty():
		var current_pos = queue.pop_front()
		
		if visited.has(current_pos):
			continue
		visited[current_pos] = true
	
		for direction in CheckDirections.values():
			var checking_pos = index + propogate_check_directions[direction]
			
			if checking_pos.x < 0 or checking_pos.x >= grid_size.x: continue
			if checking_pos.y < 0 or checking_pos.y >= grid_size.y: continue
			if checking_pos.z < 0 or checking_pos.z >= grid_size.z: continue
			
			#if tiles[checking_pos].size() == 1:
				#continue
			
			# pass
			var possible_tiles = get_possible_tiles_for_neighbor(index, direction)
			
			var new_tiles = intersect_arrays(tiles[checking_pos], possible_tiles)
			
			if new_tiles.size() < tiles[checking_pos].size():
				tiles[checking_pos] = new_tiles
				
				# Add neighbor to queue if it needs further propagation
				if !visited.has(checking_pos):
					queue.append(checking_pos)


func collapse(index: Vector3i) -> void:
	var size = tiles[index].size()
	var collapsed_tile = tiles[index][randi_range(0, size - 1)]
	tiles[index] = [collapsed_tile]


func intersect_arrays(array1: Array, array2: Array) -> Array:
	var result: Array = []
	for item in array1:
		if array2.has(item):
			result.append(item)
	return result


#endregion


func create_visual() -> void:
	grid_map.clear()
	for x:int in range(grid_size.x):
		for z:int in range(grid_size.z):
			for y:int in range(grid_size.y):
				if !tiles.has(Vector3i(x,y,z)):
					continue
				
				var item: Array = tiles[Vector3i(x, y, z)]
				if item.is_empty():
					continue
				if item[0] == "Empty":
					continue
				if item.size() > 1:
					continue
				
				grid_map.mesh_library = wfc_constraints.mesh_library
				var cell = wfc_constraints.cell_on_name(item[0])
				var rotation = wfc_constraints.rotation_on_name(item[0])
				grid_map.set_cell_item(Vector3i(x,y,z), cell, rotation)





#region OLD BAD RECRURSSION METHOD

func start_collapse() -> void:
	var start_tile: String = "start"
	var start_rand_pos: Vector3i = random_vector3i(grid_size)
	tiles[Vector3i(start_rand_pos)].clear()
	tiles[Vector3i(start_rand_pos)].append(start_tile) # TERRIBLE HARD CODED IN
	
	
	collapse_adjacent_recursive(start_rand_pos)
	
	print(tiles)
	


func collapse_adjacent_recursive(original_pos: Vector3i, visited_tiles := {}) -> void:
	if visited_tiles.has(original_pos):
		return
	visited_tiles[original_pos] = true
	
	
	for direction in CheckDirections.values():
		# check if out of bounds, if it is, ignore
		var checking_pos: Vector3i = original_pos + propogate_check_directions[direction]
		
		if checking_pos.x < 0 or checking_pos.x >= grid_size.x:
			continue
		if checking_pos.y < 0 or checking_pos.y >= grid_size.y:
			continue
		if checking_pos.z < 0 or checking_pos.z >= grid_size.z:
			continue
		if not tiles.has(checking_pos):
			print("Skipping invalid position:", checking_pos)
			continue
		if tiles[checking_pos] == ["Empty"]:
			continue
		
	
		var available_tiles: Array[String] = []
		
		# add items to the array where the constraints are true
		for tile in tiles[original_pos]:
			if tile == "Empty":
				continue
			available_tiles.append_array(wfc_constraints.rules[tile][direction])
		
		# setting dictionary for the given position
		available_tiles = array_unique(available_tiles)
		tiles[checking_pos].clear()
		tiles[checking_pos] = available_tiles
		
		# getting smallest tiles
		if available_tiles.size() < smallest_collapse_size:
			smallest_collapse_size = available_tiles.size()
			smallest_collapses.clear()
			smallest_collapses.append(checking_pos)
		elif available_tiles.size() == smallest_collapse_size:
			smallest_collapses.append(checking_pos)
		
		
		collapse_adjacent_recursive(checking_pos, visited_tiles)
#endregion


func get_possible_tiles_for_neighbor(index: Vector3i, direction: int) -> Array:
	var possible: Array = []
	
	# For each tile possibility at current position
	for tile in tiles[index]:
		
		# Get what tiles can be adjacent in this direction
		if wfc_constraints.rules.has(tile) and wfc_constraints.rules[tile].size() > direction:
			var allowed = wfc_constraints.rules[tile][direction]
			for allowed_tile in allowed:
				if !possible.has(allowed_tile):
					possible.append(allowed_tile)
	
	return possible

func array_unique(array: Array[String]) -> Array:
	var unique: Array[String] = []
	for item in array:
		if not unique.has(item):
			unique.append(item)
	return unique

func random_vector3i(bounds: Vector3i) -> Vector3i:
	return Vector3i(randi_range(0, grid_size.x - 1), randi_range(0, grid_size.y - 1), randi_range(0, grid_size.z - 1))
	
func count_uncollapsed() -> int:
	var count = 0
	for pos in tiles.keys():
		if tiles[pos].size() > 1:
			count += 1
	return count
