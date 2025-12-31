extends Node2D
class_name CameraRig2D

@export var follow_smooth: float = 14.0
@export var look_lerp_speed: float = 0.12
@export var reset_lerp_speed: float = 0.2

@onready var cam = $Camera

var _player: CharacterBody2D

var _zones_overlapping: Array[CameraZone] = []
var _active_zone: CameraZone

# Per-zone (or defaults)
var vertical_offset: float = -300.0
var look_down_offset: float = 600.0
var look_ahead_offset: float = 400.0
var frames_to_look_down: int = 40

# Runtime look state
var looking_down: bool = false
var down_frames_held: int = 0
var _current_y_offset: float = -300.0
var _current_x_offset: float = 0.0

signal _freeze_frames_finished()

func _ready() -> void:
	top_level = true
	_player = get_parent() as CharacterBody2D
	if _player == null:
		push_error("CameraRig2D must be a child of a CharacterBody2D.")
		return

	_apply_zone_settings(null)
	_current_y_offset = vertical_offset
	global_position = _player.global_position + Vector2(0.0, _current_y_offset)

func _process(delta: float) -> void:
	if _player == null:
		return

	_update_look_logic()

	var desired: Vector2 = _compute_desired_target()
	var clamped: Vector2 = _apply_zone_edge_clamp(desired)

	# Smooth follow (single source of truth)
	if Globals.game_processing:
		var t: float = 1.0 - exp(-follow_smooth * delta)
		global_position = global_position.lerp(clamped, t)

	# Pixel-snapping (optional): apply to rig instead of camera
	global_position = global_position.round()

func _update_look_logic() -> void:
	# Look-down only when holding down + on floor (replace globals.player_is_on_floor)
	if Input.is_action_pressed("down") and _player.is_on_floor():
		down_frames_held += 1
		if down_frames_held > frames_to_look_down:
			looking_down = true
	else:
		down_frames_held = 0
		looking_down = false

	# Smooth offsets
	var axis: float = Input.get_axis("left", "right")
	var target_x: float = axis * look_ahead_offset
	_current_x_offset = lerp(_current_x_offset, target_x, look_lerp_speed)

	var target_y: float = vertical_offset
	if looking_down:
		target_y = look_down_offset

	_current_y_offset = lerpf(_current_y_offset, target_y, 0.1 if looking_down else reset_lerp_speed)

func _compute_desired_target() -> Vector2:
	var base: Vector2 = _player.global_position
	return base + Vector2(_current_x_offset, _current_y_offset)

func _get_camera_half_extents() -> Vector2:
	var visible_size: Vector2 = cam.get_viewport().get_visible_rect().size
	var zoom: Vector2 = cam.zoom
	return (visible_size * 0.5) / zoom


func _apply_zone_edge_clamp(pos: Vector2) -> Vector2:
	if _active_zone == null:
		return pos

	var rect: Rect2 = _active_zone.get_global_rect()
	var half: Vector2 = _get_camera_half_extents()

	var min_x: float = rect.position.x + half.x
	var max_x: float = rect.position.x + rect.size.x - half.x
	var min_y: float = rect.position.y + half.y
	var max_y: float = rect.position.y + rect.size.y - half.y

	# If the zone is smaller than the viewport, force center
	if min_x > max_x:
		min_x = rect.position.x + rect.size.x * 0.5
		max_x = min_x
	if min_y > max_y:
		min_y = rect.position.y + rect.size.y * 0.5
		max_y = min_y

	return Vector2(
		clamp(pos.x, min_x, max_x),
		clamp(pos.y, min_y, max_y)
	)

func register_zone(zone: CameraZone) -> void:
	if zone == null:
		return
	if _zones_overlapping.has(zone):
		return
	_zones_overlapping.append(zone)
	_refresh_active_zone()

func unregister_zone(zone: CameraZone) -> void:
	if zone == null:
		return
	_zones_overlapping.erase(zone)
	_refresh_active_zone()

func _refresh_active_zone() -> void:
	# If we're not overlapping any zones, keep the last active zone.
	# This is the "sticky bounds" behavior.
	if _zones_overlapping.is_empty():
		return

	var best: CameraZone = null
	var best_priority: int = -999999

	for z: CameraZone in _zones_overlapping:
		if z == null:
			continue
		if z.zone_priority > best_priority:
			best_priority = z.zone_priority
			best = z

	# Only switch if we found a valid zone
	if best != null and best != _active_zone:
		_active_zone = best
		_apply_zone_settings(_active_zone)



	_active_zone = best
	_apply_zone_settings(_active_zone)

func _apply_zone_settings(zone: CameraZone) -> void:
	if zone == null:
		# Defaults (match your current script)
		look_ahead_offset = 400.0
		vertical_offset = -300.0
		look_down_offset = 600.0
		frames_to_look_down = 40
		return

	look_ahead_offset = zone.look_ahead_offset
	vertical_offset = zone.vertical_offset
	look_down_offset = zone.look_down_offset
	frames_to_look_down = zone.frames_to_look_down

func start_shake(strength: float = 1.0, decay: float = 0.85, max_offset: float = 8.0) -> void:
	if cam != null:
		cam.start_shake(strength, decay, max_offset)

func freeze_frames(timescale: float, duration: float) -> void:
	Engine.time_scale = timescale
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
	emit_signal("_freeze_frames_finished")

func snap_to_current() -> void:
	# Instantly place camera at correct clamped spot (no smoothing).
	var desired: Vector2 = _compute_desired_target()
	var clamped: Vector2 = _apply_zone_edge_clamp(desired)
	global_position = clamped

func snap_to_zone_for_player_position() -> void:
	# Pick best zone for the player's current position, then snap.
	_set_active_zone_from_player_position()
	snap_to_current()
	
func _set_active_zone_from_player_position() -> void:
	var zones: Array = get_tree().get_nodes_in_group(&"camera_zones")
	var player_pos: Vector2 = _player.global_position

	var best: CameraZone = null
	var best_priority: int = -999999
	var best_dist_sq: float = INF

	for n: Node in zones:
		var z: CameraZone = n as CameraZone
		if z == null:
			continue

		var rect: Rect2 = z.get_global_rect()

		# Prefer zones that CONTAIN the player
		if rect.has_point(player_pos):
			if z.zone_priority > best_priority:
				best_priority = z.zone_priority
				best = z
			continue

		# Otherwise, compute distance to rect (for "nearest zone" fallback)
		var d_sq: float = _distance_sq_point_to_rect(player_pos, rect)
		if d_sq < best_dist_sq:
			best_dist_sq = d_sq
			best = z
			best_priority = z.zone_priority

	_active_zone = best
	_apply_zone_settings(_active_zone)

func _distance_sq_point_to_rect(p: Vector2, r: Rect2) -> float:
	var cx: float = clamp(p.x, r.position.x, r.position.x + r.size.x)
	var cy: float = clamp(p.y, r.position.y, r.position.y + r.size.y)
	var d: Vector2 = p - Vector2(cx, cy)
	return d.length_squared()

func clear_active_zone() -> void:
	_active_zone = null
