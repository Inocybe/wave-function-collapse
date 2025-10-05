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


func generate_constraints() -> void:
	for pos in grid_map.get_used_cells():
		var tile_name: String = get_name_at_pos(pos)
		var tile_constraints: Dictionary = constraints.get_or_add(tile_name, {})
		
		# get adjacent tiles
		for direction in ConstraintDirections.values():
			var adjacent_cell_position: Vector3 = constraint_check_vectors[direction]
			var adjacent_tile_name: String = get_name_at_pos(adjacent_cell_position)
			tile_constraints.get_or_add(direction, []).append(adjacent_tile_name)



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
	
	if ResourceLoader.exists("res://resources/wfc_constraints.tres", "WFCConstraints"):
		wfc_constraints_resource = ResourceLoader.load("res://resources/wfc_constraints.tres", "WFCConstraints")
	else:
		wfc_constraints_resource = WFCResource.new()
	
	wfc_constraints_resource.rules = constraints
	ResourceSaver.save(wfc_constraints_resource, "res://resources/wfc_constraints.tres")
