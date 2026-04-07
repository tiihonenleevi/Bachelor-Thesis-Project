class_name Door extends Area2D

signal player_entered_door(door: Door)

## Direction the player is moving when entering the specific door
var entry_direction: String
## Transition type for the specific door
#var transition_type: String = "wipe_to_"

## How far into the room/level the player is pushed
var push_distance: int = 20
## Scene that needs to be loaded when entering the specific door
@export var new_scene_path: String
## The name of the door the player enters in the new scene
var entry_door_name: String = "Door"

func _ready() -> void:
	entry_direction = name.to_snake_case().get_slice("_", 1)
	#transition_type += entry_direction
	if entry_direction == "up":
		entry_door_name += "Down"
	elif entry_direction == "right":
		entry_door_name += "Left"
	elif entry_direction == "down":
		entry_door_name += "Up"
	elif entry_direction == "left":
		entry_door_name += "Right"

func _on_body_entered(body: Node2D) -> void:
	print("attempting to move to " + entry_door_name)
	# If body isn't player doesn't do anything
	if not body.is_in_group("Player"):
		return
	
	# Emits the signal that player has entered the door and gives itself as a parameter
	player_entered_door.emit(self)
	
	var gameplay_node: Gameplay = get_tree().get_first_node_in_group("Gameplay") as Gameplay
	# Variable for the scene the door is in
	var scene_to_unload: Node = gameplay_node.current_level
	
	SceneManager.swap_scenes_zelda(new_scene_path, gameplay_node.level_holder, scene_to_unload, get_move_dir())
	# Cleans up the door
	#queue_free()

## Returns the starting location of the player based on the door's location and the
## entry_direction (the Vector towards the room/level)
func get_player_entry_vector() -> Vector2:
	var vector: Vector2 = Vector2.RIGHT
	# Check the entry direction
	match entry_direction:
		"left":
			vector = Vector2.LEFT
		"right":
			vector = Vector2.RIGHT
		"up":
			vector = Vector2.UP
		"down":
			vector = Vector2.DOWN
	# Return Vector2 according to entry direction
	return global_position + (-vector * push_distance)

## Inverts entry direction to determine the direction player would have been moving
## when they entered the room
func get_move_dir() -> Vector2:
	var dir: Vector2 = Vector2.RIGHT
	# Check the entry direction
	match entry_direction:
		"left":
			dir = Vector2.LEFT
		"right":
			dir = Vector2.RIGHT
		"up":
			dir = Vector2.UP
		"down":
			dir = Vector2.DOWN
	# Return Vector2 according to entry direction (inverted)
	return dir
