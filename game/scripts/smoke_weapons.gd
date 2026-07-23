extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var k = load("res://scenes/kunai.tscn").instantiate()
	var s = load("res://scenes/shuriken.tscn").instantiate()
	root.add_child(k)
	root.add_child(s)
	k.setup(null, 1, 0)
	s.setup(null, 1, 1)
	await process_frame
	print("KUNAI anims=", k.sprite.sprite_frames.get_animation_names())
	print("SHURIKEN anims=", s.sprite.sprite_frames.get_animation_names())
	print("WEAPONS PASS")
	quit(0)
