extends Node2D

func _ready():
	globals.world_node = $World
	Globals.load_room_offsets_from_file()
	Globals.enter_room("Testing")
