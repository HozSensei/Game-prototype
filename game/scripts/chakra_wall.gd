extends StaticBody2D
## Mur de chakra destructible (technique défensive).

@export var max_hp: int = 3
@export var lifetime: float = 10.0

var hp: int = 3
var _owner: Node = null


func setup(owner_fighter: Node, facing: int) -> void:
	_owner = owner_fighter
	hp = max_hp
	scale.x = absf(scale.x) * (1 if facing >= 0 else -1)


func _ready() -> void:
	add_to_group("chakra_wall")
	add_to_group("world_solid")
	collision_layer = 1
	collision_mask = 0
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
	_update_visual()


func take_damage(amount: int = 1) -> void:
	hp -= amount
	_update_visual()
	if hp <= 0:
		queue_free()


func _update_visual() -> void:
	var body := get_node_or_null("Body") as Polygon2D
	if body:
		var a := 0.35 + 0.2 * float(maxi(hp, 0)) / float(max_hp)
		body.color = Color(0.35, 0.75, 1.0, a)
