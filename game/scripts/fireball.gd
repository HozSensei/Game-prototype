extends Area2D
## Boule de feu (spéciale type Katon).

@export var speed: float = 220.0
@export var damage: float = 34.0
@export var lifetime: float = 2.0

var _dir: int = 1
var _owner: Node = null
var _spent: bool = false


func setup(owner_fighter: Node, facing: int) -> void:
	_owner = owner_fighter
	_dir = facing
	scale.x = absf(scale.x) * facing


func _ready() -> void:
	add_to_group("fireball_hit")
	add_to_group("kunai_hit") # réutilise le filtre projectile côté hurtbox
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	position.x += speed * _dir * delta
	rotation += delta * 8.0 * _dir


func _on_body_entered(body: Node) -> void:
	if body == _owner:
		return
	# Mur / sol
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
		fighter.take_hit(damage, Vector2(_dir * 160.0, -80.0), _dir)
		queue_free()
