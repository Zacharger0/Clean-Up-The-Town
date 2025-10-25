extends Node

@onready var score_label: Label = $ScoreLabel
@onready var game_timer: Timer = $GameTimer
@onready var game_over_label: Label = $GameOverLabel  # new


var money: int = 0
var total_score: int = 0
var total_trash_collected: int = 0
var game_time: float = 20.0  # seconds

signal score_updated(new_score: int)
signal trash_collected(new_total: int)
signal timer_ended

func _ready() -> void:
	game_timer.wait_time = 1.0
	game_timer.autostart = true
	game_timer.connect("timeout", Callable(self, "_on_game_timer_timeout"))
	game_over_label.visible = false
	_update_score_label()

func add_trash(value: int) -> void:
	total_trash_collected += 1
	total_score += value
	score_updated.emit(total_score)
	trash_collected.emit(total_trash_collected)
	_update_score_label()

func _on_game_timer_timeout() -> void:
	game_time -= 1
	if game_time <= 0:
		game_time = 0
		game_timer.stop()
		timer_ended.emit()
		_show_game_over()
	_update_score_label()

func _update_score_label() -> void:
	var minutes = int(game_time) / 60
	var seconds = int(game_time) % 60
	score_label.text = "Score: %d | Trash: %d
	\nMoney: $%d | Time: %02d:%02d" % [
	total_score,
	total_trash_collected,
	money,
	minutes,
	seconds
]
	

func _show_game_over() -> void:
	game_over_label.text = "GAME OVER\nScore: %d" % total_score
	game_over_label.visible = true

	# restart scene after 3 seconds
	await get_tree().create_timer(3.0).timeout
	get_tree().reload_current_scene()
