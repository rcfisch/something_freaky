extends Button
class_name InventorySlot

signal slot_pressed(slot_index: int)

@export var slot_index: int = 0

@onready var icon_texture: TextureRect = $MarginContainer/TextureRect

var item_id: String = ""

func _ready() -> void:
	print(icon)
	pressed.connect(_on_pressed)

func set_item(new_item_id: String, texture: Texture2D = null) -> void:
	item_id = new_item_id
	icon_texture.texture = texture
	icon_texture.visible = texture != null
	print("slot ", slot_index, " item=", item_id, " texture=", texture)

func _on_pressed() -> void:
	slot_pressed.emit(slot_index)
