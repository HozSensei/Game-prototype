extends Node2D
## Arène locale 1v1 — round / restart.

@onready var p1: CharacterBody2D = $Fighters/Player1
@onready var p2: CharacterBody2D = $Fighters/Player2
@onready var spawn_p1: Marker2D = $Spawns/P1
@onready var spawn_p2: Marker2D = $Spawns/P2
@onready var hud: CanvasLayer = $HUD
@onready var result_label: Label = $HUD/ResultLabel

var _round_over: bool = false


func _ready() -> void:
	GameBus.fighter_defeated.connect(_on_fighter_defeated)
	result_label.visible = false
	_start_round()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart_match"):
		_start_round()


func _start_round() -> void:
	_round_over = false
	GameBus.match_active = true
	result_label.visible = false
	p1.reset_round(spawn_p1.global_position)
	p2.reset_round(spawn_p2.global_position)
	p1.facing = 1
	p2.facing = -1
	p1._apply_facing()
	p2._apply_facing()


func _on_fighter_defeated(fighter: Node) -> void:
	if _round_over:
		return
	_round_over = true
	GameBus.match_active = false
	var winner_id := 2 if fighter.player_id == 1 else 1
	result_label.text = "Joueur %d gagne !\n[R] pour rejouer" % winner_id
	result_label.visible = true
	GameBus.match_over.emit(winner_id)
