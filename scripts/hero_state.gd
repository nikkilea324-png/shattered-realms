class_name HeroState
extends RefCounted

var hero_name: String
var hero_class: String
var level: int = 1
var xp: int = 0
var hp: int = 10
var max_hp: int = 10

func _init(p_name: String = "Hero", p_class: String = "warden") -> void:
	hero_name = p_name
	hero_class = p_class
	max_hp = 28 if p_class == "warden" else 20
	hp = max_hp

func gain_xp(amount: int) -> void:
	xp += amount
	while xp >= level * 100:
		xp -= level * 100
		level += 1
		max_hp += 4
		hp = max_hp
