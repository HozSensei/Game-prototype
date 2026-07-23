extends Node2D
## Arène locale 1v1 — solo KBM ou 2 manettes.

@onready var p1: CharacterBody2D = $Fighters/Player1
@onready var p2: CharacterBody2D = $Fighters/Player2
@onready var spawn_p1: Marker2D = $Spawns/P1
@onready var spawn_p2: Marker2D = $Spawns/P2
@onready var result_label: Label = $HUD/ResultLabel

var _round_over: bool = false


func _ready() -> void:
	GameBus.fighter_defeated.connect(_on_fighter_defeated)
	InputSetup.pads_changed.connect(_on_pads_changed)
	result_label.visible = false
	_start_round()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart_match"):
		_start_round()


func _on_pads_changed(_a: int, _b: int) -> void:
	p1.controllable = InputSetup.is_player_active(1)
	p2.controllable = InputSetup.is_player_active(2)


func _start_round() -> void:
	_round_over = false
	GameBus.match_active = true
	result_label.visible = false
	# Nettoie projectiles / murs / pickups de la manche précédente
	for n in get_tree().get_nodes_in_group("kunai_hit"):
		if is_instance_valid(n):
			n.queue_free()
	for n in get_tree().get_nodes_in_group("chakra_wall"):
		if is_instance_valid(n):
			n.queue_free()
	for n in get_tree().get_nodes_in_group("ammo_pickup"):
		if is_instance_valid(n):
			n.queue_free()
	p1.reset_round(spawn_p1.global_position)
	p2.reset_round(spawn_p2.global_position)
	p1.facing = 1
	p2.facing = -1
	p1._apply_facing()
	p2._apply_facing()
	_on_pads_changed(-1, -1)


func _on_fighter_defeated(fighter: Node) -> void:
	if _round_over:
		return
	_round_over = true
	GameBus.match_active = false
	var winner_id := 2 if fighter.player_id == 1 else 1
	result_label.text = "Joueur %d gagne !\n[R] / Start pour rejouer" % winner_id
	result_label.visible = true
	GameBus.match_over.emit(winner_id)
