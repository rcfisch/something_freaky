extends CharacterBody2D
class_name entity

# Anything that needs to be applied to all creatures is done in here.

signal health_changed(current: int, max: int)

@export var code : String = "unassigned"

@export var is_damageable : bool = true

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
	print("Hazard respawn pos: ",Globals.hazard_respawn_pos)
	print("Death respawn pos: ",Globals.death_respawn_pos)
	emit_signal(&"health_changed", health, max_health)
	if health <= 0:
		emit_signal(&"died")
	return health <= 0

	
func heal(amount: int = 1) -> void:
	if amount <= 0:
		return
	health = clampi(health + amount, 0, max_health)
	emit_signal(&"health_changed", health, max_health)
	
func set_health(value: int) -> void:
	health = clampi(value, 0, max_health)
	emit_signal(&"health_changed", health, max_health)
	
#if you need to override this function just call super() at the end
func trigger_death():
	queue_free()
