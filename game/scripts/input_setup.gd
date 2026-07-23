extends Node
## Assigne dynamiquement jusqu'à 2 manettes → P1 / P2.

signal pads_changed(p1_device: int, p2_device: int)

var p1_device: int = -1
var p2_device: int = -1

const ACTIONS := [
	"left", "right", "up", "down",
	"jump", "attack_light", "attack_heavy",
	"throw", "shuriken", "dodge", "substitute", "special",
]


func _ready() -> void:
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_refresh_pads()


func get_device_for_player(player_id: int) -> int:
	return p1_device if player_id == 1 else p2_device


func is_pad_assigned(player_id: int) -> bool:
	return get_device_for_player(player_id) >= 0


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

	if p1_device >= 0:
		_bind_pad(p1_device, "p1")
		_add_button("restart_match", p1_device, JOY_BUTTON_START)
	if p2_device >= 0:
		_bind_pad(p2_device, "p2")
		_add_button("restart_match", p2_device, JOY_BUTTON_START)

	pads_changed.emit(p1_device, p2_device)
	print("Pads: P1=", p1_device, " (", _pad_name(p1_device), ") | P2=", p2_device, " (", _pad_name(p2_device), ")")


func _pad_name(device: int) -> String:
	if device < 0:
		return "aucune"
	return Input.get_joy_name(device)


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
	_add_axis(prefix + "_left", device, JOY_AXIS_LEFT_X, -1.0)
	_add_axis(prefix + "_right", device, JOY_AXIS_LEFT_X, 1.0)
	_add_axis(prefix + "_up", device, JOY_AXIS_LEFT_Y, -1.0)
	_add_axis(prefix + "_down", device, JOY_AXIS_LEFT_Y, 1.0)
	_add_button(prefix + "_left", device, JOY_BUTTON_DPAD_LEFT)
	_add_button(prefix + "_right", device, JOY_BUTTON_DPAD_RIGHT)
	_add_button(prefix + "_up", device, JOY_BUTTON_DPAD_UP)
	_add_button(prefix + "_down", device, JOY_BUTTON_DPAD_DOWN)
	_add_button(prefix + "_jump", device, JOY_BUTTON_A)
	_add_button(prefix + "_attack_light", device, JOY_BUTTON_X)
	_add_button(prefix + "_attack_heavy", device, JOY_BUTTON_Y)
	_add_button(prefix + "_throw", device, JOY_BUTTON_B)
	_add_button(prefix + "_shuriken", device, JOY_BUTTON_LEFT_STICK)
	_add_button(prefix + "_dodge", device, JOY_BUTTON_RIGHT_SHOULDER)
	_add_button(prefix + "_substitute", device, JOY_BUTTON_LEFT_SHOULDER)
	_add_button(prefix + "_special", device, JOY_BUTTON_RIGHT_STICK)


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
