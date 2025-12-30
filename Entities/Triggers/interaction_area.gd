extends Area2D
class_name InteractionArea

signal _on_area_interacted()

@export var require_on_floor: bool = true

var _player_inside: player = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


	globals.hazard_respawn_pos = global_position
func _input(event: InputEvent) -> void:
	if _player_inside == null:
		return
	if event.is_action_pressed("interact"):
		emit_signal("_on_area_interacted")
	

func _on_body_entered(body: Node2D) -> void:
	if body is player:
		_player_inside = body as player

func _on_body_exited(body: Node2D) -> void:
	if body == _player_inside:
		_player_inside = null
			
		
