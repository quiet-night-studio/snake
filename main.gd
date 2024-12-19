extends Node2D

const GRID_SIZE: int = 8
const DROP_WEIGHTS = {"FRUIT": 0.6, "OTHER": 0.4}

const Scenes = {
	SNAKE = preload("res://scenes/snake/snake.tscn"),
	DROPS =
	{
		BLOCK = preload("res://scenes/drops/block.tscn"),
		GHOST = preload("res://scenes/drops/ghost.tscn"),
		FRUIT = preload("res://scenes/drops/fruit.tscn"),
		REVERSE = preload("res://scenes/drops/reverse.tscn"),
		SPEED_SLOW = preload("res://scenes/drops/speedslow.tscn")
	}
}

const number_textures = {
	0: preload("res://assets/default/tiles/tile_0135.png"),
	1: preload("res://assets/default/tiles/tile_0136.png"),
	2: preload("res://assets/default/tiles/tile_0137.png"),
	3: preload("res://assets/default/tiles/tile_0138.png"),
	4: preload("res://assets/default/tiles/tile_0139.png"),
	5: preload("res://assets/default/tiles/tile_0140.png"),
	6: preload("res://assets/default/tiles/tile_0141.png"),
	7: preload("res://assets/default/tiles/tile_0142.png"),
	8: preload("res://assets/default/tiles/tile_0143.png"),
	9: preload("res://assets/default/tiles/tile_0144.png")
}

enum GameState { MENU, PLAYING, GAME_OVER }

@onready var drops_timer: Timer = $DropsTimer
@onready var tilemap: TileMapLayer = $WallsLayer
@onready var points_label: Label = %PointsLabel
@onready var death_panel_container: PanelContainer = %DeathPanelContainer
@onready var start_button: Button = %StartButton
@onready var menu_panel_container: PanelContainer = %MenuPanelContainer
@onready var counter_panel_container: PanelContainer = %CounterPanelContainer
@onready var score_label: Label = %ScoreLabel
@onready var tens: Sprite2D = %Tens
@onready var units: Sprite2D = %Units
@onready var try_again_button: Button = %TryAgainButton

var current_state: GameState = GameState.MENU
var total_points: int = 0
var drops_list: Array[PackedScene]


func _ready() -> void:
	_setup_drops_list()
	_setup_connections()
	_initialize_game()


func _setup_drops_list() -> void:
	drops_list = [
		Scenes.DROPS.REVERSE,
		Scenes.DROPS.GHOST,
		Scenes.DROPS.BLOCK,
		Scenes.DROPS.SPEED_SLOW,
		Scenes.DROPS.FRUIT
	]


func _setup_connections() -> void:
	Signals.points_updated.connect(_on_points_updated)
	Signals.player_died.connect(_end_game)
	drops_timer.timeout.connect(_spawn_random_drop)
	start_button.pressed.connect(_start_game)
	try_again_button.pressed.connect(_start_game)


func _initialize_game() -> void:
	current_state = GameState.MENU
	total_points = 0
	_update_ui_visibility()


func _update_ui_visibility() -> void:
	menu_panel_container.visible = current_state == GameState.MENU
	counter_panel_container.visible = current_state == GameState.PLAYING
	death_panel_container.visible = current_state == GameState.GAME_OVER


func clear_stage() -> void:
	for child in $Drops.get_children():
		child.queue_free()

	for child in $SnakePieces.get_children():
		child.queue_free()

	tens.texture = number_textures[0]
	units.texture = number_textures[0]


func _start_game() -> void:
	current_state = GameState.PLAYING
	total_points = 0
	_spawn_snake()
	drops_timer.start()
	_update_ui_visibility()


func _end_game() -> void:
	current_state = GameState.GAME_OVER
	drops_timer.stop()
	_update_ui_visibility()
	_update_score_display()
	clear_stage()


func _spawn_snake() -> void:
	var snake: Node = Scenes.SNAKE.instantiate()
	snake.pieces_container = $SnakePieces
	snake.position = Vector2(200, 208)
	add_child(snake)


func _on_points_updated(points: int) -> void:
	total_points += points
	var t = total_points / 10
	var u = total_points % 10

	tens.texture = number_textures[t]
	units.texture = number_textures[u]


func _update_score_display() -> void:
	var points_suffix = "point" + ("s" if total_points != 1 else "")
	score_label.text = "You scored %d %s!" % [total_points, points_suffix]


func _spawn_random_drop() -> void:
	var drop_scene: PackedScene
	if randf() <= DROP_WEIGHTS.FRUIT:
		drop_scene = Scenes.DROPS.FRUIT
	else:
		drop_scene = drops_list.pick_random()

	_spawn_drop(drop_scene)


func _spawn_drop(drop_scene: PackedScene) -> void:
	var drop = drop_scene.instantiate()
	var valid_position = _get_valid_spawn_position()
	drop.position = valid_position
	$Drops.add_child(drop)


# Everything below this line is AI generated code
# with some manual adjustments.
func _get_valid_spawn_position() -> Vector2:
	var pos = _get_random_position()
	var max_attempts := 100
	var attempts := 0

	while not _is_position_valid(pos) and attempts < max_attempts:
		pos = _get_random_position()
		attempts += 1

	if attempts >= max_attempts:
		push_warning("Could not find valid spawn position after %d attempts" % max_attempts)

	return pos


func _get_random_position() -> Vector2:
	var used_rect := tilemap.get_used_rect()
	var random_x = randi_range(used_rect.position.x, used_rect.end.x - 10)
	var random_y = randi_range(used_rect.position.y, used_rect.end.y - 10)
	var world_position = tilemap.map_to_local(Vector2i(random_x, random_y))
	return world_position.snapped(Vector2(GRID_SIZE, GRID_SIZE))


func _is_position_valid(pos: Vector2) -> bool:
	var tile_pos = tilemap.local_to_map(pos)

	if _is_position_out_of_bounds(tile_pos):
		return false

	if _has_obstacle_at_position(tile_pos):
		return false

	if _has_drop_at_position(pos):
		return false

	return true


func _is_position_out_of_bounds(tile_pos: Vector2i) -> bool:
	var used_rect = tilemap.get_used_rect()
	return not used_rect.has_point(tile_pos)


func _has_obstacle_at_position(tile_pos: Vector2i) -> bool:
	var tile_data = tilemap.get_cell_tile_data(tile_pos)
	return tile_data != null


func _has_drop_at_position(pos: Vector2) -> bool:
	for child in get_children():
		if child.has_method("is_drop") and child.position == pos:
			return true
	return false
