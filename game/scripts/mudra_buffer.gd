class_name MudraBuffer
extends RefCounted
## Buffer de mudras directionnels (↑↓←→) pour déclencher une spéciale.

signal sequence_changed(sequence: Array)
signal special_armed(armed: bool)

const SPECIAL_RECIPE: Array[String] = ["up", "down", "left", "right"]
const WINDOW_SEC := 3.0
const MAX_LEN := 8

var sequence: Array[String] = []
var _armed: bool = false
var _last_input_time: float = 0.0


func reset() -> void:
	sequence.clear()
	_set_armed(false)
	sequence_changed.emit(sequence)


func push_direction(dir: String, now: float) -> void:
	if sequence.size() > 0 and now - _last_input_time > WINDOW_SEC:
		sequence.clear()
		_set_armed(false)
	_last_input_time = now
	sequence.append(dir)
	if sequence.size() > MAX_LEN:
		sequence = sequence.slice(sequence.size() - MAX_LEN)
	sequence_changed.emit(sequence)
	_check_recipe()


func try_consume_special(now: float) -> bool:
	if not _armed:
		return false
	if now - _last_input_time > WINDOW_SEC:
		reset()
		return false
	reset()
	return true


func is_armed() -> bool:
	return _armed


func _check_recipe() -> void:
	if sequence.size() < SPECIAL_RECIPE.size():
		_set_armed(false)
		return
	var tail := sequence.slice(sequence.size() - SPECIAL_RECIPE.size())
	var ok := true
	for i in SPECIAL_RECIPE.size():
		if tail[i] != SPECIAL_RECIPE[i]:
			ok = false
			break
	_set_armed(ok)


func _set_armed(value: bool) -> void:
	if _armed == value:
		return
	_armed = value
	special_armed.emit(_armed)
