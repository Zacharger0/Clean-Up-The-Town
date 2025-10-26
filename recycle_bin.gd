extends Area2D

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var prompt_label: Label = $Label
@onready var score_manager: Node = get_tree().get_first_node_in_group("score_manager")
@onready var recycle_sfx: AudioStreamPlayer2D = $Recycle
@onready var money_sfx: AudioStreamPlayer2D = $MoneySFX

var player_near := false
var hold_time := 0.0
var required_hold_time := 3.0
var recycling := false

func _ready() -> void:
	progress_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	progress_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	progress_bar.set_anchors_preset(Control.PRESET_CENTER)
	progress_bar.size = Vector2(100, 1)  # actual on-screen size

	var border := StyleBoxFlat.new()
	border.bg_color = Color.BLACK
	border.set_border_width_all(1)
	border.border_color = Color.BLACK
	border.set_corner_radius_all(1)
	progress_bar.add_theme_stylebox_override("background", border)

	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0, 1, 0)
	fill.set_corner_radius_all(1)
	progress_bar.add_theme_stylebox_override("fill", fill)

	progress_bar.visible = false
	prompt_label.visible = false

	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

# ---------------- PROCESS ----------------
func _process(delta: float) -> void:
	if not score_manager:
		score_manager = get_tree().get_first_node_in_group("score_manager")

	if player_near:
		if Input.is_action_pressed("recycle") and not recycling:
			if score_manager and score_manager.total_trash_value > 0:
				hold_time += delta
				progress_bar.visible = true
				progress_bar.value = clamp(hold_time / required_hold_time, 0.0, 1.0)
				progress_bar.modulate = Color(0.0, progress_bar.value, 0.0)
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

# ---------------- PLAYER DETECTION ----------------
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

# ---------------- RECYCLE ANIMATION ----------------
func _start_recycle_animation() -> void:
	prompt_label.visible = false
	progress_bar.visible = false
	if not score_manager:
		return

	var total_value: int = score_manager.total_trash_value
	if total_value <= 0:
		recycling = false
		prompt_label.text = "No trash to recycle!"
		prompt_label.visible = true
		return

	if recycle_sfx:
		recycle_sfx.pitch_scale = randf_range(0.75, 1.25)
		recycle_sfx.play()
	_shake_bin()
	_spawn_recycle_trash(total_value)

	var recycle_result: Dictionary = await score_manager.recycle_trash()

	var predicted_money: int = recycle_result.get("earned_money", 0)
	var predicted_bonus: float = recycle_result.get("bonus_multiplier", 1.0)

	_show_money_popup(predicted_money)
	if predicted_bonus > 1.0:
		_show_bonus_popup(predicted_bonus)

	if money_sfx:
		money_sfx.pitch_scale = randf_range(0.9, 1.1)
		money_sfx.play()

	recycling = false
	hold_time = 0.0
	prompt_label.text = "Hold [E] to recycle"
	prompt_label.visible = true
# ---------------- SHAKE EFFECT ----------------
func _shake_bin() -> void:
	var tween := create_tween()
	var original_pos := position
	tween.tween_property(self, "position", original_pos + Vector2(5, 0), 0.05)
	tween.tween_property(self, "position", original_pos - Vector2(5, 0), 0.05)
	tween.tween_property(self, "position", original_pos, 0.05)

# ---------------- TRASH BURST ----------------
func _spawn_recycle_trash(total_value: int) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return

	var num_trash: int = clamp(int(total_value / 10), 5, 50)
	var trash_textures := [
		preload("res://sprites/apple.png"),
		preload("res://sprites/trashbag.png"),
		preload("res://sprites/cardboard.png")
	]

	for i in range(num_trash):
		var trash_sprite := Sprite2D.new()
		trash_sprite.texture = trash_textures[randi() % trash_textures.size()]
		trash_sprite.global_position = player.global_position
		add_child(trash_sprite)

		var arc_offset := Vector2(randf_range(-40, 40), -randf_range(60, 120))
		var mid_pos := player.global_position + arc_offset
		var tween := create_tween()
		tween.tween_property(trash_sprite, "global_position", mid_pos, 0.25).set_trans(Tween.TRANS_SINE)
		tween.tween_property(trash_sprite, "global_position", global_position, 0.35).set_trans(Tween.TRANS_SINE)
		tween.tween_callback(trash_sprite.queue_free)

# ---------------- MONEY POPUP ----------------
func _show_money_popup(amount: int) -> void:
	if amount <= 0:
		return

	var popup := Label.new()
	popup.text = "+$%d" % amount
	popup.modulate = Color(0.2, 1.0, 0.2, 1.0)
	popup.set("theme_override_font_sizes/font_size", 18)
	popup.set("theme_override_font_weights/bold", 800)
	popup.global_position = global_position + Vector2(-20, -160)
	add_child(popup)

	var tween := create_tween()
	popup.scale = Vector2(0.5, 0.5)
	tween.tween_property(popup, "scale", Vector2(1.2, 1.2), 0.15).set_trans(Tween.TRANS_BACK)
	tween.tween_property(popup, "scale", Vector2(1.0, 1.0), 0.1)
	tween.tween_interval(0.5)
	tween.tween_property(popup, "position:y", popup.position.y - 80, 1.2).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(popup, "modulate:a", 0.0, 1.2)
	tween.tween_callback(popup.queue_free)

# ---------------- BONUS POPUP ----------------
func _show_bonus_popup(multiplier: float) -> void:
	if multiplier <= 1.0 or multiplier < 1.25:
		return

	var popup := Label.new()
	popup.text = "%.2fx BONUS!" % multiplier
	popup.modulate = Color(1.0, 0.9, 0.2, 1.0)
	popup.set("theme_override_font_sizes/font_size", 18)
	popup.set("theme_override_font_weights/bold", 900)
	popup.global_position = global_position + Vector2(-70, -190)
	add_child(popup)

	var tween := create_tween()
	popup.scale = Vector2(0.5, 0.5)
	tween.tween_property(popup, "scale", Vector2(1.3, 1.3), 0.2).set_trans(Tween.TRANS_BACK)
	tween.tween_property(popup, "scale", Vector2(1.0, 1.0), 0.1)
	tween.tween_interval(0.5)
	tween.tween_property(popup, "position:y", popup.position.y - 90, 1.3).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(popup, "modulate:a", 0.0, 1.3)
	tween.tween_callback(popup.queue_free)
