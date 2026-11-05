extends SceneTree

# Native renderer evidence only; tools/ is excluded from every playable export.

func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var capture_path := OS.get_environment("GENERIC2D_CAPTURE_PATH")
	if capture_path.is_empty():
		push_error("GENERIC2D_CAPTURE_PATH must name an output PNG")
		quit(1)
		return
	var size_text := OS.get_environment("CSMFIGHT_CAPTURE_SIZE")
	if not size_text.is_empty():
		var dimensions := size_text.split("x")
		if dimensions.size() == 2:
			var capture_size := Vector2i(dimensions[0].to_int(), dimensions[1].to_int())
			if capture_size.x > 0 and capture_size.y > 0:
				DisplayServer.window_set_size(capture_size)
				root.size = capture_size
	var main: Variant = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var capture_mode := OS.get_environment("CSMFIGHT_CAPTURE_MODE")
	if capture_mode == "special":
		main.set("_mode", "local")
	if capture_mode in ["arena", "pause", "versus", "special"]:
		main.call("_start_match")
		await process_frame
		if capture_mode == "arena" or capture_mode == "special":
			main.set("_countdown", 0.0)
			await process_frame
			if capture_mode == "special":
				var actor_one: Variant = main.get("_actor_one")
				var actor_two: Variant = main.get("_actor_two")
				var starting_health := int(actor_two.get("health"))
				actor_one.position.x = actor_two.position.x - 196.0
				actor_one.energy = 100.0
				actor_one.face_toward(actor_two.position.x)
				main.call("_try_attack", 1, "special")
				if int(actor_two.get("health")) != starting_health - 25:
					push_error("Special attack smoke did not hit for the expected 25 damage")
					quit(1)
					return
				if str(actor_one.get("action")) != "special":
					push_error("Special attack animation did not remain active after the hit")
					quit(1)
					return
				print("[capture] signature special connected for 25 damage")
		elif capture_mode == "pause":
			main.call("_toggle_pause")
		var settle_frames := 2 if capture_mode == "special" else 8
		for _frame: int in settle_frames:
			await process_frame
		if capture_mode != "special":
			await create_timer(0.25).timeout
	var image := root.get_texture().get_image()
	var error := image.save_png(capture_path)
	print("[capture] %s (%s)" % [capture_path, error_string(error)])
	root.get_node("AudioDirector").call("release_streams")
	await process_frame
	quit(0 if error == OK else 1)
