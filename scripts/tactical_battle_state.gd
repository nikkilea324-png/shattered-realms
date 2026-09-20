class_name TacticalBattleState
extends RefCounted

# Deterministic, data-driven battlefield engine. The UI decides how actions are
# presented; this class owns combat rules so the same rules can power territory
# battles, city assaults, army encounters, and dungeon-scale skirmishes.

const UNIT_DATA_PATH := "res://data/unit_types.json"

var turn: int = 1
var active_side := "player"
var player_units: Dictionary = {}
var enemy_units: Dictionary = {}
var player_commander_id := ""
var enemy_commander_id := ""
var terrain := "open"
var log: Array[String] = []
var victory := false
var defeat := false

func setup(player_force: Dictionary, enemy_force: Dictionary, p_terrain: String = "open", p_player_commander: String = "", p_enemy_commander: String = "") -> void:
	player_units = _copy_force(player_force)
	enemy_units = _copy_force(enemy_force)
	terrain = p_terrain
	player_commander_id = p_player_commander
	enemy_commander_id = p_enemy_commander
	turn = 1
	active_side = "player"
	victory = false
	defeat = false
	log.clear()

func attack(attacker_side: String, attacker_id: String, target_id: String) -> Dictionary:
	if victory or defeat:
		return {"ok": false, "message": "Battle is already resolved."}
	var attackers := player_units if attacker_side == "player" else enemy_units
	var defenders := enemy_units if attacker_side == "player" else player_units
	if not attackers.has(attacker_id) or not defenders.has(target_id):
		return {"ok": false, "message": "Invalid unit selection."}
	var attacker: Dictionary = attackers[attacker_id]
	var target: Dictionary = defenders[target_id]
	var distance := 1
	var range_value := _stat(attacker_id, "range")
	if range_value < distance:
		return {"ok": false, "message": "%s cannot reach %s." % [attacker_id, target_id]}
	var damage := _calculate_damage(attacker_id, target_id, attacker, target)
	var target_hp := int(target.get("hp", 0))
	target_hp = maxi(0, target_hp - damage)
	target["hp"] = target_hp
	defenders[target_id] = target
	log.append("%s %s attacks %s for %d damage." % [attacker_side, attacker_id, target_id, damage])
	if target_hp == 0:
		defenders.erase(target_id)
		log.append("%s %s is destroyed." % [attacker_side, target_id])
	_check_result()
	return {"ok": true, "damage": damage, "destroyed": target_hp == 0, "message": log.back()}

func end_turn() -> void:
	if victory or defeat:
		return
	active_side = "enemy" if active_side == "player" else "player"
	if active_side == "player":
		turn += 1
		log.append("Turn %d begins." % turn)
	else:
		log.append("Enemy phase begins.")

func get_force_strength(side: String) -> int:
	var force := player_units if side == "player" else enemy_units
	var strength := 0
	for unit_id in force:
		var u: Dictionary = force[unit_id]
		strength += int(u.get("hp", 0)) + int(u.get("attack", 0)) * int(u.get("count", 1))
	return strength

func _calculate_damage(attacker_id: String, target_id: String, attacker: Dictionary, target: Dictionary) -> int:
	var attack_value := int(attacker.get("attack", 0))
	var defense_value := int(target.get("defense", 0))
	var multiplier := _matchup_multiplier(attacker_id, target_id)
	if terrain == "forest" and attacker_id == "rangers":
		multiplier += 0.20
	if terrain == "high_ground" and attacker_id in ["archers", "crossbowmen", "rangers"]:
		multiplier += 0.15
	var morale_factor := 0.75 + float(attacker.get("morale", 50)) / 200.0
	return maxi(1, roundi((attack_value * multiplier * morale_factor) - (defense_value * 0.35)))

func _matchup_multiplier(attacker_id: String, target_id: String) -> float:
	var bonus := 1.0
	if attacker_id == "spearmen" and target_id in ["knights", "riders"]:
		bonus += 0.75
	if attacker_id == "axemen" and target_id in ["shieldguard", "knights", "swordsmen"]:
		bonus += 0.50
	if attacker_id == "crossbowmen" and target_id in ["knights", "shieldguard", "swordsmen"]:
		bonus += 0.55
	if attacker_id == "riders" and target_id in ["archers", "rangers", "crossbowmen"]:
		bonus += 0.45
	if attacker_id == "archers" and target_id in ["militia", "rangers"]:
		bonus += 0.20
	if attacker_id == "mages" and target_id in ["militia", "riders", "swordsmen"]:
		bonus += 0.30
	if attacker_id == "shieldguard" and target_id in ["archers", "crossbowmen"]:
		bonus += 0.20
	return bonus

func _stat(unit_id: String, stat_name: String) -> int:
	var data := _unit_data()
	if not data.has("unit_types") or not data.unit_types.has(unit_id):
		return 1
	return int(data.unit_types[unit_id].get("stats", {}).get(stat_name, 1))

func _unit_data() -> Dictionary:
	if not FileAccess.file_exists(UNIT_DATA_PATH):
		return {"unit_types": {}}
	var file := FileAccess.open(UNIT_DATA_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {"unit_types": {}}

func _copy_force(force: Dictionary) -> Dictionary:
	var result := {}
	var data := _unit_data()
	for unit_id in force:
		if not data.unit_types.has(unit_id):
			continue
		var definition: Dictionary = data.unit_types[unit_id]
		var count := int(force[unit_id])
		var stats: Dictionary = definition.get("stats", {})
		result[unit_id] = {
			"count": count,
			"hp": int(stats.get("health", 1)) * count,
			"attack": int(stats.get("attack", 1)),
			"defense": int(stats.get("defense", 1)),
			"morale": int(stats.get("morale", 50))
		}
	return result

func _check_result() -> void:
	if enemy_units.is_empty():
		victory = true
		log.append("VICTORY — enemy force destroyed.")
	elif player_units.is_empty():
		defeat = true
		log.append("DEFEAT — your force has been destroyed.")
