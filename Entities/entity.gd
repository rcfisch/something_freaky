extends CharacterBody2D
class_name entity
# Anything that needs to be applied to all creatures is done in here.

@export var code : String = "unassigned"

#@onready var room_code : String

enum damage_types{
	piercing,
	bludgen,
	slash,
	fire,
	water,
	air,
	earth
}
