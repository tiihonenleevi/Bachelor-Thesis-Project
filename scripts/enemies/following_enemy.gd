extends CharacterBody2D

@onready var state_machine: StateMachine = $StateMachine
@onready var animations: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	state_machine.init(self, animations)
