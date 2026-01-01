extends Control
class_name Options

@onready var _pages: Dictionary = {
	"controls": $MarginContainer/HBoxContainer/ContentMargin/Content/InteriorMargins/KeybindsMenu,
	# add later:
	"graphics": $MarginContainer/HBoxContainer/ContentMargin/Content/InteriorMargins/GraphicsMenu,
	# "audio": $MarginContainer/HBoxContainer/ContentMargin/Content/InteriorMargins/AudioMenu,
	"gameplay": $MarginContainer/HBoxContainer/ContentMargin/Content/InteriorMargins/GameplayMenu,
}

@onready var labels: Dictionary = {
	"screen_shake": $MarginContainer/HBoxContainer/ContentMargin/Content/InteriorMargins/GraphicsMenu/VBoxContainer/ScreenShakeAmount/Value,
}

var _current_page: Control = null
# CONFIG SETTINGS

var screen_shake_amount : int = 1

func _ready() -> void:
	_open_page("controls")
	_on_screen_shake_value_changed(Settings.screen_shake_scale * 100)

func _open_controls() -> void:
	_open_page("controls")

func _open_graphics() -> void:
	_open_page("graphics")

func _open_audio() -> void:
	_open_page("audio")

func _open_gameplay() -> void:
	_open_page("gameplay")

func _open_page(page_id: String) -> void:
	if not _pages.has(page_id):
		return

	_current_page = _pages[page_id] as Control

	for key in _pages.keys():
		var page: Control = _pages[key] as Control
		page.visible = (page == _current_page)
		
func screen_shake():
	pass


func _on_screen_shake_value_changed(value: float) -> void:
	var scale: float = float(value) / 100.0
	Settings.screen_shake_scale = clampf(scale, 0.0, 1.0)
	Settings.save_settings()
	_update_label("screen_shake", str(value,"%"))
	
func _update_label(label_key: String, value: String) -> void:
	if labels[label_key] == null:
		return
	labels[label_key].text = value
		
	
	
	
