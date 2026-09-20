extends Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		var game := get_parent()
		if game.has_method("_handle_click"):
			game._handle_click(event.position)
			accept_event()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var game := get_parent()
		if game.has_method("_handle_click"):
			game._handle_click(event.position)
			accept_event()
