extends State

@export var speed: int = 80

func enter() -> void:
	# Calls the State's implementation of enter()
	# super()
	pass

func physics_update(_delta: float) -> void:
	var direction = parent.position.direction_to(GameState.player.position)
	parent.velocity = direction * speed
