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

func test_turn_based_movement_consumes_action_points() -> void:
	game._handle_click(Vector2(100, 200))
	assert_that(game.action_points).is_equal(3)
	var start := game.hero_cell
	game._handle_click(game.BOARD_ORIGIN + Vector2(start + Vector2i(1, 0)) * game.GRID + Vector2(10, 10))
	assert_that(game.hero_cell).is_equal(start + Vector2i(1, 0))
	assert_that(game.action_points).is_equal(2)

func test_enemy_contact_starts_tactical_encounter() -> void:
	game._handle_click(Vector2(100, 200))
	game.hero_cell = game.enemy_cell + Vector2i(-1, 0)
	game.action_points = 3
	game._handle_click(game.BOARD_ORIGIN + Vector2(game.enemy_cell) * game.GRID + Vector2(10, 10))
	assert_that(game.in_combat).is_true()
	assert_that(game.message).contains("Tactical encounter")

func test_attack_and_enemy_turn_progress_combat() -> void:
	game._handle_click(Vector2(100, 200))
	game.in_combat = true
	game.enemy_hp = 2
	game.hero_hp = 5
	game._handle_ui_action("attack")
	assert_that(game.enemy_hp).is_equal(1)
	assert_that(game.hero_hp).is_equal(4)
	assert_that(game.turn_number).is_equal(2)

func test_victory_ends_combat() -> void:
	game._handle_click(Vector2(100, 200))
	game.in_combat = true
	game.enemy_hp = 1
	game._handle_ui_action("attack")
	assert_that(game.in_combat).is_false()
	assert_that(game.enemy_defeated).is_true()
	assert_that(game.message).contains("Victory")
