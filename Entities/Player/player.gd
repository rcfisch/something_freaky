extends living_entity

var move_dir : int = 0 # player input axis
var accel : int = 400 # pixels/frame
var air_accel : int = 400 # pixels/frame
var friction : float = 0.2 # value 0-1 that controls the amount of the player's velocity that's removed per frame- 1 will stop immediately, 0 will accelerate never stop 
var air_friction : float = 0.05 # read above
var air_input_friction : float = 0.0002 # read above
var input_friction : float = 0.001 # read above
var max_fall_speed : int = 1600 * 4 # pixels/frame
var max_walk_speed : int = 800 * 4 # pixels/frame
# Dash
var dash_velocity : int = 2000 * 4
var dash_frames : int  = 12
var special_dash_frames = 16
var frames_since_dash : int
var dash_direction : Vector2
var wavedash_vel : int = 3000 * 4
var facing : Vector2 = Vector2(1,1)
# Jump
@export var jump_height : float = 300 * 4 # pixels
@export var jump_seconds_to_peak : float = 0.5
@export var jump_seconds_to_descent : float = 0.4
@export var variable_jump_gravity_multiplier : float = 5 # amount that gravity is multiplied when you stop holding jump- higher value gives more jump control
@export var coyote_frames : int = 8 # amount of frames the player is allowed to jump after walking off a ledge
@export var jump_buffer_frames : int = 4 # amount of frames the the jump button buffers for
var jump_buffer_time : int # keeps track of how many frames have passed since you pressed jump
var coyote_time : int # keeps track of how many frames have passed since you left the ground
var is_jumping : bool = false # check if the player is jumping
const CORNER_CORRECTION_HEIGHT = 20.0  # or around 5-10% of your character height
# Jump Calculations
@onready var jump_velocity : float = ((2.0 * jump_height) / jump_seconds_to_peak) * -1
@onready var jump_gravity : float = ((-2.0 * jump_height) / (jump_seconds_to_peak * jump_seconds_to_peak)) * -1
@onready var fall_gravity : float = ((-2.0 * jump_height) / (jump_seconds_to_descent * jump_seconds_to_descent)) * -1

# Totem Abilities

var afterimage_cast : bool = false
var afterimage_pos : Vector2




func _physics_process(delta: float) -> void:
	
	move(delta) # handles movement and player input
	get_facing()
	animate()
	dash()
	handle_jump_frames() # handles coyote time and jump buffering
	if is_on_floor() and jump_buffer_frames == 0: is_jumping = false
	if Input.is_action_just_pressed("jump") and !is_jumping:
		if coyote_time > 0:
			jump() # jump when you press jump
		else:
			jump_buffer_time = jump_buffer_frames
	if velocity.y > 0:
		is_jumping = false # keep track of if the player is moving up or not
	apply_friction(delta) # reduce a certain percentage of the player's velocity every frame
	apply_gravity(delta) # apply the gravity found by _get_gravity()
	#print_stats() # print helpful stats
	
	speed_boost()
	handle_afterimage()
	move_and_slide() # built in function required for movement
	dash_after_move_and_slide()
func animate():
	$StaticSprite.scale.x = -facing.x

func move(delta):
	move_dir = Input.get_axis("left", "right")
	var target_speed = move_dir * max_walk_speed
	var accel_rate := 0.0
	if is_on_floor():
		accel_rate = accel
	else:
		accel_rate = air_accel
	if frames_since_dash == 0:
		velocity.x = approach(velocity.x, target_speed, accel_rate * delta * 60)
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
			frames_since_dash = 0
		else:
			velocity.x += dash_velocity * dash_direction.normalized().x
			velocity.y = dash_velocity * dash_direction.normalized().y
			frames_since_dash += 1
	elif frames_since_dash > dash_frames: 
		# Clamp horizontal velocity only if the dash wasn't downward
		if dash_direction.y <= 0 or is_on_floor():
			velocity.x = clamp(velocity.x, -max_walk_speed, max_walk_speed)
		if dash_direction.normalized().y < 0:
			velocity.y = clamp(velocity.y, -max_walk_speed, max_walk_speed)
		frames_since_dash = 0
	if Input.is_action_just_pressed("dash"):
		dash_direction = Input.get_vector("left","right","up","down")
		if dash_direction == Vector2.ZERO:
			dash_direction.x = facing.x
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
