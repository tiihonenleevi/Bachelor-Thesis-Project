extends State

@onready var chase_timer: Timer = $ChaseTimer

@export var speed: int = 60

func enter() -> void:
	chase_timer.start()

func physics_update(_delta: float) -> void:
	var direction = parent.position.direction_to(GameState.player.position)
	parent.velocity = direction * speed

func _on_chase_timer_timeout() -> void:
	change_state.emit("Shoot")
