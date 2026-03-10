extends Control

@onready var label: Label = $CenterContainer/Label
@export var default_action: String = "interact"
@export var fade_time: float = 0.15
@export var bob_speed: float = 0.8
@export var bob_amount: float = 4.0

var base_position: Vector2
var bob_time: float = 0.0

var fade_tween: Tween

func _ready() -> void:
	base_position = position
	modulate.a = 0.0
	visible = false
	
func _process(delta: float) -> void:
	if visible:
		bob_time += delta
		position.y = base_position.y + sin(bob_time * TAU * bob_speed) * bob_amount


func get_action_key(action: String) -> String:
	var events: Array[InputEvent] = InputMap.action_get_events(action)

	for event: InputEvent in events:
		if event is InputEventKey:
			var key_event: InputEventKey = event
			return OS.get_keycode_string(key_event.physical_keycode)
		elif event is InputEventJoypadButton:
			var joypad_event: InputEventJoypadButton = event
			return "Button %s" % joypad_event.button_index
		elif event is InputEventMouseButton:
			var mouse_event: InputEventMouseButton = event
			return "Mouse %s" % mouse_event.button_index

	return ""


func show_prompt(action_name: String = default_action) -> void:
	var key_name: String = get_action_key(action_name)
	label.text = key_name

	if fade_tween:
		fade_tween.kill()

	visible = true
	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 1.0, fade_time)


func hide_prompt() -> void:
	if fade_tween:
		fade_tween.kill()

	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, fade_time)

	await fade_tween.finished
	visible = false
