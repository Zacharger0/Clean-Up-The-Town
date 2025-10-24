extends CharacterBody2D

@onready var player_sprite: Sprite2D = $Sprite2D

@onready var sfx_skateboard: AudioStreamPlayer2D = $SFX_Skateboard

var skate_min_pitch := 0.9
var skate_max_pitch := 1.4
var skate_fade_speed := -15.0
var skate_volume := -15.0  # dB (adjust for your mix)
var skate_min_volume := -25.0

var base_speed := 150.0
var max_speed := 320.0
var acceleration := 800.0
var deceleration := 900.0
var drift_factor := 3.5  # higher = tighter control, lower = more slide

var current_speed := 0.0
var time := 0.0
var wobble_timer := 0.0
var wobble_delay := 0.2  # delay before wobble starts after moving

var input_direction := Vector2.ZERO
var facing_direction := Vector2(1, 0)

func _ready() -> void:
	var debug_overlay = get_tree().get_root().get_node_or_null("World/DebugOverlay")
	if debug_overlay:
		debug_overlay.tracked_object = self

func get_input(delta):
	input_direction = Input.get_vector("left", "right", "up", "down")

	# --- Smooth acceleration and deceleration ---
	if Input.is_action_pressed("sprint") and input_direction != Vector2.ZERO:
		current_speed = lerp(current_speed, max_speed, delta * 2.5)
	elif input_direction != Vector2.ZERO:
		current_speed = lerp(current_speed, base_speed, delta * 3.5)
	else:
		current_speed = lerp(current_speed, 0.0, delta * 6.0)

	# --- Apply drifted velocity ---
	var target_velocity = input_direction * current_speed
	velocity = lerp(velocity, target_velocity, delta * drift_factor)

	# --- Handle wobble delay ---
	if velocity.length() > 5:
		wobble_timer += delta
	else:
		wobble_timer = 0.0

	# --- Wobble and lean only when moving left/right, after delay ---
	if wobble_timer > wobble_delay and abs(velocity.x) > abs(velocity.y):
		wobble_and_lean(delta)
	else:
		rotation = lerp(rotation, 0.0, delta * 8.0)

	# --- Update facing direction ---
	if input_direction != Vector2.ZERO:
		facing_direction = input_direction.normalized()

	if facing_direction.x > 0:
		player_sprite.flip_h = false
	elif facing_direction.x < 0:
		player_sprite.flip_h = true


func _physics_process(delta: float) -> void:
	get_input(delta)
	move_and_slide()
	_update_skate_sfx(delta)
	


func wobble_and_lean(delta):
	# Wobble decreases at high speed
	var speed_ratio = clamp(current_speed / max_speed, 0.0, 1.0)
	var wobble_strength = lerp(0.1, 0.02, speed_ratio)
	var wobble_speed = lerp(18.0, 8.0, speed_ratio)

	# Smooth, delayed wobble
	var wobble = sin(time * wobble_speed) * wobble_strength

	# Lean into turn based on horizontal velocity
	var lean_amount = clamp(velocity.x / max_speed, -0.25, 0.25)

	rotation = wobble + lean_amount
	time += delta

func _update_skate_sfx(delta: float) -> void:
	var moving_speed = velocity.length()
	var min_speed_to_play = 5.0

	# --- Player is moving ---
	if moving_speed > min_speed_to_play:
		# start sound if not already playing
		if not sfx_skateboard.playing:
			sfx_skateboard.volume_db = skate_min_volume  # start quiet
			sfx_skateboard.play()

		# smooth fade-in for short movements
		sfx_skateboard.volume_db = lerp(
			sfx_skateboard.volume_db,
			skate_volume,
			delta * 2.5  # increase for faster fade-in
		)

		# adjust pitch by speed
		var speed_ratio = clamp(current_speed / max_speed, 0.0, 1.0)
		sfx_skateboard.pitch_scale = lerp(
			sfx_skateboard.pitch_scale,
			lerp(skate_min_pitch, skate_max_pitch, speed_ratio),
			delta * 4
		)

	# --- Player is slowing/stopped ---
	else:
		# fast fade-out then stop
		sfx_skateboard.volume_db = lerp(
			sfx_skateboard.volume_db,
			skate_min_volume,
			delta * 10.0  # higher = quicker cutoff
		)
		if sfx_skateboard.volume_db <= skate_min_volume + 1.0:
			sfx_skateboard.stop()
