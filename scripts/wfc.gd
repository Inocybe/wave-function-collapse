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
var smallest_collapses: Array[Vector3]


func _ready() -> void:
	initialize()
	start_collapse()



#region Initilize Grid
func initialize() -> void:
	var array_of_available_tiles = wfc_constraints.rules.keys()
	for x in range(grid_size.x):
		for z in range(grid_size.z):
			for y in range(grid_size.y):
				tiles.get_or_add(Vector3i(x, y, z), array_of_available_tiles.duplicate())
#endregion


func start_collapse() -> void:
	var start_tile: String = "start"
	var start_rand_pos: Vector3i = random_vector3i(grid_size)
	tiles[Vector3i(start_rand_pos)].clear()
	tiles[Vector3i(start_rand_pos)].append(start_tile) # TERRIBLE HARD CODED IN
	
	for direction in CheckDirections.values():
		var adjacent_tile_pos: Vector3i = propogate_check_directions[direction] + start_rand_pos
		var available_tiles: Array[String] = collapse_adjacent(start_rand_pos, [start_tile], direction)
		
		# getting smallest tiles
		if available_tiles.size() < smallest_collapse_size:
			smallest_collapse_size = available_tiles.size()
			smallest_collapses.clear()
			smallest_collapses.append(adjacent_tile_pos)
		elif available_tiles.size() == smallest_collapse_size:
			smallest_collapses.append(adjacent_tile_pos)
	


func collapse_adjacent(original_pos: Vector3i, original_pos_tiles: Array[String], checking_dir: int) -> Array[String]:
	var available_tiles: Array[String] = []
	
	for tile in original_pos_tiles:
		available_tiles.append_array(wfc_constraints.rules[tile][checking_dir])
	
	available_tiles = array_unique(available_tiles)
	return available_tiles





func array_unique(array: Array[String]) -> Array:
	var unique: Array[String] = []
	for item in array:
		if not unique.has(item):
			unique.append(item)
	return unique

func random_vector3i(bounds: Vector3i) -> Vector3i:
	return Vector3i(randi_range(0, grid_size.x - 1), randi_range(0, grid_size.y- 1), randi_range(0, grid_size.z - 1))
	
