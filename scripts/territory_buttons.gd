extends Control

var regions := [
	["Crownspine", Rect2(55,145,300,220)],
	["Greenvale", Rect2(325,335,295,225)],
	["Dreadfen", Rect2(610,400,285,205)],
	["Ashen March", Rect2(885,115,300,250)],
	["Sunreach", Rect2(920,405,270,200)]
]

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for region in regions:
		var button := Button.new()
		button.position = region[1].position
		button.size = region[1].size
		button.text = ""
		button.flat = true
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color(0, 0, 0, 0)
		var hover := normal.duplicate()
		hover.bg_color = Color(1, 1, 1, 0.08)
		var pressed := normal.duplicate()
		pressed.bg_color = Color(1, 1, 1, 0.18)
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", pressed)
		button.pressed.connect(_pressed.bind(region[0]))
		add_child(button)

func _pressed(territory_name: String) -> void:
	var game := get_parent()
	if game.has_method("_handle_click"):
		var region := regions.filter(func(r): return r[0] == territory_name)[0]
		game._handle_click(region[1].get_center())
