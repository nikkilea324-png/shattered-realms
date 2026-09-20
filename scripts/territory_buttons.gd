extends Control

var regions := [
	["Crownspine", Rect2(55,145,300,220)],
	["Ravenwood", Rect2(325,335,295,225)],
	["Greenvale", Rect2(325,335,295,225)],
	["Dreadfen", Rect2(610,400,285,205)],
	["Ashen March", Rect2(885,115,300,250)],
	["Sunreach", Rect2(920,405,270,200)]
]

var current_mode := ""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rebuild()

func _process(_delta: float) -> void:
	var game: Node2D = get_parent()
	if game.mode != current_mode:
		_rebuild()
	elif game.mode == "territory":
		var want_cave_button := game.hero_cell == game.cave_cell and not game.in_combat
		var want_attack_button := game.in_combat
		var has_cave_button := get_node_or_null("EnterCave") != null
		var has_attack_button := get_node_or_null("Attack") != null
		if want_cave_button != has_cave_button or want_attack_button != has_attack_button:
			_rebuild()

func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	current_mode = get_parent().mode
	if current_mode == "world":
		for region in regions:
			_add_button(region[1], "", "territory", region[0])
	elif current_mode == "territory":
		_add_button(Rect2(1025,560,190,52), "END TURN", "end_turn", "")
		if get_parent().in_combat:
			_add_button(Rect2(1025,625,190,52), "ATTACK", "attack", "")
		elif get_parent().hero_cell == get_parent().cave_cell:
			_add_button(Rect2(1025,625,190,52), "ENTER CAVE", "enter_cave", "")
	elif current_mode == "dungeon":
		_add_button(Rect2(1025,625,190,52), "RETURN TO MAP", "return_world", "")

func _add_button(rect: Rect2, label: String, action: String, territory_name: String) -> void:
	var button := Button.new()
	button.name = "EnterCave" if action == "enter_cave" else ("Attack" if action == "attack" else action + "_" + territory_name)
	button.position = rect.position
	button.size = rect.size
	button.text = label
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0) if label == "" else Color("#5c4a32")
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.border_color = Color("#b49b6d")
	var hover := normal.duplicate()
	hover.bg_color = Color(1, 1, 1, 0.10)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.pressed.connect(_action_pressed.bind(action, territory_name))
	add_child(button)

func _action_pressed(action: String, territory_name: String = "") -> void:
	var game := get_parent()
	if action == "territory":
		game.selected_territory = territory_name
	game._handle_ui_action(action)
