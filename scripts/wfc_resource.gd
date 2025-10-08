class_name WFCResource extends Resource

@export var rules: Dictionary
@export var mesh_library: MeshLibrary



func cell_on_name(string: String) -> int:
	if string.contains("-90"):
		string.replace("-90", "")
	if string.contains("-180"):
		string.replace("-270", "")
	if string.contains("-270"):
		string.replace("-270", "")
	if mesh_library.find_item_by_name(string + "-symmetrical") != -1:
		return mesh_library.find_item_by_name(string + "-symmetrical")
	
	return mesh_library.find_item_by_name(string)
