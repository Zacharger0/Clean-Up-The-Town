extends Area2D

@export var range: float = 200.0
@export var offset_distance: float = 25.0
@export var pulse_strength: float = 0.08
@export var pulse_speed: float = 10.0

var active: bool = false
var recharging: bool = false
var overheated: bool = false
var time_accum := 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null

func _ready() -> void:
	# This Area2D must be on Layer "vacuum" and Mask "trash"
	# (Project -> Debug -> Visible Collision Shapes helps verify)
	monitoring = false
	monitorable = true
	if collision_shape and collision_shape.shape is CircleShape2D:
		(collision_shape.shape as CircleShape2D).radius = range
	if sprite:
		sprite.modulate = Color(0.7, 0.8, 1.0, 0.5)
	set_process(true)
	add_to_group("vacuum")

# ------------- user feedback when denied -------------
func shake_denied() -> void:
	var t := create_tween()
	var original_pos := position
	var amplitude := 6.0
	for i in range(6):
		var offs := Vector2(randf_range(-amplitude, amplitude), randf_range(-amplitude, amplitude))
		t.tween_property(self, "position", original_pos + offs, 0.04)
	t.tween_property(self, "position", original_pos, 0.06)
	if sprite:
		var start_col := sprite.modulate
		t.parallel().tween_property(sprite, "modulate", Color(1, 0.25, 0.25, start_col.a), 0.08)
		t.tween_property(sprite, "modulate", start_col, 0.20)

# ------------- states -------------
func activate_vacuum() -> void:
	if overheated:
		return
	active = true
	recharging = false
	monitoring = true
	if sprite:
		sprite.modulate = Color(0.9, 1.0, 1.0, 1.0)
	print("🌀 Vacuum ON")

func deactivate_vacuum() -> void:
	active = false
	monitoring = false
	if not overheated and sprite:
		sprite.modulate = Color(0.7, 0.8, 1.0, 0.5)
	print("💤 Vacuum OFF")

func is_active() -> bool:
	return active

func show_overheat() -> void:
	overheated = true
	recharging = true
	if sprite:
		sprite.modulate = Color(1.0, 0.2, 0.2, 1.0) # red while hot
	print("🔥 Overheated!")

func update_recharge_visual(progress: float) -> void:
	if not sprite:
		return
	if overheated:
		var start := Color(1.0, 0.2, 0.2, 1.0)
		var end := Color(0.7, 0.8, 1.0, 0.5)
		sprite.modulate = start.lerp(end, clamp(progress, 0.0, 1.0))
	elif recharging:
		var base := Color(0.6, 0.7, 1.0, 0.5)
		var end := Color(0.9, 1.0, 1.0, 1.0)
		sprite.modulate = base.lerp(end, clamp(progress, 0.0, 1.0))

func end_overheat_recovery() -> void:
	overheated = false
	recharging = false
	if sprite:
		sprite.modulate = Color(0.7, 0.8, 1.0, 0.5)
	print("✅ Vacuum cooled down")

# ------------- follow mouse + pulse + “ping” trash -------------
func _process(delta: float) -> void:
	if not is_inside_tree():
		return

	var player := get_parent() as Node2D
	if player == null:
		return

	time_accum += delta * pulse_speed

	# Orbit toward mouse
	var mouse_global := get_global_mouse_position()
	var dir := (mouse_global - player.global_position).normalized()
	rotation = dir.angle()
	position = dir * offset_distance

	# Flip sprite for correct facing
	if sprite:
		sprite.flip_v = dir.x < 0
		if active:
			var pulse := 1.0 + sin(time_accum) * pulse_strength
			sprite.scale = Vector2(pulse, pulse)
		else:
			sprite.scale = Vector2.ONE

	# --- 💥 MULTI-TRASH VACUUM LOGIC ---
	if active:
		for area in get_overlapping_areas():
			if area.is_in_group("trash") and not area.is_being_vacuumed:
				# directly trigger its shake/fly sequence
				area.is_being_vacuumed = true
				if area.has_method("_shake_then_pull"):
					area.call_deferred("_shake_then_pull", self)
