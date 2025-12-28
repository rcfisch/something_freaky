extends Area2D
class_name CameraZone

		
@export var zone_priority: int = 0
@export var look_ahead_offset: float = 400.0
@export var vertical_offset: float = -300.0
@export var look_down_offset: float = 600.0
@export var frames_to_look_down: int = 40


@onready var _shape: CollisionShape2D = $CollisionShape2D as CollisionShape2D

func _ready() -> void:
	add_to_group(&"camera_zones")

func get_global_rect() -> Rect2:
	if _shape.shape == null:
		return Rect2(global_position, Vector2.ZERO)

	var rect_shape: RectangleShape2D = _shape.shape as RectangleShape2D
	if rect_shape == null:
		return Rect2(global_position, Vector2.ZERO)

	var half: Vector2 = rect_shape.size * 0.5
	var center: Vector2 = _shape.global_position
	return Rect2(center - half, rect_shape.size)
