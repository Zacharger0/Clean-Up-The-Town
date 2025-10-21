extends Node2D

@onready var player: CharacterBody2D = $Player
var speed = 10

func _process(delta: float) -> void:
	if player:
		var direction = (player.position - position).normalized()
		position += direction * speed * delta
