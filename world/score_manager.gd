extends Node

@onready var score_label: Label = $ScoreLabel
@onready var game_timer: Timer = $GameTimer
@onready var game_over_label: Label = $GameOverLabel

# --- Core Stats ---
var total_trash_collected: int = 0      # how many items picked up
var total_trash_value: int = 0          # hidden value for recycling
var total_score: int = 0                # lifetime score (increases on pickup)
var money: int = 0
var game_time: float = 30.0  # seconds

# --- Signals ---
signal score_updated(new_score: int)
signal trash_collected(new_total: int)
signal money_updated(new_money: int)
signal timer_ended

func _ready() -> void:
	add_to_group("score_manager")
	game_timer.wait_time = 1.0
	game_timer.autostart = true
	game_timer.connect("timeout", Callable(self, "_on_game_timer_timeout"))
	game_over_label.visible = false
	_update_score_label()

# ---------------------- ADD TRASH ----------------------

func add_trash(value: int) -> void:
	# Each trash gives immediate score but also builds up hidden value for recycling
	total_trash_collected += 1
	total_trash_value += value  # used internally for money conversion
	total_score += value        # visible lifetime score
	trash_collected.emit(total_trash_collected)
	score_updated.emit(total_score)
	_update_score_label()

# ---------------------- RECYCLE LOGIC ----------------------

func recycle_trash() -> void:
	if total_trash_value <= 0:
		return

	# Convert hidden trash value to money
	var earned_money = int(total_trash_value / 10)
	money += earned_money
	total_trash_value = 0  # reset after recycling

	money_updated.emit(money)
	_update_score_label()

# ---------------------- TIMER ----------------------

func _on_game_timer_timeout() -> void:
	game_time -= 1
	if game_time <= 0:
		game_time = 0
		game_timer.stop()
		timer_ended.emit()
		_show_game_over()
	_update_score_label()

# ---------------------- UPDATE LABEL ----------------------

func _update_score_label() -> void:
	var minutes := int(game_time) / 60
	var seconds := int(game_time) % 60
	score_label.text = "🏆 SCORE: %d\n🧩 TRASH COLLECTED: %d\n💰 MONEY: $%d\n⏱ TIME: %02d:%02d" % [
		total_score,
		total_trash_collected,
		money,
		minutes,
		seconds
	]

# ---------------------- GAME OVER ----------------------

func _show_game_over() -> void:
	game_over_label.text = "GAME OVER\nScore: %d" % total_score
	game_over_label.visible = true
	await get_tree().create_timer(3.0).timeout
	get_tree().reload_current_scene()
