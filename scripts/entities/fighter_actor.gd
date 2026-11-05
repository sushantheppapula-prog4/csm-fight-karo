class_name FighterActor
extends Node2D

var fighter: Dictionary = {}
var player_number := 1
var health := 100
var energy := 0.0
var blocking := false
var jump_height := 0.0
var action := "idle"
var action_left := 0.0
var stage_scale := 1.0
var facing_left := false
var _sprite: Sprite2D
var _face_sprite: Sprite2D
var _base_y := -156.0
var _hit_flash := 0.0
var _clock := 0.0


func setup(character: Dictionary, slot: int, render_scale: float = 1.0) -> void:
	fighter = character.duplicate(true)
	player_number = slot
	stage_scale = render_scale
	z_index = 2
	facing_left = slot == 2
	_build_visual()


func _build_visual() -> void:
	for child in get_children():
		child.queue_free()
	_sprite = Sprite2D.new()
	_sprite.name = "FighterArt"
	var path := str(fighter.get("avatar", ""))
	if ResourceLoader.exists(path):
		_sprite.texture = load(path) as Texture2D
	_sprite.centered = true
	_sprite.position = Vector2(0, _base_y)
	_sprite.scale = Vector2(0.82 * stage_scale, 0.82 * stage_scale)
	_sprite.z_index = -1
	_sprite.flip_h = facing_left
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_sprite)
	_face_sprite = Sprite2D.new()
	_face_sprite.name = "SessionFaceOverlay"
	_face_sprite.centered = true
	_face_sprite.visible = false
	_face_sprite.position = Vector2(0, -262.0 * stage_scale)
	_face_sprite.scale = Vector2.ONE * (0.34 * stage_scale)
	_face_sprite.flip_h = facing_left
	_face_sprite.z_index = 4
	_face_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_face_sprite)
	queue_redraw()


func set_face_texture(texture: Texture2D) -> void:
	if not is_instance_valid(_face_sprite):
		return
	_face_sprite.texture = texture
	_face_sprite.visible = texture != null
	queue_redraw()


func face_toward(opponent_x: float) -> void:
	facing_left = global_position.x > opponent_x
	if is_instance_valid(_sprite):
		_sprite.flip_h = facing_left
	if is_instance_valid(_face_sprite):
		_face_sprite.flip_h = facing_left


func set_action(next_action: String, duration: float = 0.22) -> void:
	if action == next_action and action_left > 0.0:
		return
	if next_action in ["idle", "walk"]:
		var one_shot_active := action in ["punch", "kick", "special", "hit"] and action_left > 0.0
		var airborne_jump_active := action == "jump" and jump_height > 1.0
		if one_shot_active or airborne_jump_active:
			return
	if action in ["victory", "defeat"] and next_action not in ["victory", "defeat"]:
		return
	action = next_action
	action_left = maxf(duration, 0.0)
	blocking = next_action == "block"
	if next_action == "hit":
		_hit_flash = 0.14
	queue_redraw()


func flash_hit() -> void:
	_hit_flash = 0.15


func _process(delta: float) -> void:
	_clock += delta
	if action_left > 0.0:
		action_left = maxf(0.0, action_left - delta)
		if action_left <= 0.0 and action not in ["victory", "defeat"]:
			action = "block" if blocking else "idle"
	if _hit_flash > 0.0:
		_hit_flash = maxf(0.0, _hit_flash - delta)
	if not is_instance_valid(_sprite):
		return
	var bob := sin(_clock * 4.0 + float(player_number)) * 3.0
	var y_offset := -jump_height
	var tilt := 0.0
	var stretch := Vector2.ONE
	match action:
		"walk":
			bob = absf(sin(_clock * 13.0)) * 6.0
			stretch = Vector2(0.98, 1.02)
		"punch":
			tilt = -0.10 if facing_left else 0.10
			stretch = Vector2(1.07, 0.96)
		"kick":
			tilt = 0.12 if facing_left else -0.12
			stretch = Vector2(0.94, 1.06)
		"special":
			tilt = -0.16 if facing_left else 0.16
			stretch = Vector2(1.12, 1.08)
		"block":
			stretch = Vector2(0.91, 1.05)
			bob = -2.0
		"hit":
			tilt = 0.17 if facing_left else -0.17
			stretch = Vector2(0.96, 1.02)
		"victory":
			bob = -8.0 + sin(_clock * 8.0) * 5.0
			stretch = Vector2(1.02, 0.96)
		"defeat":
			bob = 4.0
			tilt = 0.10 if facing_left else -0.10
	_sprite.position.y = _base_y - jump_height + bob
	_sprite.rotation = tilt
	_sprite.scale = Vector2(0.82 * stage_scale * stretch.x, 0.82 * stage_scale * stretch.y)
	_sprite.modulate = Color(1.0, 0.8, 0.8, 1.0) if _hit_flash > 0.0 else Color.WHITE
	if is_instance_valid(_face_sprite):
		_face_sprite.position = Vector2(0, _sprite.position.y - 106.0 * stage_scale)
	queue_redraw()


func _draw_signature_effect(accent: Color) -> void:
	var direction := -1.0 if facing_left else 1.0
	var unit := stage_scale
	var center := Vector2(direction * 118.0 * unit, -222.0 * unit)
	var glow := Color(accent, 0.68)
	var highlight := Color(1.0, 1.0, 1.0, 0.88)
	var width := maxf(2.0, 4.0 * unit)
	match str(fighter.get("id", "")):
		"cr":
			var notice := Rect2(center + Vector2(-25.0, -20.0) * unit, Vector2(50.0, 40.0) * unit)
			draw_rect(notice, glow)
			draw_rect(notice, highlight, false, width, true)
			for row in 3:
				var y := notice.position.y + (10.0 + float(row) * 8.0) * unit
				draw_line(Vector2(notice.position.x + 8.0 * unit, y), Vector2(notice.end.x - 8.0 * unit, y), highlight, 2.0 * unit, true)
		"lady_don":
			draw_arc(center, 54.0 * unit, PI * 0.15, PI * 1.82, 28, glow, width + 2.0, true)
			for ray in 3:
				var angle := float(ray) * 0.46 + 0.2
				draw_line(center, center + Vector2(cos(angle) * direction, sin(angle)) * 72.0 * unit, highlight, 2.5 * unit, true)
		"shiva_fighter":
			var bolt := PackedVector2Array([center + Vector2(3.0, -43.0) * unit, center + Vector2(direction * -15.0, -9.0) * unit, center + Vector2(direction * 13.0, 0.0) * unit, center + Vector2(direction * -8.0, 45.0) * unit])
			draw_polyline(bolt, glow, width + 2.0, true)
			draw_polyline(bolt, highlight, maxf(1.5, width * 0.38), true)
		"fighter_51":
			for streak in 4:
				var start := center - Vector2(direction * (18.0 + float(streak) * 14.0), -18.0 + float(streak) * 9.0) * unit
				var finish := start + Vector2(direction * 42.0, -12.0) * unit
				draw_line(start, finish, Color(accent, 0.32 + float(streak) * 0.13), width, true)
		"fighter_52":
			var head := Rect2(center + Vector2(-30.0, -30.0) * unit, Vector2(38.0, 23.0) * unit)
			draw_rect(head, glow)
			draw_rect(head, highlight, false, width, true)
			draw_line(center + Vector2(direction * -3.0, -8.0) * unit, center + Vector2(direction * 27.0, 46.0) * unit, highlight, width + 1.0, true)
		"fighter_53":
			draw_arc(center, 48.0 * unit, 0.0, TAU, 36, glow, width + 2.0, true)
			for ray in 10:
				var angle := TAU * float(ray) / 10.0
				draw_line(center + Vector2(cos(angle), sin(angle)) * 55.0 * unit, center + Vector2(cos(angle), sin(angle)) * 78.0 * unit, highlight, 2.5 * unit, true)
		"second_cr":
			for order in 2:
				var shift := float(order) * 19.0 * unit
				draw_line(center + Vector2(-31.0 * unit, -18.0 * unit + shift), center + Vector2(22.0 * unit, -18.0 * unit + shift), glow, width + 2.0, true)
				draw_line(center + Vector2(13.0 * unit, -28.0 * unit + shift), center + Vector2(23.0 * unit, -18.0 * unit + shift), highlight, width, true)
		"arabian_horse":
			for trail in 4:
				var offset := float(trail) * 13.0 * unit
				draw_line(center - Vector2(direction * (84.0 * unit + offset), 20.0 * unit + offset), center - Vector2(direction * (18.0 * unit), 20.0 * unit + offset), Color(accent, 0.34 + float(trail) * 0.12), width, true)
		"swapna_taker":
			draw_arc(center, 52.0 * unit, PI * 0.45, PI * 1.82, 28, glow, width + 2.0, true)
			for star in 3:
				var point := center + Vector2(direction * (28.0 + float(star) * 19.0), -32.0 + float(star) * 22.0) * unit
				draw_circle(point, 3.0 * unit, highlight)
		"coa":
			var blueprint := Rect2(center + Vector2(-37.0, -34.0) * unit, Vector2(74.0, 68.0) * unit)
			draw_rect(blueprint, Color(accent, 0.15))
			draw_rect(blueprint, glow, false, width, true)
			for grid in range(1, 3):
				var fraction := float(grid) / 3.0
				draw_line(Vector2(blueprint.position.x + blueprint.size.x * fraction, blueprint.position.y), Vector2(blueprint.position.x + blueprint.size.x * fraction, blueprint.end.y), highlight, 1.5 * unit, true)
				draw_line(Vector2(blueprint.position.x, blueprint.position.y + blueprint.size.y * fraction), Vector2(blueprint.end.x, blueprint.position.y + blueprint.size.y * fraction), highlight, 1.5 * unit, true)
		"chubby_cheeks":
			draw_circle(center, 40.0 * unit, Color(accent, 0.20))
			draw_arc(center, 47.0 * unit, 0.0, TAU, 36, glow, width + 2.0, true)
			draw_arc(center, 62.0 * unit, PI * 0.15, PI * 1.75, 30, highlight, 2.0 * unit, true)
		"cheshma_girl":
			var lens := center + Vector2(0.0, -10.0) * unit
			draw_arc(lens, 17.0 * unit, 0.0, TAU, 24, glow, width, true)
			draw_line(lens + Vector2(direction * 17.0 * unit, -5.0 * unit), lens + Vector2(direction * 94.0 * unit, -29.0 * unit), highlight, width + 2.0, true)
			draw_line(lens + Vector2(direction * 17.0 * unit, 5.0 * unit), lens + Vector2(direction * 94.0 * unit, 29.0 * unit), glow, width + 2.0, true)


func _draw() -> void:
	var accent := Color(str(fighter.get("color", "#43E9FF")))
	if action == "special":
		_draw_signature_effect(accent)
	# Soft feet shadow keeps the generated transparent sprite grounded.
	draw_set_transform(Vector2(0, 0), 0.0, Vector2(1.0, 0.36))
	draw_circle(Vector2(0, 0), 64.0 * stage_scale, Color(0.0, 0.0, 0.0, 0.36))
	draw_circle(Vector2(0, 0), 64.0 * stage_scale, Color(accent, 0.26), false, 2.0)
	draw_set_transform(Vector2.ZERO)
	if energy > 0.0:
		draw_arc(Vector2(0, -156.0 * stage_scale), 170.0 * stage_scale, PI * 1.12, PI * 1.88, 40, Color(accent, 0.35 + energy / 250.0), 3.0, true)
