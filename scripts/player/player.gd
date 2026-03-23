extends CharacterBody2D

const SPEED: int = 120
@export var hp: int = 4

var can_shoot: bool = true
@onready var magic_scene: PackedScene = load("res://scenes/projectiles/magic.tscn")
@onready var shoot_timer: Timer = $ShootTimer

func _ready() -> void:
	GameState.player = self

func get_input():
	# Get the input direction
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	# Apply the input direction to velocity
	velocity = direction * SPEED

func _physics_process(_delta: float) -> void:
	var shoot_direction = Input.get_vector("shoot_left", "shoot_right", "shoot_up", "shoot_down")
	if can_shoot && shoot_direction:
		shoot(shoot_direction)
	
	get_input()
	move_and_slide()

func shoot(shoot_direction: Vector2) -> void:
	can_shoot = false
	shoot_timer.start()
	var magic = magic_scene.instantiate()
	magic.direction = shoot_direction
	magic.global_position = global_position
	get_parent().add_child(magic)

func _on_shoot_timer_timeout() -> void:
	can_shoot = true

func take_damage(dmg_amount: int) -> void:
	hp -= dmg_amount

	if hp <= 0:
		print("dead")
