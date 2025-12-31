extends Control
class_name Options

@onready var _pages: Dictionary = {
	"controls": $MarginContainer/HBoxContainer/ContentMargin/Content/KeybindsMenu,
	# add later:
	# "graphics": $MarginContainer/HBoxContainer/ContentMargin/Content/GraphicsMenu,
	# "audio": $MarginContainer/HBoxContainer/ContentMargin/Content/AudioMenu,
	"gameplay": $MarginContainer/HBoxContainer/ContentMargin/Content/GameplayMenu,
}

var _current_page: Control = null

func _ready() -> void:
	_open_page("controls")

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
