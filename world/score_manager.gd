extends Node

@onready var score_label: Label = $ScoreLabel
@onready var game_timer: Timer = $GameTimer
@onready var game_over_label: Label = $GameOverLabel

signal score_updated(new_score: int)
signal trash_collected(new_total: int)
signal money_updated(new_money: int)
signal money_tick
signal timer_ended

var total_trash_collected: int = 0
var total_trash_value: int = 0
var total_score: int = 0
var money: int = 0
var game_time: float = 30.0

func _ready() -> void:
	add_to_group("score_manager")
	game_timer.wait_time = 1.0
	game_timer.autostart = true
	game_timer.connect("timeout", Callable(self, "_on_game_timer_timeout"))
	game_over_label.visible = false
	_update_score_label()

func add_trash(value: int) -> void:
	total_trash_collected += 1
	total_trash_value += value
	total_score += value
	trash_collected.emit(total_trash_collected)
	score_updated.emit(total_score)
	_update_score_label()

func recycle_trash() -> void:
	if total_trash_value <= 0:
		return

	var earned_money: int = int(total_trash_value / 10)
	var added_money := 0
	var trash_remaining := total_trash_value

	while trash_remaining > 0:
		await get_tree().create_timer(0.05).timeout
		var decrease: int = min(2, trash_remaining)
		trash_remaining -= decrease
		total_trash_value = trash_remaining
		total_trash_collected = trash_remaining

		if added_money < earned_money:
			money += 1
			added_money += 1
			money_tick.emit()  # 👈 tell recycle bin to do visual + sfx

		_update_score_label()

	total_trash_value = 0
	total_trash_collected = 0
	_update_score_label()
	money_updated.emit(money)

func _on_game_timer_timeout() -> void:
	game_time -= 1
	if game_time <= 0:
		game_timer.stop()
		timer_ended.emit()
		_show_game_over()
	_update_score_label()

func _update_score_label() -> void:
	var minutes := int(game_time) / 60
	var seconds := int(game_time) % 60
	score_label.text = "SCORE: %d | TRASH: %d | MONEY: $%d | TIME: %02d:%02d" % [
		total_score, total_trash_collected, money, minutes, seconds
	]

func _show_game_over() -> void:
	game_over_label.text = "GAME OVER\nScore: %d" % total_score
	game_over_label.visible = true
	await get_tree().create_timer(3.0).timeout
	get_tree().reload_current_scene()
