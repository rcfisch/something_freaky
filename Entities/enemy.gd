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
# times per second the enemy checks for the player
@export var awareness_check_frequency : int = 20
# the distance to which the player is automatically alerted.
@export var alert_distance : float = 3
# raycasts that will alert the enemy to the player
@export var alert_rays : Array[RayCast2D]

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
		# Checks if player is too close to enemy
		if (((position.x - globals.player_pos.x)**2 + (position.y - globals.player_pos.y)**2)**0.5 <= alert_distance):
			awareness_state = awareness.attacking
			print("player seen by enemy " + code)
		#Checks if player is seen by enemy, THE RAYS MUST BE SET TO A COLLISION MASK WITH PLAYER ONLY
		for ray in alert_rays:
			if (ray.is_colliding()):
				awareness_state = awareness.attacking
				print("player seen by enemy " + code)

func idle_process(delta):
	pass
func patroling_process(delta):
	pass
func attacking_process(delta):
	pass
