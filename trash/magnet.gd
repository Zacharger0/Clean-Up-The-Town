extends Node2D

var player: CharacterBody2D = null
var speed := 100.0

func _process(delta: float) -> void:
	if player:
		var direction = (player.global_position - global_position).normalized()
		global_position += direction * speed * delta
