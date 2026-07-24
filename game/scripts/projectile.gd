extends Area2D
## Projectile kunai / shuriken — aim + gravité, puis munition au sol.

enum Kind { KUNAI, SHURIKEN }

@export var kind: Kind = Kind.KUNAI
@export var throw_speed: float = 1760.0
@export var fall_gravity: float = 520.0
@export var damage: float = 8.0
@export var lifetime: float = 3.5
@export var stuck_lifetime: float = 0.45
@export var visual_scale: float = 0.7

var velocity: Vector2 = Vector2.RIGHT * 1760.0
var _owner: Node = null
var _spent: bool = false
var _stuck: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var _pickup_scene: PackedScene


func setup(owner_fighter: Node, aim_dir: Vector2, projectile_kind: Kind = Kind.KUNAI) -> void:
	_owner = owner_fighter
	kind = projectile_kind
	var dir := aim_dir
	if dir.length_squared() < 0.0001:
		dir = Vector2.RIGHT
	dir = dir.normalized()
	if kind == Kind.SHURIKEN:
		throw_speed = 1900.0
		fall_gravity = 500.0
		damage = 7.0
	else:
		throw_speed = 1760.0
		fall_gravity = 560.0
		damage = 8.0
	velocity = dir * throw_speed


func _ready() -> void:
	_pickup_scene = preload("res://scenes/ammo_pickup.tscn")
	add_to_group("kunai_hit")
	z_as_relative = false
	z_index = 2
	scale = Vector2(visual_scale, visual_scale)
	if kind == Kind.KUNAI:
		sprite.sprite_frames = WeaponAtlas.make_frames(WeaponAtlas.KUNAI_FLY, WeaponAtlas.KUNAI_STUCK)
	else:
		sprite.sprite_frames = WeaponAtlas.make_frames(WeaponAtlas.SHURIKEN_FLY, WeaponAtlas.SHURIKEN_STUCK)
	sprite.play("fly")
	_orient_to_velocity()
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	get_tree().create_timer(lifetime).timeout.connect(_on_lifetime_timeout)


func _physics_process(delta: float) -> void:
	if _stuck:
		return
	velocity.y += fall_gravity * delta
	position += velocity * delta
	_orient_to_velocity(delta)


func _orient_to_velocity(delta: float = 0.016) -> void:
	if velocity.length_squared() < 1.0:
		return
	if kind == Kind.KUNAI:
		sprite.rotation = velocity.angle()
	else:
		sprite.rotation += delta * 16.0 * signf(velocity.x if absf(velocity.x) > 0.01 else 1.0)


func _stuck_rotation_for_impact() -> float:
	var impact := velocity.angle() if velocity.length_squared() > 1.0 else 0.0
	if kind == Kind.KUNAI:
		# Pointe vers la droite dans l'atlas → aligne sur l'impact.
		return impact
	# Shuriken en X : une pointe suit la direction d'impact.
	return impact - PI * 0.25


func _on_lifetime_timeout() -> void:
	if not _stuck:
		_drop_pickup()
		queue_free()


func _stick(on_wall: Node = null) -> void:
	if _stuck:
		return
	_stuck = true
	_spent = true
	sprite.play("stuck")
	sprite.rotation = _stuck_rotation_for_impact()
	# Enfonce la pointe et dessine derrière les solids pour masquer la partie plantée.
	var impact_dir := velocity.normalized() if velocity.length_squared() > 1.0 else Vector2.RIGHT
	position += impact_dir * 8.0
	z_as_relative = false
	z_index = -1
	set_deferred("monitoring", false)
	if on_wall and on_wall.has_method("take_damage"):
		on_wall.take_damage(1)
	var tween := create_tween()
	tween.tween_interval(stuck_lifetime)
	tween.tween_callback(_finish_stick)


func _finish_stick() -> void:
	_drop_pickup()
	queue_free()


func _drop_pickup() -> void:
	var parent := get_parent()
	if parent == null or _pickup_scene == null:
		return
	var pickup := _pickup_scene.instantiate()
	parent.add_child(pickup)
	pickup.setup(int(kind), global_position, sprite.rotation)


func _on_body_entered(body: Node) -> void:
	if body == _owner or _stuck:
		return
	if body.is_in_group("chakra_wall") or body is StaticBody2D:
		_stick(body)


func _on_area_entered(area: Area2D) -> void:
	if _spent or _stuck:
		return
	if not area.is_in_group("fighter_hurtbox"):
		return
	var fighter := area.get_parent()
	if fighter == null or fighter == _owner:
		return
	if fighter.has_method("take_hit"):
		_spent = true
		var knock_dir := velocity.normalized() if velocity.length_squared() > 1.0 else Vector2.RIGHT
		fighter.take_hit(damage, knock_dir * 100.0 + Vector2(0, -40.0), int(signf(knock_dir.x)), 0.22)
		_drop_pickup()
		queue_free()
