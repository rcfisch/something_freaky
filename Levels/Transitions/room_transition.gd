extends Area2D
class_name transition

@export var room : String = "Testing"
@export_category("Direction (+ = right/down")
@export var transition_direction : Vector2 = Vector2.LEFT

var has_triggered := false

func _on_body_entered(body):
	if body.name == "Player":
		var velocity : Vector2 = body.velocity
		if velocity.normalized().dot(transition_direction.normalized()) > 0.1:
			Globals.enter_room(room)
	
