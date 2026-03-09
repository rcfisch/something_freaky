extends Node2D
class_name Totem



func _on_area_interacted() -> void:
	Globals.death_respawn_pos = self.global_position
	Globals.respawn_room_id = Globals.current_room_id
	Globals.clear_all_dead_enemies()


func _on_area_interact_held() -> void:
	var totem_ui_scene: PackedScene = load("res://GUI/Totems/totem_ui.tscn")
	var totem_ui: Node = totem_ui_scene.instantiate()
	get_tree().current_scene.add_child(totem_ui)
	
