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
@export var contact_damage : int = 1
@export var i_frames_given : int = 0

@export_category("Awareness Checks")
# times per second the enemy checks for the player
@export var awareness_check_frequency : int = 5
# the distance to which the player is automatically alerted.
@export var alert_distance : float = 3
# raycasts that will alert the enemy to the player
@export var alert_rays : Array[RayCast2D]

@onready var awareness_state : awareness = starting_awareness
var _player_inside: player = null

func _ready() -> void:
	$HurtPlayerArea.body_entered.connect(_on_body_entered)
	$HurtPlayerArea.body_exited.connect(_on_body_exited)
	print("ROOM IN READY: ", globals.current_room, " dead: ", globals.current_room.dead_enemies)
	if enemy_id in globals.current_room.dead_enemies:
		queue_free()
		return
	globals.current_room.enemies.append(self)

func _physics_process(delta):
	if _player_inside:
		attempt_damage_player(_player_inside)
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
func check_awareness(delta: float) -> void:
	awareness_check_counter += delta
	if awareness_check_counter < 1.0 / float(awareness_check_frequency):
		return
	awareness_check_counter = 0.0
	if self.global_position.distance_to(globals.player_pos) <= alert_distance:
		on_alert()
		return
	for ray: RayCast2D in alert_rays:
		if ray.is_colliding() and ray.get_collider() == player:
			on_alert()
			return
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
			var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position, enemy.global_position)
			var result = space_state.intersect_ray(query)
			if result.is_empty():
				continue
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
	print ("Current room enemies: ", globals.current_room.enemies, "		Current room dead enemies: ", globals.current_room.dead_enemies)
	print("ROOM IN DEATH: ", globals.current_room, " dead before: ", globals.current_room.dead_enemies)
	super()
func _on_body_entered(body: Node2D) -> void:
	if body is player:
		_player_inside = body as player
		attempt_damage_player(body)

func attempt_damage_player(body: Node2D):
	if body.invulnerable == false:
		if i_frames_given != 0:
			body.damage(contact_damage, i_frames_given)
		else:
			body.damage(contact_damage)
		var attack_direction: Vector2 = Vector2(sign(body.global_position.x - global_position.x), 0).normalized()
		body.knockback(attack_direction)
		print(attack_direction)
	

func _on_body_exited(body: Node2D) -> void:
	if body == _player_inside:
		_player_inside = null
	
