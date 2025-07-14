extends Node
class_name globals

static var game_paused : bool = false

static var player_pos : Vector2
static var respawn_pos : Vector2

static var current_room : room


class room:
	var enemies : Array[enemy]
