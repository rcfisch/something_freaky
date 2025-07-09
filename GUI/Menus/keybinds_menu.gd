extends ScrollContainer

var listening_button: Button = null

func _ready():
	for button in get_tree().get_nodes_in_group("rebind_buttons"):
		button.pressed.connect(_on_rebind_pressed.bind(button))

		var action_name = button.get_meta("action_name")
		var events = InputMap.action_get_events(action_name)

		if events.size() > 0 and events[0] is InputEventKey:
			var keycode: Key = (events[0] as InputEventKey).physical_keycode
			button.text = OS.get_keycode_string(keycode)
		else:
			button.text = "Unset"

func _on_rebind_pressed(button: Button):
	listening_button = button
	button.text = "Press key..."
	set_process_input(true)

func _input(event):
	if listening_button == null:
		return

	if event is InputEventKey and event.pressed:
		var action_name: String = listening_button.get_meta("action_name")

		InputMap.action_erase_events(action_name)
		InputMap.action_add_event(action_name, event)

		listening_button.text = OS.get_keycode_string(event.physical_keycode)
		listening_button = null
		set_process_input(false)
