extends Button

func _ready() -> void:
	var action_name: String = str($"../../".name).to_lower()
	set_meta(&"action_name", action_name)
	# Let the menu refresh after everything is ready
	call_deferred("_refresh_me")

func _refresh_me() -> void:
	var menu: Node = get_node_or_null(^"../../../..")
	if menu != null and menu.has_method("_refresh_button_text"):
		menu.call("_refresh_button_text", self)
