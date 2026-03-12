extends State


var target: CharacterBody2D

func enter() -> void:
	# Calls the State's implementation of enter()
	# super()
	SignalManager.give_player().connect(get_player)
	pass

func _physics_process(_delta: float) -> void:
	pass

func get_player(player: CharacterBody2D):
	target = player
