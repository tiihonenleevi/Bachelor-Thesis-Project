class_name Door extends Area2D

signal player_entered_door(door: Door)

## Direction the player is moving when entering the specific door
var entry_direction: String
## How far into the room/level the player is pushed
var push_distance: int = 20
## Scene that needs to be loaded when entering the specific door
@export var new_scene_path: String
## Set by level.gd from generator data — the exact door node name to spawn at in the next room
var entry_door_name: String = ""

func _ready() -> void:
	# "DoorUp_0".to_snake_case() → "door_up_0" → slice index 1 → "up"
	entry_direction = name.to_snake_case().get_slice("_", 1)

func _on_body_entered(body: Node2D) -> void:
	# If body isn't player doesn't do anything
	if not body.is_in_group("Player"):
		return
	
	# Emits the signal that player has entered the door and gives itself as a parameter
	player_entered_door.emit(self)
	
	var gameplay_node: Gameplay = get_tree().get_first_node_in_group("Gameplay")
	# Variable for the scene the door is in
	var scene_to_unload: Node = gameplay_node.current_level
	
	SceneManager.swap_scenes_zelda(new_scene_path, gameplay_node.level_holder, scene_to_unload, get_move_dir())

## Returns the starting location of the player based on the door's location and the
## entry_direction (the Vector towards the room/level)
func get_player_entry_vector() -> Vector2:
	var vector: Vector2
	# Check the entry direction
	match entry_direction:
		"left": vector = Vector2.LEFT
		"right": vector = Vector2.RIGHT
		"up": vector = Vector2.UP
		"down": vector = Vector2.DOWN
	# Return Vector2 according to entry direction
	return global_position + (-vector * push_distance)

## Inverts entry direction to determine the direction player would have been moving
## when they entered the room
func get_move_dir() -> Vector2:
	var dir: Vector2 = Vector2.RIGHT
	# Check the entry direction
	match entry_direction:
		"left": dir = Vector2.LEFT
		"right": dir = Vector2.RIGHT
		"up": dir = Vector2.UP
		"down": dir = Vector2.DOWN
	# Return Vector2 according to entry direction (inverted)
	return dir
