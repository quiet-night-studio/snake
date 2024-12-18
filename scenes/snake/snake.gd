extends CharacterBody2D

var snake_body: PackedScene = preload("res://scenes/snake/snake_body.tscn")

@onready var collision_area: Area2D = $CollisionArea
@onready var drop_area: Area2D = $DropArea
@onready var ghost_timer: Timer = %GhostTimer
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var reverse_timer: Timer = %ReverseTimer

enum Direction { UP, DOWN, LEFT, RIGHT }

var current_direction := Direction.RIGHT
var move_timer: float = 0.0
var move_delay: float = 0.2  # Adjust this to control snake speed
var grid_size: int = 8  # Size of each movement step
var move_vector: Vector2 = Vector2.ZERO
var reverse_active: bool = false

var pieces: Array
var position_history: Array[Vector2]


func _ready() -> void:
	Signals.food_eaten.connect(_on_food_eaten)
	Signals.ghost_eaten.connect(_on_ghost_eaten)
	Signals.player_died.connect(_on_player_died)
	Signals.reverse_eaten.connect(_on_reverse_eaten)

	collision_area.area_entered.connect(_on_collision_area_entered)
	drop_area.area_entered.connect(_on_drop_area_entered)

	ghost_timer.timeout.connect(_ghost_timer_timeout)
	reverse_timer.timeout.connect(_on_reverse_timer_timeout)

	position = position.snapped(Vector2(grid_size, grid_size))
	position_history.push_front(position)


func _on_reverse_timer_timeout() -> void:
	sprite_2d.modulate = Color(1, 1, 1, 1)
	reverse_active = false


func _on_reverse_eaten() -> void:
	sprite_2d.modulate = Color(1, 0, 0, 1)
	reverse_timer.start()
	reverse_active = true


func _ghost_timer_timeout() -> void:
	collision_area.monitoring = true
	sprite_2d.modulate = Color(1, 1, 1, 1)


func _on_ghost_eaten() -> void:
	collision_area.monitoring = false
	ghost_timer.start()
	sprite_2d.modulate = Color(1, 1, 1, 0.5)


func _on_player_died() -> void:
	queue_free()


# I could delete this method. The detection and signal emission is already done in the drop script.
func _on_drop_area_entered(area: Area2D) -> void:
	print("collected: ", area.name)


func _on_collision_area_entered(area: Area2D) -> void:
	print("area: ", area.name)
	Signals.player_died.emit()


func _physics_process(delta: float) -> void:
	# This code adds constraints for some cases.
	# Eg.: The snake cannot go down when it's goind up.
	if reverse_active:
		if Input.is_action_just_pressed("ui_up") and current_direction != Direction.UP:
			current_direction = Direction.DOWN
		elif Input.is_action_just_pressed("ui_down") and current_direction != Direction.DOWN:
			current_direction = Direction.UP
		elif Input.is_action_just_pressed("ui_left") and current_direction != Direction.LEFT:
			current_direction = Direction.RIGHT
		elif Input.is_action_just_pressed("ui_right") and current_direction != Direction.RIGHT:
			current_direction = Direction.LEFT
	else:
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
			var target_position = position_history[i + 1]
			pieces[i].position = target_position


func _on_food_eaten() -> void:
	var body_scene: Area2D = snake_body.instantiate()

	if pieces.is_empty():
		body_scene.position = position - (move_vector * 8)
	else:
		body_scene.position = pieces[-1].position

	owner.call_deferred("add_child", body_scene)
	pieces.append(body_scene)

	Signals.points_updated.emit()
