extends CanvasLayer
class_name FadeLayer

@onready var fade_rect := $FadeRect

func _ready():
	globals.fade = self

func fade_out(duration := 0.5):
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tween.finished

func fade_in(duration := 0.5):
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, duration)
	await tween.finished
