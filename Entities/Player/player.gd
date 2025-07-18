extends entity # extends entity, extends CharacterBody2D
class_name player

@onready var camera = $Camera

var current_control_method : String = "keyboard"
var move_dir : int = 0 # player input axis
var facing : Vector2 = Vector2(1,1) # direction the player is facing
@onready var movement_multiplier : int = 2
signal dead

# Movement
static var movement_enabled : bool = true
@export_category("Movement")
@export var accel : int = 100 # ground acceleration, pixels/frame
@export var air_accel : int = 100 # air acceleration, pixels/frame
@export var friction : float = 0.8 # friction applied when not pressing input, ground
@export var air_friction : float = 0.1 # friction applied when not pressing input, air
@export var air_input_friction : float = 0.01 # friction applied while input is pressed in air
@export var input_friction : float = 0.03 # friction applied while input is pressed on ground
@export var max_fall_speed : int = 1600 # max fall speed
@export var max_fall_speed_gliding : int = 800 # max fall speed
@export var max_walk_speed : int = 800 # max horizontal speed from walking

# Dash
signal dash_started
@export_category("Dash")
@export var dash_velocity : int = 1600 # speed of dash
@export var dash_frames : int = 16 # duration of dash in frames
var dash_attack : int = 10 # duration in which you cannot dash after finishing your dash, in frames
var frames_since_dash : int # how many frames have passed since dash started
var dash_direction : Vector2 # direction of dash
@export var wavedash_vel : int = 2000 # velocity applied for wavedash
var can_dash : bool = true
@export var dash_refresh_frames = 10
var is_dashing : bool = false
var dash_x : float
var dash_y : float
var frames_since_dash_ended : int

# Attack
@export_category("Attack")
@export var attack_damage : int = 1
@export var attack_knockback_velocity : float = 1000
@export var attack_knockback_bump : float = 1000
@export var pogo_velocity : float = 2000
var is_pogoing : bool = false
var attack_direction : Vector2
var is_being_knocked_back : bool = false
var attack_stagger_time : int = 0
var attack_stagger_frames : int = 10
static var attacking : bool = false

# Jump
@export_category("Jump")
@export var jump_height : float = 300 * 2 # jump height
@export var jump_seconds_to_peak : float = 0.5 # time to reach peak of jump
@export var jump_seconds_to_descent : float = 0.4 # time from peak to ground
@export var variable_jump_gravity_multiplier : float = 8 # gravity multiplier when jump is released early
@export var coyote_frames : int = 8 # time buffer after leaving ground to still allow jump
@export var jump_buffer_frames : int = 4 # time buffer after pressing jump to allow jump
var jump_buffer_time : int # counter for jump buffer
var coyote_time : int # counter for coyote time
var is_jumping : bool = false # tracks if currently jumping
var double_jump_used : bool = false

const CORNER_CORRECTION_HEIGHT = 20.0 # number of units allowed for vertical corner correction

# Jump Calculations
@onready var jump_velocity : float = ((2.0 * jump_height) / jump_seconds_to_peak) * -1 # upward velocity at jump start
@onready var jump_gravity : float = ((-2.0 * jump_height) / (jump_seconds_to_peak * jump_seconds_to_peak)) * -1 # gravity during jump ascent
@onready var fall_gravity : float = ((-2.0 * jump_height) / (jump_seconds_to_descent * jump_seconds_to_descent)) * -1 # gravity during fall

# Totem Abilities
@onready var form_sprites := {
	form.GHOST: $"Sprites/00_Ghost",
	form.FOX: $"Sprites/01_Fox",
	form.BUTTERFLY: $"Sprites/02_Butterfly"
}

enum form {
	GHOST,
	FOX,
	BUTTERFLY
}
@onready var current_sprite : Node = $"Sprites/01_Fox"
var current_form: form = form.FOX
# 0 = Ghost
# 1 = Fox
# 2 = Butterfly

var afterimage_cast : bool = false # whether the afterimage is active
var afterimage_pos : Vector2 # stored afterimage position

func _ready() -> void:
	globals.respawn_pos = self.position
	globals.player_id = get_rid()
	accel *= movement_multiplier
	air_accel *= movement_multiplier
	max_fall_speed *= movement_multiplier
	max_walk_speed *= movement_multiplier
	dash_velocity *= movement_multiplier
	wavedash_vel *= movement_multiplier

func _input(event):
	if event.is_action_pressed("1"):
		change_form(form.FOX)
	if event.is_action_pressed("2"):
		change_form(form.BUTTERFLY)

func _physics_process(delta: float) -> void:
	current_control_method = detect_controller()
	#print(current_control_method)
	if attack_stagger_time > 0:
		movement_enabled = false
	else: movement_enabled = true
	if movement_enabled:
		move(delta) # handles movement and player input
	get_facing() # updates facing direction
	animate() # handles sprite flipping
	dash() # handles dash logic
	if (is_on_floor() and frames_since_dash > dash_frames - dash_refresh_frames) or (is_on_floor() and frames_since_dash == -1):
		can_dash = true
	if is_dashing:
		continue_dash()
	if is_dashing:
		frames_since_dash_ended = 0
	else: frames_since_dash_ended += 1
	
	handle_jump_frames() # handles coyote time and jump buffering
	
	if is_on_floor():
		double_jump_used = false
		is_pogoing = false
		if jump_buffer_frames == 0: 
			is_jumping = false # reset jump state on landing
			is_being_knocked_back = false
	if Input.is_action_just_pressed("jump") and !is_jumping: #FIX THIS LINE, YOU SHOULD STILL BE ABLE TO DOUBLE JUMP WHILE JUMPING
		if coyote_time > 0:
			jump() # jump if coyote time is active
		elif !double_jump_used and !is_on_floor() and !is_dashing:
			double_jump()
		else:
			jump_buffer_time = jump_buffer_frames # otherwise, buffer the jump
	if velocity.y > 0:
		is_jumping = false # reset jump state on descent
		is_being_knocked_back =  false
		is_pogoing = false
	apply_friction(delta) # apply horizontal friction
	if !is_dashing:
		apply_gravity(delta) # apply gravity based on state
	# print_stats() # optional debug
	
	attack_stagger_time -= 1
	if Input.is_action_just_pressed("attack") and !attacking:
		attack()
	
	#speed_boost() # manually add velocity in direction (debug/testing)
	handle_afterimage() # handle teleport-style afterimage system
	move_and_slide() # apply calculated velocity
	update_globals()
func animate():
	if movement_enabled:
		current_sprite.scale.x = facing.x * current_sprite.scale.y # flip sprite based on facing
	if Input.is_action_just_pressed("jump"): 
		current_sprite.play("jump")
		current_sprite.frame = 0
	if is_on_floor() and !Input.is_action_just_pressed("jump"): current_sprite.play("static")
	if velocity.y > 0: current_sprite.play("fall")
	if is_dashing: 
		$Particles/Dash.emitting = true
	else: $Particles/Dash.emitting = false
func get_facing() -> Vector2:
	if round(Input.get_axis("left","right")) != 0:
		facing.x = round(Input.get_axis("left","right"))
	if round(Input.get_axis("up","down")) != 0:
		facing.y = round(Input.get_axis("up","down"))
	return facing
func move(delta):
	if is_being_knocked_back and !is_pogoing: 
		return
	
	move_dir = round(Input.get_axis("left", "right")) # get input direction
	var target_speed = move_dir * max_walk_speed # determine target speed
	var accel_rate := 0.0 # base accel
	
	if is_on_floor(): accel_rate = accel # use ground accel
	else: accel_rate = air_accel # use air accel

	if !is_dashing and abs(velocity.x) <= max_walk_speed and move_dir != 0:
		velocity.x = approach(velocity.x, target_speed, accel_rate * delta * 60)
func approach(current: float, target: float, amount: float) -> float:
	if current < target:
		return min(current + amount, target)
	elif current > target:
		return max(current - amount, target)
	return target
func apply_friction(delta):
	if move_dir == 0 or (is_being_knocked_back and !is_pogoing) or is_dashing:
		if is_on_floor() and !is_dashing:
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
		if (is_jumping == true and Input.is_action_pressed("jump")) or (is_being_knocked_back and Input.is_action_pressed("attack")) or (frames_since_dash_ended < 60 and Input.is_action_pressed("jump")) or (frames_since_dash_ended < 60 and Input.is_action_pressed("dash")) or (is_pogoing and Input.is_action_pressed("attack")):
			return jump_gravity
		else:
			return jump_gravity * variable_jump_gravity_multiplier
	else:
		return fall_gravity
func apply_gravity(delta):
	if current_form == form.GHOST:
		if !is_on_floor():
			if velocity.y < max_fall_speed_gliding:
				velocity.y += (_get_gravity()/3) * delta
			else:
				velocity.y = max_fall_speed_gliding
	else:
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
		frames_since_dash_ended = 100
		if dash_direction.normalized().y > 0.2 and abs(dash_direction.normalized().x) > 0.2 :
			velocity.y = jump_velocity / 1.5
			velocity.x = wavedash_vel * facing.x
		else: 
			velocity.y = jump_velocity
			velocity.x = (dash_velocity * 0.8) * dash_direction.normalized().x
		end_dash(true) # ends the dash cleanly
	else:
		velocity.y = jump_velocity
func double_jump():
	if current_form == form.BUTTERFLY:
		velocity.y = jump_velocity
		is_jumping = true
		coyote_time = 0
		double_jump_used = true
		$Particles/DoubleJump.emitting = true
	else: 
		change_form(form.BUTTERFLY)
		is_being_knocked_back = false
		velocity.y = jump_velocity
		is_jumping = true
		coyote_time = 0
		double_jump_used = true
		$Particles/DoubleJump.emitting = true
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
	if Input.is_action_just_pressed("dash") and can_dash and !is_dashing and frames_since_dash_ended > dash_attack:
		if current_form == form.FOX:
			begin_dash()
		else: 
			change_form(form.FOX)
			begin_dash()
func begin_dash():
	emit_signal("dash_started")
	camera.freeze_frames(0.2, 0.06)
	current_control_method = detect_controller()
	$Particles/Dash.rotation = -Vector2.RIGHT.angle_to(dash_direction.normalized())
	
	if options.eight_direction_dash:
		dash_direction = round(Input.get_vector("left", "right", "up", "down"))
	else:
		if current_control_method == "controller":
			dash_direction = Input.get_vector("left", "right", "up", "down")
		else: 
			dash_direction = get_viewport().get_mouse_position() - Vector2((get_viewport().size.x / 2),(get_viewport().size.y / 2))
	if dash_direction == Vector2.ZERO:
		dash_direction.x = facing.x

	is_dashing = true
	can_dash = false
	frames_since_dash = 0
	
	dash_x = dash_velocity * dash_direction.normalized().x
	dash_y = dash_velocity * dash_direction.normalized().y

	# Preserve horizontal momentum if already higher than dash
	if abs(velocity.x) > abs(dash_x) and sign(velocity.x) == sign(dash_x):
		dash_x = ((dash_velocity * dash_direction.normalized().x)/3) + velocity.x # only give a third of the additional dash momentum to prevent large buildup of speed from a wavedash
	velocity.x = dash_x

	velocity.y = dash_y
func continue_dash():
	frames_since_dash += 1

	# Optionally force constant velocity if needed
	velocity.x = dash_x #velocity * dash_direction.normalized().x
	velocity.y = dash_y #velocity * dash_direction.normalized().y

	if frames_since_dash >= dash_frames:
		end_dash(false)
func end_dash(bypass_clamp : bool):
	is_dashing = false
	frames_since_dash = -1
	if !bypass_clamp:
	# Optional: clamp X if the dash wasn't downward
		if dash_direction.normalized().y < 0.2 or is_on_floor():
			velocity.x = clamp(velocity.x, -max_walk_speed, max_walk_speed)
		if dash_direction.y < 0:
			velocity.y = clamp(velocity.y, -max_walk_speed, max_walk_speed)
func attack():
	attack_direction = round(Input.get_vector("left", "right", "up", "down"))
	if attack_direction == Vector2.ZERO or is_on_floor():
		attack_direction.x = facing.x
	if round(attack_direction.normalized()).y == 1 and !is_on_floor():
		attack_direction = Vector2(0,1)
	if abs(attack_direction.x) == 1: attack_direction.y = 0
	$Attack.attack(attack_direction,1,1,attack_damage,20, true)
func _attack_connected(body):
		if $Attack.did_connect:
			return
		camera.freeze_frames(0.2, 0.06)
		camera.start_shake(0.4, 0.94, 10)
		double_jump_used = false
		is_being_knocked_back = true
		attack_stagger_time = attack_stagger_frames
		$Attack.attack_connected(body)
		print("Attack connected with: ", body.name)
		#velocity -= attack_direction.normalized() * Vector2(attack_knockback_velocity,attack_knockback_velocity)
		if attack_direction.y > 0:
			velocity.y = -pogo_velocity
			is_pogoing = true
		elif attack_direction.normalized().y > -0.2 :
			if is_on_floor():
				velocity = Vector2( -attack_direction.x * (attack_knockback_velocity / (1 - friction)), -attack_knockback_bump)
			else: 
				velocity = Vector2( -attack_direction.x * attack_knockback_velocity, -attack_knockback_bump)
func trigger_death():
	emit_signal("dead")
	position = globals.respawn_pos
	print("Player dead :(")
func detect_controller() -> String:
	if round(Input.get_axis("left","right")) != Input.get_axis("left","right"):
		return "controller"
	elif Input.is_action_just_pressed("detect_keyboard"):
		return "keyboard"
	else: return current_control_method
func change_form(new_form: form) -> void:
	for sprite in form_sprites.values():
		sprite.hide()
	if form_sprites.has(new_form):
		form_sprites[new_form].show()
		current_sprite = form_sprites[new_form]
		current_form = new_form
func _on_hurt_box_body_entered(body: Node2D) -> void:
	trigger_death()

func update_globals():
	globals.player_pos = position
	globals.player_is_on_floor = is_on_floor()
