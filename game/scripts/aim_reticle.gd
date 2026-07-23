extends Node2D
## Flèche de visée + aperçu d'arc balistique.

@onready var arrow: Polygon2D = $Arrow
@onready var arc: Line2D = $Arc

var aim_dir: Vector2 = Vector2.RIGHT


func _ready() -> void:
	arc.width = 1.5
	arc.default_color = Color(1, 1, 1, 0.4)
	arrow.color = Color(1.0, 0.92, 0.45, 0.95)


func set_aim(dir: Vector2, throw_speed: float = 320.0, projectile_gravity: float = 520.0) -> void:
	if dir.length_squared() < 0.0001:
		dir = Vector2.RIGHT
	aim_dir = dir.normalized()
	arrow.rotation = aim_dir.angle()
	_rebuild_arc(throw_speed, projectile_gravity)


func _rebuild_arc(throw_speed: float, projectile_gravity: float) -> void:
	var pts := PackedVector2Array()
	var pos := Vector2.ZERO
	var vel := aim_dir * throw_speed
	var dt := 0.04
	for i in 20:
		pts.append(pos)
		vel.y += projectile_gravity * dt
		pos += vel * dt
		if pos.length() > 240.0 or pos.y > 160.0:
			break
	arc.points = pts
