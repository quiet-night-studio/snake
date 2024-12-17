extends CharacterBody2D

var snake_body: PackedScene = preload("res://scenes/snake/snake_body.tscn")

@onready var collision_area: Area2D = $CollisionArea
@onready var drop_area: Area2D = $DropArea

enum Direction { UP, DOWN, LEFT, RIGHT }

var current_direction := Direction.RIGHT
var move_timer := 0.0
var move_delay := 0.2  # Adjust this to control snake speed
var grid_size := 8  # Size of each movement step
var move_vector := Vector2.ZERO

var pieces: Array
var position_history: Array[Vector2]


func _ready() -> void:
	position = position.snapped(Vector2(grid_size, grid_size))
	Signals.food_eaten.connect(_on_food_eaten)
	position_history.push_front(position)
	collision_area.area_entered.connect(_on_collision_area_entered)
	drop_area.area_entered.connect(_on_drop_area_entered)


func _on_drop_area_entered(area: Area2D) -> void:
	print(area.name)
	print("YOU PICKED UP SOMETHING")


func _on_collision_area_entered(area: Area2D) -> void:
	print(area.name)
	print("YOU DIED")


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
		position_history.push_front(position)

		for i in range(pieces.size()):
			var target_position = position_history[i+1]
			pieces[i].position = target_position


func _on_food_eaten() -> void:
	var body_scene: Area2D = snake_body.instantiate()

	if pieces.is_empty():
		body_scene.position = position - (move_vector * 8)
	else:
		body_scene.position = pieces[-1].position

	owner.call_deferred("add_child",body_scene)
	pieces.append(body_scene)
