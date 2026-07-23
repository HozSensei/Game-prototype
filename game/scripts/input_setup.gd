extends Node
## Modes : solo clavier-souris, ou 1–2 manettes (pas de P2 clavier).

signal pads_changed(p1_device: int, p2_device: int)
signal mode_changed(solo_kbm: bool, pad_count: int)

var p1_device: int = -1
var p2_device: int = -1
var solo_kbm: bool = true

const ACTIONS := [
	"left", "right", "up", "down",
	"jump", "attack_melee", "attack_heavy",
	"throw", "cycle_ammo", "dodge", "substitute",
	"stance", "special_confirm",
]


func _ready() -> void:
	_ensure_actions()
	_clear_prefix_non_joy("p1")
	_clear_prefix_non_joy("p2") # aucun P2 clavier
	_bind_keyboard_mouse_p1()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_refresh_pads()


func get_device_for_player(player_id: int) -> int:
	return p1_device if player_id == 1 else p2_device


func is_player_active(player_id: int) -> bool:
	if player_id == 1:
		return true # P1 toujours actif (KBM ou pad)
	# P2 uniquement si une 2e manette est branchée
	return p2_device >= 0


func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
	_refresh_pads()


func _refresh_pads() -> void:
	_clear_joy_events()
	var pads: Array[int] = []
	for id in Input.get_connected_joypads():
		pads.append(int(id))
	pads.sort()

	p1_device = pads[0] if pads.size() >= 1 else -1
	p2_device = pads[1] if pads.size() >= 2 else -1
	solo_kbm = p1_device < 0

	if p1_device >= 0:
		_bind_pad(p1_device, "p1")
	if p2_device >= 0:
		_bind_pad(p2_device, "p2")

	# Restart sur Start de n'importe quel pad assigné
	for d in [p1_device, p2_device]:
		if d >= 0:
			_add_button("restart_match", d, JOY_BUTTON_START)

	pads_changed.emit(p1_device, p2_device)
	mode_changed.emit(solo_kbm, pads.size())
	print("Mode: ", "SOLO KBM" if solo_kbm else "PAD", " | P1=", p1_device, " P2=", p2_device)


func _ensure_actions() -> void:
	for prefix in ["p1", "p2"]:
		for a in ACTIONS:
			var name := "%s_%s" % [prefix, a]
			if not InputMap.has_action(name):
				InputMap.add_action(name, 0.25)
	if not InputMap.has_action("restart_match"):
		InputMap.add_action("restart_match", 0.5)


func _bind_keyboard_mouse_p1() -> void:
	# Nettoie d'abord les events clavier/souris P1 pour éviter les doublons au reload
	_clear_prefix_non_joy("p1")
	# Move ZQSD/WASD (physical = positions)
	_add_key("p1_left", KEY_A)
	_add_key("p1_right", KEY_D)
	_add_key("p1_up", KEY_W)
	_add_key("p1_down", KEY_S)
	# Flèches aussi pour mudras (Helldivers)
	_add_key("p1_left", KEY_LEFT)
	_add_key("p1_right", KEY_RIGHT)
	_add_key("p1_up", KEY_UP)
	_add_key("p1_down", KEY_DOWN)
	_add_key("p1_jump", KEY_SPACE)
	_add_key("p1_dodge", KEY_SHIFT)
	_add_key("p1_substitute", KEY_E)
	_add_key("p1_cycle_ammo", KEY_Q)
	_add_key("p1_attack_heavy", KEY_F)
	_add_key("p1_stance", KEY_CTRL)
	_add_mouse("p1_attack_melee", MOUSE_BUTTON_LEFT)
	_add_mouse("p1_throw", MOUSE_BUTTON_RIGHT)
	_add_mouse("p1_special_confirm", MOUSE_BUTTON_LEFT)
	_add_key("restart_match", KEY_R)
	# P2 : aucun clavier


func _clear_prefix_non_joy(prefix: String) -> void:
	for a in ACTIONS:
		var name := "%s_%s" % [prefix, a]
		if not InputMap.has_action(name):
			continue
		for ev in InputMap.action_get_events(name):
			if ev is InputEventKey or ev is InputEventMouseButton:
				InputMap.action_erase_event(name, ev)


func _clear_action_keys(action: String) -> void:
	if not InputMap.has_action(action):
		return
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			InputMap.action_erase_event(action, ev)


func _clear_joy_events() -> void:
	for prefix in ["p1", "p2"]:
		for action_suffix in ACTIONS:
			var action := "%s_%s" % [prefix, action_suffix]
			if not InputMap.has_action(action):
				continue
			for ev in InputMap.action_get_events(action):
				if ev is InputEventJoypadButton or ev is InputEventJoypadMotion:
					InputMap.action_erase_event(action, ev)
	if InputMap.has_action("restart_match"):
		for ev in InputMap.action_get_events("restart_match"):
			if ev is InputEventJoypadButton or ev is InputEventJoypadMotion:
				InputMap.action_erase_event("restart_match", ev)


func _bind_pad(device: int, prefix: String) -> void:
	for move_action in ["left", "right", "up", "down"]:
		var full := "%s_%s" % [prefix, move_action]
		if InputMap.has_action(full):
			InputMap.action_set_deadzone(full, 0.25)
	_add_axis(prefix + "_left", device, JOY_AXIS_LEFT_X, -1.0)
	_add_axis(prefix + "_right", device, JOY_AXIS_LEFT_X, 1.0)
	_add_axis(prefix + "_up", device, JOY_AXIS_LEFT_Y, -1.0)
	_add_axis(prefix + "_down", device, JOY_AXIS_LEFT_Y, 1.0)
	_add_button(prefix + "_left", device, JOY_BUTTON_DPAD_LEFT)
	_add_button(prefix + "_right", device, JOY_BUTTON_DPAD_RIGHT)
	_add_button(prefix + "_up", device, JOY_BUTTON_DPAD_UP)
	_add_button(prefix + "_down", device, JOY_BUTTON_DPAD_DOWN)
	_add_button(prefix + "_jump", device, JOY_BUTTON_A)
	_add_button(prefix + "_attack_melee", device, JOY_BUTTON_X)
	_add_button(prefix + "_attack_heavy", device, JOY_BUTTON_Y)
	_add_button(prefix + "_throw", device, JOY_BUTTON_B)
	_add_button(prefix + "_cycle_ammo", device, JOY_BUTTON_RIGHT_STICK)
	_add_button(prefix + "_dodge", device, JOY_BUTTON_RIGHT_SHOULDER)
	_add_button(prefix + "_substitute", device, JOY_BUTTON_LEFT_STICK)
	_add_button(prefix + "_stance", device, JOY_BUTTON_LEFT_SHOULDER) # LB
	_add_axis(prefix + "_special_confirm", device, JOY_AXIS_TRIGGER_RIGHT, 1.0) # RT
	_add_button(prefix + "_special_confirm", device, JOY_BUTTON_A) # A aussi si armé (géré code)


func _add_key(action: String, keycode: int) -> void:
	if not InputMap.has_action(action):
		return
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	InputMap.action_add_event(action, ev)


func _add_mouse(action: String, button: int) -> void:
	if not InputMap.has_action(action):
		return
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)


func _add_button(action: String, device: int, button: int) -> void:
	if not InputMap.has_action(action):
		return
	var ev := InputEventJoypadButton.new()
	ev.device = device
	ev.button_index = button
	InputMap.action_add_event(action, ev)


func _add_axis(action: String, device: int, axis: int, axis_value: float) -> void:
	if not InputMap.has_action(action):
		return
	var ev := InputEventJoypadMotion.new()
	ev.device = device
	ev.axis = axis
	ev.axis_value = axis_value
	InputMap.action_add_event(action, ev)
