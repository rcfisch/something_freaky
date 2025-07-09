extends Control

func _ready():
	visible = globals.game_paused

func _input(event):
	if event.is_action_pressed("pause"):
		if $"../OptionsMenu".visible:
			$"../OptionsMenu".hide()
			show()
		else:
			toggle_pause()
		
		
func toggle_pause():
	globals.game_paused = !globals.game_paused
	get_tree().paused = globals.game_paused
	visible = globals.game_paused
	


func _on_resume_pressed():
	toggle_pause()


func _on_quit_pressed():
	get_tree().quit()


func _on_options_pressed():
	hide()
	$"../OptionsMenu".show()
	
