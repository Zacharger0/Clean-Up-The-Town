extends Area2D

signal trash_collected

var time = 1
var freq = 10
var amplitude = 1

var start_y: float
var phase_offset 

var player: CharacterBody2D

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))
#	start_y = position.y 
#	phase_offset = randf() * TAU
	
func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D:  
		trash_collected.emit()
		queue_free()

#func _physics_process(delta: float) -> void:
#	wobble(delta)
	
#func wobble(delta):
#	position.y = start_y + sin(time * freq + phase_offset) * amplitude
#	time += delta
	
