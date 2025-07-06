extends Area2D
class_name attack

var damage : int = 0
var size : float = 20
var frames_since_attack : int = 0

func _ready():
	end_attack()
	
func _physics_process(delta):
	frames_since_attack -= 1
	if frames_since_attack == 0:
		end_attack()

func attack(direction : Vector2 = Vector2(1,0), scale_x : float = 1,  scale_y : float = 1, damage : int = 0, time : int = 20, player : bool = false) -> bool: 
	frames_since_attack = time
	self.rotation = Vector2.RIGHT.angle_to(direction.normalized())
	$Sprite.show()
	$AttackHitbox.disabled = false
	self.scale = Vector2(scale_x,scale_y)
	if self.has_overlapping_bodies():
		return true
	else: 
		return false
	
func end_attack():
	$Sprite.hide()
	$AttackHitbox.disabled = true
