class_name Player extends CharacterBody2D

@export var max_hp: int = 4
@export var hp: int = 4

var can_shoot: bool = true
var shoot_direction: Vector2
@onready var shoot_timer: Timer = $ShootTimer

var can_move: bool = true

@onready var animations: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_machine: StateMachine = $StateMachine
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hurt_box_shape: CollisionShape2D = $HurtBox/CollisionShape2D

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
		get_tree().call_deferred("change_scene_to_file", "res://scenes/ui/dead_screen.tscn")
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
	collision_shape.set_deferred("disabled", true)
	hurt_box_shape.set_deferred("disabled", true)

func enable() -> void:
	can_move = true
	collision_shape.set_deferred("disabled", false)
	hurt_box_shape.set_deferred("disabled", false)
