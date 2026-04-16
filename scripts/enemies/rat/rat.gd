extends CharacterBody2D

@export var hp: float = 5
@onready var state_machine: StateMachine = $StateMachine

@onready var hp_pickup_scene: PackedScene = load("res://scenes/items/hp_pickup.tscn")
@export var hp_pickup_chance = 0.1

func _ready() -> void:
	state_machine.init(self)

func _physics_process(_delta: float) -> void:
	move_and_slide()

func take_damage(amount: float) -> void:
	hp -= amount
	# check if the enemy needs to die
	if hp <= 0:
		SignalBus.enemy_died.emit()
		
		# decide whether to drop hp pickup or not
		if randf() <= hp_pickup_chance:
			var hp_pickup = hp_pickup_scene.instantiate()
			get_tree().current_scene.add_child(hp_pickup)
			hp_pickup.global_position = global_position
		
		queue_free()
