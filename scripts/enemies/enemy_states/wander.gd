extends State

var directions: Array = ["left", "up", "right", "down"]

func enter() -> void:
	# Calls the State's implementation of enter()
	super()

func _physics_process(delta: float) -> void:
	# Check if player is on site
	
	
	# Get random movement direction
	var direction = directions.pick_random()
