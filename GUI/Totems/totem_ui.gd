extends Control
class_name InventoryUI

@export var slot_nodes: Array[InventorySlot] = []

@export var starting_items: Array[String] = []
	
var items: Array[String] = ["butterfly", "fox", "cat", "", "", "", "", "", "", ""]
var selected_slot_index: int = -1

var item_icons: Dictionary = {
	"butterfly": preload("res://Assets/Testing/butterfly.png"),
	"fox": preload("res://Assets/Testing/fox-static.png"),
	"cat": preload("res://Assets/Art/Player/kitty-small.png")
}

var item_to_form: Dictionary = {
	"butterfly": player.form.BUTTERFLY,
	"fox": player.form.FOX,
	"cat": player.form.CAT,
	"": player.form.NULL
}
var form_to_item: Dictionary = {
	player.form.BUTTERFLY: "butterfly",
	player.form.FOX: "fox",
	player.form.CAT: "cat",
	player.form.NULL: ""
}

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		globals.input_allowed = true
		self.queue_free()
	if event.is_action_pressed("interact"):
		globals.input_allowed = true
		globals.game_paused = false
		self.queue_free()



func _ready() -> void:
	
	print("slot_nodes.size(): ", slot_nodes.size())
	print("items.size(): ", items.size())
	
	globals.input_allowed = false
	globals.game_paused = true
	
	starting_items.clear()

	starting_items.append(form_to_item.get(Globals.form_slot_1, ""))
	starting_items.append(form_to_item.get(Globals.form_slot_2, ""))
	starting_items.append(form_to_item.get(Globals.form_slot_3, ""))
	starting_items.append(form_to_item.get(Globals.form_slot_4, ""))

	for form: player.form in Globals.unused_forms:
		starting_items.append(form_to_item.get(form, ""))

	while starting_items.size() < 10:
		starting_items.append("")

	items = starting_items.duplicate()
	items = starting_items.duplicate()
				
	for i: int in range(slot_nodes.size()):
		slot_nodes[i].slot_index = i
		slot_nodes[i].slot_pressed.connect(_on_slot_pressed)
	refresh_slots()

func refresh_slots() -> void:
	for i: int in range(slot_nodes.size()):
		var item_id: String = items[i]
		var texture: Texture2D = null
		if item_icons.has(item_id):
			texture = item_icons[item_id]
		slot_nodes[i].set_item(item_id, texture)
	export_slots_to_globals()
	globals.refresh_unused_forms()

func _on_slot_pressed(slot_index: int) -> void:
	if selected_slot_index == -1:
		selected_slot_index = slot_index
		update_selection_visuals()
		return

	if selected_slot_index == slot_index:
		selected_slot_index = -1
		update_selection_visuals()
		return

	swap_items(selected_slot_index, slot_index)
	selected_slot_index = -1
	refresh_slots()
	update_selection_visuals()

func swap_items(index_a: int, index_b: int) -> void:
	var temp: String = items[index_a]
	items[index_a] = items[index_b]
	items[index_b] = temp

func update_selection_visuals() -> void:
	for i: int in range(slot_nodes.size()):
		if i == selected_slot_index:
			slot_nodes[i].modulate = Color(1.2, 1.2, 0.8)
		else:
			slot_nodes[i].modulate = Color(1, 1, 1)
			
func export_slots_to_globals() -> void:
	Globals.form_slot_1 = item_to_form.get(items[0], null)
	Globals.form_slot_2 = item_to_form.get(items[1], null)
	Globals.form_slot_3 = item_to_form.get(items[2], null)
	Globals.form_slot_4 = item_to_form.get(items[3], null)
