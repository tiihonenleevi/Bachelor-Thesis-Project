extends CharacterBody2D

var direction: Vector2
const SPEED: int = 200
var max_range: float = 130
var distance_travelled: float = 0

func _physics_process(delta: float) -> void:
	velocity = direction * SPEED
	
	# calculate the distance travelled this physics process
	distance_travelled += velocity.length() * delta
	# check for max range
	if distance_travelled >= max_range || is_on_wall():
		# delete magic
		queue_free()
	move_and_slide()


func _on_area_2d_area_entered(_area: Area2D) -> void:
	print("hit")
	queue_free()
