extends Control

const ScreenFactory = preload("res://scripts/ui/screen_factory.gd")
const FighterRosterType = preload("res://scripts/game/fighter_roster.gd")
const FightRulesType = preload("res://scripts/game/fight_rules.gd")
const FighterActorType = preload("res://scripts/entities/fighter_actor.gd")
const ARENA_ART = preload("res://assets/game/arena_background.jpg")
const TITLE_ART = preload("res://assets/game/title_illustration.jpg")
const MUSIC_PATH = "res://assets/game/audio/arcade_theme.ogg"
const VOICE_PATHS := {
	"Orey, internal exam anukunnava?": "res://assets/game/audio/quips/quip_01.ogg",
	"Naa range veru ra!": "res://assets/game/audio/quips/quip_02.ogg",
	"First attendance veyyi ra!": "res://assets/game/audio/quips/quip_03.ogg",
	"Dheenamma, mass entry!": "res://assets/game/audio/quips/quip_04.ogg",
	"Side ivvu ra babu!": "res://assets/game/audio/quips/quip_05.ogg",
	"Pass avvadam kuda oka art ra!": "res://assets/game/audio/quips/quip_06.ogg",
	"Ayyayyo, debba padindhi!": "res://assets/game/audio/quips/quip_07.ogg",
	"Friendship cancelled ra!": "res://assets/game/audio/quips/quip_08.ogg"
}
const MAX_UPLOAD_BYTES := 6 * 1024 * 1024

class ArenaEffects extends Node2D:
	var owner_game: Node

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if owner_game == null or str(owner_game.get("_screen")) != "arena":
			return
		var size := get_viewport_rect().size
		if size.x <= 0.0 or size.y <= 0.0:
			return
		var floor_y := size.y * (0.56 if size.y > size.x * 1.15 else 0.73)
		var cyan := Color("43e9ff")
		var pink := Color("ff4eb5")
		draw_line(Vector2(0, floor_y), Vector2(size.x, floor_y), Color(cyan, 0.52), 2.0, true)
		draw_line(Vector2(0, floor_y + 4.0), Vector2(size.x, floor_y + 4.0), Color(pink, 0.24), 1.0, true)
		for index: int in 9:
			var x := size.x * (float(index) / 8.0)
			draw_line(Vector2(size.x * 0.5, floor_y), Vector2(x, size.y), Color(cyan, 0.045), 1.0, true)
		for particle: Dictionary in owner_game.get("_fx_particles"):
			var life_ratio := clampf(float(particle.life) / float(particle.max_life), 0.0, 1.0)
			var tint: Color = particle.tint
			tint.a *= life_ratio
			draw_circle(particle.position, float(particle.radius) * life_ratio, tint)


var _screen := "menu"
var _background: TextureRect
var _wash: ColorRect
var _actor_layer: Node2D
var _fx_layer: ArenaEffects
var _page: Control
var _voice_player: AudioStreamPlayer
var _voice_timer: Timer

var _roster: Array[Dictionary] = []
var _selected_p1 := "cr"
var _selected_p2 := "swapna_taker"
var _mode := "cpu"
var _difficulty := "Normal"
var _sound_enabled := true
var _music_enabled := true
var _voice_enabled := true
var _music_started := false
var _session_results: Array[Dictionary] = []
var _custom_faces: Dictionary = {}
var _custom_voice: Dictionary = {}
var _custom_dialogue: Dictionary = {}
var _custom_id := "cr"
var _draft_image: Image
var _draft_crop := Vector2.ZERO
var _upload_kind := "photo"
var _file_dialog: FileDialog
var _photo_preview: TextureRect
var _photo_name_label: Label
var _crop_x_slider: HSlider
var _crop_y_slider: HSlider
var _dialogue_input: LineEdit

var _actor_one: FighterActor
var _actor_two: FighterActor
var _hud_health_one: ProgressBar
var _hud_health_two: ProgressBar
var _hud_energy_one: ProgressBar
var _hud_energy_two: ProgressBar
var _hud_timer: Label
var _hud_round: Label
var _hud_dialogue: Label
var _hud_pause_button: Button
var _vs_overlay: Control
var _touch_pad: Control
var _touch_pressed: Dictionary = {}
var _key_latches: Dictionary = {}
var _round_wins: Array[int] = [0, 0]
var _round_number := 1
var _round_timer := 60.0
var _countdown := 0.0
var _between_round_timer := 0.0
var _phase := "idle"
var _match_winner := -1
var _low_health_seen := [false, false]
var _jump_heights := [0.0, 0.0]
var _jump_speeds := [0.0, 0.0]
var _attack_cooldowns := [0.0, 0.0]
var _knockback_speeds := [0.0, 0.0]
var _cpu_decision_timer := 0.0
var _cpu_block_timer := 0.0
var _ground_y := 0.0
var _fx_particles: Array[Dictionary] = []
var _last_dialogue := ""
var _dialogue_time := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_roster = FighterRosterType.all_characters()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_layers()
	_build_voice_player()
	_load_game_audio()
	_show_menu()
	get_viewport().size_changed.connect(_on_viewport_changed)
	set_process(true)


func _build_layers() -> void:
	_background = TextureRect.new()
	_background.name = "GameArtwork"
	_background.texture = TITLE_ART
	_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ScreenFactory.full_rect(_background)
	add_child(_background)
	_wash = ColorRect.new()
	_wash.color = Color(0.04, 0.025, 0.09, 0.48)
	_wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ScreenFactory.full_rect(_wash)
	add_child(_wash)
	_actor_layer = Node2D.new()
	_actor_layer.name = "LocalFighters"
	_actor_layer.visible = false
	add_child(_actor_layer)
	_fx_layer = ArenaEffects.new()
	_fx_layer.name = "ArcadeFightEffects"
	_fx_layer.owner_game = self
	_fx_layer.z_index = 5
	add_child(_fx_layer)
	_page = Control.new()
	_page.name = "Page"
	_page.mouse_filter = Control.MOUSE_FILTER_PASS
	ScreenFactory.full_rect(_page)
	add_child(_page)


func _build_voice_player() -> void:
	_voice_player = AudioStreamPlayer.new()
	_voice_player.name = "SessionVoicePlayer"
	_voice_player.bus = "SFX"
	_voice_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_voice_player)
	_voice_timer = Timer.new()
	_voice_timer.one_shot = true
	_voice_timer.timeout.connect(func() -> void:
		if is_instance_valid(_voice_player):
			_voice_player.stop()
	)
	add_child(_voice_timer)


func _load_game_audio() -> void:
	AudioDirector.register_cue("music.title", MUSIC_PATH)
	AudioDirector.register_cue("music.gameplay", MUSIC_PATH)
	AudioDirector.register_cue("fight.punch", "res://assets/game/audio/punch.mp3")
	AudioDirector.register_cue("fight.kick", "res://assets/game/audio/kick.mp3")
	AudioDirector.register_cue("fight.jump", "res://assets/game/audio/jump.mp3")
	AudioDirector.register_cue("fight.special", "res://assets/game/audio/special.mp3")
	AudioDirector.register_cue("game.victory", "res://assets/game/audio/victory.mp3")
	AudioDirector.register_cue("game.defeat", "res://assets/game/audio/defeat.mp3")
	AudioDirector.register_cue("ui.confirm", "res://assets/game/audio/punch.mp3")
	AudioDirector.register_cue("ui.cancel", "res://assets/game/audio/jump.mp3")


func _process(delta: float) -> void:
	if _dialogue_time > 0.0:
		_dialogue_time = maxf(0.0, _dialogue_time - delta)
		if _dialogue_time == 0.0 and is_instance_valid(_hud_dialogue):
			_hud_dialogue.text = ""
	for particle: Dictionary in _fx_particles:
		particle.position += particle.velocity * delta
		particle.velocity *= 0.92
		particle.life -= delta
	_fx_particles = _fx_particles.filter(func(p: Dictionary) -> bool: return float(p.life) > 0.0)
	if _screen != "arena" or _phase == "paused" or _phase == "finished":
		return
	if _phase == "countdown":
		_countdown -= delta
		if _countdown <= 0.0:
			if is_instance_valid(_vs_overlay):
				_vs_overlay.visible = false
			_phase = "fight"
			_round_timer = FightRulesType.ROUND_DURATION_SECONDS
			_set_dialogue(_pick_quip(_actor_one.fighter, "start"), _actor_one.fighter, 1.65, false)
			_play_sound("ui.confirm")
		else:
			if is_instance_valid(_vs_overlay):
				_vs_overlay.visible = _countdown > 3.0
			if is_instance_valid(_hud_dialogue):
				_hud_dialogue.text = "FRIENDS BY DAY. ENEMIES IN THE ARENA." if _countdown > 3.0 else "ROUND %d\n%d" % [_round_number, maxi(1, ceili(_countdown))]
			_refresh_hud()
		return
	if _phase == "round_result":
		_between_round_timer -= delta
		if _between_round_timer <= 0.0:
			if _round_wins[0] >= FightRulesType.rounds_needed_to_win() or _round_wins[1] >= FightRulesType.rounds_needed_to_win():
				_finish_match()
			else:
				_round_number += 1
				_start_round()
		_refresh_hud()
		return
	if _phase != "fight":
		return
	_step_combat(delta)
	if _mode != "practice":
		_round_timer = maxf(0.0, _round_timer - delta)
	if _actor_one.health <= 0 or _actor_two.health <= 0:
		_resolve_round(0 if _actor_one.health > _actor_two.health else 1)
	elif _mode != "practice" and _round_timer <= 0.0:
		if _actor_one.health == _actor_two.health:
			_round_timer = 12.0
			_set_dialogue("SUDDEN DEATH — last hit wins!", _actor_one.fighter, 1.5, false)
		else:
			_resolve_round(0 if _actor_one.health > _actor_two.health else 1)
	_refresh_hud()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if _screen == "arena":
				_toggle_pause()
			elif _screen == "pause":
				_resume_match()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			if _screen == "pause":
				_resume_match()
	if event is InputEventScreenTouch and event.pressed:
		_on_user_gesture()


func _on_viewport_changed() -> void:
	if is_instance_valid(_touch_pad):
		_touch_pad.visible = _should_show_touch_controls()
	if _screen == "arena":
		_layout_fighters()
	if is_instance_valid(_fx_layer):
		_fx_layer.queue_redraw()


func _new_page(screen_name: String) -> Control:
	if is_instance_valid(_page):
		_page.queue_free()
	_page = Control.new()
	_page.name = "%sPage" % screen_name.capitalize()
	_page.mouse_filter = Control.MOUSE_FILTER_PASS
	ScreenFactory.full_rect(_page)
	add_child(_page)
	_screen = screen_name
	return _page


func _place(control: Control, left: float, top: float, right: float, bottom: float, inset: Vector4 = Vector4.ZERO) -> void:
	control.anchor_left = left
	control.anchor_top = top
	control.anchor_right = right
	control.anchor_bottom = bottom
	control.offset_left = inset.x
	control.offset_top = inset.y
	control.offset_right = inset.z
	control.offset_bottom = inset.w


func _add_label(parent: Control, text: String, font_size: int, color: Color, rect: Rect2, kind: String = "heading", centered: bool = false) -> Label:
	var label := ScreenFactory.display_label(text, font_size, color, kind)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if centered:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(label, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	parent.add_child(label)
	return label


func _make_button(parent: Control, caption: String, rect: Rect2, action: Callable, primary: bool = false, accent: Color = Color("43e9ff")) -> Button:
	var button := ScreenFactory.button(caption, 180.0)
	button.custom_minimum_size = Vector2(0.0, 46.0)
	button.add_theme_font_size_override("font_size", 15)
	if primary:
		button.add_theme_color_override("font_color", Color("0c1021"))
		button.add_theme_color_override("font_hover_color", Color("0c1021"))
		button.add_theme_color_override("font_pressed_color", Color("0c1021"))
		button.add_theme_stylebox_override("normal", ScreenFactory.plate(accent, Color(accent, 0.95), Color(accent, 0.22)))
		button.add_theme_stylebox_override("hover", ScreenFactory.plate(accent.lightened(0.12), Color.WHITE, Color(accent, 0.38)))
		button.add_theme_stylebox_override("pressed", ScreenFactory.plate(accent.darkened(0.08), accent, Color(accent, 0.16)))
	else:
		button.add_theme_stylebox_override("normal", ScreenFactory.plate(Color(0.06, 0.055, 0.105, 0.92), Color(accent, 0.42), Color(accent, 0.08)))
		button.add_theme_stylebox_override("hover", ScreenFactory.plate(Color(0.11, 0.08, 0.17, 0.98), Color(accent, 0.88), Color(accent, 0.20)))
		button.add_theme_stylebox_override("pressed", ScreenFactory.plate(Color(0.08, 0.06, 0.14, 0.98), accent))
	_place(button, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	parent.add_child(button)
	button.pressed.connect(_on_user_gesture)
	button.pressed.connect(action)
	AudioDirector.register_button(button)
	return button


func _add_back_button(parent: Control, return_to: Callable, caption: String = "← BACK") -> void:
	_make_button(parent, caption, Rect2(0.82, 0.045, 0.96, 0.12), return_to, false, Color("ff4eb5"))


func _on_user_gesture() -> void:
	AudioDirector.unlock_audio()
	if _sound_enabled and _music_enabled and not _music_started:
		_music_started = AudioDirector.play_music("music.title")
	elif _sound_enabled and _music_enabled and not AudioDirector._music_cue.is_empty():
		return
	elif _sound_enabled and _music_enabled and _music_started:
		AudioDirector.play_music("music.title")


func _play_sound(cue_id: String, pitch: float = 1.0) -> void:
	if _sound_enabled:
		AudioDirector.play_cue(cue_id, pitch)


func _start_game_music() -> void:
	if not _sound_enabled or not _music_enabled:
		return
	AudioDirector.unlock_audio()
	_music_started = AudioDirector.play_music("music.gameplay")


func _show_menu() -> void:
	get_tree().paused = false
	_phase = "idle"
	_actor_layer.visible = false
	_background.texture = TITLE_ART
	_wash.color = Color(0.035, 0.022, 0.075, 0.54)
	var page := _new_page("menu")
	var panel := ScreenFactory.panel(Color(0.035, 0.028, 0.075), Color(0.22, 0.23, 0.38, 0.55), Vector2(26, 22))
	_place(panel, 0.035, 0.06, 0.535, 0.95, Vector4(0, 0, 0, 0))
	page.add_child(panel)
	var title_one := _add_label(page, "CSM FIGHT", 62, Color("43e9ff"), Rect2(0.075, 0.105, 0.49, 0.205), "title")
	title_one.add_theme_color_override("font_shadow_color", Color(0.1, 0.75, 1.0, 0.55))
	title_one.add_theme_constant_override("shadow_offset_x", 0)
	title_one.add_theme_constant_override("shadow_offset_y", 5)
	_add_label(page, "KARO LITE", 58, Color("ff4eb5"), Rect2(0.075, 0.205, 0.49, 0.31), "title")
	_add_label(page, "FRIENDS BY DAY. ENEMIES IN THE ARENA.", 15, Color("e0d8f0"), Rect2(0.078, 0.31, 0.49, 0.37), "eyebrow")
	_add_label(page, "LOCAL 1V1  •  VS AI  •  PRACTICE", 13, Color("b4aacb"), Rect2(0.078, 0.37, 0.49, 0.415), "heading")
	var menu_actions: Array[Array] = [
		["PLAY NOW", Callable(self, "_show_selection")],
		["CHARACTER COLLECTION", Callable(self, "_show_collection")],
		["CUSTOMIZE FIGHTER", Callable(self, "_show_customize")],
		["HOW TO PLAY", Callable(self, "_show_howto")],
		["SETTINGS", Callable(self, "_show_settings")]
	]
	for index: int in menu_actions.size():
		var top := 0.445 + float(index) * 0.095
		_make_button(page, str(menu_actions[index][0]), Rect2(0.075, top, 0.485, top + 0.074), menu_actions[index][1], index == 0, Color("43e9ff") if index == 0 else Color("b58aff"))
	_add_label(page, "NO LOGIN  •  NO BACKEND  •  SESSION ONLY", 11, Color("a398b8"), Rect2(0.078, 0.94, 0.49, 0.98), "eyebrow")
	_add_label(page, "12 FIGHTERS  /  2 RIVAL GANGS", 13, Color("e9defb"), Rect2(0.58, 0.87, 0.96, 0.93), "eyebrow", true)
	_add_label(page, "Custom photos and match results stay in memory for this session.", 11, Color("bfb4d2"), Rect2(0.58, 0.92, 0.96, 0.97), "heading", true)


func _show_selection() -> void:
	_actor_layer.visible = false
	_background.texture = TITLE_ART
	_wash.color = Color(0.035, 0.022, 0.08, 0.84)
	var page := _new_page("selection")
	_add_label(page, "PICK YOUR SIDE", 36, Color("f8f4ff"), Rect2(0.04, 0.025, 0.70, 0.10), "title")
	_add_label(page, "Player 1 stays in CSM Gang. Player 2 / CPU stays in Opposite Gang.", 15, Color("cec3df"), Rect2(0.045, 0.105, 0.75, 0.155), "heading")
	_add_back_button(page, Callable(self, "_show_menu"), "← MENU")
	var left_panel := _new_panel(page, Rect2(0.035, 0.19, 0.49, 0.79), Color("43e9ff"))
	var right_panel := _new_panel(page, Rect2(0.51, 0.19, 0.965, 0.79), Color("ff4eb5"))
	_add_label(left_panel, "PLAYER 1   /   CSM GANG", 19, Color("43e9ff"), Rect2(0.035, 0.025, 0.96, 0.11), "eyebrow", true)
	_add_label(left_panel, "Selected: %s" % FighterRosterType.name_for_id(_selected_p1), 14, Color("f5f0ff"), Rect2(0.04, 0.11, 0.96, 0.17), "heading", true)
	_add_label(right_panel, "PLAYER 2   /   OPPOSITE GANG", 19, Color("ff77c8"), Rect2(0.035, 0.025, 0.965, 0.11), "eyebrow", true)
	_add_label(right_panel, "Selected: %s" % FighterRosterType.name_for_id(_selected_p2), 14, Color("f5f0ff"), Rect2(0.04, 0.11, 0.96, 0.17), "heading", true)
	var p1_grid := GridContainer.new()
	p1_grid.columns = 4
	p1_grid.add_theme_constant_override("h_separation", 8)
	p1_grid.add_theme_constant_override("v_separation", 9)
	_place(p1_grid, 0.035, 0.20, 0.97, 0.95, Vector4(0, 0, 0, -8))
	left_panel.add_child(p1_grid)
	for fighter_id: String in FighterRosterType.team_ids("csm"):
		var fighter := FighterRosterType.fighter_by_id(fighter_id)
		p1_grid.add_child(_fighter_card(fighter, 1, fighter_id == _selected_p1, Color("43e9ff")))
	var p2_grid := GridContainer.new()
	p2_grid.columns = 2
	p2_grid.add_theme_constant_override("h_separation", 14)
	p2_grid.add_theme_constant_override("v_separation", 12)
	_place(p2_grid, 0.08, 0.23, 0.92, 0.92)
	right_panel.add_child(p2_grid)
	for fighter_id: String in FighterRosterType.team_ids("opposite"):
		var fighter := FighterRosterType.fighter_by_id(fighter_id)
		p2_grid.add_child(_fighter_card(fighter, 2, fighter_id == _selected_p2, Color("ff4eb5")))
	_make_button(page, "CONTINUE TO GAME MODE  →", Rect2(0.34, 0.835, 0.67, 0.92), Callable(self, "_show_mode_selection"), true)
	_add_label(page, "Character choices are locked to each gang.", 12, Color("c3b8d5"), Rect2(0.35, 0.92, 0.65, 0.97), "heading", true)


func _new_panel(parent: Control, rect: Rect2, accent: Color) -> Control:
	var panel := ScreenFactory.holo_panel(accent, Vector2(17, 14))
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	_place(panel, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	parent.add_child(panel)
	var content := Control.new()
	content.mouse_filter = Control.MOUSE_FILTER_PASS
	ScreenFactory.full_rect(content)
	panel.add_child(content)
	return content


func _fighter_card(fighter: Dictionary, slot: int, selected: bool, accent: Color) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(118, 135)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_stylebox_override("normal", ScreenFactory.plate(Color(0.045, 0.042, 0.085, 0.9), Color(accent, 0.9 if selected else 0.32), Color(accent, 0.12 if selected else 0.025), 0.08))
	button.add_theme_stylebox_override("hover", ScreenFactory.plate(Color(0.10, 0.07, 0.15, 0.98), Color(accent, 0.92), Color(accent, 0.18), 0.08))
	button.add_theme_stylebox_override("focus", ScreenFactory.plate(Color.TRANSPARENT, accent, Color(accent, 0.2), 0.08))
	var art := TextureRect.new()
	var path := str(fighter.get("avatar", ""))
	if ResourceLoader.exists(path):
		art.texture = load(path) as Texture2D
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_place(art, 0.06, 0.04, 0.94, 0.69)
	button.add_child(art)
	var name_label := ScreenFactory.display_label(str(fighter.get("name", "Fighter")), 14, Color("f8f4ff"), "heading")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(name_label, 0.025, 0.69, 0.975, 0.88)
	button.add_child(name_label)
	var move_label := ScreenFactory.label(str(fighter.get("signature", "Special")), 9, accent)
	move_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	move_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	move_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(move_label, 0.04, 0.87, 0.96, 0.99)
	button.add_child(move_label)
	button.pressed.connect(_on_user_gesture)
	button.pressed.connect(Callable(self, "_choose_character").bind(slot, str(fighter.id)))
	AudioDirector.register_button(button)
	return button


func _choose_character(slot: int, fighter_id: String) -> void:
	if slot == 1:
		if fighter_id not in FighterRosterType.team_ids("csm"):
			return
		_selected_p1 = fighter_id
	else:
		if fighter_id not in FighterRosterType.team_ids("opposite"):
			return
		_selected_p2 = fighter_id
	_show_selection()


func _show_mode_selection() -> void:
	_actor_layer.visible = false
	_wash.color = Color(0.035, 0.022, 0.08, 0.84)
	var page := _new_page("mode")
	_add_label(page, "CHOOSE YOUR FIGHT", 38, Color("f8f4ff"), Rect2(0.05, 0.035, 0.70, 0.12), "title")
	_add_back_button(page, Callable(self, "_show_selection"))
	_add_label(page, "%s  vs  %s" % [FighterRosterType.name_for_id(_selected_p1), FighterRosterType.name_for_id(_selected_p2)], 19, Color("f3e8ff"), Rect2(0.14, 0.15, 0.86, 0.21), "heading", true)
	var options: Array[Dictionary] = [
		{"id":"local", "title":"LOCAL 1V1", "body":"Two friends. One keyboard. No excuses.", "color":Color("43e9ff")},
		{"id":"cpu", "title":"VS AI", "body":"You as Player 1; your picked rival as CPU.", "color":Color("ff4eb5")},
		{"id":"practice", "title":"PRACTICE", "body":"Test hits, blocks, jumps and specials.", "color":Color("b68aff")}
	]
	for index: int in options.size():
		var item: Dictionary = options[index]
		var left := 0.065 + float(index) * 0.30
		var tile := _new_panel(page, Rect2(left, 0.27, left + 0.27, 0.72), item.color)
		_add_label(tile, str(item.title), 21, item.color, Rect2(0.05, 0.08, 0.95, 0.22), "eyebrow", true)
		_add_label(tile, str(item.body), 16, Color("ded5ec"), Rect2(0.08, 0.30, 0.92, 0.59), "heading", true)
		var action := Callable(self, "_select_mode").bind(str(item.id))
		_make_button(tile, "SELECT", Rect2(0.10, 0.72, 0.90, 0.90), action, str(item.id) == _mode, item.color)
	_add_label(page, "VS AI difficulty", 15, Color("f3e8ff"), Rect2(0.28, 0.77, 0.48, 0.84), "eyebrow", true)
	var difficulty := OptionButton.new()
	for value: String in ["Easy", "Normal", "Hard"]:
		difficulty.add_item(value)
	difficulty.select(1 if _difficulty == "Normal" else (0 if _difficulty == "Easy" else 2))
	difficulty.custom_minimum_size = Vector2(180, 40)
	_place(difficulty, 0.48, 0.765, 0.63, 0.84)
	page.add_child(difficulty)
	difficulty.item_selected.connect(func(index: int) -> void: _difficulty = ["Easy", "Normal", "Hard"][index])
	_make_button(page, "START MATCH  →", Rect2(0.36, 0.865, 0.64, 0.94), Callable(self, "_start_match"), true)
	_add_label(page, "Best of 3 rounds  •  60 seconds each  •  100 HP", 12, Color("bdb1cd"), Rect2(0.34, 0.945, 0.66, 0.98), "heading", true)


func _select_mode(mode_id: String) -> void:
	if mode_id in ["local", "cpu", "practice"]:
		_mode = mode_id
	_show_mode_selection()


func _show_collection() -> void:
	_actor_layer.visible = false
	_wash.color = Color(0.035, 0.022, 0.08, 0.88)
	var page := _new_page("collection")
	_add_label(page, "THE COLLECTION", 38, Color("f8f4ff"), Rect2(0.05, 0.035, 0.70, 0.12), "title")
	_add_label(page, "Twelve personalities. Two locked rival rosters. One campus worth of banter.", 14, Color("cec3df"), Rect2(0.055, 0.13, 0.80, 0.18), "heading")
	_add_back_button(page, Callable(self, "_show_menu"), "← MENU")
	var team_rows := [
		{"title":"CSM GANG", "ids":FighterRosterType.team_ids("csm"), "color":Color("43e9ff"), "left":0.035, "right":0.50},
		{"title":"OPPOSITE GANG", "ids":FighterRosterType.team_ids("opposite"), "color":Color("ff4eb5"), "left":0.515, "right":0.965}
	]
	for team: Dictionary in team_rows:
		var panel := _new_panel(page, Rect2(float(team.left), 0.22, float(team.right), 0.88), team.color)
		_add_label(panel, str(team.title), 20, team.color, Rect2(0.035, 0.025, 0.965, 0.10), "eyebrow", true)
		var scroll := ScrollContainer.new()
		_place(scroll, 0.035, 0.12, 0.965, 0.98, Vector4(0, 0, 0, -6))
		panel.add_child(scroll)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 10)
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(column)
		var ids: Array = team.ids
		var item_cols := HFlowContainer.new()
		item_cols.add_theme_constant_override("h_separation", 8)
		item_cols.add_theme_constant_override("v_separation", 8)
		item_cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_child(item_cols)
		for fighter_id: String in ids:
			var fighter := FighterRosterType.fighter_by_id(fighter_id)
			item_cols.add_child(_collection_card(fighter, team.color))


func _collection_card(fighter: Dictionary, accent: Color) -> Control:
	var card := ScreenFactory.panel(Color(0.04, 0.04, 0.085), Color(accent, 0.24), Vector2(12, 8))
	card.custom_minimum_size = Vector2(198, 184)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	card.add_child(column)
	var art := TextureRect.new()
	art.texture = load(str(fighter.avatar)) as Texture2D
	art.custom_minimum_size = Vector2(0, 95)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	column.add_child(art)
	var name_label := ScreenFactory.display_label(str(fighter.name), 16, Color("f8f4ff"), "heading")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(name_label)
	var move_label := ScreenFactory.label(str(fighter.signature), 11, accent)
	move_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(move_label)
	var custom_button := ScreenFactory.quiet_button("CUSTOMIZE", 11)
	custom_button.pressed.connect(_on_user_gesture)
	custom_button.pressed.connect(Callable(self, "_customize_fighter").bind(str(fighter.id)))
	column.add_child(custom_button)
	return card


func _customize_fighter(fighter_id: String) -> void:
	_custom_id = fighter_id
	_show_customize()


func _show_customize() -> void:
	_actor_layer.visible = false
	_wash.color = Color(0.035, 0.022, 0.08, 0.90)
	var page := _new_page("customize")
	_add_label(page, "MAKE IT YOUR FIGHTER", 34, Color("f8f4ff"), Rect2(0.05, 0.03, 0.73, 0.105), "title")
	_add_label(page, "All photos, voice clips and custom taunts stay in this tab's memory; nothing is uploaded or saved.", 13, Color("cdbfdc"), Rect2(0.055, 0.112, 0.81, 0.165), "heading")
	_add_back_button(page, Callable(self, "_show_menu"), "← MENU")
	var selector := OptionButton.new()
	for fighter: Dictionary in _roster:
		selector.add_item("%s  •  %s" % [fighter.name, fighter.team])
	var selection_index := 0
	for index: int in _roster.size():
		if str(_roster[index].id) == _custom_id:
			selection_index = index
	selector.select(selection_index)
	_place(selector, 0.055, 0.20, 0.47, 0.255)
	page.add_child(selector)
	selector.item_selected.connect(_on_custom_character_chosen)
	var portrait_panel := _new_panel(page, Rect2(0.055, 0.29, 0.38, 0.82), Color("43e9ff"))
	_add_label(portrait_panel, "SESSION FACE CARD", 15, Color("43e9ff"), Rect2(0.05, 0.035, 0.95, 0.12), "eyebrow", true)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", ScreenFactory.style_box(Color(0.02, 0.018, 0.04), Color("43e9ff"), 18, 2))
	_place(frame, 0.12, 0.16, 0.88, 0.72)
	portrait_panel.add_child(frame)
	var crop_view := Control.new()
	crop_view.clip_contents = true
	crop_view.custom_minimum_size = Vector2(220, 220)
	frame.add_child(crop_view)
	_photo_preview = TextureRect.new()
	_photo_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_photo_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_photo_preview.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_photo_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_photo_preview.size = Vector2(272, 272)
	_photo_preview.position = Vector2(-26, -26)
	crop_view.add_child(_photo_preview)
	_photo_name_label = _add_label(portrait_panel, "Default fighter art", 11, Color("cbc0da"), Rect2(0.08, 0.74, 0.92, 0.82), "heading", true)
	var photo_button := _make_button(page, "CHOOSE PHOTO", Rect2(0.43, 0.31, 0.69, 0.38), Callable(self, "_open_photo_picker"), true)
	photo_button.add_theme_font_size_override("font_size", 13)
	_make_button(page, "APPLY FACE CARD", Rect2(0.70, 0.31, 0.94, 0.38), Callable(self, "_apply_photo"), false)
	_make_button(page, "REMOVE PHOTO", Rect2(0.70, 0.39, 0.94, 0.46), Callable(self, "_remove_photo"), false, Color("ff9b8e"))
	_add_label(page, "Crop / position X", 12, Color("f3e8ff"), Rect2(0.44, 0.42, 0.59, 0.47), "eyebrow")
	_crop_x_slider = _make_slider(page, Rect2(0.59, 0.425, 0.93, 0.47), _draft_crop.x)
	_add_label(page, "Crop / position Y", 12, Color("f3e8ff"), Rect2(0.44, 0.49, 0.59, 0.54), "eyebrow")
	_crop_y_slider = _make_slider(page, Rect2(0.59, 0.495, 0.93, 0.54), _draft_crop.y)
	_crop_x_slider.value_changed.connect(func(value: float) -> void: _draft_crop.x = value; _refresh_face_preview())
	_crop_y_slider.value_changed.connect(func(value: float) -> void: _draft_crop.y = value; _refresh_face_preview())
	_add_label(page, "Optional recorded voice clip (.wav, .ogg or .mp3)", 13, Color("f3e8ff"), Rect2(0.43, 0.575, 0.92, 0.625), "eyebrow")
	_make_button(page, "ADD / REPLACE VOICE", Rect2(0.43, 0.64, 0.69, 0.71), Callable(self, "_open_voice_picker"), false, Color("b68aff"))
	_make_button(page, "REMOVE VOICE", Rect2(0.70, 0.64, 0.94, 0.71), Callable(self, "_remove_voice"), false, Color("ff9b8e"))
	_add_label(page, "Custom Special Taunt", 13, Color("f3e8ff"), Rect2(0.43, 0.735, 0.69, 0.79), "eyebrow")
	_dialogue_input = LineEdit.new()
	_dialogue_input.placeholder_text = "Add a funny Telugu-English line…"
	_dialogue_input.max_length = 88
	_dialogue_input.text = str(_custom_dialogue.get(_custom_id, ""))
	_place(_dialogue_input, 0.43, 0.79, 0.78, 0.85)
	page.add_child(_dialogue_input)
	_make_button(page, "SAVE TAUNT", Rect2(0.79, 0.79, 0.94, 0.85), Callable(self, "_save_custom_dialogue"), false, Color("43e9ff"))
	_add_label(page, "RAM only  •  never uploaded  •  clears when this session ends", 11, Color("b5aac5"), Rect2(0.43, 0.89, 0.94, 0.94), "heading", true)
	_refresh_face_preview()


func _make_slider(parent: Control, rect: Rect2, value: float) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = -1.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = value
	_place(slider, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	parent.add_child(slider)
	return slider


func _on_custom_character_chosen(index: int) -> void:
	if index >= 0 and index < _roster.size():
		_custom_id = str(_roster[index].id)
		_draft_image = null
		_draft_crop = Vector2.ZERO
		_show_customize()


func _refresh_face_preview() -> void:
	if not is_instance_valid(_photo_preview):
		return
	var fighter := FighterRosterType.fighter_by_id(_custom_id)
	if _draft_image != null and not _draft_image.is_empty():
		_photo_preview.texture = ImageTexture.create_from_image(_draft_image)
		_photo_preview.position = Vector2(-26 - _draft_crop.x * 32.0, -26 - _draft_crop.y * 32.0)
		_photo_name_label.text = "Photo preview — move sliders to crop"
	elif _custom_faces.has(_custom_id):
		_photo_preview.texture = _custom_faces[_custom_id]
		_photo_preview.position = Vector2(-26, -26)
		_photo_name_label.text = "Custom face card active in this session"
	else:
		_photo_preview.texture = load(str(fighter.avatar)) as Texture2D
		_photo_preview.position = Vector2(-26, -26)
		_photo_name_label.text = "Default fighter art"


func _open_photo_picker() -> void:
	_open_upload("photo")


func _open_voice_picker() -> void:
	_open_upload("voice")


func _open_upload(kind: String) -> void:
	_upload_kind = kind
	if OS.has_feature("web"):
		var window := JavaScriptBridge.get_interface("window")
		window.set("__csmUploadResult", JavaScriptBridge.create_callback(Callable(self, "_on_browser_file_selected")))
		var accept := "image/png,image/jpeg,image/webp" if kind == "photo" else "audio/wav,audio/ogg,audio/mpeg,.wav,.ogg,.mp3"
		var kind_json := JSON.stringify(kind)
		var accept_json := JSON.stringify(accept)
		var script := """
		(() => {
		  const pick = document.createElement('input');
		  pick.type = 'file'; pick.accept = %s;
		  pick.style.position = 'fixed'; pick.style.left = '-10000px';
		  const finish = (payload) => { const cb = window.__csmUploadResult; if (cb) cb(payload); delete window.__csmUploadResult; pick.remove(); };
		  pick.onchange = () => {
		    const file = pick.files && pick.files[0];
		    if (!file) { finish(''); return; }
		    if (file.size > %d) { finish('ERROR:SIZE'); return; }
		    const allowed = %s === 'photo' ? ['image/png','image/jpeg','image/webp'] : ['audio/wav','audio/x-wav','audio/ogg','audio/mpeg','audio/mp3'];
		    if (!allowed.includes(file.type) && !/\\.(png|jpe?g|webp|wav|ogg|mp3)$/i.test(file.name)) { finish('ERROR:TYPE'); return; }
		    const reader = new FileReader();
		    reader.onerror = () => finish('ERROR:READ');
		    reader.onload = () => finish(JSON.stringify({ name:file.name, mime:file.type, data:reader.result }));
		    reader.readAsDataURL(file);
		  };
		  document.body.appendChild(pick); pick.click();
		})();
		""" % [accept_json, MAX_UPLOAD_BYTES, kind_json]
		JavaScriptBridge.eval(script, true)
		return
	_file_dialog = FileDialog.new()
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.use_native_dialog = false
	_file_dialog.title = "Choose a session-only %s" % ("photo" if kind == "photo" else "voice recording")
	_file_dialog.filters = PackedStringArray(["*.png, *.jpg, *.jpeg, *.webp ; Images"] if kind == "photo" else ["*.wav, *.ogg, *.mp3 ; Audio recordings"])
	_file_dialog.file_selected.connect(_on_native_file_selected)
	_file_dialog.canceled.connect(func() -> void: if is_instance_valid(_file_dialog): _file_dialog.queue_free())
	add_child(_file_dialog)
	_file_dialog.popup_centered_ratio(0.78)


func _on_browser_file_selected(payload: Variant) -> void:
	var raw := str(payload)
	if raw.is_empty():
		return
	if raw.begins_with("ERROR:"):
		var message := "File is too large (6 MB maximum)." if raw == "ERROR:SIZE" else "Unsupported file; use PNG/JPG/WEBP for photos or WAV/OGG/MP3 for audio."
		_show_dialog_notice(message)
		return
	var parsed: Variant = JSON.parse_string(raw)
	if not parsed is Dictionary:
		_show_dialog_notice("That file could not be read.")
		return
	var data_uri := str(parsed.get("data", ""))
	var comma := data_uri.find(",")
	if comma < 0:
		_show_dialog_notice("That file could not be decoded.")
		return
	var bytes := Marshalls.base64_to_raw(data_uri.substr(comma + 1))
	_process_upload(str(parsed.get("name", "photo")), str(parsed.get("mime", "")), bytes)


func _on_native_file_selected(path: String) -> void:
	var bytes := FileAccess.get_file_as_bytes(path)
	_process_upload(path.get_file(), path.get_extension().to_lower(), bytes)
	if is_instance_valid(_file_dialog):
		_file_dialog.queue_free()


func _process_upload(file_name: String, mime: String, bytes: PackedByteArray) -> void:
	if bytes.is_empty() or bytes.size() > MAX_UPLOAD_BYTES:
		_show_dialog_notice("Choose a file smaller than 6 MB.")
		return
	if _upload_kind == "photo":
		var image := Image.new()
		var error := ERR_FILE_UNRECOGNIZED
		var kind := mime.to_lower()
		if kind.contains("png") or file_name.to_lower().ends_with(".png"):
			error = image.load_png_from_buffer(bytes)
		elif kind.contains("webp") or file_name.to_lower().ends_with(".webp"):
			error = image.load_webp_from_buffer(bytes)
		else:
			error = image.load_jpg_from_buffer(bytes)
		if error != OK or image.is_empty():
			_show_dialog_notice("That photo could not be opened.")
			return
		var longest := maxi(image.get_width(), image.get_height())
		if longest > 1200:
			var factor := 1200.0 / float(longest)
			image.resize(maxi(1, roundi(image.get_width() * factor)), maxi(1, roundi(image.get_height() * factor)), Image.INTERPOLATE_LANCZOS)
		_draft_image = image
		if is_instance_valid(_photo_name_label):
			_photo_name_label.text = "%s — preview only" % file_name.get_basename().left(24)
		_refresh_face_preview()
		return
	var extension := file_name.get_extension().to_lower()
	var stream: AudioStream
	if extension == "wav" or mime.contains("wav"):
		stream = AudioStreamWAV.load_from_buffer(bytes)
	elif extension == "ogg" or mime.contains("ogg"):
		stream = AudioStreamOggVorbis.load_from_buffer(bytes)
	elif extension == "mp3" or mime.contains("mpeg") or mime.contains("mp3"):
		stream = AudioStreamMP3.load_from_buffer(bytes)
	if stream == null:
		_show_dialog_notice("That voice recording could not be opened.")
		return
	_custom_voice[_custom_id] = stream
	_show_dialog_notice("Recorded voice added for %s — RAM only." % FighterRosterType.name_for_id(_custom_id))


func _create_circular_face(source: Image, crop: Vector2) -> Texture2D:
	if source == null or source.is_empty():
		return null
	var side := mini(source.get_width(), source.get_height())
	var x_room := source.get_width() - side
	var y_room := source.get_height() - side
	var origin_x := clampi(roundi(float(x_room) * (0.5 + crop.x * 0.5)), 0, x_room)
	var origin_y := clampi(roundi(float(y_room) * (0.5 + crop.y * 0.5)), 0, y_room)
	var cropped := Image.create(side, side, false, Image.FORMAT_RGBA8)
	for y: int in side:
		for x: int in side:
			cropped.set_pixel(x, y, source.get_pixel(origin_x + x, origin_y + y))
	cropped.resize(128, 128, Image.INTERPOLATE_LANCZOS)
	var center := Vector2(63.5, 63.5)
	for y: int in 128:
		for x: int in 128:
			if Vector2(float(x), float(y)).distance_to(center) > 62.5:
				var pixel := cropped.get_pixel(x, y)
				pixel.a = 0.0
				cropped.set_pixel(x, y, pixel)
	return ImageTexture.create_from_image(cropped)


func _apply_photo() -> void:
	if _draft_image == null or _draft_image.is_empty():
		_show_dialog_notice("Choose a photo first.")
		return
	var crop := Vector2(_crop_x_slider.value if is_instance_valid(_crop_x_slider) else _draft_crop.x, _crop_y_slider.value if is_instance_valid(_crop_y_slider) else _draft_crop.y)
	_custom_faces[_custom_id] = _create_circular_face(_draft_image, crop)
	_draft_image = null
	_draft_crop = crop
	_refresh_face_preview()
	if is_instance_valid(_actor_one) and str(_actor_one.fighter.id) == _custom_id:
		_actor_one.set_face_texture(_custom_faces[_custom_id])
	if is_instance_valid(_actor_two) and str(_actor_two.fighter.id) == _custom_id:
		_actor_two.set_face_texture(_custom_faces[_custom_id])
	_show_dialog_notice("Face card applied for %s. It stays in memory for this session." % FighterRosterType.name_for_id(_custom_id))


func _remove_photo() -> void:
	_custom_faces.erase(_custom_id)
	_draft_image = null
	_refresh_face_preview()
	if is_instance_valid(_actor_one) and str(_actor_one.fighter.id) == _custom_id:
		_actor_one.set_face_texture(null)
	if is_instance_valid(_actor_two) and str(_actor_two.fighter.id) == _custom_id:
		_actor_two.set_face_texture(null)


func _remove_voice() -> void:
	_custom_voice.erase(_custom_id)
	_show_dialog_notice("Custom voice removed for %s." % FighterRosterType.name_for_id(_custom_id))


func _save_custom_dialogue() -> void:
	if not is_instance_valid(_dialogue_input):
		return
	var line := _dialogue_input.text.strip_edges()
	if line.is_empty():
		_custom_dialogue.erase(_custom_id)
	else:
		_custom_dialogue[_custom_id] = line
	_show_dialog_notice("Special taunt saved for %s — session only." % FighterRosterType.name_for_id(_custom_id))


func _show_dialog_notice(message: String) -> void:
	var toast := ScreenFactory.panel(Color(0.035, 0.03, 0.075, 0.98), Color("43e9ff"), Vector2(18, 12))
	toast.z_index = 20
	var label := ScreenFactory.label(message, 13, Color("f4eaff"))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast.add_child(label)
	_place(toast, 0.24, 0.83, 0.76, 0.94)
	_page.add_child(toast)
	var timer := get_tree().create_timer(2.0)
	timer.timeout.connect(func() -> void: if is_instance_valid(toast): toast.queue_free())


func _show_howto() -> void:
	_actor_layer.visible = false
	_wash.color = Color(0.025, 0.02, 0.065, 0.92)
	var page := _new_page("howto")
	_add_label(page, "HOW TO PLAY", 40, Color("f8f4ff"), Rect2(0.055, 0.045, 0.70, 0.13), "title")
	_add_back_button(page, Callable(self, "_show_menu"), "← MENU")
	var controls := _new_panel(page, Rect2(0.05, 0.19, 0.52, 0.87), Color("43e9ff"))
	var rules := _new_panel(page, Rect2(0.56, 0.19, 0.95, 0.87), Color("ff4eb5"))
	_add_label(controls, "PLAYER 1  /  CSM GANG", 17, Color("43e9ff"), Rect2(0.06, 0.04, 0.94, 0.12), "eyebrow")
	_add_label(controls, "A / D       MOVE\nW             JUMP\nF               PUNCH  •  9 damage\nG              KICK  •  15 damage\nS              BLOCK  •  reduce damage\nH              SIGNATURE SPECIAL  •  25 damage\n\nPLAYER 2  /  OPPOSITE GANG\n← / →       MOVE\n↑              JUMP\nK              PUNCH     •     L  KICK\n↓              BLOCK\n;               SIGNATURE SPECIAL", 16, Color("f2eaff"), Rect2(0.07, 0.15, 0.95, 0.91), "heading")
	_add_label(rules, "THE RULES", 18, Color("ff77c8"), Rect2(0.06, 0.04, 0.94, 0.12), "eyebrow")
	_add_label(rules, "BEST OF THREE\nWin two rounds. Each round lasts 60 seconds.\n\nSPECIAL ENERGY\nLand punches or kicks to fill your energy. Save up for the fighter's signature attack.\n\nBLOCK, JUMP, REPEAT\nBlocking reduces incoming damage. Jump to avoid ground attacks. Stay inside the arena.\n\nGAME MODES\nLOCAL 1V1: Two people share a keyboard.\nVS AI: Choose your Opposite Gang rival and difficulty.\nPRACTICE: A stationary opponent; hits reset for repeat practice.\n\nMOBILE\nUse the on-screen movement and combat buttons.\n\nNo online accounts. Photos and results live in memory for this session only.", 15, Color("f2eaff"), Rect2(0.07, 0.16, 0.94, 0.94), "heading")
	_make_button(page, "GOT IT  →", Rect2(0.39, 0.90, 0.61, 0.97), Callable(self, "_show_menu"), true)


func _show_settings() -> void:
	_actor_layer.visible = false
	_wash.color = Color(0.025, 0.02, 0.065, 0.90)
	var page := _new_page("settings")
	_add_label(page, "ARCADE SETTINGS", 40, Color("f8f4ff"), Rect2(0.06, 0.05, 0.72, 0.14), "title")
	_add_back_button(page, Callable(self, "_show_menu"), "← MENU")
	var panel := _new_panel(page, Rect2(0.20, 0.22, 0.80, 0.78), Color("b68aff"))
	_add_label(panel, "All preferences reset when this session ends.", 14, Color("cec3df"), Rect2(0.08, 0.09, 0.92, 0.17), "heading", true)
	_make_button(panel, "SOUND: %s" % ("ON" if _sound_enabled else "OFF"), Rect2(0.17, 0.25, 0.83, 0.36), Callable(self, "_toggle_sound"), _sound_enabled, Color("43e9ff"))
	_make_button(panel, "MUSIC: %s" % ("ON" if _music_enabled else "OFF"), Rect2(0.17, 0.41, 0.83, 0.52), Callable(self, "_toggle_music"), _music_enabled, Color("b68aff"))
	_make_button(panel, "TELUGU VOICE: %s" % ("ON" if _voice_enabled else "OFF"), Rect2(0.17, 0.57, 0.83, 0.68), Callable(self, "_toggle_voice"), _voice_enabled, Color("ff4eb5"))
	_add_label(panel, "Personal photos are never uploaded and no game data is written to storage.", 13, Color("c1b5cf"), Rect2(0.06, 0.76, 0.94, 0.88), "heading", true)


func _toggle_sound() -> void:
	_sound_enabled = not _sound_enabled
	if not _sound_enabled:
		AudioDirector.stop_music(0.0)
		_music_started = false
	_show_settings()


func _toggle_music() -> void:
	_music_enabled = not _music_enabled
	if _music_enabled and _sound_enabled:
		_on_user_gesture()
	elif not _music_enabled:
		AudioDirector.stop_music()
		_music_started = false
	_show_settings()


func _toggle_voice() -> void:
	_voice_enabled = not _voice_enabled
	if not _voice_enabled and is_instance_valid(_voice_player):
		_voice_player.stop()
	_show_settings()


func _pick_quip(fighter: Dictionary, kind: String) -> String:
	var fighter_id := str(fighter.get("id", ""))
	if kind == "special" and _custom_dialogue.has(fighter_id):
		return str(_custom_dialogue[fighter_id])
	var quips: Dictionary = fighter.get("quips", {})
	var lines: Array = quips.get(kind, quips.get("start", ["Naa range veru ra!"]))
	if lines.is_empty():
		return "Naa range veru ra!"
	var pick: String = str(lines[_rng.randi_range(0, lines.size() - 1)])
	if pick == _last_dialogue and lines.size() > 1:
		pick = str(lines[(lines.find(pick) + 1) % lines.size()])
	return pick


func _set_dialogue(line: String, fighter: Dictionary, duration: float = 1.6, voice: bool = true) -> void:
	_last_dialogue = line
	_dialogue_time = duration
	if is_instance_valid(_hud_dialogue):
		_hud_dialogue.text = line
	if not voice or not _sound_enabled or not _voice_enabled:
		return
	var fighter_id := str(fighter.get("id", ""))
	if _custom_voice.has(fighter_id):
		_voice_player.stream = _custom_voice[fighter_id]
		_voice_player.play()
		return
	var voice_path := str(VOICE_PATHS.get(line, ""))
	if not voice_path.is_empty() and ResourceLoader.exists(voice_path):
		_voice_player.stream = load(voice_path) as AudioStream
		_voice_player.play()


func _start_match() -> void:
	if _selected_p1 not in FighterRosterType.team_ids("csm") or _selected_p2 not in FighterRosterType.team_ids("opposite"):
		return
	get_tree().paused = false
	_phase = "countdown"
	_countdown = 4.4
	_match_winner = -1
	_round_wins = [0, 0]
	_round_number = 1
	for child: Node in _actor_layer.get_children():
		child.queue_free()
	_actor_layer.visible = true
	var viewport_size := get_viewport_rect().size
	var portrait := viewport_size.y > viewport_size.x * 1.15
	var render_scale := 0.68 if portrait else 0.78
	_actor_one = FighterActorType.new()
	_actor_one.name = "PlayerOne"
	_actor_one.setup(FighterRosterType.fighter_by_id(_selected_p1), 1, render_scale)
	_actor_two = FighterActorType.new()
	_actor_two.name = "PlayerTwo"
	_actor_two.setup(FighterRosterType.fighter_by_id(_selected_p2), 2, render_scale)
	_actor_layer.add_child(_actor_one)
	_actor_layer.add_child(_actor_two)
	_apply_face_to_actor(_actor_one)
	_apply_face_to_actor(_actor_two)
	_background.texture = ARENA_ART
	_wash.color = Color(0.035, 0.025, 0.085, 0.35)
	_fx_particles.clear()
	_build_arena_hud()
	_layout_fighters()
	_start_game_music()
	_round_timer = FightRulesType.ROUND_DURATION_SECONDS
	_phase = "countdown"
	_low_health_seen = [false, false]
	_attack_cooldowns = [0.0, 0.0]
	_jump_heights = [0.0, 0.0]
	_jump_speeds = [0.0, 0.0]
	_knockback_speeds = [0.0, 0.0]
	_cpu_decision_timer = 0.55
	_cpu_block_timer = 0.0
	_set_dialogue("Orey, internal exam anukunnava?", _actor_one.fighter, 2.0, true)


func _apply_face_to_actor(actor: FighterActor) -> void:
	var fighter_id := str(actor.fighter.get("id", ""))
	if _custom_faces.has(fighter_id):
		actor.set_face_texture(_custom_faces[fighter_id])


func _layout_fighters() -> void:
	if not is_instance_valid(_actor_one) or not is_instance_valid(_actor_two):
		return
	var size := get_viewport_rect().size
	var portrait := size.y > size.x * 1.15
	_ground_y = size.y * (0.56 if portrait else 0.73)
	_actor_one.position = Vector2(size.x * 0.34, _ground_y)
	_actor_two.position = Vector2(size.x * 0.66, _ground_y)
	if is_instance_valid(_fx_layer):
		_fx_layer.queue_redraw()


func _build_arena_hud() -> void:
	var page := _new_page("arena")
	_page.process_mode = Node.PROCESS_MODE_ALWAYS
	_page.z_index = 6
	_hud_timer = _add_label(page, "60", 31, Color("fff7f0"), Rect2(0.44, 0.025, 0.56, 0.10), "title", true)
	_hud_round = _add_label(page, "ROUND 1  •  0 — 0", 13, Color("e1d4f4"), Rect2(0.37, 0.105, 0.63, 0.15), "eyebrow", true)
	_build_player_hud(page, 0)
	_build_player_hud(page, 1)
	_build_versus_splash(page)
	_hud_dialogue = _add_label(page, "", 19, Color("fff4ff"), Rect2(0.16, 0.65, 0.84, 0.74), "heading", true)
	_hud_pause_button = _make_button(page, "Ⅱ  PAUSE", Rect2(0.86, 0.19, 0.985, 0.255), Callable(self, "_toggle_pause"), false, Color("ff4eb5"))
	_hud_pause_button.add_theme_font_size_override("font_size", 11)
	if _should_show_touch_controls():
		_add_label(page, "HOLD TO MOVE  •  TAP TO JUMP / ATTACK  •  SPECIAL NEEDS FULL ENERGY", 9, Color("e7dbf2"), Rect2(0.08, 0.91, 0.92, 0.97), "heading", true)
	else:
		_add_label(page, "P1  A/D move  •  W jump  •  F/G attack  •  S block  •  H special", 10, Color("e7dbf2"), Rect2(0.025, 0.895, 0.58, 0.94), "heading")
		if _mode == "local":
			_add_label(page, "P2  ←/→ move  •  ↑ jump  •  K/L attack  •  ↓ block  •  ; special", 10, Color("e7dbf2"), Rect2(0.42, 0.895, 0.96, 0.94), "heading", true)
		else:
			_add_label(page, "P2 / CPU: %s  •  %s" % [FighterRosterType.name_for_id(_selected_p2), "PRACTICE DUMMY" if _mode == "practice" else "%s AI" % _difficulty.to_upper()], 10, Color("e7dbf2"), Rect2(0.42, 0.895, 0.96, 0.94), "heading", true)
	_touch_pad = _build_touch_controls(page)
	_touch_pad.visible = _should_show_touch_controls()


func _build_versus_splash(parent: Control) -> void:
	_vs_overlay = Control.new()
	_vs_overlay.name = "VersusSplash"
	_vs_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vs_overlay.z_index = 1
	ScreenFactory.full_rect(_vs_overlay)
	_vs_overlay.visible = _phase == "countdown" and _countdown > 3.0
	parent.add_child(_vs_overlay)
	var panel := _new_panel(_vs_overlay, Rect2(0.035, 0.31, 0.965, 0.52), Color("b68aff"))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var compact := get_viewport_rect().size.x < 620.0
	var name_size := 16 if compact else 25
	var p1 := FighterRosterType.fighter_by_id(_selected_p1)
	var p2 := FighterRosterType.fighter_by_id(_selected_p2)
	_add_label(panel, "PLAYER 1  •  CSM GANG", 9, Color("43e9ff"), Rect2(0.02, 0.10, 0.43, 0.30), "eyebrow", true)
	_add_label(panel, str(p1.name).to_upper(), name_size, Color("f8f4ff"), Rect2(0.02, 0.30, 0.43, 0.66), "title", true)
	_add_label(panel, str(p1.signature), 10, Color("bcefff"), Rect2(0.02, 0.68, 0.43, 0.94), "heading", true)
	_add_label(panel, "VS", 38 if compact else 52, Color("ff4eb5"), Rect2(0.43, 0.18, 0.57, 0.82), "title", true)
	_add_label(panel, "PLAYER 2  •  OPPOSITE GANG", 9, Color("ff74c5"), Rect2(0.57, 0.10, 0.98, 0.30), "eyebrow", true)
	_add_label(panel, str(p2.name).to_upper(), name_size, Color("f8f4ff"), Rect2(0.57, 0.30, 0.98, 0.66), "title", true)
	_add_label(panel, str(p2.signature), 10, Color("ffd0e9"), Rect2(0.57, 0.68, 0.98, 0.94), "heading", true)


func _build_player_hud(parent: Control, player_index: int) -> void:
	var left := 0.025 if player_index == 0 else 0.60
	var right := 0.405 if player_index == 0 else 0.98
	var accent := Color("43e9ff") if player_index == 0 else Color("ff4eb5")
	var actor := _actor_one if player_index == 0 else _actor_two
	var panel := _new_panel(parent, Rect2(left, 0.035, right, 0.19), accent)
	_add_label(panel, "%s   /   %s" % [actor.fighter.name, actor.fighter.team], 15, accent, Rect2(0.035, 0.055, 0.965, 0.29), "eyebrow", player_index == 1)
	var health := _new_progress_bar(accent)
	_place(health, 0.06, 0.38, 0.94, 0.58)
	panel.add_child(health)
	var energy := _new_progress_bar(Color("b68aff"))
	_place(energy, 0.06, 0.70, 0.94, 0.87)
	panel.add_child(energy)
	_add_label(panel, "HP", 10, Color("f5edff"), Rect2(0.06, 0.58, 0.17, 0.71), "eyebrow")
	_add_label(panel, "%s  /  100" % actor.fighter.signature, 10, Color("e0d4f3"), Rect2(0.18, 0.58, 0.94, 0.71), "heading", player_index == 1)
	if player_index == 0:
		_hud_health_one = health
		_hud_energy_one = energy
	else:
		_hud_health_two = health
		_hud_energy_two = energy


func _new_progress_bar(accent: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = 100
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", ScreenFactory.style_box(Color(0.018, 0.018, 0.035, 0.94), Color(1, 1, 1, 0.12), 8, 1))
	bar.add_theme_stylebox_override("fill", ScreenFactory.style_box(accent, Color(accent, 0.95), 8, 1))
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return bar


func _build_touch_controls(parent: Control) -> Control:
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_PASS
	ScreenFactory.full_rect(holder)
	parent.add_child(holder)
	var controls: Array[Dictionary] = [
		{"text":"◀", "action":"left", "left":0.025, "right":0.13},
		{"text":"▶", "action":"right", "left":0.14, "right":0.245},
		{"text":"JUMP", "action":"jump", "left":0.255, "right":0.37},
		{"text":"PUNCH", "action":"punch", "left":0.55, "right":0.66},
		{"text":"KICK", "action":"kick", "left":0.665, "right":0.765},
		{"text":"BLOCK", "action":"block", "left":0.77, "right":0.87},
		{"text":"SPECIAL", "action":"special", "left":0.875, "right":0.985}
	]
	for item: Dictionary in controls:
		var button := _make_button(holder, str(item.text), Rect2(float(item.left), 0.805, float(item.right), 0.89), Callable(self, "_noop"), false, Color("43e9ff"))
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 10)
		var action_name := str(item.action)
		button.button_down.connect(_set_touch_action.bind(action_name, true))
		button.button_up.connect(_set_touch_action.bind(action_name, false))
	return holder


func _set_touch_action(action_name: String, pressed: bool) -> void:
	_touch_pressed[action_name] = pressed


func _noop() -> void:
	pass


func _should_show_touch_controls() -> bool:
	return DisplayServer.is_touchscreen_available() or DisplayServer.window_get_size().x < 900


func _start_round() -> void:
	_actor_one.health = FightRulesType.STARTING_HEALTH
	_actor_two.health = FightRulesType.STARTING_HEALTH
	_actor_one.energy = 0.0
	_actor_two.energy = 0.0
	_actor_one.blocking = false
	_actor_two.blocking = false
	_jump_heights = [0.0, 0.0]
	_jump_speeds = [0.0, 0.0]
	_attack_cooldowns = [0.0, 0.0]
	_knockback_speeds = [0.0, 0.0]
	_low_health_seen = [false, false]
	_round_timer = FightRulesType.ROUND_DURATION_SECONDS
	_countdown = 3.0
	_phase = "countdown"
	_layout_fighters()
	_actor_one.set_action("idle", 0.15)
	_actor_two.set_action("idle", 0.15)
	_set_dialogue("ROUND %d" % _round_number, _actor_one.fighter, 0.8, false)
	_refresh_hud()


func _step_combat(delta: float) -> void:
	_attack_cooldowns[0] = maxf(0.0, _attack_cooldowns[0] - delta)
	_attack_cooldowns[1] = maxf(0.0, _attack_cooldowns[1] - delta)
	if _mode == "cpu":
		_step_human(1, delta)
		_step_cpu(delta)
	elif _mode == "local":
		_step_human(1, delta)
		_step_human(2, delta)
	else:
		_step_human(1, delta)
		_actor_two.blocking = false
		_actor_two.set_action("idle", 0.12)
	_step_jumps(delta)
	_step_knockbacks(delta)
	_resolve_body_collision()
	_actor_one.face_toward(_actor_two.position.x)
	_actor_two.face_toward(_actor_one.position.x)
	if _actor_one.health > 0 and _actor_one.health <= 28 and not _low_health_seen[0]:
		_low_health_seen[0] = true
		_show_dialogue("low", _actor_one.fighter)
	elif _actor_two.health > 0 and _actor_two.health <= 28 and not _low_health_seen[1]:
		_low_health_seen[1] = true
		_show_dialogue("low", _actor_two.fighter)


func _step_human(slot: int, delta: float) -> void:
	var actor := _actor_one if slot == 1 else _actor_two
	var opponent := _actor_two if slot == 1 else _actor_one
	var left_key := KEY_A if slot == 1 else KEY_LEFT
	var right_key := KEY_D if slot == 1 else KEY_RIGHT
	var jump_key := KEY_W if slot == 1 else KEY_UP
	var left_down := Input.is_physical_key_pressed(left_key) or (slot == 1 and bool(_touch_pressed.get("left", false)))
	var right_down := Input.is_physical_key_pressed(right_key) or (slot == 1 and bool(_touch_pressed.get("right", false)))
	var axis := float(int(right_down) - int(left_down))
	if axis != 0.0:
		actor.position.x += axis * 305.0 * delta
		actor.set_action("walk", 0.12)
	elif actor.blocking:
		actor.set_action("block", 0.12)
	else:
		actor.set_action("idle", 0.15)
	actor.position.x = clampf(actor.position.x, 34.0, get_viewport_rect().size.x - 34.0)
	var block_key := KEY_S if slot == 1 else KEY_DOWN
	var block_down := Input.is_physical_key_pressed(block_key) or (slot == 1 and bool(_touch_pressed.get("block", false)))
	actor.blocking = block_down
	if block_down:
		actor.set_action("block", 0.14)
	if _edge_pressed(slot, "jump", Input.is_physical_key_pressed(jump_key) or (slot == 1 and bool(_touch_pressed.get("jump", false)))):
		_start_jump(slot)
	var punch_key := KEY_F if slot == 1 else KEY_K
	var kick_key := KEY_G if slot == 1 else KEY_L
	var punch_down := Input.is_physical_key_pressed(punch_key) or (slot == 1 and bool(_touch_pressed.get("punch", false)))
	var kick_down := Input.is_physical_key_pressed(kick_key) or (slot == 1 and bool(_touch_pressed.get("kick", false)))
	var special_down := (Input.is_physical_key_pressed(KEY_H) or bool(_touch_pressed.get("special", false))) if slot == 1 else (Input.is_physical_key_pressed(KEY_SEMICOLON))
	if _edge_pressed(slot, "punch", punch_down):
		_try_attack(slot, "punch")
	elif _edge_pressed(slot, "kick", kick_down):
		_try_attack(slot, "kick")
	elif _edge_pressed(slot, "special", special_down):
		_try_attack(slot, "special")
	# A real input makes the browser audio context available before the first cue.
	if axis != 0.0 or punch_down or kick_down or special_down:
		AudioDirector.unlock_audio()


func _edge_pressed(slot: int, action_name: String, pressed: bool) -> bool:
	var key := "%d:%s" % [slot, action_name]
	var was_pressed := bool(_key_latches.get(key, false))
	_key_latches[key] = pressed
	return pressed and not was_pressed


func _start_jump(slot: int) -> void:
	var actor := _actor_one if slot == 1 else _actor_two
	if _jump_heights[slot - 1] > 3.0:
		return
	_jump_speeds[slot - 1] = 460.0
	actor.set_action("jump", 0.36)
	_play_sound("fight.jump")


func _step_jumps(delta: float) -> void:
	for index: int in 2:
		if _jump_heights[index] > 0.0 or _jump_speeds[index] > 0.0:
			_jump_heights[index] = maxf(0.0, _jump_heights[index] + _jump_speeds[index] * delta)
			_jump_speeds[index] -= 980.0 * delta
		if _jump_heights[index] <= 0.0:
			_jump_heights[index] = 0.0
			_jump_speeds[index] = 0.0
	_actor_one.position.y = _ground_y
	_actor_two.position.y = _ground_y
	_actor_one.jump_height = _jump_heights[0]
	_actor_two.jump_height = _jump_heights[1]


func _step_knockbacks(delta: float) -> void:
	for index: int in 2:
		if absf(_knockback_speeds[index]) < 4.0:
			_knockback_speeds[index] = 0.0
			continue
		var actor := _actor_one if index == 0 else _actor_two
		actor.position.x += _knockback_speeds[index] * delta
		_knockback_speeds[index] *= pow(0.06, delta)
		actor.position.x = clampf(actor.position.x, 34.0, get_viewport_rect().size.x - 34.0)


func _resolve_body_collision() -> void:
	var separation := _actor_two.position.x - _actor_one.position.x
	var minimum_gap := 82.0
	if absf(separation) >= minimum_gap:
		return
	var direction := 1.0 if separation >= 0.0 else -1.0
	var midpoint := (_actor_one.position.x + _actor_two.position.x) * 0.5
	_actor_one.position.x = clampf(midpoint - direction * minimum_gap * 0.5, 34.0, get_viewport_rect().size.x - 34.0)
	_actor_two.position.x = clampf(midpoint + direction * minimum_gap * 0.5, 34.0, get_viewport_rect().size.x - 34.0)


func _step_cpu(delta: float) -> void:
	var distance := absf(_actor_two.position.x - _actor_one.position.x)
	var toward_player := -1.0 if _actor_two.position.x > _actor_one.position.x else 1.0
	var speed := 178.0
	var attack_probability := 0.45
	var defend_probability := 0.09
	var special_probability := 0.30
	var cooldown := 0.72
	match _difficulty:
		"Normal":
			speed = 226.0
			attack_probability = 0.62
			defend_probability = 0.15
			special_probability = 0.43
			cooldown = 0.56
		"Hard":
			speed = 280.0
			attack_probability = 0.82
			defend_probability = 0.23
			special_probability = 0.63
			cooldown = 0.42
	if _cpu_block_timer > 0.0:
		_cpu_block_timer -= delta
		_actor_two.blocking = true
		_actor_two.set_action("block", 0.12)
		return
	_actor_two.blocking = false
	if distance > 158.0:
		_actor_two.position.x += toward_player * speed * delta
		_actor_two.position.x = clampf(_actor_two.position.x, 34.0, get_viewport_rect().size.x - 34.0)
		_actor_two.set_action("walk", 0.14)
		return
	_cpu_decision_timer -= delta
	if _cpu_decision_timer > 0.0:
		_actor_two.set_action("idle", 0.18)
		return
	_cpu_decision_timer = cooldown + _rng.randf_range(-0.08, 0.16)
	if _actor_one.energy >= 65.0 and _rng.randf() < defend_probability:
		_cpu_block_timer = 0.30 + defend_probability
		_actor_two.blocking = true
		_actor_two.set_action("block", _cpu_block_timer)
		return
	if _actor_two.energy >= FightRulesType.SPECIAL_ENERGY_COST and distance <= FightRulesType.attack_range("special") and _rng.randf() < special_probability:
		_try_attack(2, "special")
	elif _rng.randf() < attack_probability:
		_try_attack(2, "kick" if _rng.randf() < 0.44 else "punch")
	else:
		_cpu_block_timer = 0.24
		_actor_two.blocking = true
		_actor_two.set_action("block", _cpu_block_timer)


func _try_attack(slot: int, action_name: String) -> void:
	var index := slot - 1
	if _attack_cooldowns[index] > 0.0:
		return
	var attacker := _actor_one if slot == 1 else _actor_two
	var defender := _actor_two if slot == 1 else _actor_one
	if action_name == "special":
		if attacker.energy < FightRulesType.SPECIAL_ENERGY_COST:
			if slot == 1:
				_set_dialogue("Charge your special meter with hits!", attacker.fighter, 1.1, false)
			return
		attacker.energy = 0.0
		attacker.set_action("special", 0.52)
		_play_sound("fight.special")
		_spawn_sparks(attacker.global_position + Vector2(0, -185), Color(str(attacker.fighter.color)), 22)
		var custom_taunt := str(_custom_dialogue.get(str(attacker.fighter.id), ""))
		if not custom_taunt.is_empty():
			_set_dialogue(custom_taunt, attacker.fighter, 1.8, true)
		else:
			_show_dialogue("special", attacker.fighter)
		_attack_cooldowns[index] = 0.82
	else:
		attacker.set_action(action_name, 0.36 if action_name == "punch" else 0.46)
		_play_sound("fight.punch" if action_name == "punch" else "fight.kick", 1.0 + _rng.randf_range(-0.04, 0.05))
		_spawn_sparks(attacker.global_position + Vector2(0, -185), Color(str(attacker.fighter.color)), 8)
		_attack_cooldowns[index] = 0.38 if action_name == "punch" else 0.56
		_show_dialogue(action_name, attacker.fighter, 1.35, true)
	var range := FightRulesType.attack_range(action_name)
	var distance := absf(attacker.position.x - defender.position.x)
	if distance > range or (defender == _actor_one and _jump_heights[0] > 105.0 and action_name != "special") or (defender == _actor_two and _jump_heights[1] > 105.0 and action_name != "special"):
		if slot == 1:
			_set_dialogue("WHIFF! Move closer before you swing.", attacker.fighter, 0.95, false)
		return
	var raw := FightRulesType.damage_for(action_name)
	var damage := FightRulesType.damage_after_block(raw, defender.blocking)
	defender.health = maxi(0, defender.health - damage)
	if action_name != "special":
		attacker.energy = minf(100.0, attacker.energy + FightRulesType.energy_on_hit(action_name))
	defender.energy = minf(100.0, defender.energy + 8.0)
	defender.flash_hit()
	defender.set_action("hit", 0.23)
	var away := signf(defender.position.x - attacker.position.x)
	if away == 0.0:
		away = -1.0 if slot == 1 else 1.0
	var force := 155.0 if action_name == "punch" else (245.0 if action_name == "kick" else 375.0)
	if defender.blocking:
		force *= 0.32
	_knockback_speeds[1 if defender == _actor_two else 0] += away * force
	_spawn_sparks(defender.global_position + Vector2(0, -190), Color(str(defender.fighter.color)), 11 if action_name != "special" else 28)
	if defender.health <= 0:
		defender.set_action("defeat", 1.2)


func _spawn_sparks(position: Vector2, color: Color, count: int) -> void:
	for index: int in count:
		var angle := _rng.randf_range(-PI, PI)
		var speed := _rng.randf_range(45.0, 240.0)
		_fx_particles.append({
			"position":position,
			"velocity":Vector2(cos(angle), sin(angle)) * speed,
			"life":_rng.randf_range(0.18, 0.55),
			"max_life":0.55,
			"radius":_rng.randf_range(2.0, 8.0),
			"tint":color
		})
	if is_instance_valid(_fx_layer):
		_fx_layer.queue_redraw()


func _resolve_round(winner: int) -> void:
	if _phase != "fight":
		return
	if _mode == "practice":
		var dummy := _actor_two
		dummy.health = FightRulesType.STARTING_HEALTH
		dummy.energy = 0.0
		_actor_one.health = FightRulesType.STARTING_HEALTH
		_actor_one.energy = 0.0
		_set_dialogue("PRACTICE HIT — dummy reset. Keep testing!", _actor_one.fighter, 1.6, false)
		return
	_phase = "round_result"
	_between_round_timer = 2.1
	if winner >= 0:
		_round_wins[winner] += 1
		var champ := _actor_one if winner == 0 else _actor_two
		champ.set_action("victory", 1.0)
		var outcome := "ROUND %d — %s TAKES IT!" % [_round_number, champ.fighter.name.to_upper()]
		_set_dialogue(outcome, champ.fighter, 2.0, false)
		_play_sound("game.victory" if winner == 0 else "game.defeat")
	else:
		_set_dialogue("ROUND DRAW! Reset and go again.", _actor_one.fighter, 1.8, false)
	_refresh_hud()


func _finish_match() -> void:
	_match_winner = 0 if _round_wins[0] >= FightRulesType.rounds_needed_to_win() else 1
	_phase = "finished"
	var winner_actor := _actor_one if _match_winner == 0 else _actor_two
	var loser_actor := _actor_two if _match_winner == 0 else _actor_one
	winner_actor.set_action("victory", 100.0)
	loser_actor.set_action("defeat", 100.0)
	var record := {"winner":str(winner_actor.fighter.name), "loser":str(loser_actor.fighter.name), "score":"%d — %d" % [_round_wins[0], _round_wins[1]], "mode":_mode, "difficulty":_difficulty}
	_session_results.append(record)
	_play_sound("game.victory" if _match_winner == 0 else "game.defeat")
	_show_results(record)


func _show_results(record: Dictionary) -> void:
	_background.texture = TITLE_ART
	_wash.color = Color(0.025, 0.015, 0.065, 0.78)
	var page := _new_page("results")
	var winner := _actor_one if _match_winner == 0 else _actor_two
	var loser := _actor_two if _match_winner == 0 else _actor_one
	var outcome_badge := "PLAYER 1 VICTORY" if _match_winner == 0 else "PLAYER 1 DEFEAT"
	if _mode == "local":
		outcome_badge = "PLAYER 1 WINS  •  PLAYER 2 DEFEATED" if _match_winner == 0 else "PLAYER 2 WINS  •  PLAYER 1 DEFEATED"
	_add_label(page, outcome_badge, 18, Color("ffdb78"), Rect2(0.11, 0.075, 0.89, 0.14), "eyebrow", true)
	_add_label(page, str(record.winner).to_upper(), 54, Color("43e9ff") if _match_winner == 0 else Color("ff4eb5"), Rect2(0.13, 0.14, 0.87, 0.25), "title", true)
	_add_label(page, "%s defeats %s" % [winner.fighter.signature, loser.fighter.name], 16, Color("e8dff4"), Rect2(0.18, 0.25, 0.82, 0.31), "heading", true)
	_add_label(page, str(record.score), 33, Color("f8f4ff"), Rect2(0.34, 0.32, 0.66, 0.40), "title", true)
	_add_label(page, "BEST OF 3 COMPLETE  •  SESSION BOUTS: %d" % _session_results.size(), 12, Color("c7b9d4"), Rect2(0.25, 0.405, 0.75, 0.455), "eyebrow", true)
	var victorious := _pick_quip(winner.fighter, "win")
	var defeated := _pick_quip(loser.fighter, "loss")
	_add_label(page, "%s\n%s" % [victorious, defeated], 15, Color("ece0fa"), Rect2(0.20, 0.46, 0.80, 0.54), "heading", true)
	_set_dialogue(victorious, winner.fighter, 1.9, true)
	_make_button(page, "REMATCH", Rect2(0.22, 0.55, 0.48, 0.64), Callable(self, "_rematch"), true, Color("43e9ff"))
	_make_button(page, "CHANGE FIGHTERS", Rect2(0.52, 0.55, 0.78, 0.64), Callable(self, "_show_selection"), false, Color("ff4eb5"))
	_make_button(page, "MAIN MENU", Rect2(0.36, 0.68, 0.64, 0.77), Callable(self, "_return_to_menu"), false, Color("b68aff"))
	_add_label(page, "Ayyayyo, debba padindhi!  •  Friendship cancelled ra!  •  Pass avvadam kuda oka art ra!", 12, Color("cfc3df"), Rect2(0.12, 0.83, 0.88, 0.91), "heading", true)
	_add_label(page, "No scores or photos were saved.", 11, Color("a59ab4"), Rect2(0.35, 0.93, 0.65, 0.97), "eyebrow", true)


func _rematch() -> void:
	_start_match()


func _return_to_menu() -> void:
	get_tree().paused = false
	_actor_layer.visible = false
	_show_menu()


func _refresh_hud() -> void:
	if is_instance_valid(_hud_health_one):
		_hud_health_one.value = _actor_one.health
		_hud_health_two.value = _actor_two.health
		_hud_energy_one.value = _actor_one.energy
		_hud_energy_two.value = _actor_two.energy
	if is_instance_valid(_hud_timer):
		_hud_timer.text = "∞" if _mode == "practice" else "%02d" % maxi(0, ceili(_round_timer))
	if is_instance_valid(_hud_round):
		_hud_round.text = "ROUND %d  •  %d — %d" % [_round_number, _round_wins[0], _round_wins[1]]


func _toggle_pause() -> void:
	if _screen != "arena" or _phase in ["finished", "paused"]:
		return
	_phase = "paused"
	AudioDirector.set_game_paused(true)
	var page := _new_page("pause")
	_page.process_mode = Node.PROCESS_MODE_ALWAYS
	_page.mouse_filter = Control.MOUSE_FILTER_STOP
	var veil := ColorRect.new()
	veil.color = Color(0.012, 0.008, 0.035, 0.78)
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	ScreenFactory.full_rect(veil)
	page.add_child(veil)
	var panel := _new_panel(page, Rect2(0.26, 0.22, 0.74, 0.80), Color("b68aff"))
	_add_label(panel, "MATCH PAUSED", 31, Color("f8f4ff"), Rect2(0.06, 0.09, 0.94, 0.24), "title", true)
	_add_label(panel, "Take a breath. Attendance is still pending.", 14, Color("cfc3df"), Rect2(0.08, 0.28, 0.92, 0.38), "heading", true)
	_make_button(panel, "RESUME FIGHT", Rect2(0.16, 0.47, 0.84, 0.59), Callable(self, "_resume_match"), true)
	_make_button(panel, "RESTART MATCH", Rect2(0.16, 0.62, 0.84, 0.73), Callable(self, "_restart_match"), false, Color("ff4eb5"))
	_make_button(panel, "EXIT TO MENU", Rect2(0.16, 0.76, 0.84, 0.87), Callable(self, "_return_to_menu"), false, Color("43e9ff"))


func _resume_match() -> void:
	get_tree().paused = false
	_phase = "fight"
	AudioDirector.set_game_paused(false)
	_build_arena_hud()
	_refresh_hud()


func _restart_match() -> void:
	get_tree().paused = false
	_start_match()


func _show_dialogue(kind: String, fighter: Dictionary, duration: float = 1.6, voice: bool = true) -> void:
	_set_dialogue(_pick_quip(fighter, kind), fighter, duration, voice)


func _on_custom_dialogue_for_special(fighter_id: String) -> String:
	return str(_custom_dialogue.get(fighter_id, ""))
