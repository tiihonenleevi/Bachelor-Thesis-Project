extends Node
class_name State

signal change_state(new_state: StringName)

var parent: CharacterBody2D

## Call when entering the state
func enter() -> void:
	# If there were any animations they would be played from here
	pass

## Call when exiting state. Handy for clean ups
func exit() -> void:
	pass

func update(_delta) -> void:
	pass

func physics_update(_delta) -> void:
	pass
