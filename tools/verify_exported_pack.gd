extends SceneTree

var _failures: Array[String] = []
var _checks := 0


func _initialize() -> void:
	call_deferred("_verify")


func _verify() -> void:
	_check(ProjectSettings.get_setting("application/config/name") == "CSM Fight Karo Lite", "exported identity")
	for path: String in [
		"res://assets/game/title_illustration.jpg",
		"res://assets/game/arena_background.jpg",
		"res://assets/game/audio/arcade_theme.ogg",
		"res://assets/share/favicon-small.png",
		"res://assets/template/fonts/ui_regular.tres",
	]:
		_check(ResourceLoader.exists(path), "required pack resource exists: " + path)
	for fighter_id: String in ["cr", "lady_don", "shiva_fighter", "fighter_51", "fighter_52", "fighter_53", "second_cr", "arabian_horse"]:
		_check(fighter_id in load("res://scripts/game/fighter_roster.gd").get_script_constant_map().get("CSM_IDS", []), "CSM roster is packaged: " + fighter_id)
	for fighter_id: String in ["swapna_taker", "coa", "chubby_cheeks", "cheshma_girl"]:
		_check(fighter_id in load("res://scripts/game/fighter_roster.gd").get_script_constant_map().get("OPPOSITE_IDS", []), "opponent roster is packaged: " + fighter_id)
	_check(root.get_node_or_null("SaveStore") == null, "no SaveStore autoload in package")
	_check(root.get_node_or_null("GlobalLeaderboard") == null, "no network leaderboard autoload in package")
	var packed := load("res://scenes/main.tscn") as PackedScene
	_check(packed != null, "exported main scene loads")
	if packed != null:
		var main := packed.instantiate()
			root.add_child(main)
			await process_frame
			await process_frame
			_check(str(main.get("_screen")) == "menu", "pack boots directly to the custom game menu")
			_check(str(main.get("_selected_p1")) in ["cr", "lady_don", "shiva_fighter", "fighter_51", "fighter_52", "fighter_53", "second_cr", "arabian_horse"], "Player 1 starts inside CSM Gang")
			_check(str(main.get("_selected_p2")) in ["swapna_taker", "coa", "chubby_cheeks", "cheshma_girl"], "Player 2 starts inside Opposite Gang")
			main.call("_start_match")
			await process_frame
		await process_frame
		_check(str(main.get("_screen")) == "arena", "match launches to the custom arena")
		_check(main.get("_actor_one") != null and main.get("_actor_two") != null, "both locally controlled fighter actors are created")
		_check(int(main.get("_round_timer")) == 60, "match starts with the 60-second round clock")
		var audio := root.get_node_or_null("AudioDirector")
		_check(audio != null and audio.call("play_cue", "fight.punch"), "browser build registers and routes the original punch cue")
		if audio != null:
			audio.call("release_streams")
		main.call("_return_to_menu")
		main.queue_free()
		await process_frame
	if _failures.is_empty():
		print("[exported-pack] PASS: identity, session-only play, locked rosters, assets, menu, combat scene and audio")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("[exported-pack] " + failure)
		print("[exported-pack] FAIL: %d failures across %d checks" % [_failures.size(), _checks])
		quit(1)


func _check(condition: bool, context: String) -> void:
	_checks += 1
	if not condition and context not in _failures:
		_failures.append(context)
