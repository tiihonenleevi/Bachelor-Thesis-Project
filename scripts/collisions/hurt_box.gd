extends Area2D
class_name HurtBox

func _init() -> void:
	collision_layer = 0

func _ready() -> void:
	area_entered.connect(_on_hit_box_area_entered)

func _on_hit_box_area_entered(hitbox: Area2D) -> void:
	print("take_damage")
	if hitbox == null:
		return
	if owner.has_method("take_damage"):
		owner.take_damage(hitbox.damage)
