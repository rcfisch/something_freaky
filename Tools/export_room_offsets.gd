@tool
extends Node

func _ready():
	var layout_scene = load("res://Levels/Rooms/world_layout.tscn")
	var layout = layout_scene.instantiate()
	var output = {}

	for room_node in layout.get_children():
		var scene_path = room_node.scene_file_path
		if scene_path == "":
			printerr("Skipping %s (not a packed scene instance)" % room_node.name)
			continue

		output[room_node.name] = {
			"position": {
				"x": room_node.global_position.x,
				"y": room_node.global_position.y
			},
			"path": scene_path
		}

	var file = FileAccess.open("res://data/room_layout.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(output, "\t"))
	file.close()

	print("✅ Room layout exported.")
