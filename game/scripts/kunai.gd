extends Area2D
## Kunai / shuriken projectile.

@export var speed: float = 280.0
@export var damage: float = 8.0
@export var lifetime: float = 1.4

var _dir: int = 1
var _owner: Node = null
var _spent: bool = false


func setup(owner_fighter: Node, facing: int) -> void:
	_owner = owner_fighter
	_dir = facing
	scale.x = facing


func _ready() -> void:
	add_to_group("kunai_hit")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	var timer := get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	position.x += speed * _dir * delta


func _on_body_entered(body: Node) -> void:
	if body == _owner:
		return
	if body.is_in_group("world_solid"):
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
		fighter.take_hit(damage, Vector2(_dir * 90.0, -40.0), _dir)
		queue_free()
