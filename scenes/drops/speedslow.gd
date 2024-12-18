extends Area2D


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(_area: Node2D):
	Signals.speedslow_eaten.emit()
	queue_free()
