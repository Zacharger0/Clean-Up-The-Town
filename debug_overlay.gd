extends CanvasLayer

@onready var panel: PanelContainer = $PanelContainer
@onready var debug_text: RichTextLabel = $PanelContainer/VBoxContainer/DebugText

var visible_state := false
var tracked_object: Node = null
var secondary_object: Node = null

# Stores original default values to compare against
var default_player_values := {
	"base_speed": 150.0,
	"max_speed": 320.0,
	"acceleration": 800.0,
	"deceleration": 900.0,
	"drift_factor": 10.0
}

var edit_mode := false
var command_input: LineEdit
var feedback_label: Label
var feedback_timer: Timer
var input_locked := false  # blocks player input while typing

func _ready() -> void:
	visible = false

	# --- Style tweaks ---
	debug_text.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	debug_text.set("theme_override_font_sizes/normal_font_size", 9)
	debug_text.set("theme_override_font_sizes/bold_font_size", 9)
	debug_text.set("theme_override_constants/line_separation", -3)

	panel.self_modulate = Color(1, 1, 1, 0.75)
	panel.position = Vector2(10, 10)
	panel.custom_minimum_size = Vector2(230, 0)

	# --- Command input box ---
	command_input = LineEdit.new()
	command_input.placeholder_text = "Type var=value (ex: max_speed=400)"
	command_input.visible = false
	command_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	command_input.set("theme_override_font_sizes/normal_font_size", 9)
	panel.get_node("VBoxContainer").add_child(command_input)
	command_input.connect("text_submitted", Callable(self, "_on_command_entered"))
	command_input.connect("focus_entered", Callable(self, "_on_focus_entered"))
	command_input.connect("focus_exited", Callable(self, "_on_focus_exited"))

	# --- Feedback label ---
	feedback_label = Label.new()
	feedback_label.text = ""
	feedback_label.modulate = Color(0.8, 1.0, 0.8, 0.0)
	feedback_label.position = Vector2(10, 180)
	feedback_label.set("theme_override_font_sizes/font_size", 10)
	add_child(feedback_label)

	# --- Timer for feedback fade ---
	feedback_timer = Timer.new()
	feedback_timer.wait_time = 1.2
	feedback_timer.one_shot = true
	add_child(feedback_timer)
	feedback_timer.connect("timeout", Callable(self, "_on_feedback_timeout"))

# ---------- MAIN LOOP ----------
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("debug_toggle"):
		visible_state = !visible_state
		visible = visible_state

	if not visible:
		return

	var output := ""

# ========= HEADER =========
	output += "[center][color=green][b]=== DEV MENU ===[/b][/color][/center]\n\n"
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
		output += "Sprinting: %s\n" % str(sprinting)
		output += "Moving: %s\n" % str(moving)
		output += "Facing: (%.1f, %.1f)\n" % [
			_read_vec2(tracked_object, "facing_direction").x,
			_read_vec2(tracked_object, "facing_direction").y
		]
		output += "\n"

	# ========= SECTION 2: PLAYER SETTINGS =========
	if tracked_object:
		output += "[color=orange][b]--- PLAYER SETTINGS ---[/b][/color]\n"

	# Vars you can edit live
	var tweakable_vars = [
		"base_speed",
		"max_speed",
		"acceleration",
		"deceleration",
		"drift_factor"
	]

	for var_name in tweakable_vars:
		var current_val = _read_prop(tracked_object, var_name, 0.0)
		var base_val = default_player_values.get(var_name, current_val)

		# If changed, show (base) in parentheses
		if abs(current_val - base_val) > 0.001:
			output += "[color=lightgreen]%s[/color]: %.1f (%.1f)\n" % [
				var_name.capitalize().replace("_", " "),
				current_val,
				base_val
			]
		else:
			output += "[color=lightgreen]%s[/color]: %.1f\n" % [
				var_name.capitalize().replace("_", " "),
				current_val
			]

	# Normal non-edit debug values
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

# ---------- INPUT HANDLING ----------
func _input(event: InputEvent) -> void:
	# Toggle command input with '/'
	if event.is_action_pressed("debug_edit"):
		edit_mode = !edit_mode
		command_input.visible = edit_mode

		if edit_mode:
			command_input.text = ""
			command_input.grab_focus()
			input_locked = true
		else:
			command_input.release_focus()
			input_locked = false

		# Prevent '/' itself from being typed in
		get_viewport().set_input_as_handled()
# ---------- COMMAND PARSER ----------
func _on_command_entered(text: String) -> void:
	if not tracked_object or text == "":
		_reset_command_box()
		return

	text = text.strip_edges()
	if text.begins_with("/"):
		text = text.substr(1, text.length() - 1).strip_edges()

	var parts = text.split("=")
	if parts.size() == 2:
		var var_name = parts[0].strip_edges()
		var value_str = parts[1].strip_edges()
		var current_val = tracked_object.get(var_name) if _has_property(tracked_object, var_name) else null

		if current_val == null:
			_show_feedback("⚠️ Variable not found: " + var_name, Color(1, 0.5, 0.5))
		else:
			var new_value
			match typeof(current_val):
				TYPE_INT, TYPE_FLOAT:
					new_value = float(value_str)
				TYPE_BOOL:
					new_value = value_str.to_lower() in ["true", "1", "yes"]
				TYPE_STRING:
					new_value = value_str
				_:
					_show_feedback("⚠️ Unsupported type", Color(1, 0.5, 0.5))
					_reset_command_box()
					return

			tracked_object.set(var_name, new_value)
			_show_feedback("✅ " + var_name + " = " + str(new_value), Color(0.5, 1, 0.5))
	else:
		_show_feedback("⚠️ Invalid format (use var=value)", Color(1, 0.5, 0.5))

	_reset_command_box()

func _reset_command_box() -> void:
	command_input.text = ""
	command_input.visible = false
	edit_mode = false
	input_locked = false

# ---------- FOCUS LOCK ----------
func _on_focus_entered() -> void:
	input_locked = true

func _on_focus_exited() -> void:
	input_locked = false

# ---------- FEEDBACK ----------
func _show_feedback(text: String, color: Color) -> void:
	feedback_label.text = text
	var temp_color = color
	temp_color.a = 1.0
	feedback_label.modulate = temp_color
	feedback_timer.start()

func _on_feedback_timeout() -> void:
	var tween = create_tween()
	tween.tween_property(feedback_label, "modulate:a", 0.0, 0.6)
	tween.parallel().tween_property(feedback_label, "position:y", feedback_label.position.y - 5, 0.6)

# ---------- HELPERS ----------
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
