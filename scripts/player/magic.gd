extends CharacterBody2D

var direction: Vector2
const SPEED: int = 200
var max_range: float = 130
var distance_travelled: float = 0
@onready var hit_box: HitBox = $HitBox

func _ready() -> void:
	# Get the collision layer of the one that's shooting
	# and use that to deduct the required collision properties
	var parent_layer = get_parent().get_parent().collision_layer
	collision_layer = parent_layer * 2
	hit_box.collision_layer = parent_layer * 2
	if parent_layer == 2:
		collision_mask = 9
	elif parent_layer == 8:
		collision_mask = 3

func _physics_process(delta: float) -> void:
	velocity = direction * SPEED
	
	# calculate the distance travelled this physics process
	distance_travelled += velocity.length() * delta
	# check for max range
	if distance_travelled >= max_range || is_on_wall():
		# delete magic
		queue_free()
	move_and_slide()
