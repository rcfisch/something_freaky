extends Node
class_name globals

static var game_paused : bool = false

static var player_is_on_floor : bool
static var player_pos : Vector2
static var player_id : RID
static var respawn_pos : Vector2

static var current_room : room = room.new()


class room:
	var enemies : Array[Object]
