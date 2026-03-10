extends Node2D

class_name Totem
var interacted : bool = false
var held : bool = false

func _physics_process(delta: float) -> void:
	if !interacted and $InteractionArea._player_inside != null:
		$KeyPrompt.show_prompt()
		$TextPrompt.visible = true
	if $InteractionArea._player_inside == null:
		interacted = false
		held = false
		$KeyPrompt.hide_prompt()
		$TextPrompt.hide_prompt()
	if interacted:
		$TextPrompt.show_prompt("HOLD:")
	if held:
		$KeyPrompt.hide_prompt()
		$TextPrompt.hide_prompt()


func _on_area_interacted() -> void:
	Globals.death_respawn_pos = self.global_position
	Globals.respawn_room_id = Globals.current_room_id
	Globals.clear_all_dead_enemies()
	interacted = true


func _on_area_interact_held() -> void:
	var totem_ui_scene: PackedScene = load("res://GUI/Totems/totem_ui.tscn")
	var totem_ui: Node = totem_ui_scene.instantiate()
	get_tree().current_scene.add_child(totem_ui)
	held = true
	
