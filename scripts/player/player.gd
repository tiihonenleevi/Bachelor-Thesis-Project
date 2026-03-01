extends CharacterBody2D

const SPEED = 300.0

func _ready() -> void:
	pass

func get_input():
	# Get the input direction
	var direction = Input.get_vector("move left", "move right", "move up", "move down")
	# Apply the input direction to velocity
	velocity = direction * SPEED

func _physics_process(_delta: float) -> void:
	get_input()
	move_and_slide()
