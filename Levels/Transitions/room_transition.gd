extends Area2D
class_name transition

@export var room : String = "Testing"
@export_category("Direction (+ = right/down")
@export var transition_direction : Vector2 = Vector2.LEFT

func _unhandled_input(event: InputEvent) -> void:
	if not globals.game_processing:
		return

	if not (event is InputEventKey and event.pressed):
		return

	var input_vec := Input.get_vector("left", "right", "up", "down")
	if input_vec == Vector2.ZERO:
		return

	for body in get_overlapping_bodies():
		if body.name != "Player":
			continue

		var velocity = body.velocity

		# Compare both input vector and fallback to velocity
		if input_vec.normalized().dot(transition_direction.normalized()) > 0.1 or \
		   (velocity.length() > 0 and velocity.normalized().dot(transition_direction.normalized()) > 0.1):

			Globals.enter_room(room, transition_direction)

			break
		

func _on_body_entered(body):
	if body.name == "Player":
		var velocity : Vector2 = body.velocity
		if velocity.normalized().dot(transition_direction.normalized()) > 0.1:
			Globals.enter_room(room, transition_direction)
	
