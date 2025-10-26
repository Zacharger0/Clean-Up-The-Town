extends Node

@onready var score_label: Label = $ScoreLabel
@onready var game_timer: Timer = $GameTimer
@onready var game_over_label: Label = $GameOverLabel
@onready var vacuum_cooldown_bar: ProgressBar = $VacuumCooldown

signal score_updated(new_score: int)
signal trash_collected(new_total: int)
signal money_updated(new_money: int)
signal money_tick
signal timer_ended

var total_trash_collected: int = 0   # Number of trash items picked up
var total_trash_value: int = 0       # Hidden value for recycling (not shown)
var total_score: int = 0             # Lifetime visible score
var money: int = 0
var game_time: float = 30.0

func _ready() -> void:
	add_to_group("score_manager")
	game_timer.wait_time = 1.0
	game_timer.autostart = true
	game_timer.connect("timeout", Callable(self, "_on_game_timer_timeout"))
	game_over_label.visible = false
	_update_score_label()

# ---------------------- ADD TRASH ----------------------
func add_trash(value: int) -> void:
	total_trash_collected += 1
	total_trash_value += value
	total_score += value

	trash_collected.emit(total_trash_collected)
	score_updated.emit(total_score)
	_update_score_label()

# ---------------------- RECYCLE TRASH ----------------------
func recycle_trash() -> Dictionary:
	if total_trash_value <= 0:
		return {"earned_money": 0, "bonus_multiplier": 1.0}

	var base_money := float(total_trash_value) / 10.0

	var bonus_multiplier := 1.0
	if total_trash_value >= 200:
		bonus_multiplier = 1.5
	elif total_trash_value >= 100:
		bonus_multiplier = 1.25
	elif total_trash_value >= 50:
		bonus_multiplier = 1.15
	elif total_trash_value >= 25:
		bonus_multiplier = 1.10

	var earned_money := int(base_money * bonus_multiplier)
	money += earned_money
	money_updated.emit(money)

	# Store start value for smooth visual drain
	var start_value := total_trash_value
	var duration := 1.0
	var step_time := 0.05
	var steps := int(duration / step_time)

	# Run the drain asynchronously (trash visually goes down)
	for i in range(steps):
		await get_tree().create_timer(step_time).timeout
		var t := float(i) / float(steps)
		total_trash_value = int(lerp(start_value, 0, t))
		_update_score_label()

	# ✅ Make sure it hits exactly zero
	total_trash_value = 0
	total_trash_collected = 0
	_update_score_label()

	return {"earned_money": earned_money, "bonus_multiplier": bonus_multiplier}

# ---------------------- TIMER ----------------------
func _on_game_timer_timeout() -> void:
	game_time -= 1
	if game_time <= 0:
		game_timer.stop()
		timer_ended.emit()
		_show_game_over()
	_update_score_label()

# ---------------------- UPDATE LABEL ----------------------
func _update_score_label() -> void:
	var minutes := int(game_time) / 60
	var seconds := int(game_time) % 60
	score_label.text = "SCORE: %d | TRASH: %d | MONEY: $%d | TIME: %02d:%02d" % [
		total_score, total_trash_collected, money, minutes, seconds
	]

# ---------------------- VACUUM COOLDOWN ----------------------
func set_vacuum_cooldown(value: float) -> void:
	if vacuum_cooldown_bar == null:
		vacuum_cooldown_bar = get_node_or_null("VacuumCooldown")
		if vacuum_cooldown_bar == null:
			push_warning("⚠VacuumCooldown not found in ScoreManager!")
			return
	vacuum_cooldown_bar.value = clamp(value, 0.0, 1.0)
	vacuum_cooldown_bar.visible = value < 1.0

# ---------------------- GAME OVER ----------------------
func _show_game_over() -> void:
	game_over_label.text = "GAME OVER\nScore: %d" % total_score
	game_over_label.visible = true
	await get_tree().create_timer(3.0).timeout
	get_tree().reload_current_scene()
