extends HBoxContainer

@onready var heart_gui_scene = preload("res://scenes/ui/heart_gui.tscn")

func _ready() -> void:
	SignalBus.hp_changed.connect(update_hearts)

# Adds the max amount of hearts to GUI
func set_max_hearts(max_hearts: int):
	for i in range(max_hearts):
		var heart = heart_gui_scene.instantiate()
		add_child(heart)

# Updates the UI when needed
func update_hearts(current_hp: int):
	var hearts = get_children()
	
	# Add the full hearts
	for i in range(current_hp):
		hearts[i].update(true)
	
	# Add the empty hearts
	for i in range(current_hp, hearts.size()):
		hearts[i].update(false)
