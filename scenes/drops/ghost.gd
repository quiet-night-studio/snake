extends Drop


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(_area: Area2D):
	Signals.ghost_eaten.emit()
	queue_free()
