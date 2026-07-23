extends Node
## Bindings manette runtime : P1 = pad 0, P2 = pad 1.


func _ready() -> void:
	_bind_pad(0, "p1")
	_bind_pad(1, "p2")
	_add_button("restart_match", 0, JOY_BUTTON_START)
	_add_button("restart_match", 1, JOY_BUTTON_START)


func _bind_pad(device: int, prefix: String) -> void:
	# Stick + D-pad
	_add_axis(prefix + "_left", device, JOY_AXIS_LEFT_X, -1.0)
	_add_axis(prefix + "_right", device, JOY_AXIS_LEFT_X, 1.0)
	_add_axis(prefix + "_up", device, JOY_AXIS_LEFT_Y, -1.0)
	_add_axis(prefix + "_down", device, JOY_AXIS_LEFT_Y, 1.0)
	_add_button(prefix + "_left", device, JOY_BUTTON_DPAD_LEFT)
	_add_button(prefix + "_right", device, JOY_BUTTON_DPAD_RIGHT)
	_add_button(prefix + "_up", device, JOY_BUTTON_DPAD_UP)
	_add_button(prefix + "_down", device, JOY_BUTTON_DPAD_DOWN)
	# Face buttons (layout Xbox / sud = A, est = B, ouest = X, nord = Y)
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
