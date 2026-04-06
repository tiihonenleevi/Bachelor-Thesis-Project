extends State

@onready var magic_scene: PackedScene = load("res://scenes/projectiles/magic.tscn")

func enter() -> void:
	parent.can_shoot = false
	parent.shoot_timer.start()
	var magic = magic_scene.instantiate()
	magic.direction = parent.shoot_direction
	magic.global_position = parent.global_position
	get_parent().add_child(magic)

func physics_update(_delta) -> void:
	change_state.emit("Move")
