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
	check_edge_spawn()
	check_edge_choice()
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
	# Both fast types move at the same pace: what separates them is the route, since the
	# runner charges straight in while the flanker curves around.
	check(is_equal_approx(flanker.speed, catalog.get_definition("runner").speed), "Flanker matches the runner pace")
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

func check_edge_spawn() -> void:
	var waves = load("res://src/systems/wave_director.gd").new()
	check(waves.spawns_at_edge("flanker"), "The flanker hunts in from the city limits")
	for id in ["walker", "runner", "spitter", "demolisher", "screamer", "volatile", "executioner"]:
		check(not waves.spawns_at_edge(id), "%s still spawns in the ring around the player" % id)
	var centre := Vector3.ZERO
	check(not waves.edge_spawn_allows(Vector3(20, 0, 20), centre), "Inner blocks are not rim positions")
	check(not waves.edge_spawn_allows(Vector3(60, 0, 60), centre), "Just inside the rim does not count")
	for point in [Vector3(80, 0, 0), Vector3(-80, 0, 0), Vector3(0, 0, 80), Vector3(0, 0, -80)]:
		check(waves.edge_spawn_allows(point, centre), "Every side of the rim is a valid approach")
	# A player fighting on the border must not have one appear on top of them.
	check(not waves.edge_spawn_allows(Vector3(80, 0, 0), Vector3(75, 0, 4)), "No rim spawn in the lap of the player")

func check_edge_choice() -> void:
	var waves = load("res://src/systems/wave_director.gd").new()
	var centre := Vector3.ZERO
	check(waves.choose_edge_spawn([] as Array[Vector3], centre) == null, "No rim position means no spawn")
	var far := Vector3(0, 0, -170)
	var points: Array[Vector3] = [Vector3(0, 0, -70), Vector3(0, 0, -80), far]
	# The far corner is more than EDGE_SPREAD times the closest position away.
	for i in range(40):
		check(waves.choose_edge_spawn(points, centre) != far, "The far side of the rim is never chosen")
	var only: Array[Vector3] = [far]
	check(waves.choose_edge_spawn(only, centre) == far, "With nothing closer the far position still serves")
	check(waves.EDGE_MIN_DISTANCE >= 50.0, "Rim spawns stay far enough to be an ambush")
