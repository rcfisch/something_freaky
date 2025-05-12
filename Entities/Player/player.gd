extends living_entity # extends entity, extends CharacterBody2D

var move_dir : int = 0 # player input axis
var accel : int = 400 # ground acceleration, pixels/frame
var air_accel : int = 400 # air acceleration, pixels/frame
var friction : float = 0.2 # friction applied when not pressing input, ground
var air_friction : float = 0.05 # friction applied when not pressing input, air
var air_input_friction : float = 0.0002 # friction applied while input is pressed in air
var input_friction : float = 0.001 # friction applied while input is pressed on ground
var max_fall_speed : int = 1600 * 4 # max fall speed
var max_walk_speed : int = 800 * 4 # max horizontal speed from walking

# Dash
var dash_velocity : int = 2000 * 4 # speed of dash
var dash_frames : int  = 12 # duration of dash in frames
var special_dash_frames = 16 # extra dash frames (unused currently)
var frames_since_dash : int # how many frames have passed since dash started
var dash_direction : Vector2 # direction of dash
var wavedash_vel : int = 3000 * 4 # velocity applied for wavedash
var facing : Vector2 = Vector2(1,1) # direction the player is facing

# Jump
@export var jump_height : float = 300 * 4 # jump height
@export var jump_seconds_to_peak : float = 0.5 # time to reach peak of jump
@export var jump_seconds_to_descent : float = 0.4 # time from peak to ground
@export var variable_jump_gravity_multiplier : float = 5 # gravity multiplier when jump is released early
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
var afterimage_cast : bool = false # whether the afterimage is active
var afterimage_pos : Vector2 # stored afterimage position

func _physics_process(delta: float) -> void:
	move(delta) # handles movement and player input
	get_facing() # updates facing direction
	animate() # handles sprite flipping
	dash() # handles dash logic
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
	dash_after_move_and_slide() # clean up dash state after movement

func animate():
	$StaticSprite.scale.x = -facing.x # flip sprite based on facing

func move(delta):
	move_dir = Input.get_axis("left", "right") # get input direction
	var target_speed = move_dir * max_walk_speed # determine target speed
	var accel_rate := 0.0 # base accel
	
	if is_on_floor(): accel_rate = accel # use ground accel
	else: accel_rate = air_accel # use air accel

	if frames_since_dash == 0:
		velocity.x = approach(velocity.x, target_speed, accel_rate * delta * 60) # move toward target speed

func get_facing() -> Vector2:
	if Input.get_axis("left","right") != 0:
		facing.x = Input.get_axis("left","right")
	if Input.get_axis("up","down") != 0:
		facing.y = Input.get_axis("left","right")
	return facing

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

	# Cancel dash when jump happens
	if frames_since_dash > 0:
		frames_since_dash = 0
		velocity.y = jump_velocity / 1.5
		velocity.x = wavedash_vel * move_dir
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
	if frames_since_dash <= dash_frames and frames_since_dash > 0:
		if dash_direction.normalized().y == 1 and is_on_floor(): 
			frames_since_dash = 0 # cancel dash if sliding into ground
		else:
			velocity.x += dash_velocity * dash_direction.normalized().x
			velocity.y = dash_velocity * dash_direction.normalized().y
			frames_since_dash += 1
	elif frames_since_dash > dash_frames: 
		# Clamp horizontal velocity only if the dash wasn't downward OR we're on the ground
		if dash_direction.y <= 0 or is_on_floor():
			velocity.x = clamp(velocity.x, -max_walk_speed, max_walk_speed)
		if dash_direction.normalized().y < 0:
			velocity.y = clamp(velocity.y, -max_walk_speed, max_walk_speed)
		frames_since_dash = 0

	if Input.is_action_just_pressed("dash"):
		dash_direction = Input.get_vector("left","right","up","down")
		if dash_direction == Vector2.ZERO:
			dash_direction.x = facing.x # default to facing if no input
		if abs(velocity.x) < max_walk_speed:
			velocity.x = dash_velocity * dash_direction.normalized().x
		else:
			velocity.x += dash_velocity * dash_direction.normalized().x
		velocity.y = dash_velocity * dash_direction.normalized().y
		frames_since_dash += 1

func dash_after_move_and_slide():
	if Input.is_action_just_pressed("dash") and !abs(velocity.x - dash_velocity * dash_direction.normalized().x) < max_walk_speed:
		velocity.x -= dash_velocity * dash_direction.normalized().x
	if frames_since_dash <= dash_frames and frames_since_dash > 0:
		if dash_direction.normalized().y == 0 and is_on_floor(): 
			frames_since_dash = 0
		else:
			velocity.x -= dash_velocity * dash_direction.normalized().x

func trigger_death():
	print("Player dead :(")
