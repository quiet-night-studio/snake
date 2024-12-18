extends Node2D

var block: PackedScene = preload("res://scenes/drops/block.tscn")
var ghost: PackedScene = preload("res://scenes/drops/ghost.tscn")
var fruit: PackedScene = preload("res://scenes/drops/fruit.tscn")
var reverse: PackedScene = preload("res://scenes/drops/reverse.tscn")
var speed_slow: PackedScene = preload("res://scenes/drops/speedslow.tscn")

const GRID_SIZE: int = 8

@onready var timer: Timer = $Timer
@onready var tilemap: TileMapLayer = $TileMapLayer
@onready var points_label: Label = %PointsLabel
@onready var death_panel_container: PanelContainer = %DeathPanelContainer

# var drops_list: Array[PackedScene] = [block, ghost, fruit, reverse, speed_slow]
var drops_list: Array[PackedScene] = [speed_slow]


func _ready() -> void:
	timer.timeout.connect(_on_timer_timeout)
	Signals.points_updated.connect(_on_points_updated)
	Signals.player_died.connect(_on_player_died)

	death_panel_container.visible = false


func _on_player_died() -> void:
	timer.stop()
	death_panel_container.visible = true


func _on_points_updated() -> void:
	var current_points = int(points_label.text)
	current_points += 1
	points_label.text = str(current_points)


func _on_timer_timeout() -> void:
	spawn_drop(drops_list.pick_random())


func get_random_position() -> Vector2:
	# Get the used rect of the tilemap
	var used_rect := tilemap.get_used_rect()

	# Get random coordinates within the used rect
	var random_x = randi_range(used_rect.position.x, used_rect.end.x - 10)
	var random_y = randi_range(used_rect.position.y, used_rect.end.y - 10)

	# Convert tile coordinates to world position
	var world_position = tilemap.map_to_local(Vector2i(random_x, random_y))

	# Snap to grid
	return world_position.snapped(Vector2(GRID_SIZE, GRID_SIZE))


func spawn_drop(drop_scene: PackedScene) -> void:
	var drop = drop_scene.instantiate()

	# Get a valid position
	var valid_position = get_random_position()

	# Make sure the position is valid (not occupied by walls or other drops)
	while not is_position_valid(valid_position):
		valid_position = get_random_position()

	drop.position = valid_position
	add_child(drop)


func is_position_valid(pos: Vector2) -> bool:
	# Convert world position to tile coordinates
	var tile_pos = tilemap.local_to_map(pos)

	# Check if there's a wall or obstacle at this position
	var tile_data = tilemap.get_cell_tile_data(tile_pos)
	if tile_data:
		# Return false if this is a wall/obstacle tile
		return false

	# Check if there are any other drops at this position
	for child in get_children():
		if child.has_method("is_drop") and child.position == pos:
			return false

	return true
