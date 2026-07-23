class_name WeaponAtlas
extends RefCounted
## Atlas 160x160 — 5 lignes x 32px. Ligne 3 ignorée (arme non utilisée).

const SHEET := "res://assets/weapons/weapon.png"
const CELL := 32

# row index -> usable frame columns
const KUNAI_FLY := {"row": 0, "frames": [0, 1, 2, 3, 4], "fps": 16.0}
const KUNAI_STUCK := {"row": 1, "frames": [0, 1, 2], "fps": 10.0}
const SHURIKEN_FLY := {"row": 3, "frames": [0, 1], "fps": 18.0}
const SHURIKEN_STUCK := {"row": 4, "frames": [0], "fps": 1.0}


static func make_frames(fly_cfg: Dictionary, stuck_cfg: Dictionary) -> SpriteFrames:
	var tex: Texture2D = load(SHEET)
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	_add_anim(frames, tex, "fly", fly_cfg, true)
	_add_anim(frames, tex, "stuck", stuck_cfg, false)
	return frames


static func _add_anim(frames: SpriteFrames, tex: Texture2D, name: String, cfg: Dictionary, loop: bool) -> void:
	frames.add_animation(name)
	frames.set_animation_speed(name, cfg.fps)
	frames.set_animation_loop(name, loop)
	var row: int = cfg.row
	for col in cfg.frames:
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(col * CELL, row * CELL, CELL, CELL)
		frames.add_frame(name, atlas)
