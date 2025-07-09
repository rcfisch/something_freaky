extends Control
class_name options

static var eight_direction_dash : bool = false # False=Mouse controlled, True=Keyboard controlled



func _on_eight_direction_dash_mode_pressed():
	eight_direction_dash = !eight_direction_dash
