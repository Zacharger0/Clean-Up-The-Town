extends Area2D

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var prompt_label: Label = $Label
@onready var score_manager = get_tree().get_first_node_in_group("score_manager")

# Add a small sound effect and shake tween
@onready var recycle_sfx: AudioStreamPlayer2D = $RecycleSFX

var player_near := false
var hold_time := 0.0
var required_hold_time := 3.0
var recycling := false


func _ready() -> void:
	# --- Basic bar size ---
	progress_bar.custom_minimum_size = Vector2(200, 20)

	# --- Background (black border) ---
	var border := StyleBoxFlat.new()
	border.bg_color = Color.BLACK
	border.set_border_width_all(3)
	border.border_color = Color.BLACK
	border.set_corner_radius_all(3)
	progress_bar.add_theme_stylebox_override("background", border)

	# Force horizontal fill
	progress_bar.rotation_degrees = 0
	progress_bar.anchor_left = 0
	progress_bar.anchor_right = 0
	progress_bar.anchor_top = 0
	progress_bar.anchor_bottom = 0
	progress_bar.size = Vector2(50, 5)
	progress_bar.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	progress_bar.set_v_size_flags(Control.SIZE_SHRINK_CENTER)

	# --- Fill (green interior) ---
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0, 1, 0)
	fill.set_corner_radius_all(3)
	progress_bar.add_theme_stylebox_override("fill", fill)

	progress_bar.visible = false
	prompt_label.visible = false

	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

	
func _process(delta: float) -> void:
	if not score_manager:
		score_manager = get_tree().get_first_node_in_group("score_manager")

	if player_near:
		if Input.is_action_pressed("recycle") and not recycling:
			if score_manager and score_manager.total_score > 0:
				hold_time += delta
				progress_bar.visible = true
				progress_bar.value = clamp(hold_time / required_hold_time, 0.0, 1.0)

				# 💡 Dynamic color from red → green as bar fills
				progress_bar.modulate = Color(
				0.0,
				progress_bar.value,
				0.0
)

				if hold_time >= required_hold_time:
					recycling = true
					_start_recycle_animation()
			else:
				prompt_label.text = "No trash to recycle!"
				progress_bar.visible = false
		else:
			hold_time = 0.0
			progress_bar.visible = false
	else:
		hold_time = 0.0
		
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_near = true
		prompt_label.text = "Hold [E] to recycle"
		prompt_label.visible = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_near = false
		prompt_label.visible = false
		progress_bar.visible = false
		hold_time = 0.0

# ---------------------- RECYCLING LOGIC ----------------------

func _start_recycle_animation() -> void:
	prompt_label.visible = false
	progress_bar.visible = false

	if not score_manager:
		return

	var total_trash_value: int = score_manager.total_score
	if total_trash_value <= 0:
		recycling = false
		prompt_label.text = "No trash to recycle!"
		prompt_label.visible = true
		return

	# Play sound + shake
	if recycle_sfx:
		recycle_sfx.pitch_scale = randf_range(0.75, 1.25)
		recycle_sfx.play()
	_shake_bin()

	# Spawn flying trash + convert to money
	_spawn_recycle_trash(total_trash_value)
	await _convert_trash_to_money(total_trash_value)

	recycling = false
	hold_time = 0.0
	prompt_label.text = "Hold [E] to recycle"
	prompt_label.visible = true

# ---------------------- MONEY CONVERSION ----------------------

func _convert_trash_to_money(total_value: int) -> void:
	# 1 money per 10 trash points
	var money_to_add: int = int(total_value / 10)
	var current_added: int = 0

	while score_manager.total_score > 0:
		await get_tree().create_timer(0.05).timeout

		# Decrease trash slowly, 2 points per tick
		score_manager.total_score = max(0, score_manager.total_score - 2)

		# Add money over time too
		if current_added < money_to_add:
			score_manager.money += 1
			current_added += 1

		score_manager._update_score_label()

# ---------------------- VISUAL TRASH FX ----------------------

func _spawn_recycle_trash(total_value: int) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	var num_trash: int = clamp(int(total_value / 10), 5, 50)
	var trash_textures: Array[Texture2D] = [
		preload("res://sprites/apple.png"),
		preload("res://sprites/trashbag.png"),
		preload("res://sprites/cardboard.png")
	]

	for i in range(num_trash):
		var trash_sprite := Sprite2D.new()
		trash_sprite.texture = trash_textures[randi() % trash_textures.size()]
		trash_sprite.global_position = player.global_position
		add_child(trash_sprite)

		var arc_offset: Vector2 = Vector2(randf_range(-40, 40), -randf_range(60, 120))
		var mid_pos: Vector2 = player.global_position + arc_offset
		var tween := create_tween()
		tween.tween_property(trash_sprite, "global_position", mid_pos, 0.25).set_trans(Tween.TRANS_SINE)
		tween.tween_property(trash_sprite, "global_position", global_position, 0.35).set_trans(Tween.TRANS_SINE)
		tween.tween_callback(trash_sprite.queue_free)

# ---------------------- SHAKE EFFECT ----------------------

func _shake_bin() -> void:
	var tween := create_tween()
	var original_pos := position
	tween.tween_property(self, "position", original_pos + Vector2(5, 0), 0.05)
	tween.tween_property(self, "position", original_pos - Vector2(5, 0), 0.05)
	tween.tween_property(self, "position", original_pos, 0.05)
