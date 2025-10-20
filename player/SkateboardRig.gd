extends Node2D

@onready var player: CharacterBody2D = get_parent().get_node("Player")

var smoothed_facing_direction := Vector2(1, 0)
var speed = 5
var follow_distance = 30.0 # distance behind player
var activation_distance = 10.0 # how far player must move before board reacts

func _process(delta: float) -> void:
	smoothed_facing_direction = smoothed_facing_direction.lerp(player.facing_direction, delta * 10)
	
	var follow_offset = -smoothed_facing_direction * follow_distance
	var target_position = player.position + follow_offset

	var distance_to_target = position.distance_to(target_position)

	# IF the player moves far enough away
	if distance_to_target > activation_distance:
		position = position.lerp(target_position, delta * speed)
