class_name Gameplay extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var level_holder: Node2D = $LevelHolder
@onready var heart_container: HBoxContainer = $CanvasLayer/HeartContainer

var current_level: Level

func _ready() -> void:
	heart_container.set_max_hearts(player.max_hp)
	# Connect the required signals
	SceneManager.load_complete.connect(_on_level_loaded)
	SceneManager.load_start.connect(_on_load_start)
	SceneManager.scene_added.connect(_on_level_added)
	current_level = level_holder.get_child(0) as Level

## Runs when the new level is loaded[br]
## [b][color=plum]level[/color][/b] - the new level that was loaded
func _on_level_loaded(level) -> void:
	# Checks if the passed value is actually level
	if level is Level:
		current_level = level

## Runs when the new level has been added
## [b][color=plum]level[/color][/b] - The new level
## [b][color=plum]loading_screen[/color][/b] - The loading screen
func _on_level_added(level, loading_screen: LoadingScreen) -> void:
	# Keeps the loading screen on top
	if loading_screen != null:
		var loading_parent: Node = loading_screen.get_parent() as Node
		loading_parent.move_child(loading_screen, loading_parent.get_child_count() - 1)

## Runs when the loading of the new scene starts
## [b][color=plum]loading_screen[/color][/b] - The loading screen
func _on_load_start(loading_screen: LoadingScreen) -> void:
	pass
