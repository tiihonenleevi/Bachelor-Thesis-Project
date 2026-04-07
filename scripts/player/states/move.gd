extends State

const SPEED: int = 120

func physics_update(_delta) -> void:
	if parent.can_move:
		# Get the input direction
		var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		# Apply the input direction to velocity
		parent.velocity = direction * SPEED
		
		# check for shooting
		parent.shoot_direction = Input.get_vector("shoot_left", "shoot_right", "shoot_up", "shoot_down")
		if parent.can_shoot && parent.shoot_direction:
			change_state.emit("Shoot")
	
