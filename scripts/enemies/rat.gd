extends CharacterBody2D

@export var hp: float = 5
@onready var state_machine: StateMachine = $StateMachine
@onready var animations: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	state_machine.init(self, animations)

func _physics_process(_delta: float) -> void:
	move_and_slide()

func take_damage(amount: float) -> void:
	hp -= amount
	print(hp)
	# check if the enemy needs to die
	if hp <= 0:
		queue_free()
