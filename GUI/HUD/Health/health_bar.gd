extends Control
class_name HealthBar

@export var tick_scene: PackedScene
@onready var ticks: HBoxContainer = $HealthTicks

var _tick_nodes: Array[HealthTick] = []

func bind_to_entity(target: entity) -> void:
	target.health_changed.connect(_on_health_changed)
	_on_health_changed(target.health, target.max_health)

func _on_health_changed(current: int, max: int) -> void:
	_ensure_tick_count(max)
	for i in range(max):
		_tick_nodes[i].set_filled(i < current)

func _ensure_tick_count(max: int) -> void:
	if _tick_nodes.size() == max:
		return

	for child in ticks.get_children():
		child.queue_free()
	_tick_nodes.clear()

	for i in range(max):
		var tick: HealthTick = tick_scene.instantiate() as HealthTick
		ticks.add_child(tick)
		_tick_nodes.append(tick)
