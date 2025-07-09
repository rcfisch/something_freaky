extends Control
class_name options

static var dash_keyboard_control_mode : bool = false # False=Mouse controlled, True=Keyboard controlled



func _on_dash_keyboard_control_mode_pressed():
	dash_keyboard_control_mode = !dash_keyboard_control_mode
