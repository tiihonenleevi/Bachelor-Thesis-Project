extends Node2D

var hp_amount: int = 1

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		# If player is max hp don't pickup
		if body.hp == body.max_hp:
			return
		
		if body.has_method("gain_hp"):
			body.gain_hp(hp_amount)
			queue_free()
