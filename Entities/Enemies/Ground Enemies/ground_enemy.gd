extends enemy

class_name ground_enemy

@export_category("Movement")
@export var move_speed: float = 128
@export var stagger_ticks: float = 40
var stagger_counter: float = 0
@export var turn_on_wall: bool = true
@export var turn_on_ledge: bool = true

@export_category("Sensors")
@export var ledge_ray: RayCast2D
@export var wall_ray: RayCast2D

var move_dir: int = -1

enum enemy_state {
	IDLE,
	WALKING,
	RUNNING,
	STAGGERED
}
var current_state : enemy_state

func _ready() -> void:
	super()
	$Sprite2D.play()
	scale.x *= -1
	current_state = enemy_state.IDLE
func _physics_process(delta: float) -> void:
	super(delta)

	gravity(delta)
	
	if current_state != enemy_state.STAGGERED:
		handle_turning()
		match awareness_state:
			awareness.idle:
				enter_state(enemy_state.IDLE)

			awareness.patroling:
				velocity.x = move_dir * move_speed
				enter_state(enemy_state.WALKING)

			awareness.attacking:
				attack_move(delta)
				enter_state(enemy_state.RUNNING)
	else:
		stagger_counter -= 1
		apply_friciton(delta)
		if stagger_counter <= 0:
			handle_turning()
			match awareness_state:
				awareness.idle:
					enter_state(enemy_state.IDLE)

				awareness.patroling:
					velocity.x = move_dir * move_speed
					enter_state(enemy_state.WALKING)

				awareness.attacking:
					attack_move(delta)
					enter_state(enemy_state.RUNNING)
			

	move_and_slide()
		
func handle_turning() -> void:
	if turn_on_wall and wall_ray and wall_ray.is_colliding():
		turn()

	if turn_on_ledge and ledge_ray and not ledge_ray.is_colliding():
		turn()
		
func turn() -> void:
	move_dir *= -1
	scale.x *= -1
	
func attack_move(delta: float) -> void:

	var player_pos: Vector2 = globals.player_pos

	if player_pos.x > global_position.x:
		move_dir = 1
	else:
		move_dir = -1

	velocity.x = move_dir * move_speed

func damage(int = 1):
	super()
	enter_state(enemy_state.STAGGERED)
	stagger_counter = stagger_ticks
	velocity.x -= move_dir * move_speed

func enter_state(new_state: enemy_state) -> void:
	if current_state == new_state:
		return
	var old_state: enemy_state = current_state
	emit_signal("state_exited", old_state)
	current_state = new_state
	emit_signal("state_changed", old_state, current_state)
	emit_signal("state_entered", current_state)

func knockback(attack_direction):
	velocity += Vector2((knockback_velocity * attack_direction).x, -knockback_velocity.y)
	
