class_name ArmyState
extends RefCounted

var army_name: String = "The Free Company"
var morale: int = 6
var supplies: int = 30
var units: Dictionary = {"levy": 20, "rangers": 4}

func total_units() -> int:
	var total := 0
	for value in units.values():
		total += int(value)
	return total

func consume_supply(amount: int = 1) -> void:
	supplies = maxi(0, supplies - amount)

func change_morale(amount: int) -> void:
	morale = clampi(morale + amount, 0, 10)
