extends CharacterBody2D
class_name entity

# Anything that needs to be applied to all creatures is done in here.

signal health_changed(current: int, max: int)

@export var code : String = "unassigned"

@export var is_damageable : bool = true
@export var knockback_velocity : Vector2 = Vector2.ZERO
@export var _friction: float = 0.3
@export var _air_friction: float = 0.05
@export var _max_fall_speed: int = 1600

@export_category("Health")
@export var max_health : int = 5
@onready var health : int = max_health

func set_max_health(new_max: int, keep_ratio: bool = false) -> void:
	new_max = maxi(1, new_max)
	if keep_ratio:
		var ratio: float = float(health) / float(max_health)
		max_health = new_max
		health = clampi(int(round(ratio * float(max_health))), 0, max_health)
	else:
		max_health = new_max
		health = clampi(health, 0, max_health)
	emit_signal(&"health_changed", health, max_health)

func damage(amount: int = 1) -> bool:
	print("DAMAGE:", amount, " health before:", health)
	health = clampi(health - amount, 0, max_health)
	print(" health after:", health)
	print("Hazard respawn pos: ", Globals.hazard_respawn_pos)
	print("Death respawn pos: ", Globals.death_respawn_pos)
	emit_signal(&"health_changed", health, max_health)

	if health <= 0:
		emit_signal(&"died")
		trigger_death()
		return true
	return false

	
func heal(amount: int = 1) -> void:
	if amount <= 0:
		return
	health = clampi(health + amount, 0, max_health)
	emit_signal(&"health_changed", health, max_health)
	
func set_health(value: int) -> void:
	health = clampi(value, 0, max_health)
	emit_signal(&"health_changed", health, max_health)
	
func knockback(attack_direction):
	velocity += knockback_velocity * attack_direction
	
func apply_friciton(delta):
		if is_on_floor():
			velocity.x -= (velocity.x * _friction) * (delta * 60)
		else:
			velocity.x -= (velocity.x * _air_friction) * (delta * 60)
#if you need to override this function just call super() at the end
func trigger_death():
	queue_free()

func gravity(delta):
	if velocity.y < _max_fall_speed:
		velocity.y += 4000 * delta
	else: 
		velocity.y = _max_fall_speed
