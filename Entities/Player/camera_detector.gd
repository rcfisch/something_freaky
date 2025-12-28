extends Area2D
class_name CameraDetector

@onready var rig: CameraRig2D = get_parent().get_node("CameraRig") as CameraRig2D

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _on_area_entered(a: Area2D) -> void:
	var z: CameraZone = a as CameraZone
	if z != null:
		rig.register_zone(z)

func _on_area_exited(a: Area2D) -> void:
	var z: CameraZone = a as CameraZone
	if z != null:
		rig.unregister_zone(z)
