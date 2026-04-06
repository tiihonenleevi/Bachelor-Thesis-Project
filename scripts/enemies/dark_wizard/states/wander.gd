extends State

const DIRECTIONS: Array = ["LEFT", "UP", "RIGHT", "DOWN"]
const SPEED: int = 50
@onready var detect_area: Area2D = $"../../DetectArea"
@onready var keep_going_timer: Timer = $KeepGoingTimer
@onready var ray_cast: RayCast2D = $"../../RayCast2D"
# Get random movement direction
var direction: String

func enter() -> void:
	# Calls the State's implementation of enter()
	# super()
	direction = DIRECTIONS.pick_random()
	keep_going_timer.start()

func physics_update(_delta: float) -> void:
	if ray_cast.is_colliding():
		direction = DIRECTIONS.pick_random()
	
	match direction:
		"LEFT":
			ray_cast.target_position = Vector2(-29, 0)
			parent.velocity.x = -SPEED
		"RIGHT":
			ray_cast.target_position = Vector2(29, 0)
			parent.velocity.x = SPEED
		"UP":
			ray_cast.target_position = Vector2(0, -29)
			parent.velocity.y = -SPEED
		"DOWN":
			ray_cast.target_position = Vector2(0, 29)
			parent.velocity.y = SPEED

func _on_detect_area_body_entered(body: Node2D) -> void:
	# Check if player is on site
	if body.is_in_group("Player"):
		keep_going_timer.stop()
		change_state.emit("Shoot")
		detect_area.queue_free()
		ray_cast.queue_free()


func _on_keep_going_timer_timeout() -> void:
	parent.velocity = Vector2(0, 0)
	change_state.emit("Idle")
