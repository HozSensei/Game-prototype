extends Node2D
## Viseur discret : arc de cercle léger + petite flèche au centre.

@onready var arc: Line2D = $Arc
@onready var arrow: Polygon2D = $Arrow

var aim_dir: Vector2 = Vector2.RIGHT
const RADIUS := 26.0
const HALF_ANGLE := 0.55 # radians (~63° d'arc total)


func _ready() -> void:
	arc.width = 1.25
	arc.default_color = Color(1, 1, 1, 0.28)
	arc.joint_mode = Line2D.LINE_JOINT_ROUND
	arc.begin_cap_mode = Line2D.LINE_CAP_ROUND
	arc.end_cap_mode = Line2D.LINE_CAP_ROUND
	arrow.color = Color(1.0, 0.95, 0.75, 0.55)
	arrow.polygon = PackedVector2Array([Vector2(4, 0), Vector2(-3, -2.5), Vector2(-3, 2.5)])


func set_aim(dir: Vector2, _throw_speed: float = 320.0, _grav: float = 520.0) -> void:
	if dir.length_squared() < 0.0001:
		dir = Vector2.RIGHT
	aim_dir = dir.normalized()
	var ang := aim_dir.angle()
	_rebuild_arc(ang)
	arrow.position = aim_dir * RADIUS
	arrow.rotation = ang


func _rebuild_arc(center_angle: float) -> void:
	var pts := PackedVector2Array()
	var steps := 10
	var a0 := center_angle - HALF_ANGLE
	var a1 := center_angle + HALF_ANGLE
	for i in steps + 1:
		var t := float(i) / float(steps)
		var a := lerpf(a0, a1, t)
		pts.append(Vector2(cos(a), sin(a)) * RADIUS)
	arc.points = pts
