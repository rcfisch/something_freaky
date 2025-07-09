extends Area2D
class_name attack
var attack_frames : int = 20
var damage : int = 0
var size : float = 20
var frames_remaining : int = 0
var is_player : bool = false
var did_connect : bool = false

func _ready():
	end_attack()
	
func _physics_process(delta):
	frames_remaining -= 1
	if frames_remaining == 0:
		end_attack()
	if frames_remaining == attack_frames - 5:
		$AttackHitbox.disabled = true
		$AttackHitbox.scale = Vector2.ZERO

func attack(direction : Vector2 = Vector2(1,0), scale_x : float = 1,  scale_y : float = 1, damage : int = 0, time : int = 20, attack_from_player : bool = false) -> bool: 
	$Sprite.frame = 0
	$Sprite.play("default")
	attack_frames = time
	did_connect = false
	frames_remaining = time
	self.rotation = Vector2.RIGHT.angle_to(direction.normalized())
	$Sprite.show()
	$AttackHitbox.disabled = false
	self.scale = Vector2(scale_x,scale_y)
	$AttackHitbox.scale = Vector2(1,1)
	is_player = attack_from_player
	if is_player: player.attacking = true
	if self.has_overlapping_bodies():
		return true
	else: 
		return false
	
func end_attack():
	$Sprite.hide()
	$AttackHitbox.disabled = true
	self.scale = Vector2.ZERO
	if is_player: player.attacking = false
	
func attack_connected():
	$ConnectParticles.emitting = true
	$ConnectParticles2.emitting = true
	did_connect = true
	$AttackHitbox.disabled = true
	$AttackHitbox.scale = Vector2.ZERO
	
