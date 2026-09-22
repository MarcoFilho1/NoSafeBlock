extends SceneTree
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	var waves = load("res://src/systems/wave_director.gd").new()
	if not waves.has_method("enemy_kind"):
		check(false, "Enemy composition missing")
		quit(1)
		return
	waves.start_next()
	for i in range(100):
		check(waves.enemy_kind(i / 100.0) == "walker", "Wave one has only walkers")
	waves.round_number = 5
	for i in range(100):
		check(waves.enemy_kind(i / 100.0) in ["walker", "runner", "spitter"], "Unlock rules")
	print("Enemies: %d failures" % failures)
	quit(1 if failures else 0)
