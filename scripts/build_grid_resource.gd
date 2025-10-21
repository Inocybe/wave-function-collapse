@tool
class_name BuildGripResource
extends EditorScript

enum ConstraintDirections { up, down, left, right, forward, back }
var constraint_check_vectors: Dictionary[ConstraintDirections, Vector3]= {
	ConstraintDirections.up: Vector3.UP,
	ConstraintDirections.down: Vector3.DOWN,
	ConstraintDirections.left: Vector3.LEFT,
	ConstraintDirections.right: Vector3.RIGHT,
	ConstraintDirections.forward: Vector3.FORWARD,
	ConstraintDirections.back: Vector3.BACK,
}
var opposite_check_directions: Dictionary[ConstraintDirections, ConstraintDirections] = {
	ConstraintDirections.up: ConstraintDirections.down,
	ConstraintDirections.down: ConstraintDirections.up,
	ConstraintDirections.left: ConstraintDirections.right,
	ConstraintDirections.right: ConstraintDirections.left,
	ConstraintDirections.forward: ConstraintDirections.back,
	ConstraintDirections.back: ConstraintDirections.forward
}


var mesh_library: MeshLibrary
var grid_map: GridMap

var constraints: Dictionary = {}


func _run() -> void:
	var root = get_scene()
	if root is not GridMap:
		print_rich("[color=yellow]TS scene ain't a gridmap dumbahh.[/color]")
		return
	else:
		grid_map = root
		mesh_library = grid_map.mesh_library
	
	generate_constraints()
	save_to_resource()
	print(constraints)


func generate_constraints() -> void:
	var all_tiles: Array[String] = []
	for cell in grid_map.get_used_cells():
		var cell_name: String = get_name_at_pos(cell)
		if !all_tiles.has(cell_name):
			all_tiles.append(all_tiles)
	
	for tile_name in all_tiles:
		if !constraints.has(tile_name):
			constraints[tile_name] = {}
	
	
	
	for pos in grid_map.get_used_cells():
		var tile_name: String = get_name_at_pos(pos)
		
		# get adjacent tiles
		for direction in ConstraintDirections.values():
			var adjacent_pos: Vector3 = Vector3(pos) + constraint_check_vectors[direction]
			var adjacent_tile_name: String = get_name_at_pos(adjacent_pos)
			
			add_unique_constraint(tile_name, direction, adjacent_tile_name)
			
			var opposite_dir = opposite_check_directions[direction]
			add_unique_constraint(adjacent_tile_name, opposite_dir, tile_name)
			


func add_unique_constraint(tile_name: String, direction: int, neighbor_name: String) -> void:
	if !constraints.has(tile_name):
		constraints[tile_name] = {}
	
	if !constraints[tile_name].has(direction):
		constraints[tile_name][direction] = []
	
	var existing_neighbors: Array = constraints[tile_name][direction]
	if !existing_neighbors.has(neighbor_name):
		existing_neighbors.append(neighbor_name)

func get_name_at_pos(pos: Vector3) -> String:
	var item_index = grid_map.get_cell_item(pos)
	if item_index == grid_map.INVALID_CELL_ITEM:
		return "Empty"
	
	var item_name: String = mesh_library.get_item_name(item_index)
	var item_rotation: float = round(rad_to_deg(fposmod((grid_map.get_cell_item_basis(pos).get_euler().y), TAU))) # this terrible line of code just converts stuff to rotation, so that we can put it into cell data
	var tile_name: String = item_name + ("" if item_rotation == 0 or item_name.contains("symmetrical") else "-%s" % item_rotation)
	tile_name = tile_name.replace("-symmetrical", "")
	
	return tile_name


func save_to_resource():
	var wfc_constraints_resource: WFCResource
	
	if ResourceLoader.exists("res://resources/wfc_constraints.tres", "WFCResource"):
		wfc_constraints_resource = ResourceLoader.load("res://resources/wfc_constraints.tres", "WFCResource")
	else:
		wfc_constraints_resource = WFCResource.new()
	
	wfc_constraints_resource.rules = constraints
	wfc_constraints_resource.mesh_library = mesh_library
	ResourceSaver.save(wfc_constraints_resource, "res://resources/wfc_constraints.tres")
