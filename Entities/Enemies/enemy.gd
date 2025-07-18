extends entity
class_name enemy

# the states of awareness an enemy has regarding the player
enum awareness{
	idle, # when enemy is standing still unaware of the player
	patroling, # when the enemy is pacing/walking around unaware of the player
	attacking # when the enemy is aware of and attacking the player
}
@export var enemy_id : String = "default"

@export var starting_awareness : awareness

@export_category("Awareness Checks")
# times per second the enemy checks for the player
@export var awareness_check_frequency : int = 5
# the distance to which the player is automatically alerted.
@export var alert_distance : float = 3
# raycasts that will alert the enemy to the player
@export var alert_rays : Array[RayCast2D]

@onready var awareness_state : awareness = starting_awareness

func _ready() -> void:
	if enemy_id in globals.current_room.dead_enemies:
		queue_free()
		return
	globals.current_room.enemies.append(self)

func _process(delta):
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
	if (awareness_check_counter >= 1/(awareness_check_frequency)):
		# Checks if player is too close to enemy

		if (((position.x - globals.player_pos.x)**2 + (position.y - globals.player_pos.y)**2)**0.5 <= alert_distance*500):
			#print(((position.x - globals.player_pos.x)**2 + (position.y - globals.player_pos.y)**2)**0.5/500)
			on_alert()
		#Checks if player is seen by enemy
		for ray in alert_rays:
			if ray.get_collider_rid() == globals.player_id:
				on_alert()

func on_alert(alert_others:bool = true)->void:
	if awareness_state == awareness.attacking: return
	awareness_state = awareness.attacking
	print("player seen by enemy " + code)
	if alert_others == false:
		return
	for enemy in globals.current_room.enemies:
		if not enemy == self:
			var space_state = get_world_2d().direct_space_state
			# use global coordinates, not local to node
			var query = PhysicsRayQueryParameters2D.create(position, enemy.position)
			var result = space_state.intersect_ray(query)
			if result.is_empty():
				return
			if result.collider == enemy:
				print("alerting ally " + result.collider.name)
				enemy.on_alert(false)

func idle_process(delta):
	pass
func patroling_process(delta):
	pass
func attacking_process(delta):
	pass
func trigger_death():
	if enemy_id in globals.current_room.dead_enemies:
		return
	globals.current_room.dead_enemies.append(enemy_id)
	globals.current_room.enemies.erase(self)
	super()
