class_name WFCResource extends Resource

@export var rules: Dictionary
@export var mesh_library: MeshLibrary
@export var orientations: Dictionary = {}



func cell_on_name(name: String) -> int:
	var base_name: String = name
	if name.contains("-90"):
		base_name = base_name.replace("-90.0", "")
	if name.contains("-180"):
		base_name = base_name.replace("-180.0", "")
	if name.contains("-270"):
		base_name = base_name.replace("-270.0", "")
	if mesh_library.find_item_by_name(base_name + "-symmetrical") != -1:
		return mesh_library.find_item_by_name(base_name + "-symmetrical")
	
	return mesh_library.find_item_by_name(base_name)


func rotation_on_name(name: String) -> float:
	if name.contains("-90"):
		return 10
	if name.contains("-180"):
		return 16
	if name.contains("-270"):
		return 22
	
	return 0
