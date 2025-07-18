extends Node2D
class_name CameraRegion2D

@onready var polygon := $CollisionPolygon2D

func get_clamped_point(global_point: Vector2) -> Vector2:
	if not polygon.polygon or polygon.polygon.size() < 3:
		return global_point

	var local_point = to_local(global_point)

	if Geometry2D.is_point_in_polygon(local_point, polygon.polygon):
		return global_point

	var closest_point = null
	var closest_dist = INF

	var poly = polygon.polygon
	for i in poly.size():
		var a = poly[i]
		var b = poly[(i + 1) % poly.size()]
		var segment_closest = Geometry2D.get_closest_point_to_segment(local_point, a, b)
		var dist = local_point.distance_to(segment_closest)
		if dist < closest_dist:
			closest_dist = dist
			closest_point = segment_closest

	return to_global(closest_point)
