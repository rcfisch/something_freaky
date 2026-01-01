extends Node

const SAVE_PATH: String = "user://settings.cfg"

# 0.0 = off, 1.0 = full
var screen_shake_scale: float = 1.0

func _ready() -> void:
	load_settings()

func set_screen_shake_scale(value: float) -> void:
	screen_shake_scale = clampf(value, 0.0, 1.0)
	save_settings()

func save_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("gameplay", "screen_shake_scale", screen_shake_scale)
	cfg.save(SAVE_PATH)
	print("settings saved!")

func load_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	var err: Error = cfg.load(SAVE_PATH)
	if err != OK:
		return

	screen_shake_scale = clampf(cfg.get_value("gameplay", "screen_shake_scale", 1.0), 0.0, 1.0)
	print(screen_shake_scale)
