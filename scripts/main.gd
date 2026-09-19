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

var mode := "world"
var selected_territory := ""
var hero_cell := Vector2i(2, 6)
var cave_cell := Vector2i(11, 3)
var dungeon_cell := Vector2i(1, 1)
var message := "Choose a realm to begin."

var territories := [
	{"name":"Crownspine","rect":Rect2(55,145,300,220),"kind":"mountain","color":Color("#4d5360")},
	{"name":"Greenvale","rect":Rect2(325,335,295,225),"kind":"forest","color":Color("#354d3b")},
	{"name":"Dreadfen","rect":Rect2(610,400,285,205),"kind":"swamp","color":Color("#39483f")},
	{"name":"Ashen March","rect":Rect2(885,115,300,250),"kind":"waste","color":Color("#5b4b45")},
	{"name":"Sunreach","rect":Rect2(920,405,270,200),"kind":"desert","color":Color("#806d4b")}
]

func _ready() -> void:
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
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

func _handle_click(pos: Vector2) -> void:
	if mode == "world":
		for t in territories:
			if t.rect.has_point(pos):
				selected_territory = t.name
				mode = "territory"
				hero_cell = Vector2i(2, 6)
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
			hero_cell = cell
			message = "Cave discovered — enter the dark below." if cell == cave_cell else "The party advances across the frontier."
	elif mode == "dungeon":
		if Rect2(1025, 625, 190, 52).has_point(pos):
			_to_world()
			return
		var cell := _cell_at(pos)
		if _valid_cell(cell):
			dungeon_cell = cell
			message = "RELIC FOUND — the first ancient relic is yours!" if cell == Vector2i(5, 4) else "Torchlight reveals old stone, traps, and tracks."

func _move_actor(delta: Vector2i) -> void:
	if mode != "territory" and mode != "dungeon":
		return
	if mode == "territory":
		hero_cell = _clamp_cell(hero_cell + delta)
		message = "Cave discovered — enter the dark below." if hero_cell == cave_cell else "The party advances across the frontier."
	else:
		dungeon_cell = _clamp_cell(dungeon_cell + delta)
		message = "RELIC FOUND — the first ancient relic is yours!" if dungeon_cell == Vector2i(5, 4) else "Torchlight reveals old stone, traps, and tracks."

func _cell_at(pos: Vector2) -> Vector2i:
	var local := pos - BOARD_ORIGIN
	return Vector2i(floori(local.x / GRID), floori(local.y / GRID))

func _valid_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < BOARD_COLS and cell.y >= 0 and cell.y < BOARD_ROWS

func _clamp_cell(cell: Vector2i) -> Vector2i:
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
	_draw_header(selected_territory.to_upper(), "TERRITORY BOARD  •  GRID CONQUEST")
	_draw_grid()
	# forest pockets
	for p in [Vector2i(1,1),Vector2i(2,1),Vector2i(2,2),Vector2i(13,6),Vector2i(14,6),Vector2i(14,7)]:
		var r := Rect2(BOARD_ORIGIN + Vector2(p) * GRID, Vector2(GRID, GRID))
		draw_circle(r.get_center(), 19, Color("#314432"))
	# road and river
	draw_line(BOARD_ORIGIN + Vector2(0,6.5) * GRID, BOARD_ORIGIN + Vector2(15,6.5) * GRID, Color("#6e624f"), 10)
	draw_line(BOARD_ORIGIN + Vector2(0,6.5) * GRID, BOARD_ORIGIN + Vector2(15,6.5) * GRID, Color("#3b352d"), 6)
	draw_line(BOARD_ORIGIN + Vector2(8,0) * GRID, BOARD_ORIGIN + Vector2(9,9) * GRID, Color("#294653"), 13)
	# hidden cave
	var cr := Rect2(BOARD_ORIGIN + Vector2(cave_cell) * GRID, Vector2(GRID, GRID))
	draw_circle(cr.get_center(), 18, Color("#151519"))
	draw_arc(cr.get_center(), 19, PI, TAU, 14, Color("#96715a"), 4)
	_draw_actor(hero_cell, "H")
	if hero_cell == cave_cell:
		_draw_button("ENTER CAVE", Rect2(1025,625,190,52), true)
	_draw_panel(Vector2(995,105), Vector2(250,235), "SCOUT REPORT", ["Terrain: frontier","Roads: 2","Ruins: 1","Hidden sites: 1","Hostiles: unknown","","WASD / arrows to move","Tap a tile to move"])

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
	_draw_button("RETURN TO MAP", Rect2(1025,625,190,52), false)

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
