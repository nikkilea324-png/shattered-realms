class_name ArmyState
extends RefCounted

var army_name: String = "The Free Company"
var commander_id: String = ""
var morale: int = 6
var supplies: int = 30
var units: Dictionary = {"levy": 20, "rangers": 4}

func set_commander(p_commander_id: String) -> void:
	commander_id = p_commander_id

func clear_commander() -> void:
	commander_id = ""

func has_commander() -> bool:
	return commander_id != ""

func total_units() -> int:
	var total := 0
	for value in units.values():
		total += int(value)
	return total

func consume_supply(amount: int = 1) -> void:
	supplies = maxi(0, supplies - amount)

func change_morale(amount: int) -> void:
	morale = clampi(morale + amount, 0, 10)
