class_name GameState
extends RefCounted

var turn: int = 1
var gold: int = 100
var food: int = 100
var selected_territory: String = ""
var discovered_sites: Array[String] = []
var owned_territories: Array[String] = []

func discover(site_id: String) -> void:
	if not discovered_sites.has(site_id):
		discovered_sites.append(site_id)

func own(territory_id: String) -> void:
	if not owned_territories.has(territory_id):
		owned_territories.append(territory_id)

func advance_turn() -> void:
	turn += 1
