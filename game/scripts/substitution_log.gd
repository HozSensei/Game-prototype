extends Node2D
## Bout de bois laissé par la substitution.


func _ready() -> void:
	var tween := create_tween()
	tween.tween_interval(0.85)
	tween.tween_property(self, "modulate:a", 0.0, 0.35)
	tween.tween_callback(queue_free)
