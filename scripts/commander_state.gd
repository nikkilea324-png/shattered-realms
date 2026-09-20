class_name CommanderState
extends RefCounted

var commander_id: String
var level: int = 1
var xp: int = 0
var assigned_army_id: String = ""
var governed_territory_id: String = ""
var unlocked_abilities: Array[String] = []

func _init(p_commander_id: String = "") -> void:
	commander_id = p_commander_id

func assign_to_army(army_id: String) -> void:
	assigned_army_id = army_id
	governed_territory_id = ""

func govern_territory(territory_id: String) -> void:
	governed_territory_id = territory_id
	assigned_army_id = ""

func clear_assignment() -> void:
	assigned_army_id = ""
	governed_territory_id = ""

func gain_xp(amount: int) -> bool:
	xp += amount
	var leveled := false
	while xp >= level * 100:
		xp -= level * 100
		level += 1
		leveled = true
	return leveled

func is_deployed() -> bool:
	return assigned_army_id != ""

func is_governor() -> bool:
	return governed_territory_id != ""
