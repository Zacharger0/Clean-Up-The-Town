extends CharacterBody2D

@onready var player_sprite: Sprite2D = $Sprite2D

var speed = 150
var time = 0
var freq = 25

var input_direction
var facing_direction = Vector2(1, 0)

func get_input(delta):
	input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = input_direction * speed

	if velocity != Vector2.ZERO:
		wobble(delta)
	else:
		rotation = 0

	if input_direction != Vector2.ZERO:
		facing_direction = input_direction.normalized()

	if facing_direction.x > 0:
		player_sprite.flip_h = false
	elif facing_direction.x < 0:
		player_sprite.flip_h = true

func _physics_process(delta: float) -> void:
	get_input(delta)
	move_and_slide()

func wobble(delta):
	rotation = sin(time * freq) * 0.1
	time += delta
