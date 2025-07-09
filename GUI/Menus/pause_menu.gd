extends Control

func _process(delta):
	print("check")

func _input(event):
	if event.is_action_pressed("pause"):
		globals.game_paused = !globals.game_paused
		get_tree().paused = globals.game_paused
		visible = globals.game_paused
