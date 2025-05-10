extends CharacterBody2D

var move_dir : int = 0
var speed : int = 2000
var accel : int = 100
var friction : float = 0.2 # tune this value to control friction strength
var input_friction : float = 0.1
var gravity : float = 20

func _physics_process(delta: float) -> void:
	move_dir = Input.get_axis("left", "right") # get input direction
	velocity.x += (accel * move_dir) * (delta * 60)
	
	apply_friction(delta)
	apply_gravity(delta)
	move_and_slide()


func apply_friction(delta):
		if move_dir == 0:
			velocity.x -= (velocity.x * friction) * (delta * 60)
		else: 
			velocity.x -= (velocity.x * input_friction) * (delta * 60)
func apply_gravity(delta):
	if !is_on_floor():
		velocity.y += gravity * (delta * 60)
	
