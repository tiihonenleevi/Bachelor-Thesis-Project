extends CharacterBody2D

@export var hp: float = 8
@onready var state_machine: StateMachine = $StateMachine

@onready var hp_pickup_scene: PackedScene = load("res://scenes/items/hp_pickup.tscn")
@export var hp_pickup_chance = 0.2


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
			#E 0:00:24:572   dark_wizard.gd:25 @ take_damage(): Can't change this state while flushing queries. Use call_deferred() or set_deferred() to change monitoring state instead.
			 #<C++ Error>   Condition "area->get_space() && flushing_queries" is true.
			#<C++ Source>  modules/godot_physics_2d/godot_physics_server_2d.cpp:355 @ area_set_shape_disabled()
			#<Stack Trace> dark_wizard.gd:25 @ take_damage()
			#hurt_box.gd:14 @ _on_hit_box_area_entered()
			
			get_tree().current_scene.add_child(hp_pickup)
			hp_pickup.global_position = global_position
		
		queue_free()
