class_name SpriteSheets
extends RefCounted
## Construit des SpriteFrames à partir des sheets Zegley (mannequin).

const SHEETS := {
	"idle": {"path": "res://assets/player/idle.png", "frame": Vector2i(48, 48), "count": 10, "fps": 8.0, "loop": true},
	"run": {"path": "res://assets/player/run.png", "frame": Vector2i(48, 48), "count": 8, "fps": 12.0, "loop": true},
	"jump": {"path": "res://assets/player/jump.png", "frame": Vector2i(48, 48), "count": 6, "fps": 10.0, "loop": false},
	"land": {"path": "res://assets/player/land.png", "frame": Vector2i(48, 48), "count": 9, "fps": 14.0, "loop": false},
	"roll": {"path": "res://assets/player/roll.png", "frame": Vector2i(48, 48), "count": 7, "fps": 16.0, "loop": false},
	"dash": {"path": "res://assets/player/dash.png", "frame": Vector2i(48, 48), "count": 9, "fps": 16.0, "loop": false},
	"hurt": {"path": "res://assets/player/hurt.png", "frame": Vector2i(48, 48), "count": 4, "fps": 10.0, "loop": false},
	"death": {"path": "res://assets/player/death.png", "frame": Vector2i(48, 48), "count": 10, "fps": 8.0, "loop": false},
	"attack_light": {"path": "res://assets/player/attack_light.png", "frame": Vector2i(64, 64), "count": 6, "fps": 14.0, "loop": false},
	"attack_heavy": {"path": "res://assets/player/attack_heavy.png", "frame": Vector2i(80, 64), "count": 10, "fps": 12.0, "loop": false},
	"attack_special": {"path": "res://assets/player/attack_special.png", "frame": Vector2i(80, 64), "count": 9, "fps": 12.0, "loop": false},
	"wall_slide": {"path": "res://assets/player/wall_slide.png", "frame": Vector2i(48, 48), "count": 3, "fps": 6.0, "loop": true},
}


static func build() -> SpriteFrames:
	var frames := SpriteFrames.new()
	# Remove default empty anim if present
	if frames.has_animation("default"):
		frames.remove_animation("default")

	for anim_name in SHEETS.keys():
		var cfg: Dictionary = SHEETS[anim_name]
		var tex: Texture2D = load(cfg.path)
		if tex == null:
			push_warning("SpriteSheets: missing %s" % cfg.path)
			continue
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, cfg.fps)
		frames.set_animation_loop(anim_name, cfg.loop)
		var fw: int = cfg.frame.x
		var fh: int = cfg.frame.y
		var count: int = cfg.count
		for i in count:
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(i * fw, 0, fw, fh)
			frames.add_frame(anim_name, atlas)
	return frames
