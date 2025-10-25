extends Area2D

signal trash_collected(value: int)

@onready var score_manager: Node = $"../../../../ScoreManager"

@onready var sfx_item_plop_normal: AudioStreamPlayer2D = $"../../../SFX/SFX Item Plop Normal"

var move_speed = 500.0  # SPEED THAT TRASH MOVES TO PLAYER
var activation_distance = 100.0  # MAX DISTANCE FOR MAGNET EFFECT
var player: CharacterBody2D
var coyote_time = 2.0  # HOW LONG MAGNET LASTS AFTER RELEASE
var coyote_timer = 0.0  # TRACKS COYOTE TIME LEFT
var is_magnet_active = false  # CONTROLS MAGNET STATE

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
		# CHECKS IF SPACEBAR IS HELD /AND/ TRASH IN RANGE
		if Input.is_action_pressed("ui_accept") and distance < activation_distance:
			is_magnet_active = true
			coyote_timer = coyote_time  # RESET COYOTE TIME
		elif coyote_timer > 0.0 and distance < activation_distance:
			is_magnet_active = true  # KEEP MAGNET ON DURING COYOTE
			coyote_timer -= delta  # DECREASE TIMER
		else:
			is_magnet_active = false  # TURN OFF MAGNET

		# MOVE TO PLAYER IF MAGNET ACTIVE
		if is_magnet_active:
			var direction = (player.global_position - global_position).normalized()
			position += direction * move_speed * delta

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D:
		trash_collected.emit()
		sfx_item_plop_normal.play()
		score_manager.add_trash(1)
		queue_free()
