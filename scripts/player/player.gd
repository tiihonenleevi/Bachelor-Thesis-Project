class_name Player extends CharacterBody2D

@export var max_hp: int = 4
@export var hp: int = 4

var can_shoot: bool = true
var shoot_direction: Vector2
@onready var shoot_timer: Timer = $ShootTimer
@onready var animations: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_machine: StateMachine = $StateMachine

func _ready() -> void:
	GameState.player = self
	state_machine.init(self)

func _physics_process(_delta: float) -> void:
	move_and_slide()

func _on_shoot_timer_timeout() -> void:
	can_shoot = true

func take_damage(dmg_amount: int) -> void:
	hp -= dmg_amount

	if hp <= 0:
		print("dead")

## Flips the player sprite if needed when entering door
func orient(dir: Vector2) -> void:
	if dir.x:
		animations.flip_h = dir.x < 0
