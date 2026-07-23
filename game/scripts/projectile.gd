extends Area2D
## Projectile kunai / shuriken — tir directionnel + gravité (arc).

enum Kind { KUNAI, SHURIKEN }

@export var kind: Kind = Kind.KUNAI
@export var throw_speed: float = 320.0
@export var fall_gravity: float = 520.0
@export var damage: float = 8.0
@export var lifetime: float = 2.2
@export var stuck_lifetime: float = 1.1
@export var visual_scale: float = 1.5

var velocity: Vector2 = Vector2.RIGHT * 320.0
var _owner: Node = null
var _spent: bool = false
var _stuck: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func setup(owner_fighter: Node, aim_dir: Vector2, projectile_kind: Kind = Kind.KUNAI) -> void:
	_owner = owner_fighter
	kind = projectile_kind
	var dir := aim_dir
	if dir.length_squared() < 0.0001:
		dir = Vector2.RIGHT
	dir = dir.normalized()
	if kind == Kind.SHURIKEN:
		throw_speed = 360.0
		fall_gravity = 480.0
		damage = 7.0
	else:
		throw_speed = 320.0
		fall_gravity = 540.0
		damage = 8.0
	velocity = dir * throw_speed


func _ready() -> void:
	add_to_group("kunai_hit")
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
		sprite.flip_v = false
	else:
		sprite.rotation += delta * 16.0 * signf(velocity.x if absf(velocity.x) > 0.01 else 1.0)


func _on_lifetime_timeout() -> void:
	if not _stuck:
		queue_free()


func _stick() -> void:
	if _stuck:
		return
	_stuck = true
	_spent = true
	sprite.play("stuck")
	# Oriente le sprite planté selon l'impact.
	if kind == Kind.KUNAI:
		sprite.rotation = velocity.angle()
	else:
		sprite.rotation = 0.0
	set_deferred("monitoring", false)
	var tween := create_tween()
	tween.tween_interval(stuck_lifetime)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)


func _on_body_entered(body: Node) -> void:
	if body == _owner or _stuck:
		return
	if body is StaticBody2D:
		_stick()


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
		fighter.take_hit(damage, knock_dir * 100.0 + Vector2(0, -40.0), int(signf(knock_dir.x)))
		queue_free()
