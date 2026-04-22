extends Node

const OPPOSITE: Dictionary = {
	"up": "down", "down": "up", "left": "right", "right": "left"
}
const DIR_OFFSET: Dictionary = {
	"up": Vector2i(0, -1),
	"down": Vector2i(0,  1),
	"left": Vector2i(-1, 0),
	"right": Vector2i(1,  0)
}

var max_rooms: int = 10

## Maps every grid cell a room occupies → that room's origin
var cell_map: Dictionary = {}
## Maps room origin → RoomData
var room_data_map: Dictionary = {}
## Stores grid origins of rooms that have been cleared
var cleared_rooms: Array[Vector2i] = []

var _door_cache: Dictionary = {} # resource_path → Array[DoorInfo]
var _footprint_cache: Dictionary = {} # resource_path → Vector2i
var room_scenes: Array[PackedScene] = []

var first_room_path: String = "res://scenes/levels/first_room.tscn"
var first_room: PackedScene = load(first_room_path)

class DoorInfo:
	var node_name: String
	var direction: String
	## Offset in grid cells from the room origin to the cell this door sits on
	var cell_offset: Vector2i

class RoomData:
	var scene_path: String
	var origin: Vector2i
	var footprint: Vector2i
	## door_node_name → neighbor room origin
	var connections: Dictionary = {}
	## door node names that have no neighbor
	var sealed_doors: Array[String] = []

func _ready() -> void:
	var dir := DirAccess.open("res://scenes/levels/rooms/")
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tscn"):
				var scene = load("res://scenes/levels/rooms/" + file_name)
				if scene:
					room_scenes.append(scene)
			file_name = dir.get_next()
		dir.list_dir_end()
	
	generate()
	
	# Mark the first room as cleared
	mark_room_cleared(Vector2i(0, 0))

func generate() -> void:
	cell_map.clear()
	room_data_map.clear()
	_door_cache.clear()
	_footprint_cache.clear()
	
	_cache_room_info(first_room)
	
	for scene in room_scenes:
		_cache_room_info(scene)
	
	_place_room(first_room, Vector2i.ZERO)
	
	# Seed open slots from the starting room's doors
	var open_slots: Array = []
	for door_info in _door_cache[room_scenes[0].resource_path]:
		open_slots.append({
			"room_origin": Vector2i.ZERO,
			"door_name": door_info.node_name,
			"door_cell": door_info.cell_offset,  # absolute since origin is (0,0)
			"direction": door_info.direction
		})
	
	while room_data_map.size() < max_rooms and not open_slots.is_empty():
		var i: int = randi() % open_slots.size()
		var slot: Dictionary = open_slots[i]
		open_slots.remove_at(i)
		
		var out_dir: String = slot["direction"]
		var parent_door_cell: Vector2i = slot["door_cell"]
		var in_dir: String = OPPOSITE[out_dir]
		
		# The cell the new room's entry door must occupy
		var entry_cell: Vector2i = parent_door_cell + DIR_OFFSET[out_dir]
		
		if cell_map.has(entry_cell):
			# Cell taken — stitch the two rooms together if a matching door exists
			var neighbor_origin: Vector2i = cell_map[entry_cell]
			var neighbor_door: String = _find_door_at(neighbor_origin, entry_cell, in_dir)
			if neighbor_door != "":
				room_data_map[slot["room_origin"]].connections[slot["door_name"]] = neighbor_origin
				room_data_map[neighbor_origin].connections[neighbor_door] = slot["room_origin"]
			else:
				_seal(slot["room_origin"], slot["door_name"])
			continue
		
		# Pick a random room scene and entry door facing in_dir
		# This will have an effect only on bigger room sizes
		var chosen: PackedScene = room_scenes[randi() % room_scenes.size()]
		var chosen_path: String = chosen.resource_path
		var chosen_fp: Vector2i = _footprint_cache[chosen_path]
		
		var entry_candidates: Array = _door_cache[chosen_path].filter(
			func(d: DoorInfo) -> bool: return d.direction == in_dir
		)
		
		if entry_candidates.is_empty():
			_seal(slot["room_origin"], slot["door_name"])
			continue
		
		var entry_door: DoorInfo = entry_candidates[randi() % entry_candidates.size()]
		
		# Room origin so that this entry door lands exactly on entry_cell
		var new_origin: Vector2i = entry_cell - entry_door.cell_offset
	
		if not _footprint_free(new_origin, chosen_fp):
			_seal(slot["room_origin"], slot["door_name"])
			continue
	
		_place_room(chosen, new_origin)
		
		# Connect
		room_data_map[slot["room_origin"]].connections[slot["door_name"]] = new_origin
		room_data_map[new_origin].connections[entry_door.node_name] = slot["room_origin"]
		
		# Register remaining doors as open slots
		for door_info in _door_cache[chosen_path]:
			if door_info.node_name != entry_door.node_name:
				open_slots.append({
					"room_origin": new_origin,
					"door_name": door_info.node_name,
					"door_cell": new_origin + door_info.cell_offset,
					"direction": door_info.direction
				})
	
	for slot in open_slots:
		_seal(slot["room_origin"], slot["door_name"])

# ── Public functions ──────────────────────────────────────────────────────────

## Returns RoomData by any cell the room occupies
func get_room_data(grid_pos: Vector2i) -> RoomData:
	if cell_map.has(grid_pos):
		return room_data_map.get(cell_map[grid_pos], null)
	return null

## Returns RoomData by the room's origin (top-left grid cell)
func get_room_data_by_origin(origin: Vector2i) -> RoomData:
	return room_data_map.get(origin, null)

## Returns the door node name in room_origin that connects back to from_origin
func find_connecting_door(room_origin: Vector2i, from_origin: Vector2i) -> String:
	var d: RoomData = room_data_map.get(room_origin, null)
	if d == null:
		return ""
	for door_name in d.connections:
		if d.connections[door_name] == from_origin:
			return door_name
	return ""

## Marks the room as cleared
func mark_room_cleared(origin: Vector2i) -> void:
	if origin not in cleared_rooms:
		cleared_rooms.append(origin)

## Checks whether the room is cleared
func is_room_cleared(origin: Vector2i) -> bool:
	return origin in cleared_rooms

# ── Private helpers ───────────────────────────────────────────────────────────

func _place_room(scene: PackedScene, origin: Vector2i) -> RoomData:
	var path: String = scene.resource_path
	var fp: Vector2i = _footprint_cache[path]
	var d := RoomData.new()
	d.scene_path = path
	d.origin = origin
	d.footprint = fp
	room_data_map[origin] = d
	for x in range(fp.x):
		for y in range(fp.y):
			cell_map[origin + Vector2i(x, y)] = origin
	return d

func _footprint_free(origin: Vector2i, fp: Vector2i) -> bool:
	for x in range(fp.x):
		for y in range(fp.y):
			if cell_map.has(origin + Vector2i(x, y)):
				return false
	return true

func _seal(room_origin: Vector2i, door_name: String) -> void:
	var d: RoomData = room_data_map.get(room_origin, null)
	if d and door_name not in d.sealed_doors:
		d.sealed_doors.append(door_name)

## Finds which door on a room sits on a specific absolute cell facing a specific direction
func _find_door_at(room_origin: Vector2i, absolute_cell: Vector2i, direction: String) -> String:
	var d: RoomData = room_data_map.get(room_origin, null)
	if d == null:
		return ""
	var local_cell: Vector2i = absolute_cell - room_origin
	for door_info in _door_cache[d.scene_path]:
		if door_info.cell_offset == local_cell and door_info.direction == direction:
			return door_info.node_name
	return ""

func _cache_room_info(scene: PackedScene) -> void:
	var path: String = scene.resource_path
	if _door_cache.has(path):
		return
	var tmp: Node = scene.instantiate()
	var fp: Vector2i = Vector2i(1, 1)
	if tmp.get("footprint") != null:
		fp = tmp.footprint
	_footprint_cache[path] = fp
	var doors: Array[DoorInfo] = []
	_collect_door_info(tmp, doors, fp)
	_door_cache[path] = doors
	tmp.queue_free()

func _collect_door_info(node: Node, doors: Array[DoorInfo], fp: Vector2i) -> void:
	for child in node.get_children():
		if child is Door:
			var info := DoorInfo.new()
			info.node_name = child.name
			# "DoorUp_0" → to_snake_case → "door_up_0" → split → ["door","up","0"]
			var parts: Array = child.name.to_snake_case().split("_")
			info.direction = parts[1] if parts.size() > 1 else ""
			var index: int = int(parts[2]) if parts.size() > 2 else 0
			match info.direction:
				"up": info.cell_offset = Vector2i(index, 0)
				"down": info.cell_offset = Vector2i(index, fp.y - 1)
				"right": info.cell_offset = Vector2i(fp.x - 1, index)
				"left": info.cell_offset = Vector2i(0, index)
			doors.append(info)
		else:
			_collect_door_info(child, doors, fp)
