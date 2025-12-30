extends Node2D
class_name Totem



func _on_area_interacted() -> void:
	Globals.death_respawn_pos = self.global_position
	Globals.respawn_room_id = Globals.current_room_id
