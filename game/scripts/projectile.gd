extends Area2D
## Projectile kunai / shuriken (sprites library/weapon.png).

enum Kind { KUNAI, SHURIKEN }

@export var kind: Kind = Kind.KUNAI
@export var speed: float = 300.0
@export var damage: float = 8.0
@export var lifetime: float = 1.6
@export var stuck_lifetime: float = 1.1
@export var visual_scale: float = 1.5

var _dir: int = 1
var _owner: Node = null
var _spent: bool = false
var _stuck: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func setup(owner_fighter: Node, facing: int, projectile_kind: Kind = Kind.KUNAI) -> void:
	_owner = owner_fighter
	_dir = facing
	kind = projectile_kind
	if kind == Kind.SHURIKEN:
		speed = 340.0
		damage = 7.0


func _ready() -> void:
	add_to_group("kunai_hit")
	scale = Vector2(visual_scale, visual_scale)
	if kind == Kind.KUNAI:
		sprite.sprite_frames = WeaponAtlas.make_frames(WeaponAtlas.KUNAI_FLY, WeaponAtlas.KUNAI_STUCK)
	else:
		sprite.sprite_frames = WeaponAtlas.make_frames(WeaponAtlas.SHURIKEN_FLY, WeaponAtlas.SHURIKEN_STUCK)
	sprite.flip_h = _dir < 0
	sprite.play("fly")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	get_tree().create_timer(lifetime).timeout.connect(_on_lifetime_timeout)


func _physics_process(delta: float) -> void:
	if _stuck:
		return
	position.x += speed * _dir * delta
	if kind == Kind.SHURIKEN:
		sprite.rotation += delta * 14.0 * _dir


func _on_lifetime_timeout() -> void:
	if not _stuck:
		queue_free()


func _stick() -> void:
	if _stuck:
		return
	_stuck = true
	_spent = true
	sprite.rotation = 0.0
	sprite.play("stuck")
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
		fighter.take_hit(damage, Vector2(_dir * 90.0, -40.0), _dir)
		queue_free()
