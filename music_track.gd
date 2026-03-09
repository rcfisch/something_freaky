extends Node
class_name MusicTrack

@export var layers_data: Array[MusicLayer] = []

var layers: Dictionary = {}

func _ready() -> void:
	_build_layers()

func _build_layers() -> void:
	layers.clear()

	for child: Node in get_children():
		if child is AudioStreamPlayer:
			child.queue_free()

	for layer_data: MusicLayer in layers_data:
		if layer_data == null:
			continue

		if layer_data.stream == null:
			push_warning("MusicTrack '%s' has a layer with no stream." % name)
			continue

		var key: String = layer_data.layer_name.to_lower()
		if key == "":
			push_warning("MusicTrack '%s' has a layer with no name." % name)
			continue

		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = layer_data.layer_name
		player.stream = layer_data.stream
		player.bus = layer_data.bus
		player.volume_db = layer_data.default_volume_db
		add_child(player)

		if layer_data.autoplay_silent:
			player.play()

		layers[key] = player

func play_layers(layer_names: Array[String], fade_time: float = 1.0, target_db: float = 0.0) -> void:
	var normalized_layer_names: Array[String] = []

	for layer_name: String in layer_names:
		normalized_layer_names.append(layer_name.to_lower())

	for key_variant in layers.keys():
		var key: String = String(key_variant)
		var player: AudioStreamPlayer = layers[key]

		if normalized_layer_names.has(key):
			if not player.playing:
				player.play()
			fade_volume(player, target_db, fade_time)
		else:
			fade_volume(player, -80.0, fade_time)

func fade_in_layer(layer_name: String, fade_time: float = 1.0, target_db: float = 0.0) -> void:
	var key: String = layer_name.to_lower()

	if not layers.has(key):
		push_warning("Music layer not found: %s" % layer_name)
		return

	var player: AudioStreamPlayer = layers[key]
	if not player.playing:
		player.play()
	fade_volume(player, target_db, fade_time)

func fade_out_layer(layer_name: String, fade_time: float = 1.0) -> void:
	var key: String = layer_name.to_lower()

	if not layers.has(key):
		push_warning("Music layer not found: %s" % layer_name)
		return

	var player: AudioStreamPlayer = layers[key]
	fade_volume(player, -80.0, fade_time)

func stop_all_layers(fade_time: float = 1.0) -> void:
	for key_variant in layers.keys():
		var key: String = String(key_variant)
		var player: AudioStreamPlayer = layers[key]
		fade_volume(player, -80.0, fade_time)

func set_layer_volume(layer_name: String, volume_db: float) -> void:
	var key: String = layer_name.to_lower()

	if not layers.has(key):
		push_warning("Music layer not found: %s" % layer_name)
		return

	var player: AudioStreamPlayer = layers[key]
	player.volume_db = volume_db

func has_layer(layer_name: String) -> bool:
	return layers.has(layer_name.to_lower())

func get_layer_player(layer_name: String) -> AudioStreamPlayer:
	var key: String = layer_name.to_lower()

	if not layers.has(key):
		return null

	return layers[key]

func fade_volume(player: AudioStreamPlayer, target_db: float, duration: float = 1.0) -> Tween:
	if not is_instance_valid(player):
		return null

	var tween: Tween = get_tree().create_tween()
	tween.tween_property(player, "volume_db", target_db, duration)
	return tween
