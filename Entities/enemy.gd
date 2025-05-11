extends living_entity
class_name enemy

# the states of awareness an enemy has regarding the player
enum awareness{
	idle, # when enemy is standing still unaware of the player
	patroling, # when the enemy is pacing/walking around unaware of the player
	attacking # when the enemy is aware of and attacking the player
}
#the starting awareness of this enemy when the player enters the room
@export var starting_awareness : awareness

@export_category("Awareness Checks")
@export var awareness_check_frequency : int
@export var alert_distance : float

@onready var awareness_state : awareness = starting_awareness

func _process(delta):
	#switch statement for better optimization
	match awareness_state:
		awareness.idle:
			idle_process(delta)
			check_awareness(delta)
		awareness.patroling:
			patroling_process(delta)
			check_awareness(delta)
		awareness.attacking:
			attacking_process(delta)
var awareness_check_counter : float
func check_awareness(delta):
	awareness_check_counter += delta
	print(awareness_check_counter)
	if (awareness_check_counter >= 1/(awareness_check_frequency)):
		

func idle_process(delta):
	pass
func patroling_process(delta):
	pass
func attacking_process(delta):
	pass
