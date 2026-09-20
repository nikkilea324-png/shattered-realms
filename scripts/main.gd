extends Node2D

# SHATTERED REALMS — first playable vertical slice.
# World atlas -> territory board -> hidden cave -> dungeon.
# Gameplay coordinates stay independent of artwork so painted assets can replace
# these procedural visuals later without changing the rules.

const MAP_SIZE := Vector2(1280, 720)
const GRID := 56
const BOARD_ORIGIN := Vector2(80, 105)
const BOARD_COLS := 16
const BOARD_ROWS := 9
const HEX_SIZE := 20.0
const RAVEN_COLS := 24
const RAVEN_ROWS := 16

var mode := "world"
var selected_territory := ""
var hero_cell := Vector2i(2, 6)
var cave_cell := Vector2i(11, 3)
var dungeon_cell := Vector2i(1, 1)
var message := "Choose a realm to begin."
var turn_number := 1
var action_points := 3
const MAX_ACTION_POINTS := 6
const DEFAULT_TERRITORY_MOVEMENT := 2
var movement_remaining := DEFAULT_TERRITORY_MOVEMENT
var active_commander := "Kaela Varyn"
var commander_movement := {"Ser Kaela Varyn":2,"Kaela Varyn":2,"Edrin Vale":3,"Lord Garrick Thorne":2,"Nyra Vex":3,"Hakon Blood-Eye":2,"Malrec the Ashen":2}
var hero_hp := 5
var enemy_cell := Vector2i(8, 4)
var enemy_hp := 3
var enemy_defeated := false
var in_combat := false
var discovered_cells: Dictionary = {}
var player_army := ArmyState.new()
var tactical_battle: TacticalBattleState
var selected_attack_unit := "swordsmen"
var selected_target_unit := "shieldguard"
var ravenwood_terrain: Dictionary = {}
var ravenwood_locations: Dictionary = {}
var ravenwood_armies := [
	{"name":"Kaela Varyn","role":"Defensive Army","cell":Vector2i(11,7),"icon":"K"},
	{"name":"Edrin Vale","role":"Ranger Party","cell":Vector2i(4,4),"icon":"E"},
	{"name":"Hakon Blood-Eye","role":"Raiding Army","cell":Vector2i(17,12),"icon":"H"},
	{"name":"Nyra Vex","role":"Scout","cell":Vector2i(8,10),"icon":"N"}
]

var territories := [
	{"name":"Crownspine","rect":Rect2(55,145,300,220),"kind":"mountain","color":Color("#4d5360")},
	{"name":"Ravenwood","rect":Rect2(325,335,295,225),"kind":"forest","color":Color("#354d3b")},
	{"name":"Dreadfen","rect":Rect2(610,400,285,205),"kind":"swamp","color":Color("#39483f")},
	{"name":"Ashen March","rect":Rect2(885,115,300,250),"kind":"waste","color":Color("#5b4b45")},
	{"name":"Sunreach","rect":Rect2(920,405,270,200),"kind":"desert","color":Color("#806d4b")}
]

func _ready() -> void:
	player_army.units = {"militia":1,"swordsmen":3,"spearmen":2,"archers":2,"crossbowmen":1,"knights":1,"riders":1,"rangers":1}
	_load_ravenwood()
	queue_redraw()

func _input(event: InputEvent) -> void:
	# Android sends InputEventScreenTouch rather than a mouse click on a real
	# touchscreen. Handle both so the same game works on PC and Android.
	if event is InputEventScreenTouch and event.pressed:
		if not _is_ui_point(event.position):
			_handle_click(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not _is_ui_point(event.position):
			_handle_click(event.position)
	elif event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				_to_world()
			KEY_W, KEY_UP:
				_move_actor(Vector2i(0, -1))
			KEY_S, KEY_DOWN:
				_move_actor(Vector2i(0, 1))
			KEY_A, KEY_LEFT:
				_move_actor(Vector2i(-1, 0))
			KEY_D, KEY_RIGHT:
				_move_actor(Vector2i(1, 0))

func _is_ui_point(pos: Vector2) -> bool:
	if mode == "world":
		for t in territories:
			if t.rect.has_point(pos):
				return true
	elif mode == "territory":
		return Rect2(1025, 560, 190, 117).has_point(pos)
	elif mode == "dungeon":
		return Rect2(1025, 625, 190, 52).has_point(pos)
	return false

func _handle_ui_action(action: String) -> void:
	match action:
		"territory":
			var center := Vector2.ZERO
			for t in territories:
				if t.name == selected_territory:
					center = t.rect.get_center()
					break
			_handle_click(center)
		"enter_cave":
			if mode == "territory" and hero_cell == cave_cell:
				mode = "dungeon"
				dungeon_cell = Vector2i(1, 1)
				message = "The cave descends into a forgotten dungeon."
				queue_redraw()
		"return_world":
			_to_world()
			queue_redraw()
		"attack":
			_attack_enemy()
		"end_turn":
			_end_turn()
		"scout":
			message = "Scouting complete: a hidden cave lies to the northeast."
			queue_redraw()

func _handle_click(pos: Vector2) -> void:
	if mode == "world":
		for t in territories:
			if t.rect.has_point(pos):
				selected_territory = t.name
				mode = "territory"
				hero_cell = Vector2i(11, 7) if t.name == "Ravenwood" else Vector2i(2, 6)
				if t.name == "Ravenwood":
					cave_cell = Vector2i(7, 12)
					enemy_cell = Vector2i(15, 11)
				turn_number = 1
				movement_remaining = _territory_movement_allowance()
				action_points = movement_remaining
				hero_hp = 5
				enemy_hp = 3
				enemy_defeated = false
				in_combat = false
				tactical_battle = null
				selected_attack_unit = "swordsmen"
				selected_target_unit = "shieldguard"
				discovered_cells.clear()
				_reveal_around(hero_cell, 2)
				message = "Scouts report roads, ruins, and something hidden beneath the hills."
				return
	elif mode == "territory":
		if Rect2(1025, 625, 190, 52).has_point(pos) and hero_cell == cave_cell:
			mode = "dungeon"
			dungeon_cell = Vector2i(1, 1)
			message = "The cave descends into a forgotten dungeon."
			return
		var cell := _cell_at(pos)
		if _valid_cell(cell):
			if in_combat:
				message = "Combat engaged — use ATTACK or END TURN."
				return
			if action_points <= 0:
				message = "No action points remain. End the turn."
				return
			if selected_territory == "Ravenwood" and not _raven_neighbors(hero_cell).has(cell):
				message = "That hex is not adjacent to the army."
				return
			var move_cost := _raven_movement_cost(cell) if selected_territory == "Ravenwood" else 1
			if movement_remaining < move_cost:
				message = "Not enough movement for this terrain. End the turn or use a commander with greater mobility."
				return
			if cell == enemy_cell and not enemy_defeated:
				_start_tactical_encounter()
				return
			hero_cell = cell
			movement_remaining -= move_cost
			action_points = movement_remaining
			_reveal_around(hero_cell, 2)
			message = "Cave discovered — enter the dark below." if cell == cave_cell else "The party advances across the frontier."
			queue_redraw()
	elif mode == "dungeon":
		if Rect2(1025, 625, 190, 52).has_point(pos):
			_to_world()
			return
		var cell := _cell_at(pos)
		if _valid_cell(cell):
			dungeon_cell = cell
			message = "RELIC FOUND — the first ancient relic is yours!" if cell == Vector2i(5, 4) else "Torchlight reveals old stone, traps, and tracks."
			queue_redraw()

func _move_actor(delta: Vector2i) -> void:
	if mode != "territory" and mode != "dungeon":
		return
	if mode == "territory":
		if in_combat:
			message = "Combat engaged — use ATTACK or END TURN."
			return
		if action_points <= 0:
			message = "No action points remain. End the turn."
			return
		var target := _clamp_cell(hero_cell + delta)
		if selected_territory == "Ravenwood" and not _raven_neighbors(hero_cell).has(target):
			message = "Use the hexes around the army to move."
			return
		var move_cost := _raven_movement_cost(target) if selected_territory == "Ravenwood" else 1
		if movement_remaining < move_cost:
			message = "Not enough movement points for that terrain."
			return
		if target == enemy_cell and not enemy_defeated:
			_start_tactical_encounter()
			return
		hero_cell = target
		movement_remaining -= move_cost
		action_points = movement_remaining
		_reveal_around(hero_cell, 2)
		message = "Cave discovered — enter the dark below." if hero_cell == cave_cell else "The party advances across the frontier."
		queue_redraw()
	else:
		dungeon_cell = _clamp_cell(dungeon_cell + delta)
		message = "RELIC FOUND — the first ancient relic is yours!" if dungeon_cell == Vector2i(5, 4) else "Torchlight reveals old stone, traps, and tracks."
		queue_redraw()


func _start_tactical_encounter() -> void:
	if tactical_battle != null:
		return
	tactical_battle = TacticalBattleState.new()
	var enemy_force := {"shieldguard":1,"spearmen":2,"archers":1,"riders":1}
	tactical_battle.setup(player_army.units, enemy_force, "forest")
	in_combat = true
	message = "TACTICAL BATTLE — break the enemy formation."
	queue_redraw()

func _attack_enemy() -> void:
	if mode != "territory" or not in_combat or tactical_battle == null:
		return
	if not tactical_battle.player_units.has(selected_attack_unit):
		selected_attack_unit = tactical_battle.player_units.keys()[0]
	if not tactical_battle.enemy_units.has(selected_target_unit):
		selected_target_unit = tactical_battle.enemy_units.keys()[0]
	var result := tactical_battle.attack("player", selected_attack_unit, selected_target_unit)
	if not bool(result.get("ok", false)):
		message = str(result.get("message", "Attack failed."))
		queue_redraw()
		return
	message = str(result.get("message", "Attack resolved."))
	if tactical_battle.victory:
		enemy_defeated = true
		in_combat = false
		message = "VICTORY — enemy formation shattered. The frontier is yours."
	elif tactical_battle.defeat:
		hero_hp = 0
		in_combat = false
		message = "DEFEAT — your army has been destroyed."
	else:
		tactical_battle.end_turn()
		turn_number = tactical_battle.turn
		action_points = MAX_ACTION_POINTS
	queue_redraw()

func _end_turn() -> void:
	if mode != "territory":
		return
	turn_number += 1
	movement_remaining = _territory_movement_allowance()
	action_points = movement_remaining
	if in_combat and not enemy_defeated:
		hero_hp = maxi(hero_hp - 1, 0)
		if hero_hp == 0:
			in_combat = false
			message = "Defeat. The party retreats from the frontier."
		else:
			message = "The enemy strikes as you pass the initiative. Your turn begins."
	else:
		message = "Turn %d begins. Movement restored: %d hexes." % [turn_number, movement_remaining]
	queue_redraw()

func _cell_at(pos: Vector2) -> Vector2i:
	if mode == "territory" and selected_territory == "Ravenwood":
		return _raven_hex_at(pos)
	var local := pos - BOARD_ORIGIN
	return Vector2i(floori(local.x / GRID), floori(local.y / GRID))

func _valid_cell(cell: Vector2i) -> bool:
	if mode == "territory" and selected_territory == "Ravenwood":
		return cell.x >= 0 and cell.x < RAVEN_COLS and cell.y >= 0 and cell.y < RAVEN_ROWS
	return cell.x >= 0 and cell.x < BOARD_COLS and cell.y >= 0 and cell.y < BOARD_ROWS

func _load_ravenwood() -> void:
	var file := FileAccess.open("res://data/ravenwood.json", FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		ravenwood_terrain = parsed.get("terrain", {})
		ravenwood_locations = parsed.get("locations", {})

func _raven_hex_center(cell: Vector2i) -> Vector2:
	var x := BOARD_ORIGIN.x + 30.0 + float(cell.x) * (HEX_SIZE * 1.5)
	var y := BOARD_ORIGIN.y + 24.0 + float(cell.y) * (HEX_SIZE * 1.73) + (17.0 if cell.x % 2 == 1 else 0.0)
	return Vector2(x,y)

func _raven_hex_at(pos: Vector2) -> Vector2i:
	var best := Vector2i(-99,-99)
	var best_dist := 99999.0
	for y in range(RAVEN_ROWS):
		for x in range(RAVEN_COLS):
			var cell := Vector2i(x,y)
			var d := _raven_hex_center(cell).distance_squared_to(pos)
			if d < best_dist:
				best_dist = d
				best = cell
	return best if best_dist <= HEX_SIZE * HEX_SIZE * 2.0 else Vector2i(-99,-99)

func _raven_terrain_at(cell: Vector2i) -> String:
	if cell.x <= 3 and cell.y >= 3:
		return "mountain"
	if cell.x >= 20 and cell.y >= 3:
		return "marsh"
	if cell.x >= 16 and cell.y <= 4:
		return "plains"
	if cell.y <= 3 or (cell.x <= 7 and cell.y <= 7):
		return "forest"
	if cell.x >= 7 and cell.x <= 18 and cell.y >= 4 and cell.y <= 12:
		return "forest"
	if cell.x >= 4 and cell.y >= 11:
		return "hills"
	return "plains"

func _raven_neighbors(cell: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var offsets: Array[Vector2i]
	if cell.x % 2 == 0:
		offsets = [Vector2i(-1,-1), Vector2i(0,-1), Vector2i(1,-1), Vector2i(-1,0), Vector2i(1,0), Vector2i(0,1)]
	else:
		offsets = [Vector2i(0,-1), Vector2i(1,0), Vector2i(1,1), Vector2i(0,1), Vector2i(-1,1), Vector2i(-1,0)]
	for offset in offsets:
		var neighbor := cell + offset
		if _valid_raven_cell(neighbor):
			result.append(neighbor)
	return result

func _valid_raven_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < RAVEN_COLS and cell.y >= 0 and cell.y < RAVEN_ROWS

func _raven_movement_cost(cell: Vector2i) -> int:
	var road_cells := [
		Vector2i(11,7), Vector2i(11,6), Vector2i(11,5),
		Vector2i(12,4), Vector2i(12,3), Vector2i(13,3),
		Vector2i(14,2), Vector2i(15,2), Vector2i(16,2),
		Vector2i(17,1), Vector2i(18,1)
	]
	if road_cells.has(cell):
		return 1
	match _raven_terrain_at(cell):
		"plains":
			return 1
		"forest", "hills", "mountain", "marsh":
			return 2
		_:
			return 2

func is_cell_discovered(cell: Vector2i) -> bool:
	return discovered_cells.has(cell)

func _reveal_around(center: Vector2i, radius: int) -> void:
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			var cell := Vector2i(x, y)
			if not _valid_cell(cell):
				continue
			var visible := false
			if mode == "territory" and selected_territory == "Ravenwood":
				visible = _raven_hex_center(center).distance_to(_raven_hex_center(cell)) <= HEX_SIZE * 2.8
			else:
				visible = abs(x - center.x) + abs(y - center.y) <= radius
			if visible:
				discovered_cells[cell] = true

func _clamp_cell(cell: Vector2i) -> Vector2i:
	if mode == "territory" and selected_territory == "Ravenwood":
		return Vector2i(clampi(cell.x, 0, RAVEN_COLS - 1), clampi(cell.y, 0, RAVEN_ROWS - 1))
	return Vector2i(clampi(cell.x, 0, BOARD_COLS - 1), clampi(cell.y, 0, BOARD_ROWS - 1))

func _to_world() -> void:
	mode = "world"
	selected_territory = ""
	message = "The campaign map awaits your next decision."

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), Color("#111318"))
	if mode == "world":
		_draw_world()
	elif mode == "territory":
		_draw_territory()
	else:
		_draw_dungeon()
	_draw_hud()

func _draw_world() -> void:
	_draw_header("THE SHATTERED REALMS", "WORLD ATLAS  •  CAMPAIGN LAYER")
	var river := PackedVector2Array([Vector2(0,430),Vector2(220,400),Vector2(430,455),Vector2(650,350),Vector2(860,390),Vector2(1280,300)])
	draw_polyline(river, Color("#263d49"), 20)
	draw_polyline(river, Color("#182a32"), 11)
	draw_dashed_line(Vector2(180,270), Vector2(470,470), Color("#a18d68"), 2, 10)
	draw_dashed_line(Vector2(470,470), Vector2(1040,240), Color("#a18d68"), 2, 10)
	for t in territories:
		_draw_territory_box(t)
	_draw_fort(Vector2(455,270))
	_draw_ruin(Vector2(770,245))
	_draw_monster(Vector2(1130,500))
	draw_string(ThemeDB.fallback_font, Vector2(40,660), "EXPLORE  •  DISCOVER  •  CONQUER", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#c9b991"))
	draw_string(ThemeDB.fallback_font, Vector2(40,685), "Every territory can become a detailed playable board.", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#77766f"))

func _draw_territory() -> void:
	if selected_territory == "Ravenwood":
		_draw_ravenwood()
		return
	_draw_header(selected_territory.to_upper(), "TERRITORY BOARD  •  GRID CONQUEST")
	_draw_grid()
	for p in [Vector2i(1,1),Vector2i(2,1),Vector2i(2,2),Vector2i(13,6),Vector2i(14,6),Vector2i(14,7)]:
		var r := Rect2(BOARD_ORIGIN + Vector2(p) * GRID, Vector2(GRID, GRID))
		draw_circle(r.get_center(), 19, Color("#314432"))
	_draw_actor(hero_cell, "H")
	_draw_fog_overlay()

func _draw_ravenwood() -> void:
	_draw_header("RAVENWOOD", "THE EMERALD HEART  •  TERRITORY CONQUEST")
	for y in range(RAVEN_ROWS):
		for x in range(RAVEN_COLS):
			var cell := Vector2i(x,y)
			var base := Color("#2d4933")
			match _raven_terrain_at(cell):
				"mountain": base = Color("#4c4d52")
				"marsh": base = Color("#31473e")
				"plains": base = Color("#5a583f")
			_draw_hex(_raven_hex_center(cell), base, cell == hero_cell)
	var road := PackedVector2Array([_raven_hex_center(Vector2i(11,7)),_raven_hex_center(Vector2i(11,5)),_raven_hex_center(Vector2i(12,3)),_raven_hex_center(Vector2i(15,2)),_raven_hex_center(Vector2i(18,1))])
	draw_polyline(road, Color("#8b7658"), 7)
	var river := PackedVector2Array([_raven_hex_center(Vector2i(19,1)),_raven_hex_center(Vector2i(20,4)),_raven_hex_center(Vector2i(21,7)),_raven_hex_center(Vector2i(20,10)),_raven_hex_center(Vector2i(22,13)),_raven_hex_center(Vector2i(21,15))])
	draw_polyline(river, Color("#375f69"), 11)
	_draw_raven_fog()
	for id in ravenwood_locations:
		var loc: Dictionary = ravenwood_locations[id]
		var loc_cell: Array = loc.get("cell", [0, 0])
		var cell := Vector2i(int(loc_cell[0]), int(loc_cell[1]))
		if id == "hidden_dungeon" and not is_cell_discovered(cell):
			continue
		if is_cell_discovered(cell):
			_draw_raven_location(cell, str(loc.type), str(loc.name))
	for army in ravenwood_armies:
		if is_cell_discovered(army.cell):
			_draw_commander_piece(army)
	_draw_panel(Vector2(995,105), Vector2(250,250), "RAVENWOOD", ["Capital: Oakenheart","Forest: +1 defense / ambush","Plains: 1 movement","Mountain: 3 movement / +2 defense","Marsh: 3 movement","Turn: %d" % turn_number,"Movement: %d / %d" % [movement_remaining, _territory_movement_allowance()],"Commanders: 4","Hidden dungeon: %s" % ("revealed" if is_cell_discovered(Vector2i(7,12)) else "unknown")])

func _draw_hex(center: Vector2, fill: Color, selected: bool = false) -> void:
	var pts := PackedVector2Array()
	for i in range(6):
		var a := PI / 6.0 + float(i) * PI / 3.0
		pts.append(center + Vector2(cos(a),sin(a)) * HEX_SIZE)
	draw_colored_polygon(pts, fill)
	pts.append(pts[0])
	draw_polyline(pts, Color("#d9bf72") if selected else Color("#737266"), 1.5)

func _draw_raven_location(cell: Vector2i, kind: String, label: String) -> void:
	var c := _raven_hex_center(cell)
	var col := Color("#c7b26b")
	if kind == "enemy" or kind == "monster_lair": col = Color("#a4473f")
	elif kind == "dungeon": col = Color("#9a72b2")
	draw_circle(c, 12, Color("#141518"))
	draw_circle(c, 8, col)
	draw_string(ThemeDB.fallback_font, c + Vector2(-45,31), label, HORIZONTAL_ALIGNMENT_LEFT, 105, 9, Color("#e5dcc7"))

func _draw_commander_piece(army: Dictionary) -> void:
	var army_cell: Vector2i = army.get("cell", Vector2i.ZERO)
	var c := _raven_hex_center(army_cell)
	draw_circle(c + Vector2(0,-9), 15, Color("#101114"))
	draw_circle(c + Vector2(0,-9), 11, Color("#b59b63"))
	draw_string(ThemeDB.fallback_font, c + Vector2(-5,-4), str(army.get("icon", "?")), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#171719"))
	draw_string(ThemeDB.fallback_font, c + Vector2(-42,25), str(army.get("name", "Army")), HORIZONTAL_ALIGNMENT_LEFT, 100, 9, Color("#ddd3bd"))

func _draw_raven_fog() -> void:
	for y in range(RAVEN_ROWS):
		for x in range(RAVEN_COLS):
			var cell := Vector2i(x,y)
			if not is_cell_discovered(cell):
				_draw_hex(_raven_hex_center(cell), Color("#121519"))
func _draw_fog_overlay() -> void:
	for y in range(BOARD_ROWS):
		for x in range(BOARD_COLS):
			var cell := Vector2i(x, y)
			if not is_cell_discovered(cell):
				var r := Rect2(BOARD_ORIGIN + Vector2(cell) * GRID, Vector2(GRID, GRID))
				draw_rect(r, Color("#101216"))
				draw_rect(r, Color("#2a2d31"), false, 1)

func _draw_dungeon() -> void:
	_draw_header("THE HOLLOW BELOW", "DUNGEON  •  EXPLORATION LAYER")
	_draw_grid()
	for c in [Vector2i(6,1),Vector2i(7,1),Vector2i(8,1),Vector2i(6,2),Vector2i(8,2),Vector2i(6,3),Vector2i(7,3),Vector2i(8,3),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(3,6),Vector2i(5,6)]:
		var r := Rect2(BOARD_ORIGIN + Vector2(c) * GRID, Vector2(GRID, GRID))
		draw_rect(r, Color("#29252a"))
		draw_circle(r.get_center(), 6, Color("#665a4d"))
	_draw_actor(dungeon_cell, "H")
	_draw_actor(Vector2i(5,4), "R")
	_draw_panel(Vector2(995,105), Vector2(250,235), "DUNGEON LOG", ["Depth: 1","Light: 7 turns","Traps: unknown","Enemies: unknown","Relics: 1","","Find the reliquary.","Escape with your loot."])

func _draw_grid() -> void:
	for y in range(BOARD_ROWS):
		for x in range(BOARD_COLS):
			var r := Rect2(BOARD_ORIGIN + Vector2(x,y) * GRID, Vector2(GRID, GRID))
			draw_rect(r, Color("#202722") if (x+y)%2 == 0 else Color("#242b27"))
			draw_rect(r, Color("#55554b"), false, 1)

func _draw_actor(cell: Vector2i, label: String) -> void:
	var center := BOARD_ORIGIN + Vector2(cell) * GRID + Vector2(GRID/2, GRID/2)
	draw_circle(center, 20, Color("#0d0e10"))
	draw_circle(center, 16, Color("#d7c18a") if label == "H" else Color("#c7a44c"))
	draw_string(ThemeDB.fallback_font, center + Vector2(-6,7), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#171719"))

func _draw_territory_box(t: Dictionary) -> void:
	var r: Rect2 = t.rect
	var box := StyleBoxFlat.new()
	box.bg_color = t.color
	box.border_color = Color("#786e60")
	box.set_border_width_all(2)
	box.set_corner_radius_all(22)
	draw_style_box(box, r)
	_draw_terrain(r, t.kind)
	draw_string(ThemeDB.fallback_font, r.position + Vector2(16,32), t.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#e7ddc8"))
	draw_string(ThemeDB.fallback_font, r.position + Vector2(16,57), "TERRITORY • CLICK TO ENTER", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#b9ad98"))

func _draw_terrain(r: Rect2, kind: String) -> void:
	match kind:
		"mountain":
			for i in range(7):
				var x := r.position.x + 25 + i * 38
				draw_colored_polygon(PackedVector2Array([Vector2(x,r.end.y-35),Vector2(x+20,r.position.y+55),Vector2(x+42,r.end.y-35)]), Color("#676b73"))
		"forest":
			for i in range(20):
				var p := Vector2(r.position.x+20+(i*47)%260, r.position.y+75+(i*31)%120)
				draw_circle(p, 14, Color("#243a2b"))
				draw_colored_polygon(PackedVector2Array([p+Vector2(0,-24),p+Vector2(-15,10),p+Vector2(15,10)]), Color("#53664b"))
		"swamp":
			for i in range(9):
				var p := Vector2(r.position.x+25+(i*61)%250, r.position.y+75+(i*29)%100)
				draw_circle(p, 15, Color("#1e302c"))
				draw_circle(p+Vector2(8,4), 5, Color("#71806d"))
		"waste":
			for i in range(12):
				var p := Vector2(r.position.x+20+(i*53)%270, r.position.y+75+(i*37)%140)
				draw_line(p,p+Vector2(25,-10),Color("#7c6656"),3)
		"desert":
			for i in range(8):
				var p := Vector2(r.position.x+20+(i*69)%240, r.position.y+75+(i*31)%100)
				draw_arc(p,22,PI,TAU,12,Color("#a28d62"),3)

func _draw_header(title: String, subtitle: String) -> void:
	draw_rect(Rect2(0,0,1280,82), Color("#0d0e11"))
	draw_string(ThemeDB.fallback_font, Vector2(38,34), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 27, Color("#eadfc9"))
	draw_string(ThemeDB.fallback_font, Vector2(40,61), subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#8f8a7d"))

func _draw_hud() -> void:
	draw_rect(Rect2(0,590,1280,130), Color("#0d0e11"))
	draw_string(ThemeDB.fallback_font, Vector2(38,625), message, HORIZONTAL_ALIGNMENT_LEFT, 930, 15, Color("#d5cbb9"))
	if mode != "world":
		draw_string(ThemeDB.fallback_font, Vector2(38,680), "ESC • RETURN TO WORLD MAP", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#77766f"))

func _draw_panel(pos: Vector2, size: Vector2, title: String, lines: Array) -> void:
	draw_rect(Rect2(pos,size), Color("#15171b"))
	draw_rect(Rect2(pos,size), Color("#665d50"), false, 1)
	draw_string(ThemeDB.fallback_font, pos+Vector2(16,28), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#d8c59d"))
	var y := 55.0
	for line in lines:
		draw_string(ThemeDB.fallback_font, pos+Vector2(16,y), str(line), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#aaa59b"))
		y += 21

func _draw_button(label: String, rect: Rect2, active: bool) -> void:
	draw_rect(rect, Color("#5c4a32") if active else Color("#292b2e"))
	draw_rect(rect, Color("#b49b6d"), false, 1)
	draw_string(ThemeDB.fallback_font, rect.position+Vector2(18,32), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#eee3ce"))

func _draw_fort(p: Vector2) -> void:
	draw_rect(Rect2(p,Vector2(42,34)),Color("#24252a"))
	draw_rect(Rect2(p,Vector2(42,34)),Color("#9b8c70"),false,2)
	for x in [0,16,32]:
		draw_rect(Rect2(p+Vector2(x,-8),Vector2(10,10)),Color("#24252a"))

func _draw_ruin(p: Vector2) -> void:
	draw_line(p,p+Vector2(0,40),Color("#8b806c"),7)
	draw_line(p+Vector2(30,5),p+Vector2(30,40),Color("#8b806c"),7)
	draw_line(p,p+Vector2(30,5),Color("#8b806c"),7)

func _draw_monster(p: Vector2) -> void:
	draw_circle(p,28,Color("#241b20"))
	draw_circle(p+Vector2(-13,-4),6,Color("#b28b56"))
	draw_circle(p+Vector2(13,-4),6,Color("#b28b56"))
	draw_string(ThemeDB.fallback_font,p+Vector2(-7,37),"?",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("#b28b56"))

func _territory_movement_allowance() -> int:
	return int(commander_movement.get(active_commander, DEFAULT_TERRITORY_MOVEMENT))
