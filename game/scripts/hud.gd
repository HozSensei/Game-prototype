extends CanvasLayer
## HUD vie / chakra / munitions / mode d'entrée.

@onready var p1_hp: ProgressBar = $Root/P1/HP
@onready var p1_chakra: ProgressBar = $Root/P1/Chakra
@onready var p1_mudra: Label = $Root/P1/Mudra
@onready var p1_title: Label = $Root/P1/Title
@onready var p2_hp: ProgressBar = $Root/P2/HP
@onready var p2_chakra: ProgressBar = $Root/P2/Chakra
@onready var p2_mudra: Label = $Root/P2/Mudra
@onready var p2_title: Label = $Root/P2/Title
@onready var help: Label = $Root/Help


func _ready() -> void:
	GameBus.fighter_stats_changed.connect(_on_stats)
	GameBus.mudra_updated.connect(_on_mudra)
	GameBus.special_ready.connect(_on_special_ready)
	InputSetup.pads_changed.connect(_on_pads_changed)
	InputSetup.mode_changed.connect(_on_mode_changed)
	_style_bar(p1_hp, Color(0.75, 0.18, 0.2), Color(0.2, 0.22, 0.26))
	_style_bar(p2_hp, Color(0.75, 0.18, 0.2), Color(0.2, 0.22, 0.26))
	_style_bar(p1_chakra, Color(0.2, 0.55, 0.95), Color(0.2, 0.22, 0.26))
	_style_bar(p2_chakra, Color(0.2, 0.55, 0.95), Color(0.2, 0.22, 0.26))
	_on_pads_changed(InputSetup.p1_device, InputSetup.p2_device)
	_on_mode_changed(InputSetup.mode_name, InputSetup.pad_count)


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


func _on_mode_changed(mode_name: String, _pad_count: int) -> void:
	match mode_name:
		"solo_kbm":
			help.text = "SOLO clavier: ZQSD | Souris vise | LMB mêlée | RMB jet | Ctrl stance (↑↓←→ sphère / ↑↑ mur) + LMB | Q munition | F katana | E sub | Shift roll | Espace\nBranche 1 manette pour jouer au pad, 2 manettes pour le duel."
		"solo_pad":
			help.text = "SOLO manette: StickG move | StickD vise | LB stance + D-pad + RT/A confirm | X/Y mêlée | B jet | RB roll | L3 sub | R3 munition | Start restart\nDébranche la manette pour repasser clavier/souris."
		_:
			help.text = "DUEL 2 manettes: LB stance + D-pad + RT | StickD vise | X/Y mêlée | B jet | RB roll | L3 sub | R3 munition | Start restart"


func _on_pads_changed(p1_device: int, p2_device: int) -> void:
	p1_title.text = "Joueur 1" + _pad_suffix(p1_device, true)
	p2_title.text = "Joueur 2" + _pad_suffix(p2_device, false)


func _pad_suffix(device: int, is_p1: bool) -> String:
	if device >= 0:
		return "  [%s]" % Input.get_joy_name(device)
	if is_p1:
		return "  (clavier/souris)"
	return "  (manette requise)"


func _on_stats(fighter: Node) -> void:
	var hp_bar: ProgressBar
	var ck_bar: ProgressBar
	var mudra: Label
	if fighter.player_id == 1:
		hp_bar = p1_hp
		ck_bar = p1_chakra
		mudra = p1_mudra
	else:
		hp_bar = p2_hp
		ck_bar = p2_chakra
		mudra = p2_mudra
	hp_bar.max_value = fighter.max_health
	hp_bar.value = fighter.health
	ck_bar.max_value = fighter.max_chakra
	ck_bar.value = fighter.chakra
	var kind_name := "kunai" if fighter.ammo_kind == 0 else "shuriken"
	if not fighter.controllable:
		mudra.text = "inactif"
		mudra.modulate = Color(0.6, 0.6, 0.6)
	elif not str(mudra.text).contains("↑") and not str(mudra.text).contains("READY"):
		mudra.text = "%d %s" % [fighter.ammo, kind_name]
		mudra.modulate = Color(1, 1, 1)


func _on_mudra(player_id: int, sequence: Array) -> void:
	var label := p1_mudra if player_id == 1 else p2_mudra
	var symbols: PackedStringArray = []
	for d in sequence:
		match str(d):
			"up": symbols.append("↑")
			"down": symbols.append("↓")
			"left": symbols.append("←")
			"right": symbols.append("→")
	label.text = " ".join(symbols) if symbols.size() > 0 else label.text


func _on_special_ready(player_id: int, ready: bool) -> void:
	var label := p1_mudra if player_id == 1 else p2_mudra
	label.modulate = Color(1.0, 0.85, 0.2) if ready else Color(1, 1, 1)
