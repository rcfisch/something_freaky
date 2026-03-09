extends Area2D
class_name InteractionArea

signal _on_area_interacted()
signal area_interact_held()
@export var require_on_floor: bool = true

var _player_inside: player = null
var frames_interacting : int = 0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


	globals.hazard_respawn_pos = global_position
func _input(event: InputEvent) -> void:
	if _player_inside == null:
		return
	if event.is_action_pressed("interact"):
		emit_signal("_on_area_interacted")
		
func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("interact"):
		frames_interacting += 1
	else:
		frames_interacting = 0
	if frames_interacting >= 60:
		frames_interacting = 0
		emit_signal("area_interact_held")
	if _player_inside == null:
		frames_interacting = 0
	
		
		
	

func _on_body_entered(body: Node2D) -> void:
	if body is player:
		_player_inside = body as player

func _on_body_exited(body: Node2D) -> void:
	if body == _player_inside:
		_player_inside = null


	
