extends CharacterBody2D

var move_dir : int = 0
var speed : int = 2000
var accel : int = 100
var friction : float = 0.2 # tune this value to control friction strength
var input_friction : float = 0.1
var gravity : float = 20
var max_fall_speed : int = 1600

# Jump
@export var jump_height : float = 300
@export var jump_seconds_to_peak : float = 0.5
@export var jump_seconds_to_descent : float = 0.4
@export var variable_jump_gravity_multiplier : float = 5
@export var coyote_frames : int = 8
var coyote_time : int
var is_jumping : bool = false
# Jump Calculations
@onready var jump_velocity : float = ((2.0 * jump_height) / jump_seconds_to_peak) * -1
@onready var jump_gravity : float = ((-2.0 * jump_height) / (jump_seconds_to_peak * jump_seconds_to_peak)) * -1
@onready var fall_gravity : float = ((-2.0 * jump_height) / (jump_seconds_to_descent * jump_seconds_to_descent)) * -1


func _physics_process(delta: float) -> void:

	move(delta)
	handle_coyote_frames()
	if Input.is_action_just_pressed("jump"):
		jump()
	if velocity.y > 0:
		is_jumping = false
	apply_friction(delta)
	apply_gravity(delta)
	print_stats()
	move_and_slide()


func move(delta):
	move_dir = Input.get_axis("left", "right") # get input direction
	velocity.x += (accel * move_dir) * (delta * 60)
func apply_friction(delta):
		if move_dir == 0:
			velocity.x -= (velocity.x * friction) * (delta * 60)
		else: 
			velocity.x -= (velocity.x * input_friction) * (delta * 60)
func _get_gravity() -> float:
# Return correct gravity for the situation
	if velocity.y < 0:
		if is_jumping == true and Input.is_action_pressed("jump"):
			return jump_gravity  
		else:
			return jump_gravity * variable_jump_gravity_multiplier
	else:
		return fall_gravity
func apply_gravity(delta):
	if !is_on_floor():
		if velocity.y < max_fall_speed:
			velocity.y += _get_gravity() * delta
		else: 
			velocity.y = max_fall_speed
func jump():
	if coyote_time > 0:
		velocity.y = jump_velocity
		is_jumping = true
		coyote_time = 0
func handle_coyote_frames():
	if is_on_floor() and is_jumping == false:
		coyote_time = coyote_frames
	else:
		coyote_time = max(coyote_time - 1, 0)
		
func print_stats():
	print("Coyote Time: ",coyote_time)
