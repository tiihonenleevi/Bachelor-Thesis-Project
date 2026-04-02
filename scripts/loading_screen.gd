class_name LoadingScreen extends CanvasLayer

signal transition_complete

@onready var v_box_container: VBoxContainer = %VBoxContainer
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var anim_player: AnimationPlayer = %AnimationPlayer
@onready var timer: Timer = $Timer

var starting_anim_name: String

func _ready() -> void:
	v_box_container.visible = false

## Starts the transition (plays the first half of the transition)
## [b][color=plum]anim_name[/b] - The name of the animation
func start_transition(anim_name: String) -> void:
	# Checks if there is an animation with the given name
	if !anim_player.has_animation(anim_name):
		push_warning("%s' animation name doesn't exist" % anim_name)
		# Makes sure the game doesn't crash even with erroneous animation name
		anim_name = "fade_to_black"
	
	starting_anim_name = anim_name
	anim_player.play(anim_name)
	
	# If timer reaches the end before loading is finished, this will show
	# the progress bar and the loading text
	timer.start()

## Called by the SceneManager to play the last part of the transition once the new scene is loaded
func finish_transition() -> void:
	if timer:
		timer.stop()
	
	# Construct the second half of the transition's animation name
	var ending_anim_name: String = starting_anim_name.replace("to","from")
	# Checks if there is an animation with the given name
	if !anim_player.has_animation(ending_anim_name):
		push_warning("%s' animation name doesn't exist" % ending_anim_name)
		# Makes sure the game doesn't crash even with erroneous animation name
		ending_anim_name = "fade_from_black"
	
	anim_player.play(ending_anim_name)
	
	# Deletes this scene after the final animation has played
	await anim_player.animation_finished
	queue_free()

## Called at the end of "in" transitions on the method track of the AnimationPlayer let SceneManager
## know that the screen is obscured and loading of the incoming scene can begin
func report_midpoint() -> void:
	transition_complete.emit()

## If loading takes long enough that this timer fires, the loading bar and text will become visible
## and progress is displayed
func _on_timer_timeout() -> void:
	v_box_container.visible = true

## Updates the progress bar
func update_bar(val: float) -> void:
	progress_bar.value = val
