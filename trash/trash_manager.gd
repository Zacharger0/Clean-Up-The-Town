extends Node2D

@export var cardboard_box: PackedScene

const MAX_TRASH_AMOUNT = 25
var current_trash_amount = 0

func _physics_process(delta: float) -> void:
	var random_x = randf_range(-100, 100)
	var random_y = randf_range(-100, 100)
	spawn_trash(random_x, random_y)

func spawn_trash(random_x, random_y):
	if cardboard_box != null and current_trash_amount < MAX_TRASH_AMOUNT:
		var trash = cardboard_box.instantiate()
		add_child(trash)
		trash.position = Vector2(random_x, random_y)
		trash.trash_collected.connect(_on_trash_collected)
		current_trash_amount += 1
	elif cardboard_box == null:
		print("No cardboard box assigned")
		return

func _on_trash_collected() -> void:
	current_trash_amount -= 1
	
