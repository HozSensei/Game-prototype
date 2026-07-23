extends SceneTree

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var k = load("res://scenes/kunai.tscn").instantiate()
	k.setup(null, Vector2(0.8, -0.4), 0)
	root.add_child(k)
	await process_frame
	print("KUNAI vel=", k.velocity, " anims=", k.sprite.sprite_frames.get_animation_names())
	var s = load("res://scenes/shuriken.tscn").instantiate()
	s.setup(null, Vector2(-0.5, -0.7), 1)
	root.add_child(s)
	await process_frame
	print("SHURIKEN vel=", s.velocity)
	var f = load("res://scenes/fighter.tscn").instantiate()
	root.add_child(f)
	await process_frame
	print("FIGHTER aim=", f.aim_dir, " reticle=", f.aim_reticle != null)
	print("AIM PASS")
	quit(0)
