extends SceneTree

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("CHECK: start")
	var packed: PackedScene = load("res://scenes/arena.tscn")
	if packed == null:
		printerr("CHECK FAIL: arena.tscn null")
		quit(1)
		return
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	print("CHECK: arena OK nodes=", scene.get_child_count())
	var p1 = scene.get_node_or_null("Fighters/Player1")
	var p2 = scene.get_node_or_null("Fighters/Player2")
	print("CHECK: p1=", p1, " p2=", p2)
	if p1 == null or p2 == null:
		printerr("CHECK FAIL: missing fighters")
		quit(1)
		return
	print("CHECK: p1 health=", p1.health, " chakra=", p1.chakra)
	print("CHECK: p1 anim=", p1.sprite.animation)
	print("CHECK: anims=", p1.sprite.sprite_frames.get_animation_names())
	print("CHECK: p2 facing=", p2.facing)
	# Simulate special mudra path
	p1._mudra.push_direction("up", 1.0)
	p1._mudra.push_direction("down", 1.1)
	p1._mudra.push_direction("left", 1.2)
	p1._mudra.push_direction("right", 1.3)
	print("CHECK: mudra armed=", p1._mudra.is_armed())
	print("CHECK PASS")
	quit(0)
