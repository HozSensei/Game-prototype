extends Area2D
## Boule de feu (spéciale type Katon) — aimable + légère gravité.

@export var speed: float = 260.0
@export var fall_gravity: float = 280.0
@export var damage: float = 34.0
@export var lifetime: float = 2.2

var velocity: Vector2 = Vector2.RIGHT * 260.0
var _owner: Node = null
var _spent: bool = false


func setup(owner_fighter: Node, facing: int) -> void:
	setup_aimed(owner_fighter, Vector2(facing, 0))


func setup_aimed(owner_fighter: Node, aim_dir: Vector2) -> void:
	_owner = owner_fighter
	var dir := aim_dir
	if dir.length_squared() < 0.0001:
		dir = Vector2.RIGHT
	velocity = dir.normalized() * speed


func _ready() -> void:
	add_to_group("fireball_hit")
	add_to_group("kunai_hit")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	velocity.y += fall_gravity * delta
	position += velocity * delta
	rotation = velocity.angle()


func _on_body_entered(body: Node) -> void:
	if body == _owner:
		return
	if body.has_method("take_damage"):
		body.take_damage(2)
	if body is StaticBody2D:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if _spent:
		return
	if not area.is_in_group("fighter_hurtbox"):
		return
	var fighter := area.get_parent()
	if fighter == null or fighter == _owner:
		return
	if fighter.has_method("take_hit"):
		_spent = true
		var knock := velocity.normalized() if velocity.length_squared() > 1.0 else Vector2.RIGHT
		fighter.take_hit(damage, knock * 160.0 + Vector2(0, -80.0), int(signf(knock.x)))
		queue_free()
