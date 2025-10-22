extends CanvasLayer

@onready var panel: PanelContainer = $PanelContainer
@onready var debug_text: RichTextLabel = $PanelContainer/VBoxContainer/DebugText

var visible_state := false
var tracked_object: Node = null
var secondary_object: Node = null  # optional (e.g., Magnet, TrashManager)

func _ready() -> void:
	visible = false

	# --- Style tweaks for compact debug overlay ---

	# Use nearest-neighbor filtering for crisp pixel edges
	debug_text.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	debug_text.material = null  # ensure no smoothing materials are applied

	# Font overrides (RichTextLabel-compatible)
	debug_text.set("theme_override_fonts/font", null)
	debug_text.set("theme_override_font_sizes/normal_font_size", 10)
	debug_text.set("theme_override_font_sizes/bold_font_size", 12.5)
	debug_text.set("theme_override_constants/line_separation", 0)

	# ↓ REMOVE these — they cause errors for RichTextLabel
	# debug_text.pixel_size = 1
	# debug_text.antialiased = false

	# Shrink panel padding
	panel.set("theme_override_constants/margin_left", 4)
	panel.set("theme_override_constants/margin_top", 4)
	panel.set("theme_override_constants/margin_right", 4)
	panel.set("theme_override_constants/margin_bottom", 4)

	# Panel transparency and color
	panel.self_modulate = Color(1, 1, 1, 0.75)

	# Optional: lock size/position
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	panel.position = Vector2(10, 10)
	panel.custom_minimum_size = Vector2(220, 0)

	# Additional margin overrides
	panel.add_theme_constant_override("margin_left", 4)
	panel.add_theme_constant_override("margin_top", 4)
	panel.add_theme_constant_override("margin_right", 4)
	panel.add_theme_constant_override("margin_bottom", 4)
	
	
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("debug_toggle"):
		visible_state = !visible_state
		visible = visible_state

	if not visible:
		return

	var output := ""

	# ========= SECTION 1: LIVE STATE =========
	if tracked_object:
		var pos = _read_vec2(tracked_object, "global_position")
		var vel = _read_vec2(tracked_object, "velocity")
		var speed = vel.length()
		var sprinting = Input.is_action_pressed("sprint")
		var moving = _read_vec2(tracked_object, "input_direction").length() > 0

		output += "[color=yellow][b]--- LIVE STATE ---[/b][/color]\n"
		output += "Position: (%.1f, %.1f)\n" % [pos.x, pos.y]
		output += "Velocity: (%.1f, %.1f)\n" % [vel.x, vel.y]
		output += "Speed: %.1f\n" % speed
		output += "Current Speed Target: %.1f\n" % _read_prop(tracked_object, "current_speed", 0.0)
		output += "Sprinting: %s\n" % (str(sprinting))
		output += "Moving: %s\n" % (str(moving))
		output += "Facing: (%.1f, %.1f)\n" % [_read_vec2(tracked_object, "facing_direction").x, _read_vec2(tracked_object, "facing_direction").y]
		output += "\n"

	# ========= SECTION 2: PLAYER SETTINGS =========
	if tracked_object:
		output += "[color=orange][b]--- PLAYER SETTINGS ---[/b][/color]\n"
		output += "Base Speed: %.1f\n" % _read_prop(tracked_object, "base_speed", 0.0)
		output += "Max Speed: %.1f\n" % _read_prop(tracked_object, "max_speed", 0.0)
		output += "Acceleration: %.1f\n" % _read_prop(tracked_object, "acceleration", 0.0)
		output += "Deceleration: %.1f\n" % _read_prop(tracked_object, "deceleration", 0.0)
		output += "Drift Factor: %.1f\n" % _read_prop(tracked_object, "drift_factor", 0.0)
		output += "Wobble Timer: %.2f / Delay: %.2f\n" % [
			_read_prop(tracked_object, "wobble_timer", 0.0),
			_read_prop(tracked_object, "wobble_delay", 0.0)
		]
		output += "\n"

	# ========= SECTION 3: MAGNET / TRASH DEBUG =========
	if secondary_object:
		output += "[color=lightgreen][b]--- MAGNET / TRASH ---[/b][/color]\n"
		output += "Active: %s\n" % str(_read_prop(secondary_object, "is_magnet_active", false))
		output += "Coyote Timer: %.2f\n" % _read_prop(secondary_object, "coyote_timer", 0.0)
		output += "Move Speed: %.1f\n" % _read_prop(secondary_object, "move_speed", 0.0)
		output += "Activation Distance: %.1f\n" % _read_prop(secondary_object, "activation_distance", 0.0)
		var tpos = _read_vec2(secondary_object, "global_position")
		output += "Trash Pos: (%.1f, %.1f)\n" % [tpos.x, tpos.y]
		output += "\n"

	# ========= SECTION 4: INPUT DEBUG =========
	output += "[color=violet][b]--- INPUT ---[/b][/color]\n"
	output += "ui_accept: %s | sprint: %s\n" % [
		str(Input.is_action_pressed("ui_accept")),
		str(Input.is_action_pressed("sprint"))
	]
	output += "left: %s | right: %s | up: %s | down: %s\n" % [
		str(Input.is_action_pressed("left")),
		str(Input.is_action_pressed("right")),
		str(Input.is_action_pressed("up")),
		str(Input.is_action_pressed("down"))
	]
	output += "\n"

	# ========= SECTION 5: PERFORMANCE =========
	output += "[color=lightblue][b]--- PERFORMANCE ---[/b][/color]\n"
	output += "FPS: %d\n" % Engine.get_frames_per_second()
	output += "Process Delta: %.3f\n" % delta
	output += "Visible: %s\n" % str(visible)

	debug_text.text = output


# ---------- Helpers ----------
func _has_property(obj: Object, name: String) -> bool:
	for p in obj.get_property_list():
		if p.name == name:
			return true
	return false

func _read_prop(obj: Object, name: String, def):
	return obj.get(name) if _has_property(obj, name) else def

func _read_vec2(obj: Object, name: String) -> Vector2:
	if _has_property(obj, name):
		var v = obj.get(name)
		if typeof(v) == TYPE_VECTOR2:
			return v
	return Vector2.ZERO
