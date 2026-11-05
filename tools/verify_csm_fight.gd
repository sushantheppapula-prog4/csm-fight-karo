extends SceneTree

const Roster = preload("res://scripts/game/fighter_roster.gd")
const Rules = preload("res://scripts/game/fight_rules.gd")

var _failures: Array[String] = []
var _checks := 0


func _initialize() -> void:
	call_deferred("_verify")


func _verify() -> void:
	var roster := Roster.all_characters()
	_check(roster.size() == 12, "roster includes all 12 requested fighters")
	_check(Roster.team_ids("csm").size() == 8, "Player 1 team has eight CSM Gang fighters")
	_check(Roster.team_ids("opposite").size() == 4, "Player 2 team has four Opposite Gang fighters")
	for fighter_id: String in Roster.team_ids("csm"):
		_check(fighter_id not in Roster.team_ids("opposite"), "team rosters never overlap: " + fighter_id)
	for fighter: Dictionary in roster:
		_check(not str(fighter.get("signature", "")).is_empty(), "fighter has a signature move: " + str(fighter.get("name", "")))
		_check(ResourceLoader.exists(str(fighter.get("avatar", ""))), "fighter portrait exists: " + str(fighter.get("id", "")))
	_check(Rules.STARTING_HEALTH == 100, "starting HP is 100")
	_check(is_equal_approx(Rules.ROUND_DURATION_SECONDS, 60.0), "round timer is 60 seconds")
	_check(Rules.ROUNDS_TO_WIN == 2, "best of three requires two rounds")
	_check(Rules.damage_for("punch") == 9, "punch damage is 9")
	_check(Rules.damage_for("kick") == 15, "kick damage is 15")
	_check(Rules.damage_for("special") == 25, "signature special damage is 25")
	_check(Rules.damage_after_block(9, true) < 9, "block reduces punch damage")
	_check(Rules.damage_after_block(25, true) < 25, "block reduces special damage")
	for cue: String in ["arcade_theme.ogg", "punch.mp3", "kick.mp3", "jump.mp3", "special.mp3", "victory.mp3", "defeat.mp3"]:
		_check(FileAccess.file_exists("res://assets/game/audio/" + cue), "original sound file exists: " + cue)
	for index: int in range(1, 9):
		_check(ResourceLoader.exists("res://assets/game/audio/quips/quip_%02d.ogg" % index), "event quip %d exists" % index)
	var project := FileAccess.get_file_as_string("res://project.godot")
	_check(not project.contains("SaveStore=\"*res://autoload/save_store.gd\""), "SaveStore persistence autoload removed")
	_check(not project.contains("I18n=\"*res://autoload/i18n.gd\""), "unrequested saved locale autoload removed")
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd").to_lower()
	for forbidden: String in ["localstorage", "indexeddb", "user://", "supabase"]:
		_check(not main_source.contains(forbidden), "runtime contains no persistent-store reference: " + forbidden)
	if _failures.is_empty():
		print("[csm-fight-check] PASS: %d source, roster, balance, session-data and asset checks" % _checks)
		quit(0)
		return
	for failure: String in _failures:
		push_error("[csm-fight-check] " + failure)
	print("[csm-fight-check] FAIL: %d issues across %d checks" % [_failures.size(), _checks])
	quit(1)


func _check(condition: bool, context: String) -> void:
	_checks += 1
	if not condition and context not in _failures:
		_failures.append(context)
