extends Node
class_name State

signal change_state(new_state: StringName)

var parent: CharacterBody2D
var animations: AnimatedSprite2D

## Call when entering the state
func enter() -> void:
	# Play the proper animation for the current state
	animations.play(self.name.to_snake_case())

## Call when exiting state. Handy for clean ups
func exit() -> void:
	pass

func update(_delta) -> void:
	pass

func physics_update(_delta) -> void:
	pass
