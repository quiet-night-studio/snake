extends CharacterBody2D

enum Direction { UP, DOWN, LEFT, RIGHT }
var current_direction := Direction.RIGHT
var move_timer := 0.0
var move_delay := 0.2  # Adjust this to control snake speed
var grid_size := 8  # Size of each movement step

func _ready() -> void:
	position = position.snapped(Vector2(grid_size, grid_size))

func _physics_process(delta: float) -> void:
	# This code adds constraints for some cases.
	# Eg.: The snake cannot go down when it's goind up.
	if Input.is_action_just_pressed("ui_up") and current_direction != Direction.DOWN:
		current_direction = Direction.UP
	elif Input.is_action_just_pressed("ui_down") and current_direction != Direction.UP:
		current_direction = Direction.DOWN
	elif Input.is_action_just_pressed("ui_left") and current_direction != Direction.RIGHT:
		current_direction = Direction.LEFT
	elif Input.is_action_just_pressed("ui_right") and current_direction != Direction.LEFT:
		current_direction = Direction.RIGHT

	move_timer += delta
	if move_timer >= move_delay:
		move_timer = 0.0

		var move_vector := Vector2.ZERO
		match current_direction:
			Direction.UP:
				move_vector = Vector2.UP
			Direction.DOWN:
				move_vector = Vector2.DOWN
			Direction.LEFT:
				move_vector = Vector2.LEFT
			Direction.RIGHT:
				move_vector = Vector2.RIGHT

		velocity = move_vector * (grid_size / delta)
		move_and_slide()
		position = position.snapped(Vector2(grid_size, grid_size))
