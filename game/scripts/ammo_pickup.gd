extends Area2D
## Munition ramassable (kunai / shuriken au sol).

@export var kind: int = 0 # 0 kunai, 1 shuriken

var _stuck_rotation: float = 0.0


func setup(projectile_kind: int, global_pos: Vector2, stuck_rotation: float = 0.0) -> void:
	kind = projectile_kind
	global_position = global_pos
	_stuck_rotation = stuck_rotation
	if is_inside_tree():
		_apply_visual()


func _ready() -> void:
	add_to_group("ammo_pickup")
	body_entered.connect(_on_body_entered)
	_apply_visual()


func _apply_visual() -> void:
	var sprite: AnimatedSprite2D = $AnimatedSprite2D
	if kind == 0:
		sprite.sprite_frames = WeaponAtlas.make_frames(WeaponAtlas.KUNAI_FLY, WeaponAtlas.KUNAI_STUCK)
		sprite.play("stuck")
		sprite.rotation = _stuck_rotation
	else:
		sprite.sprite_frames = WeaponAtlas.make_frames(WeaponAtlas.SHURIKEN_FLY, WeaponAtlas.SHURIKEN_STUCK)
		sprite.play("stuck")
		sprite.rotation = 0.0
	scale = Vector2(1.4, 1.4)


func _on_body_entered(body: Node) -> void:
	if body.has_method("pickup_ammo"):
		if body.pickup_ammo(kind):
			queue_free()
