extends Node
class_name StateMachine

# Uses export so the initial state can be defined
@export var current_state: State
var states: Dictionary = {}

## Called when the node enters the scene tree
func init(parent: CharacterBody2D, animations: AnimatedSprite2D) -> void:
	# Goes through all the children of the StateMachine
	for child in get_children():
		if child is State:
			states[child.name] = child
			child.animation_name = child.name
			child.parent = parent
			child.animations = animations
			
			# Connects the StateMachine to the "change_state" signal
			child.change_state.connect(on_state_changed)
		else:
			push_warning(child.name + " isn't a State")
	
	# Enter the initial state
	current_state.enter()

func on_state_changed(new_state_name: StringName) -> void:
	var new_state = states.get(new_state_name)
	
	if new_state != null:
		# Call the exit function of the state that we want to exit
		current_state.exit()
		
		# Call the enter function of the new state
		new_state.enter()
		
		# Change the current_state to the new state
		current_state = new_state
	else:
		push_warning(new_state_name + "isn't a State")
