extends CharacterBody2D

var move_dir : int = 0 # player input axis
var accel : int = 100 # pixels/frame
var friction : float = 0.2 # value 0-1 that controls the amount of the player's velocity that's removed per frame- 1 will stop immediately, 0 will accelerate never stop 
var input_friction : float = 0.1 # read above
var max_fall_speed : int = 1600 # pixels/frame
# Jump
@export var jump_height : float = 300 # pixels
@export var jump_seconds_to_peak : float = 0.5
@export var jump_seconds_to_descent : float = 0.4
@export var variable_jump_gravity_multiplier : float = 5 # amount that gravity is multiplied when you stop holding jump- higher value gives more jump control
@export var coyote_frames : int = 8 # amount of frames the player is allowed to jump after walking off a ledge
@export var jump_buffer_frames : int = 4 # amount of frames the the jump button buffers for
var jump_buffer_time : int
var coyote_time : int # keeps track of how many frames have passed since you left the ground
var is_jumping : bool = false # check if the player is jumping
# Jump Calculations
@onready var jump_velocity : float = ((2.0 * jump_height) / jump_seconds_to_peak) * -1
@onready var jump_gravity : float = ((-2.0 * jump_height) / (jump_seconds_to_peak * jump_seconds_to_peak)) * -1
@onready var fall_gravity : float = ((-2.0 * jump_height) / (jump_seconds_to_descent * jump_seconds_to_descent)) * -1

func _physics_process(delta: float) -> void:
	move(delta) # handles movement and player input
	handle_coyote_frames() # counts coyote frames down when you leave the ground
	if Input.is_action_just_pressed("jump"):
		if coyote_time > 0:
			jump() # jump when you press jump
		else:
			jump_buffer_time = jump_buffer_frames
	if velocity.y > 0:
		is_jumping = false # keep track of if the player is moving up or not
	apply_friction(delta) # reduce a certain percentage of the player's velocity every frame
	apply_gravity(delta) # apply the gravity found by _get_gravity()
	print_stats() # print helpful stats
	move_and_slide() # built in function required for movement

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
		velocity.y = jump_velocity
		is_jumping = true
		coyote_time = 0
func handle_coyote_frames():
	if is_on_floor() and is_jumping == false:
		coyote_time = coyote_frames
	else:
		coyote_time = max(coyote_time - 1, 0)
	if is_on_floor() and is_jumping == false and jump_buffer_time > 0:
		jump()
		jump_buffer_time = 0
	else:
		jump_buffer_time = max(jump_buffer_time - 1, 0)
func print_stats():
	print("Coyote Time: ",coyote_time)
