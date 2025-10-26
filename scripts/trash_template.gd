extends Area2D

signal trash_collected(value: int)

@export var trash_value: int = 1
var sfx_item_plop_normal: AudioStreamPlayer2D
@onready var score_manager: Node = get_tree().get_first_node_in_group("score_manager")

var is_being_vacuumed := false

func _ready() -> void:
	add_to_group("trash")
	connect("area_entered", Callable(self, "_on_area_entered"))

func _on_area_entered(area: Area2D) -> void:
	if is_being_vacuumed:
		return
	if not area.is_in_group("vacuum"):
		return
	if area.has_method("is_active") and not area.is_active():
		return

	is_being_vacuumed = true
	_shake_then_pull(area)

# --------------------------------------------
# Step 1: SHAKE visibly for 0.2 seconds
# --------------------------------------------
func _shake_then_pull(vacuum: Area2D) -> void:
	var tween := create_tween()
	var original := global_position
	var shake_strength := 6.0
	var shakes := 6
	for i in range(shakes):
		var offset := Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
		tween.tween_property(self, "global_position", original + offset, 0.03)
	tween.tween_property(self, "global_position", original, 0.03)
	tween.tween_callback(Callable(self, "_fly_into_vacuum").bind(vacuum))

# --------------------------------------------
# Step 2: Tween INTO the vacuum
# --------------------------------------------
func _fly_into_vacuum(vacuum: Area2D) -> void:
	if not vacuum or not vacuum.is_inside_tree():
		queue_free()
		return

	var tween := create_tween()
	var target := vacuum.global_position

	tween.tween_property(self, "global_position", target, 0.35).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(self, "scale", Vector2(0.0, 0.0), 0.35).set_trans(Tween.TRANS_BACK)
	tween.tween_callback(Callable(self, "_collect_trash"))

# --------------------------------------------
# Step 3: Reward + remove
# --------------------------------------------
func _collect_trash() -> void:
	if sfx_item_plop_normal:
		sfx_item_plop_normal.pitch_scale = randf_range(0.7, 1.2)
		sfx_item_plop_normal.play()

	if score_manager:
		score_manager.add_trash(trash_value)

	trash_collected.emit(trash_value)
	queue_free()
