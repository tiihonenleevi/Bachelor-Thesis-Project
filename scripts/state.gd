extends Node
class_name State

signal change_state(new_state: StringName)

var animation_name: String
var parent: CharacterBody2D
var animations: AnimatedSprite2D

## Call when entering the state
func enter() -> void:
	# Play the proper animation for the current state
	animations.play(animation_name)

## Call when exiting state. Handy for clean ups
func exit() -> void:
	pass
