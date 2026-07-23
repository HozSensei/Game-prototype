class_name MudraBuffer
extends RefCounted
## Combos type Helldivers : plusieurs recettes (offensive / défensive).

signal sequence_changed(sequence: Array)
signal technique_armed(technique_id: String) # "" si rien

const RECIPES := {
	"offense": ["up", "down", "left", "right"], # sphère
	"defense": ["up", "up"], # mur
}
const WINDOW_SEC := 4.0
const MAX_LEN := 8

var sequence: Array[String] = []
var armed_technique: String = ""
var _last_input_time: float = 0.0


func reset() -> void:
	sequence.clear()
	_set_armed("")
	sequence_changed.emit(sequence)


func push_direction(dir: String, now: float) -> void:
	if sequence.size() > 0 and now - _last_input_time > WINDOW_SEC:
		sequence.clear()
		_set_armed("")
	_last_input_time = now
	sequence.append(dir)
	if sequence.size() > MAX_LEN:
		sequence = sequence.slice(sequence.size() - MAX_LEN)
	sequence_changed.emit(sequence)
	_check_recipes()


func try_consume(now: float) -> String:
	if armed_technique.is_empty():
		return ""
	if now - _last_input_time > WINDOW_SEC:
		reset()
		return ""
	var tech := armed_technique
	reset()
	return tech


func is_armed() -> bool:
	return not armed_technique.is_empty()


func _check_recipes() -> void:
	var best := ""
	var best_len := 0
	for tech_id in RECIPES.keys():
		var recipe: Array = RECIPES[tech_id]
		if sequence.size() < recipe.size():
			continue
		var tail := sequence.slice(sequence.size() - recipe.size())
		var ok := true
		for i in recipe.size():
			if str(tail[i]) != str(recipe[i]):
				ok = false
				break
		if ok and recipe.size() >= best_len:
			best = str(tech_id)
			best_len = recipe.size()
	_set_armed(best)


func _set_armed(tech: String) -> void:
	if armed_technique == tech:
		return
	armed_technique = tech
	technique_armed.emit(armed_technique)
