extends CharacterBody2D

@onready var line_2d: Line2D = $Line2D
@onready var player: CharacterBody2D = $Player
@onready var skateboard_trashcan: StaticBody2D = $Skateboard_Trashcan

func _process(delta: float) -> void:
	line_2d.set_point_position(0, player.position)
	line_2d.set_point_position(1, skateboard_trashcan.position)
