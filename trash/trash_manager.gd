extends Node2D

#@export var cardboard_box: PackedScene
#var player: CharacterBody2D = null

#const MAX_TRASH_AMOUNT = 25
#var current_trash_amount = 0
#var spawn_timer: Timer
#var random_amount_area = 100

func _ready() -> void:
	pass
#	# Create and start a timer for spawning
#	spawn_timer = Timer.new()
#	spawn_timer.wait_time = 1
#	spawn_timer.autostart = true
#	spawn_timer.one_shot = false
#	add_child(spawn_timer)

#	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

#func _on_spawn_timer_timeout() -> void:
#	# Only spawn if we haven’t reached the limit
#	if current_trash_amount < MAX_TRASH_AMOUNT:
#		var random_x = randf_range(-random_amount_area, random_amount_area)
#		var random_y = randf_range(-random_amount_area, random_amount_area)
#		spawn_trash(random_x, random_y)

#func spawn_trash(random_x: float, random_y: float) -> void:
#	if cardboard_box != null:
#		var trash = cardboard_box.instantiate()
#		add_child(trash)
#		trash.player = player  
#		trash.position = Vector2(random_x, random_y)  # Set position directly to random coordinates
#		trash.trash_collected.connect(_on_trash_collected)
#		current_trash_amount += 1
#	else:
#		print("No cardboard box assigned")
				
#func _on_trash_collected() -> void:
#	current_trash_amount -= 1
