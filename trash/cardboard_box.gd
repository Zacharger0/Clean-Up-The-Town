extends Area2D

signal trash_collected

var player: CharacterBody2D

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))  # ADDED

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D:  
		trash_collected.emit()
		queue_free()
