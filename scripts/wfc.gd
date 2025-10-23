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
var last_collapsed_tile: Vector3i
var smallest_collapse_size: int = 1000
var smallest_collapses: Array[Vector3i]
var max_iter: int = 200
var iter: int = 0


func _on_button_pressed() -> void:
	randomize()
	wfc()
	create_visual()
	print_rich("[color=red]NEW ONE[/color]")


#region WFC
func wfc() -> void:
	tiles.clear()
	iter = 0
	initialize()
	
	var start_tile: String = "start"
	var start_rand_pos: Vector3i = random_vector3i(grid_size)
	tiles[start_rand_pos] = [start_tile]
	last_collapsed_tile = start_rand_pos
	
	propogate(start_rand_pos)
	collapse_wave_function()


func initialize() -> void:
	var array_of_available_tiles = wfc_constraints.rules.keys()
	if array_of_available_tiles.has("Empty"):
		array_of_available_tiles.erase("Empty")
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
		last_collapsed_tile = lowest_entropy_cell
		
		
	
	print(tiles)


func update_smallest_collapses() -> void:
	
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
		
		var current_tiles = tiles[current_pos]
		if current_tiles.is_empty():
			printerr("Contradction at: ", current_pos)
			continue
		
		print("Checking tiles around: ", current_pos)
		
		for direction in CheckDirections.values():
			var checking_pos = current_pos + propogate_check_directions[direction]
			
			if is_position_out_of_bounds(checking_pos):
				continue
			
			var neighbor_tiles = tiles[checking_pos]
			if neighbor_tiles.is_empty():
				continue
			
			var possible_tiles = get_possible_tiles_for_neighbor(current_pos, direction)
			
			var new_tiles = intersect_arrays(possible_tiles, neighbor_tiles)
			
			if new_tiles.size() < neighbor_tiles.size():
				tiles[checking_pos] = new_tiles
				
				if !queue.has(checking_pos):
					queue.append(checking_pos)
				
				if new_tiles.is_empty():
					printerr("Created contradiction at ", checking_pos)


func collapse(index: Vector3i) -> void:
	var size = tiles[index].size()
	var collapsed_tile = tiles[index][randi_range(0, size - 1)]
	tiles[index] = [collapsed_tile]


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



func get_possible_tiles_for_neighbor(index: Vector3i, direction: int) -> Array:
	var possible: Array = []
	
	# For each tile possibility at current position
	for tile_name in tiles[index]:
		
		# Get what tiles can be adjacent in this direction
		if wfc_constraints.rules.has(tile_name):
			var rules = wfc_constraints.rules.get(tile_name, {})
			var neighbor_candidates = rules.get(direction, [])
			possible.append_array(neighbor_candidates)
	
	possible = array_unique(possible)
	
	return possible

# function to check grid_size so no out of bounds
func is_position_out_of_bounds(position: Vector3i) -> bool:
	if position.x < 0 or position.x >= grid_size.x: return true
	if position.y < 0 or position.y >= grid_size.y: return true
	if position.z < 0 or position.z >= grid_size.z: return true
	
	return false

func array_unique(array: Array) -> Array:
	var unique: Array = []
	for item in array:
		if not unique.has(item):
			unique.append(item)
	return unique

func intersect_arrays(array1: Array, array2: Array) -> Array:
	var result: Array = []
	for item in array1:
		if array2.has(item):
			result.append(item)
	return result

func random_vector3i(bounds: Vector3i) -> Vector3i:
	return Vector3i(randi_range(0, grid_size.x - 1), randi_range(0, grid_size.y - 1), randi_range(0, grid_size.z - 1))
	
func count_uncollapsed() -> int:
	var count = 0
	for pos in tiles.keys():
		if tiles[pos].size() > 1:
			count += 1
	return count
