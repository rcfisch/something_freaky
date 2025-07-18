extends Area2D
@export var room : String = "Testing"

func _on_body_entered(body):
	if body.name == "Player":
		Globals.enter_room(room)
	
