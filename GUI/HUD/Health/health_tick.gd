extends TextureRect
class_name HealthTick

@export var full_texture: Texture2D
@export var empty_texture: Texture2D

func set_filled(filled: bool) -> void:
	texture = full_texture if filled else empty_texture
