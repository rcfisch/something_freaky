extends Resource
class_name MusicLayer

@export var layer_name: String = ""
@export var stream: AudioStream
@export var bus: StringName = &"Music"
@export var default_volume_db: float = -80.0
@export var autoplay_silent: bool = true
