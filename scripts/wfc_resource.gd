class_name WFCResource extends Resource

@export var rules: Dictionary
@export var mesh_library: MeshLibrary
@export var orientations: Dictionary = {}

func cell_on_name(name: String) -> int:
	var base_name: String = strip_orientation_suffix(name)
	
	var symmetrical_index: int = mesh_library.find_item_by_name(base_name + "-symmetrical")
	if symmetrical_index != -1:
		return symmetrical_index
	
	return mesh_library.find_item_by_name(base_name)

func strip_orientation_suffix(name: String) -> String:
	var dash_index: int = name.rfind("-")
	if dash_index == -1:
		return name
	
	var suffix: String = name.substr(dash_index + 1)
	if suffix.is_valid_int():
		return name.substr(0, dash_index)
	
	return name
