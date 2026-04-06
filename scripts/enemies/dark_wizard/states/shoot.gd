extends State

var target_direction: Vector2
@onready var magic_scene: PackedScene = load("res://scenes/projectiles/magic.tscn")
@onready var cool_off_timer: Timer = $CoolOffTimer

func enter() -> void:
	target_direction = parent.global_position.direction_to(GameState.player.global_position)
	var magic = magic_scene.instantiate()
	magic.direction = target_direction
	magic.global_position = parent.global_position
	get_parent().call_deferred("add_child", magic)
	cool_off_timer.start()

func _on_cool_off_timer_timeout() -> void:
	change_state.emit("Chase")
