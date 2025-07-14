extends CharacterBody2D
class_name entity
# Anything that needs to be applied to all creatures is done in here.

@export var code : String = "unassigned"

@export var is_damageable : bool = true

@export_category("Health")
@export var max_health : int = 5

@onready var health : int = max_health

# changes health by set amount, returns whether it killed the entity
func change_health(change:int)->bool:
	health -= floor(change)
	if (health <= 0):
		trigger_death()
		print("entity: " + code + "has died.")
	elif(health > max_health):
		health = max_health
	return health <= 0

#if you need to override this function just call super() at the end
func trigger_death():
	queue_free()
