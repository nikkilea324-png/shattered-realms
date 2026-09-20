extends GdUnitTestSuite

func test_army_uses_twelve_formation_slots() -> void:
	var army := ArmyState.new()
	assert_that(army.formation_slots_used()).is_equal(5)
	assert_that(army.formation_slots_remaining()).is_equal(7)

func test_army_rejects_units_above_formation_limit() -> void:
	var army := ArmyState.new()
	assert_that(army.add_unit("shieldguard", 7)).is_true()
	assert_that(army.add_unit("knights", 1)).is_false()
	assert_that(army.formation_slots_used()).is_equal(12)

func test_army_can_add_and_remove_core_units() -> void:
	var army := ArmyState.new()
	assert_that(army.add_unit("spearmen", 2)).is_true()
	assert_that(army.remove_unit("spearmen", 1)).is_true()
	assert_that(army.units["spearmen"]).is_equal(1)
