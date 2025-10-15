class_name WFCResource extends Resource

@export var rules: Dictionary
@export var mesh_library: MeshLibrary



func cell_on_name(name: String) -> int:
	if name.contains("-90"):
		name.replace("-90", "")
	if name.contains("-180"):
		name.replace("-270", "")
	if name.contains("-270"):
		name.replace("-270", "")
	if mesh_library.find_item_by_name(name + "-symmetrical") != -1:
		return mesh_library.find_item_by_name(name + "-symmetrical")
	
	return mesh_library.find_item_by_name(name)


func rotation_on_name(name: String) -> float:
	if name.contains("-90"):
		return 90
	if name.contains("-180"):
		return 180
	if name.contains("-270"):
		return 270
	
	return 0
