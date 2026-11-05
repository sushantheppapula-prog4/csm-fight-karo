class_name FightRules
extends RefCounted

const STARTING_HEALTH := 100
const ROUND_DURATION_SECONDS := 60.0
const ROUNDS_TO_WIN := 2
const PUNCH_DAMAGE := 9
const KICK_DAMAGE := 15
const SPECIAL_DAMAGE := 25
const SPECIAL_ENERGY_COST := 100.0
const BLOCK_DAMAGE_FRACTION := 0.35

static func damage_for(action_name: String) -> int:
	match action_name:
		"punch":
			return PUNCH_DAMAGE
		"kick":
			return KICK_DAMAGE
		"special":
			return SPECIAL_DAMAGE
	return 0


static func damage_after_block(raw_damage: int, defending: bool) -> int:
	if raw_damage <= 0:
		return 0
	if not defending:
		return raw_damage
	return maxi(1, roundi(float(raw_damage) * BLOCK_DAMAGE_FRACTION))


static func energy_on_hit(action_name: String) -> float:
	match action_name:
		"punch":
			return 18.0
		"kick":
			return 28.0
	return 0.0


static func attack_range(action_name: String) -> float:
	match action_name:
		"punch":
			return 142.0
		"kick":
			return 170.0
		"special":
			return 238.0
	return 0.0


static func rounds_needed_to_win() -> int:
	return ROUNDS_TO_WIN
