extends entity
class_name living_entity

@export var is_damageable : bool

@export_category("Health")
@export var max_health : int
@export var weaknesses : Array[damage_types]
@export var resistances : Array[damage_types]

@onready var health : int = max_health
