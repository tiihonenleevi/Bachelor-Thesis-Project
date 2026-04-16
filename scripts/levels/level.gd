class_name Level extends Node2D

## All levels extend from this class.

@onready var player: Player = $"/root/Gameplay/Player"
## Holds all the doors
var doors: Array[Door]
var data: LevelDataHandoff
## Set this in the Inspector for each room scene — 1x1 for normal rooms, 2x1 for wide rooms etc.
@export var footprint: Vector2i = Vector2i(1, 1)
@onready var tile_map: TileMapLayer = $Environment

## The origin (top-left grid cell) of this room in the generated map
var my_grid_pos: Vector2i = Vector2i.ZERO
## Only doors that have a connected neighbor — sealed doors are excluded
var connected_doors: Array[Door] = []

## This node holds all the enemies of the current room
@onready var enemies: Node2D = $Enemies
@export var enemy_scenes: Array[PackedScene] = [] # assign in Inspector
@export var max_enemies: int = 6 # modify this to different room sizes
@export var min_enemies: int = 2
@onready var spawn_points: Node2D = $SpawnPoints # modify this to different room sizes

func _ready() -> void:
	SignalBus.enemy_died.connect(check_enemy_count)
	player.disable()
	player.visible = false
	
	# Search the full subtree — handles doors nested inside a "Doors" container node
	_collect_doors(self)
	
	# Allows testing a room scene directly without going through SceneManager
	if data == null:
		init_scene()
		start_scene()

func _collect_doors(node: Node) -> void:
	for child in node.get_children():
		if child is Door:
			doors.append(child)
		else:
			_collect_doors(child)

# ── SceneManager hooks ────────────────────────────────────────────────────────

func get_data():
	return data

func receive_data(received_data) -> void:
	if received_data is LevelDataHandoff:
		data = received_data
	else:
		push_warning("Level %s is receiving data it cannot process" % name)

## Called by SceneManager after this scene is added to the tree.
## Sets up player position, configures doors from the generated map and spawns enemies.
func init_scene() -> void:
	my_grid_pos = data.grid_pos if data != null else Vector2i.ZERO
	init_player_location()
	_spawn_enemies()
	_configure_doors_from_generator()

## Called by SceneManager after the transition animation finishes.
func start_scene() -> void:
	player.enable()
	_connect_to_doors()

# ── Enemy handling ────────────────────────────────────────────────────────────

## Handles enemy spawning
func _spawn_enemies() -> void:
	if enemy_scenes.is_empty() || LevelGenerator.is_room_cleared(my_grid_pos):
		return
	
	# Shuffle spawn points so enemy placement is random too
	var points: Array = spawn_points.get_children()
	points.shuffle()
	
	# Randomize the number of enemies
	var count: int = randi_range(min_enemies, max_enemies)
	for i in range(mini(count, points.size())):
		# Randomize the type of enemy
		var scene: PackedScene = enemy_scenes[randi() % enemy_scenes.size()]
		var enemy = scene.instantiate()
		enemy.global_position = points[i % points.size()].global_position
		enemies.add_child(enemy)

## Check if all the enemies ahve been defeated
func check_enemy_count() -> void:
	# Wait until end of frame so queue_free() has actually been processed
	await get_tree().process_frame
	if enemies.get_child_count() == 0:
		LevelGenerator.mark_room_cleared(my_grid_pos)
		open_doors()

# ── Player placement ──────────────────────────────────────────────────────────

func init_player_location() -> void:
	player.visible = true
	if data == null:
		return
	player.orient(data.move_dir)
	for door in doors:
		if not is_instance_valid(door):
			continue
		# Match against the exact door node name stored in handoff data
		if door.name == data.entry_door_name:
			player.global_position = door.get_player_entry_vector()

# ── Door configuration ────────────────────────────────────────────────────────

## Reads the generated map and for each door either:
##   - sets new_scene_path and opens the wall tile (connected door), or
##   - leaves monitoring off and the wall tile in place (sealed door)
func _configure_doors_from_generator() -> void:
	var room_data = LevelGenerator.get_room_data_by_origin(my_grid_pos)
	if room_data == null:
		push_warning("Level '%s': no generator data found at grid pos %s" % [name, my_grid_pos])
		return
	
	for door in doors:
		if door.name in room_data.connections:
			var neighbor_origin: Vector2i = room_data.connections[door.name]
			var neighbor_data = LevelGenerator.get_room_data_by_origin(neighbor_origin)
			if neighbor_data:
				door.new_scene_path = neighbor_data.scene_path
				# Find which door in the neighbor connects back to us
				door.entry_door_name = LevelGenerator.find_connecting_door(neighbor_origin, my_grid_pos)
			connected_doors.append(door)
		else:
			# No neighbor — replace tile and remove the Area2D
			_replace_with_wall(door)
			door.queue_free()
	
	var is_starting_room: bool = my_grid_pos == Vector2i.ZERO
	if is_starting_room || enemies.get_child_count() == 0:
		# Starting room and rooms with no enemies open doors immediately
		open_doors()
	else:
		# All other rooms start locked until enemies are defeated
		_lock_doors()

## Closes all connected doors — wall tiles stay, player cannot pass
func _lock_doors() -> void:
	for door in connected_doors:
		door.monitoring = false

## Opens all connected doors — swaps wall tiles and enables collision triggers.
## Call this when the room's enemies have been defeated.
func open_doors() -> void:
	for door in connected_doors:
		_open_door_tile(door)
		door.monitoring = true

## Opens the wall tile for a single door
func _open_door_tile(door: Door) -> void:
	var data_array: Array = _get_door_pos_and_alt(door)
	
	tile_map.set_cell(data_array[0], 0, Vector2(11, 0), data_array[3])
	tile_map.set_cell(data_array[1], 0, Vector2(10, 0), data_array[2])

## Replaces door tile with a wall tile
func _replace_with_wall(door: Door) -> void:
	var data_array: Array = _get_door_pos_and_alt(door)
	
	tile_map.set_cell(data_array[0], 0, Vector2(4, 3))
	tile_map.set_cell(data_array[1], 0, Vector2(4, 3))

## Returns the position of tiles and alternative tiles of wanted door [br]
## The values of indexes - 0: tile_1_pos, 1: tile_2_pos, 2: alt_1, 3: alt_2
func _get_door_pos_and_alt(door: Door) -> Array:
	var tile_1_pos: Vector2i = tile_map.local_to_map(tile_map.to_local(door.global_position))
	var tile_2_pos: Vector2i
	var alt_1: int
	var alt_2: int
	
	match door.entry_direction:
		"up":
			tile_2_pos = tile_1_pos - Vector2i(1, 0)
			alt_1 = 0; alt_2 = 0
		"right":
			tile_2_pos = tile_1_pos - Vector2i(0, 1)
			alt_1 = 1; alt_2 = 2
		"down":
			tile_2_pos = tile_1_pos - Vector2i(1, 0)
			
			alt_1 = 3; alt_2 = 4
		"left":
			tile_2_pos = tile_1_pos - Vector2i(0, 1)
			alt_1 = 5; alt_2 = 6
	
	var result: Array = [tile_1_pos, tile_2_pos, alt_1, alt_2]
	
	# GDScript doesn't support returning multiple values
	# so array gets returned instead
	return result

# ── Door signals ──────────────────────────────────────────────────────────────

func _on_player_entered_door(door: Door) -> void:
	_disconnect_from_doors()
	player.disable()
	
	data = LevelDataHandoff.new()
	data.entry_door_name = door.entry_door_name
	data.move_dir = door.get_move_dir()
	
	# Pass the neighbor's grid position to the incoming room
	var room_data = LevelGenerator.get_room_data_by_origin(my_grid_pos)
	if room_data and door.name in room_data.connections:
		data.grid_pos = room_data.connections[door.name]
	
	set_process(false)
	set_physics_process(false)

func _connect_to_doors() -> void:
	for door in doors:
		if not is_instance_valid(door):
			push_error("Level '%s' has an invalid door — check the Inspector" % name)
			continue
		if not door.player_entered_door.is_connected(_on_player_entered_door):
			door.player_entered_door.connect(_on_player_entered_door)

func _disconnect_from_doors() -> void:
	for door in doors:
		if is_instance_valid(door) and door.player_entered_door.is_connected(_on_player_entered_door):
			door.player_entered_door.disconnect(_on_player_entered_door)

# ── Debug ─────────────────────────────────────────────────────────────────────

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("change_doors"):
		for enemy in enemies.get_children():
			enemy.queue_free()
		# Manually trigger what dying enemies would trigger
		LevelGenerator.mark_room_cleared(my_grid_pos)
		open_doors()
