extends State

@onready var idle_timer: Timer = $IdleTimer

func enter() -> void:
	idle_timer.start()

func _on_idle_timer_timeout() -> void:
	change_state.emit("Wander")
