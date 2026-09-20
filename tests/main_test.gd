extends GdUnitTestSuite

var game: Node2D

func before_test() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	add_child(game)

func after_test() -> void:
	if is_instance_valid(game):
		game.queue_free()

func test_world_map_selects_territory() -> void:
	assert_that(game.mode).is_equal("world")
	game._handle_click(Vector2(100, 200))
	assert_that(game.mode).is_equal("territory")
	assert_that(game.selected_territory).is_equal("Crownspine")

func test_android_touch_event_selects_territory() -> void:
	var touch := InputEventScreenTouch.new()
	touch.position = Vector2(400, 400)
	touch.pressed = true
	game._input(touch)
	assert_that(game.mode).is_equal("territory")
	assert_that(game.selected_territory).is_equal("Greenvale")

func test_territory_can_reach_cave_and_enter_dungeon() -> void:
	game._handle_click(Vector2(100, 200))
	assert_that(game.mode).is_equal("territory")
	game.hero_cell = game.cave_cell
	game._handle_click(Vector2(1100, 650))
	assert_that(game.mode).is_equal("dungeon")

func test_territory_button_layer_is_present_and_touch_layer_is_transparent() -> void:
	var touch_layer := game.get_node("TouchLayer")
	var button_layer := game.get_node("TerritoryButtons")
	assert_that(touch_layer.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)
	assert_that(button_layer.get_child_count()).is_equal(5)
