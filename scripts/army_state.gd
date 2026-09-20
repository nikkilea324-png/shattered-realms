class_name ArmyState
extends RefCounted

var army_name: String = "The Free Company"
var commander_id: String = ""
const FORMATION_SLOTS := 12
var morale: int = 6
var supplies: int = 30
var units: Dictionary = {"militia": 3, "rangers": 2}

func set_commander(p_commander_id: String) -> void:
	commander_id = p_commander_id

func clear_commander() -> void:
	commander_id = ""

func has_commander() -> bool:
	return commander_id != ""

func formation_slots_used() -> int:
	return total_units()

func formation_slots_remaining() -> int:
	return maxi(0, FORMATION_SLOTS - formation_slots_used())

func can_add_unit(unit_id: String, amount: int = 1) -> bool:
	if amount <= 0:
		return false
	return formation_slots_used() + amount <= FORMATION_SLOTS

func add_unit(unit_id: String, amount: int = 1) -> bool:
	if not can_add_unit(unit_id, amount):
		return false
	units[unit_id] = int(units.get(unit_id, 0)) + amount
	return true

func remove_unit(unit_id: String, amount: int = 1) -> bool:
	if amount <= 0 or int(units.get(unit_id, 0)) < amount:
		return false
	units[unit_id] = int(units.get(unit_id, 0)) - amount
	if units[unit_id] <= 0:
		units.erase(unit_id)
	return true

func total_units() -> int:
	var total := 0
	for value in units.values():
		total += int(value)
	return total

func consume_supply(amount: int = 1) -> void:
	supplies = maxi(0, supplies - amount)

func change_morale(amount: int) -> void:
	morale = clampi(morale + amount, 0, 10)
