extends Node
class_name globals

static var game_paused : bool = false

static var player_is_on_floor : bool
static var player_pos : Vector2
static var player_id : RID
static var respawn_pos : Vector2


static var room_data: Dictionary = {}
static var current_room_id: String = ""
static var current_room: room = null
static var room_paths: Dictionary = {
	#"testing" : "res://Levels/Testing/testing.tscn"
	}
static var room_offsets: Dictionary = {
}
static var world_node: Node = null
class room:
	var room_cleared : bool = false
	var room_visited : bool = false
	var enemies : Array[Object] = []
	var dead_enemies : Array[Object] = []

func enter_room(room_id: String, spawn_position: Vector2 = Vector2.ZERO) -> void:
	# Save current room state
	current_room_id = room_id

	# Initialize room data
	if room_id not in room_data:
		room_data[room_id] = room.new()
	current_room = room_data[room_id]
	current_room.room_visited = true

	# Load room scene
	if room_id in room_paths:
		var scene_path: String = room_paths[room_id]
		var scene: PackedScene = load(scene_path)
		var room_instance = scene.instantiate()

		# Replace the current room scene
		var room_root = world_node
		if world_node == null:
			print("globals.world_node is not set!")
			return
		for child in world_node.get_children():
			child.queue_free()
		room_root.add_child(room_instance)

		# Get player node and move the room the the correct location
		var player = get_tree().get_root().get_node("World/Player")
		room_instance.global_position = room_offsets.get(room_id, Vector2.ZERO)
	else:
		push_error("Room ID %s has no associated scene path" % room_id)

func load_room_offsets_from_file(path: String = "res://data/room_layout.json"):
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Failed to load room layout file")
		return

	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Invalid room layout format")
		return

	room_offsets.clear()
	room_paths.clear()

	for room_id in data:
		var entry = data[room_id]
		room_offsets[room_id] = Vector2(entry["position"]["x"], entry["position"]["y"])
		room_paths[room_id] = entry["path"]
