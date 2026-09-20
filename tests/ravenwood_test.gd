extends GdUnitTestSuite

var game: Node2D

func before_test() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	add_child(game)

func after_test() -> void:
	if is_instance_valid(game):
		game.queue_free()

func test_ravenwood_loads_as_hex_territory() -> void:
	game._handle_click(Vector2(450, 400))
	assert_that(game.mode).is_equal("territory")
	assert_that(game.selected_territory).is_equal("Ravenwood")
	assert_that(game.hero_cell).is_equal(Vector2i(11, 7))
	assert_that(game._raven_terrain_at(Vector2i(1, 5))).is_equal("mountain")
	assert_that(game._raven_terrain_at(Vector2i(21, 6))).is_equal("marsh")

func test_ravenwood_movement_costs_terrain() -> void:
	game._handle_click(Vector2(1000, 200))
	assert_that(game._raven_movement_cost(Vector2i(10, 6))).is_equal(2)
	assert_that(game._raven_movement_cost(Vector2i(11, 6))).is_equal(1)

func test_ravenwood_has_four_commander_pieces() -> void:
	assert_that(game.ravenwood_armies.size()).is_equal(4)

func test_ravenwood_hidden_dungeon_starts_hidden() -> void:
	game._handle_click(Vector2(1000, 200))
	assert_that(game.is_cell_discovered(Vector2i(5, 7))).is_false()
