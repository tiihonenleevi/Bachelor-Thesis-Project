extends CharacterBody2D

@export var hp: float = 5
@onready var state_machine: StateMachine = $StateMachine

func _ready() -> void:
	state_machine.init(self)

func _physics_process(_delta: float) -> void:
	move_and_slide()

func take_damage(amount: float) -> void:
	hp -= amount
	print(hp)
	# check if the enemy needs to die
	if hp <= 0:
		queue_free()
