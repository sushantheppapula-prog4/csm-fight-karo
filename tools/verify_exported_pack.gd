extends SceneTree

const Roster = preload("res://scripts/game/fighter_roster.gd")

var _failures: Array[String] = []
var _checks := 0


func _initialize() -> void:
	call_deferred("_verify")


func _verify() -> void:
	_check(ProjectSettings.get_setting("application/config/name") == "CSM Fight Karo Lite", "exported identity")
	for path: String in [
		"res://scenes/main.tscn",
		"res://scripts/main.gd",
		"res://assets/game/title_illustration.jpg",
		"res://assets/game/arena_background.jpg",
		"res://assets/game/audio/arcade_theme.ogg",
		"res://assets/game/audio/punch.mp3",
		"res://assets/game/audio/kick.mp3",
		"res://assets/game/audio/jump.mp3",
		"res://assets/game/audio/special.mp3",
		"res://assets/game/audio/victory.mp3",
		"res://assets/game/audio/defeat.mp3",
		"res://assets/game/audio/quips/quip_01.ogg",
		"res://assets/template/fonts/ui_regular.tres",
	]:
		_check(ResourceLoader.exists(path), "required pack resource exists: " + path)
	for fighter_id: String in ["cr", "lady_don", "shiva_fighter", "fighter_51", "fighter_52", "fighter_53", "second_cr", "arabian_horse"]:
		_check(fighter_id in Roster.CSM_IDS, "CSM roster is packaged: " + fighter_id)
	for fighter_id: String in ["swapna_taker", "coa", "chubby_cheeks", "cheshma_girl"]:
		_check(fighter_id in Roster.OPPOSITE_IDS, "opponent roster is packaged: " + fighter_id)
	_check(root.get_node_or_null("SaveStore") == null, "no SaveStore autoload in package")
	_check(root.get_node_or_null("GlobalLeaderboard") == null, "no network leaderboard autoload in package")
	if _failures.is_empty():
		print("[exported-pack] PASS: identity, session-only assets, locked rosters and original audio are present")
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
