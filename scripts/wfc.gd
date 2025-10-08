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
var max_iter: int = grid_size.x * grid_size.z * grid_size.y
var iter: int = 0


func _on_button_pressed() -> void:
	wfc()
	create_visual()


#region WFC
func wfc() -> void:
	tiles.clear()
	initialize()
	var start_tile: String = "start"
	var start_rand_pos: Vector3i = random_vector3i(grid_size)
	tiles[Vector3i(start_rand_pos)].clear()
	tiles[Vector3i(start_rand_pos)].append(start_tile) # TERRIBLE HARD CODED IN
	propogate(start_rand_pos)
	
	collapse_wave_function()


func initialize() -> void:
	var array_of_available_tiles = wfc_constraints.rules.keys()
	for x in range(grid_size.x):
		for z in range(grid_size.z):
			for y in range(grid_size.y):
				tiles.get_or_add(Vector3i(x, y, z), [])



func collapse_wave_function() -> void:
	var fully_collapsed: bool = false
	
	while !fully_collapsed:
		
		if iter > max_iter:
			printerr("Didn't collapse.")
			print(tiles)
			return
		
		if smallest_collapses.is_empty():
			print("Fully collapsed.")
			fully_collapsed = true
			continue
		
		# gets random lowest entropy cell
		var rand_int = randi_range(0, smallest_collapses.size() - 1)
		var lowest_entropy_cell: Vector3i = smallest_collapses[rand_int]
		
		# clear smallest collapses for the next iterations
		smallest_collapses.clear()
		smallest_collapse_size = 10000
		
		
		collapse(lowest_entropy_cell)
		propogate(lowest_entropy_cell)
		iter += 1
	
	print(tiles)




func propogate(index: Vector3i) -> void:
	for direction in CheckDirections.values():
		var checking_pos = index + propogate_check_directions[direction]
		
		if checking_pos.x < 0 or checking_pos.x >= grid_size.x:
			continue
		if checking_pos.y < 0 or checking_pos.y >= grid_size.y:
			continue
		if checking_pos.z < 0 or checking_pos.z >= grid_size.z:
			continue
		if tiles[checking_pos].size() == 1:
			continue
		
		# pass
		var available_tiles = change_entropy(index, direction)
		tiles[checking_pos].clear()
		tiles[checking_pos].append_array(available_tiles)
		
		
		# save sive of array, along with pos, so we have lowest entropy
		if available_tiles == ["Empty"]:
			continue
		if available_tiles.size() < smallest_collapse_size:
			smallest_collapses.clear()
			smallest_collapses.append(checking_pos)
			smallest_collapse_size = available_tiles.size()
		elif available_tiles.size() == smallest_collapse_size:
			smallest_collapses.append(checking_pos)


func collapse(index: Vector3i) -> void:
	var size = tiles[index].size()
	var collapsed_tile = tiles[index][randi_range(0, size - 1)]
	tiles[index] = [collapsed_tile]


#endregion


func create_visual() -> void:
	for x:int in range(grid_size.x):
		for z:int in range(grid_size.z):
			for y:int in range(grid_size.y):
				var item: Array = tiles[Vector3i(x, y, z)]
				if item == []:
					continue
				if item[0] == "Empty":
					continue
				
				grid_map.mesh_library = wfc_constraints.mesh_library
				var cell = wfc_constraints.cell_on_name(item[0])
				grid_map.set_cell_item(Vector3i(x,y,z), cell)





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


func change_entropy(index: Vector3i, direction: int) -> Array:
	return wfc_constraints.rules[tiles[index][0]][direction] # TS IS THE MOST BUNS CODE, BASICALLY JUST GETS THE THING PROPERLY

func array_unique(array: Array[String]) -> Array:
	var unique: Array[String] = []
	for item in array:
		if not unique.has(item):
			unique.append(item)
	return unique

func random_vector3i(bounds: Vector3i) -> Vector3i:
	return Vector3i(randi_range(0, grid_size.x - 1), randi_range(0, grid_size.y - 1), randi_range(0, grid_size.z - 1))
	
