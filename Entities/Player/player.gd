extends entity
class_name player

#============================================================
# Node refs
#============================================================
@onready var camera: Camera2D = $CameraRig/Camera

@onready var form_sprites: Dictionary = {
	form.GHOST: $"Sprites/00_Ghost",
	form.FOX: $"Sprites/01_Fox",
	form.BUTTERFLY: $"Sprites/02_Butterfly",
	form.CAT: $"Sprites/03_Cat"
}
@onready var current_sprite: Node = $"Sprites/01_Fox"

#============================================================
# Signals
#============================================================
signal dead
signal form_changed(prev_form: form, new_form: form)
signal state_changed(prev_state: state, new_state: state)
signal state_entered(s: state)
signal state_exited(s: state)

signal dash_started

#============================================================
# Enums
#============================================================
enum ControlMethod { KEYBOARD, CONTROLLER }
enum form { GHOST, FOX, BUTTERFLY, CAT }
enum state { IDLE, RUNNING, JUMPING, FALLING, DASHING, STAGGERED, DEAD }
enum ability { DASH, DOUBLE_JUMP, WALL_JUMP }

#============================================================
# Input / general
#============================================================
var current_control_method: ControlMethod = ControlMethod.KEYBOARD
var move_dir: int = 0
var facing: Vector2 = Vector2(1, 1)
var movement_multiplier: float = 2.0

static var movement_enabled: bool = true

#============================================================
# Form / state (runtime)
#============================================================
var current_form: form = form.FOX
var current_state: state = state.IDLE
var prev_state: state = state.IDLE
var is_respawning: bool = false
#============================================================
# Movement tuning
#============================================================
@export_category("Movement")
@export var accel: int = 100
@export var air_accel: int = 100
@export var wall_jump_air_accel: int = 40
@export var friction: float = 0.8
@export var air_friction: float = 0.1
@export var air_input_friction: float = 0.01
@export var input_friction: float = 0.03
@export var max_fall_speed: int = 1600
@export var max_walk_speed: int = 600

#============================================================
# Dash tuning
#============================================================
@export_category("Dash")
@export var dash_velocity: int = 1400
@export var dash_frames: int = 20
@export var wavedash_vel: int = 1800
@export var dash_refresh_frames: int = 10
var dash_attack: int = 10 # (consider exporting if you tune it often)

# Dash runtime
var can_dash: bool = true
var is_dashing: bool = false
var frames_since_dash: int = 0
var frames_since_dash_ended: int = 0
var dash_direction: Vector2 = Vector2.ZERO
var dash_x: float = 0.0
var dash_y: float = 0.0

#============================================================
# Attack tuning
#============================================================
@export_category("Attack")
@export var attack_damage: int = 1
@export var attack_knockback_velocity: float = 1000.0
@export var attack_knockback_bump: float = 600.0
@export var pogo_velocity: float = 1600.0
@export var speed_pogo_multiplier: float = 1.2
var attack_stagger_frames: int = 10

# Attack runtime
static var attacking: bool = false
var is_pogoing: bool = false
var attack_direction: Vector2 = Vector2.ZERO
var is_being_knocked_back: bool = false
var attack_stagger_time: int = 0

#============================================================
# Jump tuning
#============================================================
@export_category("Jump")
@export var jump_height: float = 300.0 * 2.0
@export var jump_seconds_to_peak: float = 0.5
@export var jump_seconds_to_descent: float = 0.4
@export var variable_jump_gravity_multiplier: float = 5.0

@export var coyote_frames: int = 8
@export var jump_buffer_frames: int = 12

@export var jump_cut_velocity: float = 600.0
@export var jump_cut_gravity_multiplier: float = 1.5
@export var jump_cut_ramp_frames: int = 6

# Jump derived (runtime)
var jump_velocity: float = 0.0
var jump_gravity: float = 0.0
var fall_gravity: float = 0.0

# Jump runtime
var jump_cut_active: bool = false
var jump_cut_timer: int = 0
var jump_buffer_time: int = 0
var coyote_time: int = 0
var is_jumping: bool = false

#============================================================
# Wall jump tuning
#============================================================
@export_category("Wall Jump")
@export var wall_jump_h_speed: int = 1400
@export var wall_jump_v_speed: int = 2200
@export var wall_coyote_frames: int = 8
@export var wall_jump_lock_frames: int = 60
@export var wall_jump_accel_ease_frames: int = 20
@export var wall_jump_accel_start_mult: float = 0.0
@export var wall_jump_tech_lock_frames: int = 20
@export var wall_slide_gravity_multiplier: float = 0.3
@export var max_fall_speed_sliding: int = 800

# Wall jump runtime
var wall_jump_accel_mult: float = 1.0
var wall_jump_ease_time: float = 1.0
var wall_coyote_time: int = 0
var wall_jump_lock_time: int = 0
var wall_normal: Vector2 = Vector2.ZERO
var wall_jump_lock_duration: int = 0
var wall_jump_lock_prev: int = 0

#============================================================
# Double jump / glide tuning
#============================================================
@export_category("Double Jump")
@export var double_jump_velocity: float = 2000.0
@export var glide_gravity_multiplier: float = 0.4
@export var max_fall_speed_gliding: int = 600

# Double jump runtime
var double_jump_used: bool = false

#============================================================
# Ability buffering
#============================================================
@export var ability_buffer_frames: int = 4
var ability_buffer_time: int = 0

#============================================================
# Afterimage runtime
#============================================================
var afterimage_cast: bool = false
var afterimage_pos: Vector2 = Vector2.ZERO

#============================================================
# Particles
#============================================================
@export_category("Particles")
@export var speed_start: float = 650.0 * 2.0
@export var speed_full: float = 900.0 * 3.0

@export var double_jump_particles: PackedScene
@export var jump_particles: PackedScene
@export var wall_jump_particles: PackedScene
@export var landing_particles: PackedScene


func _ready() -> void:
	_recompute_jump_constants()
	$"HUD/Health".bind_to_entity(self)
	Globals.get_player = self
	Globals.hazard_respawn_pos = self.position
	Globals.death_respawn_pos = self.position
	if Globals.current_room != null:
		print("found room")
		Globals.respawn_room_id = Globals.current_room_id
	Globals.player_id = get_rid()
	accel *= movement_multiplier
	air_accel *= movement_multiplier
	max_fall_speed *= movement_multiplier
	max_fall_speed_gliding *= movement_multiplier
	max_fall_speed_sliding *= movement_multiplier
	max_walk_speed *= movement_multiplier
	dash_velocity *= movement_multiplier
	wavedash_vel *= movement_multiplier
	print(jump_velocity)
func _recompute_jump_constants() -> void:
	jump_velocity = ((2.0 * jump_height) / jump_seconds_to_peak) * -1.0
	jump_gravity = ((-2.0 * jump_height) / (jump_seconds_to_peak * jump_seconds_to_peak)) * -1.0
	fall_gravity = ((-2.0 * jump_height) / (jump_seconds_to_descent * jump_seconds_to_descent)) * -1.0
func _input(event):
	if event.is_action_pressed("ability"):
		_on_ability_input(true)
	if event.is_action_pressed("form 1"):
		change_form(form.FOX)
	if event.is_action_pressed("form 2"):
		change_form(form.BUTTERFLY)
	if event.is_action_pressed("form 3"):
		change_form(form.CAT)
	if event.is_action_pressed("attack") and !attacking:
		attack()
	if event.is_action_pressed("jump") and !is_jumping: #FIX THIS LINE, YOU SHOULD STILL BE ABLE TO DOUBLE JUMP WHILE JUMPING
		if coyote_time > 0:
			jump() # jump if coyote time is active
		elif can_use_ability(ability.WALL_JUMP) and !is_on_floor() and !is_dashing:
			wall_jump()
		elif !double_jump_used and !is_on_floor() and !is_dashing:
			double_jump()
		else:
			jump_buffer_time = jump_buffer_frames # otherwise, buffer the jump
	if event.is_action_released("jump"):
		_on_jump_released()
	if event.is_action_pressed("afterimage"):
		if !afterimage_cast:
			afterimage_pos = self.position
			afterimage_cast = !afterimage_cast
		else:
			self.position = afterimage_pos
			afterimage_cast = !afterimage_cast

func _physics_process(delta: float) -> void:
	
	
	if not Globals.game_processing: 
		current_sprite.pause()
		return
		
	current_control_method = detect_controller()
	
	if ability_buffer_time > 0:
		_on_ability_input(false)
	
	_update_wall_state()
	_update_wall_jump_accel_ease()
	move(delta) # handles movement and player input
	get_facing() # updates facing direction
	continue_dash()
	handle_jump_frames() # handles coyote time and jump buffering
	handle_allowed_actions()
	apply_friction(delta) # apply horizontal friction
	apply_gravity(delta) # apply gravity based on state
	handle_timers()
	move_and_slide() # apply calculated velocity
	resolve_state()
	update_globals()
	animate() # handles sprite
	particles()
	handle_sfx()
	debug()
func handle_timers():
	if jump_cut_timer > 0:
		jump_cut_timer -= 1
	else:
		jump_cut_active = false

	
	attack_stagger_time -= 1
	
	if is_dashing:
		frames_since_dash_ended = 0
	else: frames_since_dash_ended += 1
func handle_allowed_actions():
	if velocity.y > 0:
		is_jumping = false # reset jump state on descent
		is_being_knocked_back =  false
		is_pogoing = false
	if attack_stagger_time > 0:
		movement_enabled = false
	else: 
		movement_enabled = true
	if (is_on_floor() and frames_since_dash > dash_frames - dash_refresh_frames) or (is_on_floor() and frames_since_dash == -1):
		can_dash = true
		
var speed_rings_active : bool = false
func particles() -> void:
	# SPEED RINGS
	var rings: GPUParticles2D = $Particles/SpeedRings as GPUParticles2D
	var speed_x : float = abs(velocity.x)
	var t: float = inverse_lerp(speed_start, speed_full, speed_x)
	t = clamp(t, 0.0, 1.0)
	var active_now : bool = t > 0.01
	var was_active : bool = speed_rings_active
	if active_now and not was_active:
		rings.restart()
	if (not active_now) and was_active:
		rings.restart()
	speed_rings_active = active_now
	rings.emitting = active_now
	rings.amount_ratio = t
	rings.modulate.a = t
	
func spawn_feet_particles(particles: PackedScene):
	var p = particles.instantiate()
	$Particles.add_child(p)
	p.global_position = global_position + Vector2(0, 160)
	p.emitting = true
	if particles == wall_jump_particles:
		p.global_position = global_position + Vector2((100 * -wall_normal.x), 160.0)
	
	# JUMP PARTICLES
func animate():
	if movement_enabled:
		current_sprite.scale.x = facing.x * current_sprite.scale.y # flip sprite based on facing
	match current_state:
		state.JUMPING:
			current_sprite.play("jump")
		state.IDLE:
			current_sprite.play("static")
		state.FALLING:
			current_sprite.play("fall")
		state.RUNNING:
			current_sprite.play("static")
		state.DASHING:
			pass
func get_facing() -> Vector2:
	if round(Input.get_axis("left","right")) != 0:
		facing.x = round(Input.get_axis("left","right"))
	if round(Input.get_axis("up","down")) != 0:
		facing.y = round(Input.get_axis("up","down"))
	return facing
func move(delta):
	if !movement_enabled:
		return
	if is_being_knocked_back and !is_pogoing:
		return

	move_dir = round(Input.get_axis("left", "right"))
	var target_speed = float(move_dir) * float(max_walk_speed)

	var accel_rate : float = 0.0
	if is_on_floor():
		accel_rate = float(accel)
	else:
		accel_rate = float(air_accel) * wall_jump_accel_mult

	if is_dashing:
		return

	# --- Ground: same as before ---
	if is_on_floor():
		if move_dir != 0:
			velocity.x = approach(velocity.x, target_speed, accel_rate * delta * 60.0)
		return

	# --- Air: preserve wavedash speed unless you're actively opposing it ---
	if move_dir == 0:
		# no input: don't "approach" toward 0, let friction handle it
		return

	var same_dir : bool = sign(velocity.x) == sign(target_speed)
	var above_cap : bool = abs(velocity.x) > float(max_walk_speed)

	if above_cap and same_dir:
		# you're already faster than cap in the same direction:
		# allow NO extra accel, preserve momentum
		return

	# otherwise (turning or under cap): allow steering
	velocity.x = approach(velocity.x, target_speed, accel_rate * delta * 60.0)

func approach(current: float, target: float, amount: float) -> float:
	if current < target:
		return min(current + amount, target)
	elif current > target:
		return max(current - amount, target)
	return target
func apply_friction(delta):
	if wall_jump_lock_time > 0:
		return
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
	if velocity.y < 0.0:
		# held jump = normal ascent gravity
		var holding_jump : bool = Input.is_action_pressed("jump")

		if (is_jumping and holding_jump) or (is_being_knocked_back and Input.is_action_pressed("attack")) or (frames_since_dash_ended < 60 and Input.is_action_pressed("jump")) or (frames_since_dash_ended < 60 and Input.is_action_pressed("dash")) or (is_pogoing and Input.is_action_pressed("attack")) or ((current_form == form.BUTTERFLY or current_form == form.CAT) and Input.is_action_pressed("ability") and is_jumping):
			jump_cut_active = false
			jump_cut_timer = 0
			return jump_gravity

		# released jump = gentle extra gravity, eased in over a few frames
		var t : float = 1.0
		if jump_cut_active and jump_cut_ramp_frames > 0:
			t = 1.0 - (float(jump_cut_timer) / float(jump_cut_ramp_frames))
			t = clamp(t, 0.0, 1.0)

		var mult : float = lerp(1.0, jump_cut_gravity_multiplier, t)
		return jump_gravity * mult

	# falling
	if is_on_wall() and current_form == form.CAT:
		return fall_gravity * wall_slide_gravity_multiplier
	if Input.is_action_pressed("jump") and current_form == form.BUTTERFLY:
		return fall_gravity * glide_gravity_multiplier
	return fall_gravity

func apply_gravity(delta):
	if is_dashing:
		return
	if (current_form == form.GHOST or current_form == form.BUTTERFLY) and Input.is_action_pressed("jump"):
		if !is_on_floor():
			if velocity.y < max_fall_speed_gliding:
				velocity.y += (_get_gravity()) * delta
			else:
				velocity.y = max_fall_speed_gliding
	else:
		if !is_on_floor():
			if is_on_wall() and current_form == form.CAT:
				if velocity.y < max_fall_speed_sliding:
					velocity.y += (_get_gravity()) * delta
				else: 
					velocity.y = max_fall_speed_sliding
			else:
				if velocity.y < max_fall_speed:
					velocity.y += _get_gravity() * delta
				else: 
					velocity.y = max_fall_speed
func jump():
	enter_state(state.JUMPING)
	spawn_feet_particles(jump_particles)
	current_sprite.frame = 0
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
func _on_jump_released() -> void:
	# Only cut if we're still going up in a jump we initiated
	if is_jumping and velocity.y < 0.0:
		# Jump-cut: cap upward velocity so minimum jump stays low without huge gravity
		velocity.y = max(velocity.y, -jump_cut_velocity)

		jump_cut_active = true
		jump_cut_timer = jump_cut_ramp_frames
		is_jumping = false

func double_jump():
	if current_form == form.BUTTERFLY:
		velocity.y = -double_jump_velocity
		is_jumping = true
		enter_state(state.JUMPING)
		coyote_time = 0
		double_jump_used = true
		spawn_feet_particles(double_jump_particles)
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
		
	if is_on_floor():
		double_jump_used = false
		is_pogoing = false
		if jump_buffer_frames == 0: 
			is_jumping = false # reset jump state on landing
			is_being_knocked_back = false
func print_stats():
	print("Coyote Time: ",coyote_time)
	print("is on floor: ", is_on_floor())
	print("is jumping: ", is_jumping)
func speed_boost():
	var ui_dir : Vector2
	ui_dir = Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	velocity += Vector2(4000,4000) * ui_dir
func begin_dash():
	emit_signal("dash_started")
	$CameraRig.freeze_frames(0.2, 0.06)
	current_control_method = detect_controller()
	$Particles/Dash.rotation = -Vector2.RIGHT.angle_to(dash_direction.normalized())
	
	dash_direction = round(Input.get_vector("left", "right", "up", "down"))
	if dash_direction == Vector2.ZERO:
		dash_direction.x = facing.x
	enter_state(state.DASHING)
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
	if !is_dashing:
		return
	frames_since_dash += 1
	# Optionally force constant velocity if needed
	velocity.x = dash_x #velocity * dash_direction.normalized().x
	velocity.y = dash_y #velocity * dash_direction.normalized().y
	if frames_since_dash >= dash_frames:
		end_dash(false)
func end_dash(bypass_clamp : bool) -> void:
	is_dashing = false
	frames_since_dash = -1

	if !bypass_clamp:
		var dir_n : Vector2 = dash_direction.normalized()

		# Keep your X rule
		if dir_n.y < 0.2 or is_on_floor():
			velocity.x = clamp(velocity.x, -max_walk_speed, max_walk_speed)

		# New: always cap upward momentum (scaled by diagonal-ness)
		var up_cap : float = float(max_walk_speed) * abs(dir_n.y)
		velocity.y = max(velocity.y, -up_cap)

	# Force leave DASHING immediately
	if is_on_floor():
		if move_dir != 0:
			enter_state(state.RUNNING)
		else:
			enter_state(state.IDLE)
	else:
		if velocity.y < 0.0:
			enter_state(state.JUMPING)
		else:
			enter_state(state.FALLING)

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
		$CameraRig.freeze_frames(0.2, 0.06)
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
			if abs(velocity.x) > max_walk_speed:
				velocity.x *= speed_pogo_multiplier
		elif attack_direction.normalized().y > -0.2 :
			if is_on_floor():
				velocity = Vector2( -attack_direction.x * (attack_knockback_velocity / (1 - friction)), -attack_knockback_bump)
			else: 
				if velocity.y > -100:
					velocity = Vector2( -attack_direction.x * attack_knockback_velocity, velocity.y -attack_knockback_bump)
				else:
					velocity = Vector2( -attack_direction.x * attack_knockback_velocity, velocity.y)
func trigger_hazard_death(damage_dealt : int = 1):
	$CameraRig.freeze_frames(0.1, 0.3)
	$CameraRig/Camera.start_shake(2.0, 0.94, 12)
	await $CameraRig._freeze_frames_finished
	damage(damage_dealt)
	if current_state == state.DEAD:
		return
	position = Globals.hazard_respawn_pos
func trigger_death() -> void:
	if is_respawning:
		return
	is_respawning = true

	enter_state(state.DEAD)
	velocity = Vector2.ZERO
	movement_enabled = false

	# IMPORTANT: use the DEATH respawn you set at the totem
	var respawn_pos: Vector2 = Globals.death_respawn_pos
	var respawn_room: String = Globals.respawn_room_id

	# If your enter_room recreates/moves the player, you usually don't want to set position first.
	# Prefer: have enter_room place the player at respawn_pos (see note below).
	Globals.enter_room(respawn_room, facing)

	# If enter_room does NOT reposition player, do it after:
	position = respawn_pos

	set_health(max_health)
	print("Player dead :(")
	# Optional: re-enable once the room transition finishes (better if Globals toggles this)
	movement_enabled = true
	is_respawning = false
func detect_controller() -> ControlMethod:
	if round(Input.get_axis("left","right")) != Input.get_axis("left","right"):
		return ControlMethod.CONTROLLER
	elif Input.is_action_just_pressed("detect_keyboard"):
		return ControlMethod.KEYBOARD
	else: return current_control_method
func change_form(new_form: form) -> void:
	if current_form == new_form:
		return
	wall_jump_lock_time = min(wall_jump_lock_time, wall_jump_tech_lock_frames)
	var prev_form: form = current_form

	for sprite: Node in form_sprites.values():
		sprite.hide()

	if form_sprites.has(new_form):
		form_sprites[new_form].show()
		current_sprite = form_sprites[new_form]
		current_form = new_form

	emit_signal("form_changed", prev_form, current_form)
func _on_hurt_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("Hazard"):
		trigger_hazard_death()
func enter_state(new_state: state) -> void:
	if current_state == new_state:
		return
	if !state_allowed(new_state):
		return
	var old_state: state = current_state
	emit_signal("state_exited", old_state)
	_on_exit_state(old_state)
	prev_state = old_state
	current_state = new_state
	emit_signal("state_changed", old_state, current_state)
	emit_signal("state_entered", current_state)
	_on_enter_state(current_state)
func _on_enter_state(entered_state: state) -> void:
	match entered_state:
		state.RUNNING, state.IDLE:
			if prev_state == state.FALLING:
				spawn_feet_particles(landing_particles)
		state.DASHING:
			$Particles/Dash.emitting = true
		_:
			pass

func _on_exit_state(exited_state: state) -> void:
	match exited_state:
		state.DASHING:
			$Particles/Dash.emitting = false
		state.RUNNING:
			AudioManager.stop_loop("footstep")
		_:
			pass
func is_state_transition(from_state: state, to_state: state) -> bool:
	return prev_state == from_state and current_state == to_state
func state_allowed(tested_state: state) -> bool:
	match tested_state:
		state.IDLE:
			return true
		state.RUNNING:
			if is_on_floor():
				return true
			else:
				return false
		state.JUMPING:
			return true
		state.FALLING:
			if !is_on_floor():
				return true
			else:
				return false
		state.DASHING:
			if current_form == form.FOX:
				return true
			else:
				return false
		state.STAGGERED:
			return true
		state.DEAD:
			return true
	return false
func resolve_state(ending_dash : bool = false) -> state:
	if current_state == state.DASHING and !ending_dash:
		return current_state

	if is_on_floor():
		if move_dir != 0:
			enter_state(state.RUNNING)
		else:
			enter_state(state.IDLE)
		return current_state

	# airborne
	if velocity.y < 0.0:
		enter_state(state.JUMPING)
		return current_state

	if velocity.y > 0.0:
		enter_state(state.FALLING)
		return current_state
		
	# tiny edge case: exactly 0 vertical speed midair
	return state.FALLING


func update_globals():
	Globals.player_pos = position
	Globals.player_is_on_floor = is_on_floor()
	
func debug():
	$HUD/Debug/Position.text = "Position: (%.2f, %.2f)" % [
		position.x / movement_multiplier,
		position.y / movement_multiplier,
	]
	$HUD/Debug/Velocity.text = "Velocity: (%.2f, %.2f)" % [
		velocity.x / movement_multiplier,
		velocity.y / movement_multiplier,
	]
	$HUD/Debug/State.text = "State: " + state.find_key(current_state)
	$HUD/Debug/IsOnFloor.text = "On Floor: " + str(is_on_floor())
	$HUD/Debug/IsOnWall.text = "On Wall: " + str(is_on_wall())
	$HUD/Debug/FPS.text = "FPS: %d" % int(Engine.get_frames_per_second())
	$HUD/Debug/Health.text = "Health: " + str(health)
	
func can_use_ability(ability_checked: ability) -> bool:
	match ability_checked:
		ability.DOUBLE_JUMP:
			if !double_jump_used and !is_on_floor() and !is_dashing and !is_jumping:
				return true
			else:
				return false
		ability.DASH:
			if can_dash and !is_dashing and frames_since_dash_ended > dash_attack:
				return true
			else:
				return false
		ability.WALL_JUMP:
			if current_form != form.CAT:
				return false
			if is_on_floor():
				return false
			if is_dashing:
				return false
			if wall_coyote_time <= 0:
				return false
			if wall_jump_lock_time > 0:
				return false
			return true
	return false
func _on_ability_input(fresh_input: bool = false):
	ability_buffer_time -= 1
	match current_form:
		form.FOX:
			if can_use_ability(ability.DASH):
				begin_dash()
			elif fresh_input:
				ability_buffer_time = ability_buffer_frames
		form.BUTTERFLY:
			if can_use_ability(ability.DOUBLE_JUMP):
				double_jump()
			elif fresh_input:
				ability_buffer_time = ability_buffer_frames
		form.CAT:
			if can_use_ability(ability.WALL_JUMP):
				wall_jump()
			elif fresh_input:
				ability_buffer_time = ability_buffer_frames
	
func _update_wall_state() -> void:
	# Refresh wall info first
	if is_on_floor():
		wall_coyote_time = 0
		wall_normal = Vector2.ZERO
		wall_jump_lock_time = 0
		wall_jump_lock_duration = 0
		wall_jump_lock_prev = 0
		return

	if is_on_wall():
		wall_normal = get_wall_normal()
		wall_coyote_time = wall_coyote_frames
		if !is_jumping:
			wall_jump_lock_time = 0
	else:
		wall_coyote_time = max(wall_coyote_time - 1, 0)

	# Tick lock down
	wall_jump_lock_prev = wall_jump_lock_time
	wall_jump_lock_time = max(wall_jump_lock_time - 1, 0)

	# Tech: cancel lock down to 12 (and redefine duration so accel reaches full by frame 0)
	if move_dir == wall_normal.x and wall_jump_lock_time > wall_jump_tech_lock_frames:
		wall_jump_lock_time = wall_jump_tech_lock_frames
		wall_jump_lock_duration = wall_jump_tech_lock_frames

		
func _update_wall_jump_accel_ease() -> void:
	if wall_jump_lock_time <= 0 or wall_jump_lock_duration <= 0:
		wall_jump_accel_mult = 1.0
		return

	# 0.0 at start of lock, 1.0 exactly when lock_time reaches 0
	var progress : float = 1.0 - (float(wall_jump_lock_time) / float(wall_jump_lock_duration))
	progress = clamp(progress, 0.0, 1.0)

	# linear guarantees frame-perfect "full on unlock"
	wall_jump_accel_mult = lerp(wall_jump_accel_start_mult, 1.0, progress)

func wall_jump() -> void:
	# Push away from the wall; get_wall_normal() points *out* of the wall
	var n : Vector2 = wall_normal
	if n == Vector2.ZERO:
		n = Vector2(-facing.x, 0)
	spawn_feet_particles(wall_jump_particles)
	velocity.y = -float(wall_jump_v_speed)
	velocity.x = float(wall_jump_h_speed) * n.x
	print(float(wall_jump_h_speed) * n.x)

	facing.x = sign(velocity.x)
	enter_state(state.JUMPING)
	is_jumping = true
	double_jump_used = false # optional: let wall jump refresh butterfly double-jump style

	wall_coyote_time = 0
	wall_jump_lock_time = wall_jump_lock_frames
	wall_jump_lock_duration = wall_jump_lock_frames
	
	wall_jump_ease_time = 0.0
	wall_jump_accel_mult = wall_jump_accel_start_mult
	

func _on_health_changed(current: int, max: int) -> void:
	if health != 0:
		return
	trigger_death()

func handle_sfx():
	match current_state:
		state.RUNNING:
			match current_form:
				form.CAT:
					AudioManager.play_sfx("footstep", 0.3, 2.0,  true, 0.2)
