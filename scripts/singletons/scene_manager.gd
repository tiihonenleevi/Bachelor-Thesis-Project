extends Node

## The SceneManager class is designed to enable simple one-line calls to load one scene (Node)
## and unload another. It also handles monitoring load progress, which can be displayed as a loading
## bar to the user and it gives you optional transitions for swapping between them. Data can also 
## be handed off between scenes by implementing methods within the scenes being loaded/unloaded (see 
## [method _on_content_finished_loading] for more detail). The intended use is to switch between
## major screens (like Start and Gameplay and GameOver) or between levels. SceneManager CAN be
## used to load other assets, but it's not intended to manage loading frequently used items like
## spawning enemies or bullets. This is for high-level game management.

## Be mindful of how frequently a user might be able to take action that triggers SceneManager
## to load something as it will fail silently. Aside from accounting for this in your logic,
## a workaround could be to check _loading_in_progress == true and if so await
## SceneManager.load_complete in cases where you might be at risk of using SceneManager
## to load scenes in rapid succession. This approach will have limitations as well.

signal load_start(loading_screen: LoadingScreen) # Triggered when an asset begins loading
# Triggered right after an asset is added to SceneTree but before transition animation finishes
signal scene_added(loaded_scene: Node, loading_screen)
signal load_complete(loaded_scene: Node) # Triggered when loading has completed

# Triggered when content is loaded and final data handoff and transition out begins
signal _content_finished_loading(content)
# Triggered when attempting to load invalid content (e.g. an asset does not
# exist or path is incorrect)
signal _content_invalid(content_path: String)
# Triggered when loading has started but failed to complete
signal _content_failed_to_load(content_path: String)

# Reference to loading screen PackedScene
var _loading_screen_scene: PackedScene = preload("res://scenes/loading_screen.tscn")
# Reference to loading screen instance
var _loading_screen: LoadingScreen
# Transition being used for current load
var _transition: String
# Direction of zelda transition (should only be passed Vector2.UP/RIGHT/DOWN/LEFT)
# Is passed in when calling swap_scenes_zelda()
var _zelda_transition_direction: Vector2
# Stores the path to the asset SceneManager is trying to load
var _content_path: String
# Timer used to check in on load progress
var _load_progress_timer: Timer
# Node into which we're loading the new scene, defaults to
# get_tree().root if left null 
var _load_scene_into: Node
# Node we're unloading. In almost all cases, SceneManager will be used to swap between
# two scenes - after all that is the primary focus. However, passing in null for the
# scene to unload will skip the unloading process and simply add the new scene. This isn't
# recommended, as it can have some adverse affects depending on how it is used, but it does work.
var _scene_to_unload: Node
# Used to block SceneManager from attempting to load two things at the same time
var _loading_in_progress:bool = false

## Currently only being used to connect to required, internal signals
func _ready() -> void:
	_content_invalid.connect(_on_content_invalid)
	_content_failed_to_load.connect(_on_content_failed_to_load)
	_content_finished_loading.connect(_on_content_finished_loading)

## Adds the loading screen. The loading screen is added to the root. 
## To make changes to where the loading screen ends up, you can listen for the signals scene_added 
## and [code]load_complete[/code] to reposition loading screen or other elements, relative to the 
## loading screen appropriately.
## This may seem an odd way to do this, but the alternative is having set properties at the SceneManager level
## before loading asset OR having yet another parameter to pass in (several if you want to options to control
## where in the scene tree or relative to which node you want to put it. By simply listening for this event,
## you can write any logic you want and handle it as needed.[br]
## [b][color=plum]transition_type[/color][/b] - the name of the transition type
func _add_loading_screen(transition_type: String = "fade_to_black"):
	_transition = "no_to_transition" if transition_type == "no_transition" else transition_type
	_loading_screen = _loading_screen_scene.instantiate() as LoadingScreen
	# Instantiates the loading screen to the scene
	get_tree().root.add_child(_loading_screen)
	_loading_screen.start_transition(_transition)

## Used to change between two scenes.[br]
## [b][color=plum]scene_to_load[/color][/b] - Path to the resource you'd like to load
## [b][color=plum]load_into[/color][/b] - Node you'd like to load the resource into
## [b][color=plum]scene_to_unload[/color][/b] - Scene that needs to be unloaded. If left null skips unloading
## [b][color=plum]transition_type[/color][/b] - Name of transition. Options in Door class
func swap_scenes(scene_to_load: String, load_into: Node = null, scene_to_unload: Node = null,
				 transition_type: String = "fade_to_black") -> void:
	# If loading already in progress push warning and do nothing
	if _loading_in_progress:
		push_warning("SceneManager is already loading something")
		return
	
	_loading_in_progress = true
	if load_into == null: load_into = get_tree().root
	_load_scene_into = load_into
	_scene_to_unload = scene_to_unload
	
	_add_loading_screen(transition_type)
	_load_content(scene_to_load)

## Used to swap scenes with the Zelda-dungeon-style. Assumes that all levels are the same size.
## If level sizes vary this method should receive arguments that define the size of incoming and
## outgoing scenes and modify the tweens in the zelda block in the _on_content_finished_loading to
## properly set up the start/end locations of the two scenes.
## [b][color=plum]scene_to_load[/color][/b] - Path to the resource you'd like to load
## [b][color=plum]load_into[/color][/b] - Node you'd like to load the resource into
## [b][color=plum]scene_to_unload[/color][/b] - Scene that needs to be unloaded. Doesn't support null
## [b][color=plum]move_dir[/color][/b] - the direction the player is moving towards
func swap_scenes_zelda(scene_to_load: String, load_into: Node, scene_to_unload: Node,
					   move_dir: Vector2) -> void:
	# If loading already in progress push warning and do nothing
	if _loading_in_progress:
		push_warning("SceneManager is already loading something")
		return
	
	_loading_in_progress = true
	_transition = "zelda"
	_load_scene_into = load_into
	_scene_to_unload = scene_to_unload
	_zelda_transition_direction = move_dir
	_load_content(scene_to_load)

## Initializes content
## [b][color=plum]content_path[/color][/b] - Path to the content that needs to be loaded
func _load_content(content_path: String) -> void:
	load_start.emit(_loading_screen)
	
	# zelda transition doesn't use a loading screen
	if _transition != "zelda":
		await _loading_screen.transition_complete
	
	_content_path = content_path
	var loader = ResourceLoader.load_threaded_request(content_path)
	if not ResourceLoader.exists(content_path) or loader == null:
		_content_invalid.emit(content_path)
		return
	
	_load_progress_timer = Timer.new()
	_load_progress_timer.wait_time = 0.1
	_load_progress_timer.timeout.connect(_monitor_load_status)
	# Insert loading bar?? Maybe needed
	get_tree().root.add_child(_load_progress_timer)
	_load_progress_timer.start()

## Checks loading status
func _monitor_load_status() -> void:
	var load_progress = []
	var load_status = ResourceLoader.load_threaded_get_status(_content_path, load_progress)
	
	match load_status:
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_content_invalid.emit(_content_path)
			_load_progress_timer.stop()
			return
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			if _loading_screen != null:
				_loading_screen.update_bar(load_progress[0] * 100)
		ResourceLoader.THREAD_LOAD_FAILED:
			_content_failed_to_load.emit(_content_path)
			_load_progress_timer.stop()
			return
		ResourceLoader.THREAD_LOAD_LOADED:
			_load_progress_timer.stop()
			_load_progress_timer.queue_free()
			_content_finished_loading.emit(ResourceLoader.
								load_threaded_get(_content_path).instantiate())
			return # Isn't really necessary but doesnt't hurt either

## Fires when attempting to load invalid content
func _on_content_invalid(path: String) -> void:
	printerr("error: Cannot load resource:: '%s'" % [path])

## Fires when content has begun loading but failed to complete
func _on_content_failed_to_load(path: String) -> void:
	printerr("error: Failed to load resource:: '%s'" % [path])

## Fires when content loading is finished. Responsible for data transfer, adding
## the new scene, removing the old scene, handling zelda transition, halting the game until
## out transition finishes, also fires off the signals you vcan listen for to manage
## the SceneTree as things are added.
## [b][color=plum]new_scene[/b] - the new scene to be loaded
func _on_content_finished_loading(new_scene) -> void:
	var previous_scene = _scene_to_unload
	
	# If previous_scene has data to pass, give it to new_scene
	if previous_scene != null:
		if previous_scene.has_method("get_data") and new_scene.has_method("receive_data"):
			new_scene.receive_data(previous_scene.get_data())
	
	# Load the new_scene into designated node
	_load_scene_into.add_child(new_scene)
	
	# Listen for this if you want to perform tasks on the scene immediately after adding it to the tree
	scene_added.emit(new_scene, _loading_screen)
	
	# The next block is only used by zelda transition that don't use loading screen
	if _transition == "zelda":
		# Slide new level in
		var viewport_size: Vector2 = get_tree().root.get_viewport().get_visible_rect().size
		new_scene.position = _zelda_transition_direction * viewport_size
		var tween_in: Tween = get_tree().create_tween()
		tween_in.tween_property(new_scene, "position", Vector2.ZERO, 1).set_trans(Tween.TRANS_SINE)
		
		# Slide previous scene out
		var tween_out:Tween = get_tree().create_tween()
		var vector_off_screen:Vector2 = Vector2.ZERO
		vector_off_screen = -_zelda_transition_direction * viewport_size
		tween_out.tween_property(previous_scene, "position", vector_off_screen, 1).set_trans(Tween.TRANS_SINE)
		
		# once the tweens are done, do some cleanup
		await tween_in.finished
	
	# Remove the previous scene
	if _scene_to_unload != null and _scene_to_unload != get_tree().root:
		_scene_to_unload.queue_free()
	
	# Called right after scene is added to the tree
	if new_scene.has_method("init_scene"):
		new_scene.init_scene()
	
	# probably not necssary since we split our _content_finished_loading but it won't hurt to have an extra check
	if _loading_screen != null:
		_loading_screen.finish_transition()
		
		# Wait or loading animation to finish
		await _loading_screen.anim_player.animation_finished
	
	# If the new scene implements start_scene() call it here
	if new_scene.has_method("start_scene"):
		new_scene.start_scene()
	
	# Load is complete, free up SceneManager to load something else and emit load_complete signal
	_loading_in_progress = false
	load_complete.emit(new_scene)
