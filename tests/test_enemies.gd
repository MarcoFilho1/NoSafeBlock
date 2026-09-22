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
		check(waves.enemy_kind(i / 100.0) in ["walker", "runner", "flanker", "spitter"], "Unlock rules")
	waves.round_number = 3
	var early := []
	for i in range(100):
		early.append(waves.enemy_kind(i / 100.0))
	check(not ("flanker" in early), "Flanker stays locked before its round")
	waves.round_number = 4
	var unlocked := []
	for i in range(100):
		unlocked.append(waves.enemy_kind(i / 100.0))
	check("flanker" in unlocked, "Flanker unlocks on round four")
	check_catalog()
	check_flank_decision()
	print("Enemies: %d failures" % failures)
	quit(1 if failures else 0)

func check_catalog() -> void:
	var catalog = load("res://src/data/enemy_catalog.gd")
	var flanker: Dictionary = catalog.get_definition("flanker")
	var walker: Dictionary = catalog.get_definition("walker")
	check(flanker.name == "FLANQUEADOR", "Flanker is named in the catalog")
	check(not flanker.boss, "Flanker is a regular enemy")
	check(flanker.speed > walker.speed, "Flanker outpaces the walker")
	check(flanker.health < walker.health, "Flanker trades toughness for speed")
	# The two fast types have to stay apart: the runner charges, the flanker circles.
	check(flanker.speed < catalog.get_definition("runner").speed, "Flanker stays slower than the runner")
	# Boss identity must survive new rows being inserted before them.
	for id in ["executioner", "matriarch", "aberration"]:
		check(catalog.get_definition(id).boss, "%s is still a boss" % id)
	for id in ["walker", "runner", "spitter", "demolisher", "screamer", "volatile"]:
		check(not catalog.get_definition(id).boss, "%s is still a regular enemy" % id)

func check_flank_decision() -> void:
	var Brain = load("res://src/enemies/agent_brain.gd")
	var direct = Brain.new()
	var target := Vector3(0, 0, -10)
	check(direct.approach_target(Vector3.ZERO, target) == target, "Head-on agents walk straight at the player")
	var left = Brain.new()
	left.flank_side = 1.0
	var right = Brain.new()
	right.flank_side = -1.0
	var aimed: Vector3 = left.approach_target(Vector3.ZERO, target)
	check(is_equal_approx(aimed.z, target.z) and is_equal_approx(aimed.x, -Brain.FLANK_REACH), "Flanker aims beside the player, not at it")
	check(is_equal_approx(right.approach_target(Vector3.ZERO, target).x, Brain.FLANK_REACH), "The other side mirrors the approach")
	check(is_zero_approx((aimed - target).dot(target)), "The offset is perpendicular to the approach line")
	# The offset has to shrink on the way in, or the agent would orbit forever.
	var previous := 999.0
	for distance in [10.0, 8.0, 6.0, 4.0]:
		var offset: float = (left.approach_target(Vector3(0, 0, -10 + distance), target) - target).length()
		check(offset < previous, "Flank offset closes as the agent arrives")
		previous = offset
	check(left.approach_target(Vector3(0, 0, -7.2), target) == target, "Inside commit range the flanker charges the player")
