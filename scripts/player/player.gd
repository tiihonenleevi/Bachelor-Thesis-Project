class_name Player extends CharacterBody2D

@export var max_hp: int = 4
@export var hp: int = 4

var can_shoot: bool = true
var shoot_direction: Vector2
@onready var shoot_timer: Timer = $ShootTimer

var can_move: bool = true

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
	
	# Send signal to let hp UI know that it needs to update
	SignalBus.hp_changed.emit(hp)
	
	if hp <= 0:
		hp = 0
		print("dead")

func gain_hp(amount: int) -> void:
	if hp == max_hp:
		return
	else:
		hp += amount
		# Send signal to let hp UI know that it needs to update
		SignalBus.hp_changed.emit(hp)

## Flips the player sprite if needed when entering door
func orient(dir: Vector2) -> void:
	if dir.x:
		animations.flip_h = dir.x < 0

func disable() -> void:
	can_move = false

func enable() -> void:
	can_move = true
