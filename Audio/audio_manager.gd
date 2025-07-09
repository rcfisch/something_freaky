extends Node

@export var max_sfx_players := 16

var sfx_pool: Array[AudioStreamPlayer] = []
var sfx_library: Dictionary = {}
var music_layers: Dictionary = {}

func _ready():
	# Preload SFX
	sfx_library = {
#		"jump": preload("res://audio/sfx/jump.ogg"),
#		"dash": preload("res://audio/sfx/dash.ogg"),
#		"hit": preload("res://audio/sfx/hit.ogg"),
	}
	
	# Build pool of SFX players
	for i in max_sfx_players:
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		sfx_pool.append(player)

func play_sfx(name: String):
	if not sfx_library.has(name):
		push_warning("SFX not found: %s" % name)
		return

	for player in sfx_pool:
		if not player.playing:
			player.stream = sfx_library[name]
			player.play()
			return

func register_music_layer(name: String, stream: AudioStream, bus := "Music", autoplay := false):
	var player = AudioStreamPlayer.new()
	player.name = name
	player.stream = stream
	player.bus = bus
	player.volume_db = -80 if not autoplay else 0
	player.playing = autoplay
	add_child(player)
	music_layers[name] = player

func play_music_layer(name: String, fade_in_time := 1.0):
	if not music_layers.has(name):
		push_warning("Music layer not found: %s" % name)
		return
	var player = music_layers[name]
	player.play()
	player.fade_volume_db(0, fade_in_time)

func stop_music_layer(name: String, fade_out_time := 1.0):
	if not music_layers.has(name):
		return
	var player = music_layers[name]
	player.fade_volume_db(-80, fade_out_time)

func fade_all_layers(except := "", fade_out_time := 1.0):
	for name in music_layers:
		if name != except:
			stop_music_layer(name, fade_out_time)

# Utility to fade volume
func fade_volume(player: AudioStreamPlayer, target_db: float, duration: float = 1.0):
	if not is_instance_valid(player):
		return
	var tween := get_tree().create_tween()
	tween.tween_property(player, "volume_db", target_db, duration)
