class_name Level extends Node2D

## All levels extend from this class.
@onready var player: Player = $"/root/Gameplay/Player"
@export var doors: Array[Door] # Holds all the doors in the spesific level
var data: LevelDataHandoff
@onready var tile_map: TileMapLayer = $Environment

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player.disable()
	player.visible = false
	
	# Auto-populate doors from children — always fresh, never stale
	for child in get_children():
		if child is Door:
			doors.append(child)
	
	# This block allows to test current scene without needing the SceneManager to call these
	if data == null:
		init_scene()
		start_scene()

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("change_doors"):
		replace_door_tiles()

## When a class implements this, SceneManager.on_content_finished_loading will invoke it
## to receive this data and pass it to the next scene.
func get_data():
	return data

## Emitted at the beginning of SceneManager.on_content_finished_loading.
## When a class implements this, SceneManager.on_content_finished_loading will invoke it
## to insert data received from the previous scene
## [b][color_plum]data[/color][/b] - Possible data (such as move_dir) received from previous scene
func receive_data(received_data) -> void:
	# implementing class should do some basic checks to make sure it only acts on data it's
	# prepared to accept if previous scene sends data this scene doesn't need, simple logic as
	# follows ensures no crash occurs. Acts only on the data you want to receive and process 
	if received_data is LevelDataHandoff:
		data = received_data
		# process data here if need be, for this we just need to receive it but only if it's of the
		# correct data type.
	else:
		# SceneManager is designed to allow data mismatches like this occur, because you won't
		# always know which scene precedes or follows another. Both incoming and outgoing scenes
		# might implement get/receive_data but you may not always want to process that data.
		push_warning("Level %s is receiving data it cannot process" % name)

## Emitted in the middle of SceneManager.on_content_finished_loading, after this scene is added to
## the tree.
## Used to initialize stuff before user regains control
func init_scene() -> void:
	init_player_location()

## Emitted at the very end of SceneManager.on_content_finished_loading, after the transition has
## completed.
func start_scene() -> void:
	player.enable()
	_connect_to_doors()

## Puts player in front of the correct door, facing the correct direction
func init_player_location() -> void:
	player.visible = true
	if data != null:
		player.orient(data.move_dir)
		# Find the correct door from doors
		for door in doors:
			if not is_instance_valid(door):
				continue
			if door.name == data.entry_door_name:
				player.global_position = door.get_player_entry_vector()

## Signal emitted by Door
## Disables doors and players, create handoff data to pass to the new scene
## (if new scene is a Level).
## [b][color=plum]door[/color][/b] - Variable for the door that player can use
func _on_player_entered_door(door: Door) -> void:
	_disconnect_from_doors()
	player.disable()
	data = LevelDataHandoff.new()
	data.entry_door_name = door.entry_door_name
	data.move_dir = door.get_move_dir()
	set_process(false)
	set_physics_process(false)

## Connects to all door signals in level
func _connect_to_doors() -> void:
	for door in doors:
		if not is_instance_valid(door):
			push_error("Level '%s' has an invalid entry in its doors array — check the Inspector" % name)
			continue
		if not door.player_entered_door.is_connected(_on_player_entered_door):
			door.player_entered_door.connect(_on_player_entered_door)

## Disconnects from all door signals in level
func _disconnect_from_doors() -> void:
	for door in doors:
		if door.player_entered_door.is_connected(_on_player_entered_door):
			door.player_entered_door.disconnect(_on_player_entered_door)

func replace_door_tiles() -> void:
	for door in doors:
		var tile_1_pos: Vector2i = tile_map.local_to_map(tile_map.to_local(door.global_position))
		# Offset the second tile based on door orientation
		var tile_2_pos: Vector2i
		var alternative_1: int
		var alternative_2: int
		
		match door.entry_direction:
			"up":
				tile_2_pos = tile_1_pos - Vector2i(1, 0)
				alternative_1 = 0  # default, no rotation
				alternative_2 = 0
			"right":
				tile_2_pos = tile_1_pos - Vector2i(0, 1)
				alternative_1 = 1
				alternative_2 = 2
			"down":
				tile_2_pos = tile_1_pos - Vector2i(1, 0)
				alternative_1 = 3
				alternative_2 = 4
			"left":
				tile_2_pos = tile_1_pos - Vector2i(0, 1)
				alternative_1 = 5
				alternative_2 = 6
		tile_map.set_cell(tile_1_pos, 0, Vector2(11, 0), alternative_2)
		tile_map.set_cell(tile_2_pos, 0, Vector2(10, 0), alternative_1)
		door.monitoring = true
