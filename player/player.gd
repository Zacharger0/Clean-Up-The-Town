extends CharacterBody2D

@onready var player_sprite: Sprite2D = $Sprite2D
@onready var sfx_skateboard: AudioStreamPlayer2D = $SFX_Skateboard
@onready var score_manager: Node = get_tree().get_first_node_in_group("score_manager")
@onready var vacuum_area: Node = $VacuumArea

# --- Skateboard SFX ---
var skate_min_pitch := 0.9
var skate_max_pitch := 1.4
var skate_volume := -15.0
var skate_min_volume := -25.0

# --- Movement settings ---
var base_speed := 150.0
var max_speed := 320.0
var acceleration := 800.0
var deceleration := 900.0
var drift_factor := 3.5

var current_speed := 0.0
var time := 0.0
var wobble_timer := 0.0
var wobble_delay := 0.2
var input_direction := Vector2.ZERO
var facing_direction := Vector2(1, 0)

# --- Vacuum system ---
var vacuum_ready := true
var vacuum_active := false
var vacuum_duration := 3.0
var cooldown_duration := 1.5
var vacuum_timer := 0.0
var input_released := true   # ensures you can’t “hold” to auto-restart

func _ready() -> void:
	if not score_manager:
		score_manager = get_tree().get_first_node_in_group("score_manager")

# ------------------- MOVEMENT -------------------
func get_input(delta):
	input_direction = Input.get_vector("left", "right", "up", "down")

	if Input.is_action_pressed("sprint") and input_direction != Vector2.ZERO:
		current_speed = lerp(current_speed, max_speed, delta * 2.5)
	elif input_direction != Vector2.ZERO:
		current_speed = lerp(current_speed, base_speed, delta * 3.5)
	else:
		current_speed = lerp(current_speed, 0.0, delta * 6.0)

	var target_velocity = input_direction * current_speed
	velocity = lerp(velocity, target_velocity, delta * drift_factor)

	if velocity.length() > 5:
		wobble_timer += delta
	else:
		wobble_timer = 0.0

	if wobble_timer > wobble_delay and abs(velocity.x) > abs(velocity.y):
		wobble_and_lean(delta)
	else:
		rotation = lerp(rotation, 0.0, delta * 8.0)

	if input_direction != Vector2.ZERO:
		facing_direction = input_direction.normalized()
	player_sprite.flip_h = facing_direction.x < 0

func _physics_process(delta: float) -> void:
	get_input(delta)
	move_and_slide()
	_update_skate_sfx(delta)
	_update_vacuum(delta)

# ------------------- SKATEBOARD MOTION -------------------
func wobble_and_lean(delta):
	var speed_ratio = clamp(current_speed / max_speed, 0.0, 1.0)
	var wobble_strength = lerp(0.1, 0.02, speed_ratio)
	var wobble_speed = lerp(18.0, 8.0, speed_ratio)
	var wobble = sin(time * wobble_speed) * wobble_strength
	var lean_amount = clamp(velocity.x / max_speed, -0.25, 0.25)
	rotation = wobble + lean_amount
	time += delta

func _update_skate_sfx(delta: float) -> void:
	var moving_speed = velocity.length()
	if moving_speed > 5.0:
		if not sfx_skateboard.playing:
			sfx_skateboard.volume_db = skate_min_volume
			sfx_skateboard.play()
		sfx_skateboard.volume_db = lerp(sfx_skateboard.volume_db, skate_volume, delta * 2.5)
		var speed_ratio = clamp(current_speed / max_speed, 0.0, 1.0)
		sfx_skateboard.pitch_scale = lerp(
			sfx_skateboard.pitch_scale,
			lerp(skate_min_pitch, skate_max_pitch, speed_ratio),
			delta * 4
		)
	else:
		sfx_skateboard.volume_db = lerp(sfx_skateboard.volume_db, skate_min_volume, delta * 10.0)
		if sfx_skateboard.volume_db <= skate_min_volume + 1.0:
			sfx_skateboard.stop()

# ------------------- VACUUM SYSTEM -------------------
func _update_vacuum(delta: float) -> void:
	var pressed = Input.is_action_pressed("vacuum")
	var just_pressed = Input.is_action_just_pressed("vacuum")
	var just_released = Input.is_action_just_released("vacuum")

	if just_released:
		input_released = true
		# --- Stop vacuum early if released mid-use ---
		if vacuum_active:
			print("🧲 Vacuum stopped early by release")
			_end_vacuum(true)

	# --- Start only if player clicked after cooldown ---
	if just_pressed and input_released:
		if vacuum_ready and not vacuum_active:
			_start_vacuum()
			input_released = false
		elif not vacuum_ready:
			_on_vacuum_denied()

	# --- While active (drains duration) ---
	if vacuum_active:
		vacuum_timer -= delta
		var progress := vacuum_timer / vacuum_duration
		score_manager.set_vacuum_cooldown(progress)
		if vacuum_timer <= 0:
			_end_vacuum()

	# --- Cooldown / refill phase ---
	elif not vacuum_ready:
		vacuum_timer -= delta
		var progress := 1.0 - (vacuum_timer / cooldown_duration)
		score_manager.set_vacuum_cooldown(progress)
		if vacuum_area:
			vacuum_area.update_recharge_visual(progress)
		if vacuum_timer <= 0:
			vacuum_ready = true
			vacuum_area.recharging = false
			vacuum_area.overheated = false
			vacuum_area.end_overheat_recovery()
			vacuum_area.update_recharge_visual(1.0)
			score_manager.set_vacuum_cooldown(1.0)
			print("✅ Vacuum ready again.")

	# --- Refill if released early ---
	elif not pressed and not vacuum_active and vacuum_ready:
		# Safely get current cooldown value
		var current_value := 1.0
		if score_manager and score_manager.has_node("VacuumCooldown"):
			var bar := score_manager.get_node_or_null("VacuumCooldown")
			if bar and bar is ProgressBar:
				current_value = bar.value

		# Smoothly refill bar toward full
		if current_value < 1.0:
			current_value = lerp(current_value, 1.0, delta * 0.8)
			score_manager.set_vacuum_cooldown(current_value)
# ------------------- VACUUM STATES -------------------
func _start_vacuum() -> void:
	vacuum_active = true
	vacuum_ready = false
	vacuum_timer = vacuum_duration
	score_manager.set_vacuum_cooldown(1.0)
	if vacuum_area:
		vacuum_area.activate_vacuum()
	print("🧲 Vacuum started")
	# TODO: SFX — start sound

func _end_vacuum(cancelled := false) -> void:
	vacuum_active = false
	if cancelled:
		# Released early: start short refill cooldown
		vacuum_timer = cooldown_duration * 0.6
		vacuum_ready = false
		if vacuum_area:
			vacuum_area.deactivate_vacuum()
			vacuum_area.show_overheat() # light red flash even on cancel
		print("🧲 Vacuum cancelled early, short cooldown.")
	else:
		# Normal full overheat
		vacuum_timer = cooldown_duration
		vacuum_ready = false
		if vacuum_area:
			vacuum_area.deactivate_vacuum()
			vacuum_area.show_overheat()
		print("💤 Vacuum cooling down...")
		
func _on_vacuum_denied() -> void:
	if vacuum_area:
		vacuum_area.shake_denied()
	print("⛔ Vacuum still cooling down!")
	# TODO: SFX — denied buzz
