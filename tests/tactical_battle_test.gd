extends GdUnitTestSuite

func test_tactical_battle_builds_from_core_unit_data() -> void:
	var battle := TacticalBattleState.new()
	battle.setup({"spearmen":2,"archers":2,"knights":1},{"riders":2,"shieldguard":1},"forest")
	assert_that(battle.player_units.has("spearmen")).is_true()
	assert_that(battle.enemy_units.has("riders")).is_true()
	assert_that(battle.get_force_strength("player")).is_greater_than(0)

func test_spearmen_counter_cavalry() -> void:
	var battle := TacticalBattleState.new()
	battle.setup({"spearmen":2},{"riders":2},"open")
	var result := battle.attack("player","spearmen","riders")
	assert_that(result.ok).is_true()
	assert_that(result.damage).is_greater_than(1)

func test_forest_improves_rangers() -> void:
	var forest := TacticalBattleState.new()
	forest.setup({"rangers":1},{"militia":2},"forest")
	var open := TacticalBattleState.new()
	open.setup({"rangers":1},{"militia":2},"open")
	var forest_hit := forest.attack("player","rangers","militia")
	var open_hit := open.attack("player","rangers","militia")
	assert_that(forest_hit.damage).is_greater_than(open_hit.damage)

func test_battle_detects_victory() -> void:
	var battle := TacticalBattleState.new()
	battle.setup({"axemen":4},{"militia":1},"open")
	while not battle.victory and not battle.defeat:
		battle.attack("player","axemen","militia")
		if not battle.victory:
			break
	assert_that(battle.victory).is_true()
