extends Node2D
class_name RespawnTriggerArea

@export var require_on_floor: bool = true

var _player_inside: player = null

func _ready() -> void:
	$Sprite.hide()
	$RespawnTriggerArea.body_entered.connect(_on_body_entered)
	$RespawnTriggerArea.body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	if _player_inside == null:
		return
	if require_on_floor and not _player_inside.is_on_floor():
		return

	globals.hazard_respawn_pos = global_position

	# Optional: only set once then stop
	# set_physics_process(false)

func _on_body_entered(body: Node2D) -> void:
	if body is player:
		_player_inside = body as player

func _on_body_exited(body: Node2D) -> void:
	if body == _player_inside:
		_player_inside = null
			
		
