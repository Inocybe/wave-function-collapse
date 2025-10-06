extends Node

@export var wfc_constraints: WFCResource
@export var grid_map: GridMap
@export var grid_size: Vector3


func _ready() -> void:
	print(wfc_constraints.rules)



func initialize(size: Vector3, constraints: Dictionary) -> void:
	pass
