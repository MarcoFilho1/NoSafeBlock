extends SceneTree
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	var waves = load("res://src/systems/wave_director.gd").new()
	if not waves.has_method("boss_kind"):
		check(false, "Boss scheduling missing")
		quit(1)
		return
	for row in [[10, "executioner"], [20, "matriarch"], [30, "aberration"], [40, "executioner"]]:
		waves.round_number = row[0] - 1
		waves.start_next()
		check(waves.boss_kind() == row[1] and waves.boss_pending, "Scheduled boss")
		waves.pending = 0
		check(not waves.is_clear(), "Pending boss prevents clear")
		waves.alive = 30
		check(not waves.register_summon(), "Summons respect population")
		waves.alive = 0
		check(waves.register_boss_spawn(), "Boss reserve")
		check(not waves.register_boss_spawn(), "Only one boss")
		check(waves.register_summon(), "Count summon")
		waves.register_kill()
		check(not waves.is_clear(), "Summon prevents premature clear")
		waves.register_kill()
		check(waves.is_clear(), "Complete after all dead")
	print("Bosses: %d failures" % failures)
	quit(1 if failures else 0)
