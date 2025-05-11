extends entity
class_name living_entity

@export var is_damageable : bool = true

@export_category("Health")
@export var max_health : int = 5
@export var weaknesses : Array[damage_types]
@export var resistances : Array[damage_types]

@onready var health : int = max_health

# changes health by set amount, returns whether it killed the entity
func change_health(change:int, types:Array[damage_types]=[])->bool:
	#the mod variable
	var mod:float = 1
	#calculates modifications
	for type in types:
		if weaknesses.has(type):
			mod = mod * 0.75
		if resistances.has(type):
			mod = mod ** 1.5
	#the actual health calculation
	health -= floor(change*mod)
	#if health at or below 0 trigger death
	if (health <= 0):
		trigger_death()
		print("entity: " + code + "has died.")
	#prevents health going above max health
	elif(health > max_health):
		health = max_health
	return health <= 0 # returns whether it was a death blow

#if you need to override this function just call super() at the end
func trigger_death():
	#destroys the enemy object
	queue_free()
