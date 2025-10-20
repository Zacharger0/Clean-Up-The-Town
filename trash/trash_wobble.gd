extends Node2D

var time = 0
var freq = 3.0
var amplitude = 1.5

func _process(delta: float) -> void:
	wobble(delta)

func wobble(delta):
	#position.y = pingpong(time * freq, amplitude)
	position.y = sin(time * freq) * amplitude
	time += delta
