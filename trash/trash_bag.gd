extends "res://scripts/trash_template.gd"

func _ready() -> void:
	trash_value = 3
	sfx_item_plop_normal = $"../../../SFX/SFX Item Plop Normal"
	super._ready()
