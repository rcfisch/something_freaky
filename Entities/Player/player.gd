extends living_entity # extends entity, extends CharacterBody2D

var move_dir : int = 0 # player input axis
@onready var movement_multiplier : int = 4

@export var accel : int = 100 # ground acceleration, pixels/frame
@export var air_accel : int = 100 # air acceleration, pixels/frame
@export var friction : float = 0.2 # friction applied when not pressing input, ground
@export var air_friction : float = 0.05 # friction applied when not pressing input, air
@export var air_input_friction : float = 0.01 # friction applied while input is pressed in air
@export var input_friction : float = 0.03 # friction applied while input is pressed on ground
@export var max_fall_speed : int = 1600 # max fall speed
@export var max_walk_speed : int = 800 # max horizontal speed from walking

# Dash
var dash_velocity : int = 2000 # speed of dash
var dash_frames : int  = 16 # duration of dash in frames
var frames_since_dash : int # how many frames have passed since dash started
var dash_direction : Vector2 # direction of dash
var wavedash_vel : int = 2400 # velocity applied for wavedash
var facing : Vector2 = Vector2(1,1) # direction the player is facing
var can_dash : bool = true
var dash_refresh_frames = 10
var is_dashing : bool = false

# Jump
@export var jump_height : float = 300 * 4 # jump height
@export var jump_seconds_to_peak : float = 0.5 # time to reach peak of jump
@export var jump_seconds_to_descent : float = 0.4 # time from peak to ground
@export var variable_jump_gravity_multiplier : float = 10 # gravity multiplier when jump is released early
@export var coyote_frames : int = 8 # time buffer after leaving ground to still allow jump
@export var jump_buffer_frames : int = 4 # time buffer after pressing jump to allow jump
var jump_buffer_time : int # counter for jump buffer
var coyote_time : int # counter for coyote time
var is_jumping : bool = false # tracks if currently jumping

const CORNER_CORRECTION_HEIGHT = 20.0 # number of units allowed for vertical corner correction

# Jump Calculations
@onready var jump_velocity : float = ((2.0 * jump_height) / jump_seconds_to_peak) * -1 # upward velocity at jump start
@onready var jump_gravity : float = ((-2.0 * jump_height) / (jump_seconds_to_peak * jump_seconds_to_peak)) * -1 # gravity during jump ascent
@onready var fall_gravity : float = ((-2.0 * jump_height) / (jump_seconds_to_descent * jump_seconds_to_descent)) * -1 # gravity during fall

# Totem Abilities
@export var form : int = 0 # Which form the player is in:
# 0 = Ghost
# 1 = First Form

var afterimage_cast : bool = false # whether the afterimage is active
var afterimage_pos : Vector2 # stored afterimage position

func _ready() -> void:
	accel *= movement_multiplier
	air_accel *= movement_multiplier
	max_fall_speed *= movement_multiplier
	max_walk_speed *= movement_multiplier
	dash_velocity *= movement_multiplier
	wavedash_vel *= movement_multiplier

func _physics_process(delta: float) -> void:
	move(delta) # handles movement and player input
	get_facing() # updates facing direction
	animate() # handles sprite flipping
	dash() # handles dash logic
	if (is_on_floor() and frames_since_dash > dash_frames - dash_refresh_frames) or (is_on_floor() and frames_since_dash == -1):
		can_dash = true
	if is_dashing:
		continue_dash()
	handle_jump_frames() # handles coyote time and jump buffering
	
	if is_on_floor() and jump_buffer_frames == 0: is_jumping = false # reset jump state on landing
	if Input.is_action_just_pressed("jump") and !is_jumping:
		if coyote_time > 0:
			jump() # jump if coyote time is active
		else:
			jump_buffer_time = jump_buffer_frames # otherwise, buffer the jump
	if velocity.y > 0:
		is_jumping = false # reset jump state on descent

	apply_friction(delta) # apply horizontal friction
	apply_gravity(delta) # apply gravity based on state
	# print_stats() # optional debug
	
	speed_boost() # manually add velocity in direction (debug/testing)
	handle_afterimage() # handle teleport-style afterimage system
	move_and_slide() # apply calculated velocity

func animate():
	$StaticSprite.scale.x = -facing.x # flip sprite based on facing

func get_facing() -> Vector2:
	if Input.get_axis("left","right") != 0:
		facing.x = Input.get_axis("left","right")
	if Input.get_axis("up","down") != 0:
		facing.y = Input.get_axis("left","right")
	return facing

func move(delta):
	move_dir = Input.get_axis("left", "right") # get input direction
	var target_speed = move_dir * max_walk_speed # determine target speed
	var accel_rate := 0.0 # base accel
	
	if is_on_floor(): accel_rate = accel # use ground accel
	else: accel_rate = air_accel # use air accel

	if !is_dashing and abs(velocity.x) <= max_walk_speed:
		velocity.x = approach(velocity.x, target_speed, accel_rate * delta * 60)

func approach(current: float, target: float, amount: float) -> float:
	if current < target:
		return min(current + amount, target)
	elif current > target:
		return max(current - amount, target)
	return target

func apply_friction(delta):
	if move_dir == 0:
		if is_on_floor():
			velocity.x -= (velocity.x * friction) * (delta * 60)
		else:
			velocity.x -= (velocity.x * air_friction) * (delta * 60)
	else:
		if sign(velocity.x) != 0 and move_dir != 0 and sign(velocity.x) != sign(move_dir):
			if is_on_floor():
				velocity.x -= (velocity.x * friction) * (delta * 60)
			else:
				velocity.x -= (velocity.x * friction) * (delta * 60)
		else:
			if is_on_floor():
				velocity.x -= (velocity.x * input_friction) * (delta * 60)
			else:
				velocity.x -= (velocity.x * air_input_friction) * (delta * 60)

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

	# Cancel dash and initiate wavedash
	if is_dashing:
		if dash_direction.y > 0:
			velocity.y = jump_velocity / 1.5
			velocity.x = wavedash_vel * facing.x
		else: 
			velocity.y = jump_velocity
			velocity.x = dash_velocity * facing.x
		end_dash(true) # ends the dash cleanly
	else:
		velocity.y = jump_velocity

func handle_jump_frames():
	if is_on_floor() and is_jumping == false:
		coyote_time = coyote_frames
	else:
		coyote_time = max(coyote_time - 1, 0)

	if is_on_floor() and is_jumping == false and jump_buffer_time > 0:
		jump()
		jump_buffer_time = 0
	else:
		jump_buffer_time = max(jump_buffer_time - 1, 0)

func try_corner_correction(): # not working properly yet
	if is_on_wall() and velocity.y < 0:
		for i in range(int(CORNER_CORRECTION_HEIGHT), 0, -1):  # Start from the max
			var offset := Vector2(0, -i)
			if !test_move(transform, offset):
				global_position.y -= i
				print("Corner correction applied: ", i, " units")
				break

func print_stats():
	print("Coyote Time: ",coyote_time)
	print("is on floor: ", is_on_floor())
	print("is jumping: ", is_jumping)

func speed_boost():
	var ui_dir : Vector2
	ui_dir = Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	velocity += Vector2(4000,4000) * ui_dir

func handle_afterimage():
	if Input.is_action_just_pressed("afterimage"):
		if !afterimage_cast:
			afterimage_pos = self.position
			afterimage_cast = !afterimage_cast
		else:
			self.position = afterimage_pos
			afterimage_cast = !afterimage_cast

func dash():
	if Input.is_action_just_pressed("dash") and can_dash:
		begin_dash()
func begin_dash():
	dash_direction = Input.get_vector("left", "right", "up", "down")
	if dash_direction == Vector2.ZERO:
		dash_direction.x = facing.x

	is_dashing = true
	can_dash = false
	frames_since_dash = 0

	var dash_x = dash_velocity * dash_direction.normalized().x
	var dash_y = dash_velocity * dash_direction.normalized().y

	# Preserve horizontal momentum if already higher than dash
	if abs(velocity.x) > abs(dash_x) and sign(velocity.x) == sign(dash_x):
		velocity.x += dash_x * 0.5 # Just a boost
	else:
		velocity.x = dash_x

	velocity.y = dash_y
func continue_dash():
	frames_since_dash += 1

	# Optionally force constant velocity if needed
	velocity.x = dash_velocity * dash_direction.normalized().x
	velocity.y = dash_velocity * dash_direction.normalized().y

	if frames_since_dash >= dash_frames:
		end_dash(false)
func end_dash(bypass_clamp : bool):
	is_dashing = false
	frames_since_dash = -1
	
	if !bypass_clamp:
	# Optional: clamp X if the dash wasn't downward
		if dash_direction.y <= 0 or is_on_floor():
			velocity.x = clamp(velocity.x, -max_walk_speed, max_walk_speed)
		if dash_direction.y < 0:
			velocity.y = clamp(velocity.y, -max_walk_speed, max_walk_speed)

func trigger_death():
	print("Player dead :(")
