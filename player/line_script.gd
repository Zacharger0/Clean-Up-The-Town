extends Line2D

@onready var line_2d: Line2D = $"."
@onready var player: CharacterBody2D = $"../Player"
@onready var skateboard: StaticBody2D = $"../Skateboard"


func _process(delta: float) -> void:
	line_2d.set_point_position(0, player.position)
	line_2d.set_point_position(1, skateboard.position)
