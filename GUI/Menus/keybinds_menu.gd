extends ScrollContainer

@export var max_binds_per_action: int = 2

var listening_button: Button = null

func _ready() -> void:
	set_process_input(false)
	

	for button: Button in get_tree().get_nodes_in_group(&"rebind_buttons"):
		if not button.has_meta(&"bind_index"):
			if button.name.ends_with("d"):
				button.set_meta(&"bind_index", 0)
			if button.name.ends_with("2"):
				button.set_meta(&"bind_index", 1)
		button.pressed.connect(_on_rebind_pressed.bind(button))
		_refresh_button_text(button)

func _on_rebind_pressed(button: Button) -> void:
	listening_button = button
	button.text = "Press key..."
	set_process_input(true)

func _input(event: InputEvent) -> void:
	if listening_button == null:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		var key_event: InputEventKey = event as InputEventKey
		var action_name: String = String(listening_button.get_meta(&"action_name"))
		var bind_index: int = _get_meta_int(listening_button, &"bind_index", 0)

		_set_action_keybind(action_name, bind_index, key_event)

		_refresh_action_buttons(action_name)
		listening_button = null
		set_process_input(false)

func _set_action_keybind(action_name: String, bind_index: int, key_event: InputEventKey) -> void:
	var normalized: InputEventKey = _normalized_key_event(key_event)

	# Ensure slots exist up to max_binds_per_action
	var events: Array[InputEvent] = InputMap.action_get_events(action_name).duplicate()

	# Remove duplicates of this key from the same action (avoid double-binding within action)
	for i: int in range(events.size() - 1, -1, -1):
		if events[i] is InputEventKey and _same_key(events[i] as InputEventKey, normalized):
			events.remove_at(i)

	# Grow/shrink to fixed slot count (optional, but makes indexing stable)
	while events.size() < max_binds_per_action:
		events.append(null)
	if events.size() > max_binds_per_action:
		events.resize(max_binds_per_action)

	# Set the slot
	events[bind_index] = normalized

	# Apply back into InputMap
	InputMap.action_erase_events(action_name)
	for e: InputEvent in events:
		if e != null:
			InputMap.action_add_event(action_name, e)

func _refresh_action_buttons(action_name: String) -> void:
	for button: Button in get_tree().get_nodes_in_group(&"rebind_buttons"):
		if String(button.get_meta(&"action_name")) == action_name:
			_refresh_button_text(button)

func _refresh_button_text(button: Button) -> void:
	var action_name: String = String(button.get_meta(&"action_name"))
	var bind_meta: Variant = button.get_meta(&"bind_index")
	var bind_index: int = 0

	if typeof(bind_meta) == TYPE_INT:
		bind_index = bind_meta
	elif typeof(bind_meta) == TYPE_STRING:
		var s: String = bind_meta
		if s.is_valid_int():
			bind_index = s.to_int()
	else:
		bind_index = 0

	var events: Array[InputEvent] = InputMap.action_get_events(action_name)

	if bind_index < events.size() and events[bind_index] is InputEventKey:
		var keycode: Key = (events[bind_index] as InputEventKey).physical_keycode
		button.text = OS.get_keycode_string(keycode)
	else:
		button.text = "Unset"

func _normalized_key_event(src: InputEventKey) -> InputEventKey:
	var e: InputEventKey = InputEventKey.new()
	e.physical_keycode = src.physical_keycode
	e.keycode = src.keycode
	e.shift_pressed = false
	e.alt_pressed = false
	e.ctrl_pressed = false
	e.meta_pressed = false
	return e

func _same_key(a: InputEventKey, b: InputEventKey) -> bool:
	return a.physical_keycode == b.physical_keycode
	
func _get_meta_int(node: Object, key: StringName, fallback: int = 0) -> int:
	if not node.has_meta(key):
		return fallback

	var v: Variant = node.get_meta(key)
	match typeof(v):
		TYPE_INT:
			return v
		TYPE_FLOAT:
			return int(v)
		TYPE_STRING:
			var s: String = v
			return s.to_int() if s.is_valid_int() else fallback
		_:
			return fallback
