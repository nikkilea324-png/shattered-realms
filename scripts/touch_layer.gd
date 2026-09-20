extends Control

func _ready() -> void:
	# Main._input() handles touch/mouse globally. Keep this layer transparent so
	# native territory buttons can receive taps instead of being intercepted.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _gui_input(_event: InputEvent) -> void:
	pass
