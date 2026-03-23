extends Area2D
class_name HitBox

@export var damage: float = 1
@export var knockback: int = 0

func _init() -> void:
	collision_mask = 0
