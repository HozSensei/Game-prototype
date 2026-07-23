extends CanvasLayer
## HUD vie / chakra / mudras.

@onready var p1_hp: ProgressBar = $Root/P1/HP
@onready var p1_chakra: ProgressBar = $Root/P1/Chakra
@onready var p1_mudra: Label = $Root/P1/Mudra
@onready var p2_hp: ProgressBar = $Root/P2/HP
@onready var p2_chakra: ProgressBar = $Root/P2/Chakra
@onready var p2_mudra: Label = $Root/P2/Mudra
@onready var help: Label = $Root/Help


func _ready() -> void:
	GameBus.fighter_stats_changed.connect(_on_stats)
	GameBus.mudra_updated.connect(_on_mudra)
	GameBus.special_ready.connect(_on_special_ready)
	_style_bar(p1_hp, Color(0.75, 0.18, 0.2), Color(0.2, 0.22, 0.26))
	_style_bar(p2_hp, Color(0.75, 0.18, 0.2), Color(0.2, 0.22, 0.26))
	_style_bar(p1_chakra, Color(0.2, 0.55, 0.95), Color(0.2, 0.22, 0.26))
	_style_bar(p2_chakra, Color(0.2, 0.55, 0.95), Color(0.2, 0.22, 0.26))
	help.text = "P1: WASD+Espace | J coup | K katana | L kunai | Shift roll | I sub | U spéciale (↑↓←→)\nP2: Flèches+Ctrl | Z/X | C | Num0 | V | B  —  Manette: stick/D-pad, A saut, X/Y mêlée, B kunai, RB roll, LB sub, R3 spéciale | R restart"


func _style_bar(bar: ProgressBar, fill: Color, bg: Color) -> void:
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = fill
	fill_style.set_corner_radius_all(2)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = bg
	bg_style.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("fill", fill_style)
	bar.add_theme_stylebox_override("background", bg_style)
	bar.show_percentage = false


func _on_stats(fighter: Node) -> void:
	var hp_bar: ProgressBar
	var ck_bar: ProgressBar
	if fighter.player_id == 1:
		hp_bar = p1_hp
		ck_bar = p1_chakra
	else:
		hp_bar = p2_hp
		ck_bar = p2_chakra
	hp_bar.max_value = fighter.max_health
	hp_bar.value = fighter.health
	ck_bar.max_value = fighter.max_chakra
	ck_bar.value = fighter.chakra


func _on_mudra(player_id: int, sequence: Array) -> void:
	var label := p1_mudra if player_id == 1 else p2_mudra
	var symbols: PackedStringArray = []
	for d in sequence:
		match str(d):
			"up": symbols.append("↑")
			"down": symbols.append("↓")
			"left": symbols.append("←")
			"right": symbols.append("→")
	label.text = " ".join(symbols)


func _on_special_ready(player_id: int, ready: bool) -> void:
	var label := p1_mudra if player_id == 1 else p2_mudra
	label.modulate = Color(1.0, 0.85, 0.2) if ready else Color(1, 1, 1)
	if ready and not label.text.ends_with(" READY"):
		label.text = "%s  READY" % label.text
