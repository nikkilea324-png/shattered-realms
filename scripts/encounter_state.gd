class_name EncounterState
extends RefCounted

enum EncounterType { COMBAT, CHOICE, WORLD_THREAT }

var encounter_id: String = ""
var encounter_type: EncounterType = EncounterType.COMBAT
var threat: int = 1
var resolved: bool = false

func resolve() -> void:
	resolved = true
