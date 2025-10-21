extends Area2D

signal trash_collected

var move_speed = 50.0  # SPEED THAT TRASH MOVES TO PLAYER
var activation_distance = 100.0  # MAX DISTANCE FOR MAGNET EFFECT
var player: CharacterBody2D

func _ready() -> void:
	# CONNECTS body_entered SIGNAL
	connect("body_entered", Callable(self, "_on_body_entered"))

	# FINDS PLAYER NODE GROUP
	player = get_tree().get_first_node_in_group("player")
	if not player:
		push_warning("No player found in group 'player'. Box won't move.")

func _physics_process(delta: float) -> void:
	if player:
		# CALCULATE DISTANCE TO PLAYER
		var distance = global_position.distance_to(player.global_position)
		# CHECKS IF SPACEBAR IS HELD DOWN /AND/ TRASH IS IN RANGE
		if Input.is_action_pressed("ui_accept") and distance < activation_distance:
			# CALCULATES DIRECTION TOWARD PLAYER
			var direction = (player.global_position - global_position).normalized()
			# MOVES TO PLAYER
			position += direction * move_speed * delta

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D:
		trash_collected.emit()
		
		queue_free()
