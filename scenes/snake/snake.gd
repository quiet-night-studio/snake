extends CharacterBody2D

const SPEED_STATES = {"NORMAL": 0.2, "FAST": 0.1, "SLOW": 0.4}
const SPEED_BOOST_CHANCE: float = 0.5

enum Direction { UP, DOWN, LEFT, RIGHT }

@onready var collision_area: Area2D = $CollisionArea
@onready var drop_area: Area2D = $DropArea
@onready var ghost_timer: Timer = %GhostTimer
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var reverse_timer: Timer = %ReverseTimer
@onready var speed_slow_timer: Timer = %SpeedSlowTimer

var snake_body: PackedScene = preload("res://scenes/snake/snake_body.tscn")

var current_direction := Direction.RIGHT
var move_timer: float = 1.0
var move_delay: float = 0.2
var grid_size: int = 8
var move_vector: Vector2 = Vector2.ZERO
var reverse_active: bool = false
var current_speed_state: String = "NORMAL"
var pieces: Array
var position_history: Array[Vector2]
var pieces_container: Node


func _ready() -> void:
	Signals.food_eaten.connect(_on_food_eaten)
	Signals.ghost_eaten.connect(_on_ghost_eaten)
	Signals.player_died.connect(_on_player_died)
	Signals.reverse_eaten.connect(_on_reverse_eaten)
	Signals.speedslow_eaten.connect(_on_speedslow_eaten)

	collision_area.area_entered.connect(_on_collision_area_entered)
	collision_area.body_entered.connect(_on_collision_body_entered)

	ghost_timer.timeout.connect(_ghost_timer_timeout)
	reverse_timer.timeout.connect(_on_reverse_timer_timeout)
	speed_slow_timer.timeout.connect(_on_speed_slow_timer_timeout)

	position = position.snapped(Vector2(grid_size, grid_size))
	position_history.push_front(position)


func _on_speed_slow_timer_timeout() -> void:
	current_speed_state = "NORMAL"
	move_delay = SPEED_STATES.NORMAL


func _on_speedslow_eaten() -> void:
	current_speed_state = "FAST" if randf() < SPEED_BOOST_CHANCE else "SLOW"
	move_delay = SPEED_STATES[current_speed_state]
	speed_slow_timer.start()
	Signals.points_updated.emit(5)


func _on_reverse_timer_timeout() -> void:
	sprite_2d.modulate = Color(1, 1, 1, 1)
	reverse_active = false


func _on_reverse_eaten() -> void:
	sprite_2d.modulate = Color(1, 0, 0, 1)
	reverse_timer.start()
	reverse_active = true
	Signals.points_updated.emit(10)


func _ghost_timer_timeout() -> void:
	collision_area.collision_layer = 21
	collision_area.collision_mask = 21
	sprite_2d.modulate = Color(1, 1, 1, 1)


func _on_ghost_eaten() -> void:
	collision_area.collision_layer = 16
	collision_area.collision_mask = 16
	ghost_timer.start()
	sprite_2d.modulate = Color(1, 1, 1, 0.5)
	Signals.points_updated.emit(-1)


func _on_player_died() -> void:
	position_history.clear()
	pieces.clear()
	queue_free()


# This body detection is required to detect the collision with the walls.
func _on_collision_body_entered(_body: Node2D) -> void:
	Signals.player_died.emit()


func _on_collision_area_entered(_area: Area2D) -> void:
	Signals.player_died.emit()


func _get_inverted_directions() -> void:
	if Input.is_action_just_pressed("ui_up") and current_direction != Direction.UP:
		current_direction = Direction.DOWN
	elif Input.is_action_just_pressed("ui_down") and current_direction != Direction.DOWN:
		current_direction = Direction.UP
	elif Input.is_action_just_pressed("ui_left") and current_direction != Direction.LEFT:
		current_direction = Direction.RIGHT
	elif Input.is_action_just_pressed("ui_right") and current_direction != Direction.RIGHT:
		current_direction = Direction.LEFT


func _get_normal_directions() -> void:
	if Input.is_action_just_pressed("ui_up") and current_direction != Direction.DOWN:
		current_direction = Direction.UP
	elif Input.is_action_just_pressed("ui_down") and current_direction != Direction.UP:
		current_direction = Direction.DOWN
	elif Input.is_action_just_pressed("ui_left") and current_direction != Direction.RIGHT:
		current_direction = Direction.LEFT
	elif Input.is_action_just_pressed("ui_right") and current_direction != Direction.LEFT:
		current_direction = Direction.RIGHT


func _physics_process(delta: float) -> void:
	if reverse_active:
		_get_inverted_directions()
	else:
		_get_normal_directions()

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

		position += move_vector * grid_size
		position = position.snapped(Vector2(grid_size, grid_size))
		position_history.push_front(position)

		# Since the history array will always grow, we need to remove the last element
		# to keep it with the same size as the pieces array.
		if position_history.size() > pieces.size() + 1:
			position_history.pop_back()

		for i in range(pieces.size()):
			var target_position = position_history[i + 1]
			pieces[i].position = target_position


func _on_food_eaten() -> void:
	var body_scene: Area2D = snake_body.instantiate()
	body_scene.position = _calculate_spawn_position()

	pieces_container.call_deferred("add_child", body_scene)
	pieces.append(body_scene)

	Signals.points_updated.emit(1)


func _calculate_spawn_position() -> Vector2:
	if pieces.is_empty():
		return position - (move_vector * 8)
	return pieces[-1].position
