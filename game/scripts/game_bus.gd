extends Node
## Bus global pour events match / UI.

signal fighter_stats_changed(fighter: Node)
signal fighter_defeated(fighter: Node)
signal match_over(winner_id: int)
signal mudra_updated(player_id: int, sequence: Array)
signal special_ready(player_id: int, ready: bool)

var match_active: bool = true
