extends SceneTree

var failures: int = 0
var checks: int = 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	for path in ["res://src/core/health.gd", "res://src/player/weapon.gd", "res://src/enemies/agent_brain.gd", "res://src/systems/wave_director.gd"]:
		check(ResourceLoader.exists(path), "Missing required gameplay component: " + path)
	if failures > 0:
		finish()
		return
	test_health()
	test_weapon()
	test_brain()
	test_waves()
	finish()

func test_health() -> void:
	var health = load("res://src/core/health.gd").new(100.0)
	var deaths: Array = []
	health.died.connect(func(): deaths.append(true))
	health.damage(-10.0)
	check(health.current == 100.0, "Negative damage must not heal or harm")
	health.damage(35.0)
	check(health.current == 65.0, "Damage is applied")
	health.damage(500.0)
	health.damage(10.0)
	check(health.current == 0.0 and deaths.size() == 1, "Death clamps HP and emits once")
	check(not health.is_alive(), "Dead actor is not alive")

func test_weapon() -> void:
	var weapon = load("res://src/player/weapon.gd").new()
	check(weapon.fire(), "Loaded gun can fire")
	check(weapon.ammo == 11, "Shot consumes ammunition")
	check(not weapon.fire() and weapon.ammo == 11, "Spam cannot bypass cadence")
	weapon.tick(0.25)
	check(weapon.fire(), "Gun fires after cooldown")
	check(weapon.reload(), "Partial magazine can reload")
	check(not weapon.fire(), "Reload blocks shooting")
	check(not weapon.reload(), "Repeated reload cannot reset timer")
	weapon.tick(1.39)
	check(weapon.ammo == 10, "Ammo not granted before reload ends")
	weapon.tick(0.02)
	check(weapon.ammo == 12 and not weapon.reloading, "Reload fills magazine on completion")
	check(not weapon.reload(), "Full magazine does not reload")
	for i in range(12):
		weapon.tick(0.25)
		check(weapon.fire(), "Each available round fires")
	weapon.tick(1.0)
	check(not weapon.fire() and weapon.ammo == 0, "Empty magazine cannot shoot")

func test_brain() -> void:
	var brain = load("res://src/enemies/agent_brain.gd").new()
	check(brain.decide(20.0, true, false) == "PATROL", "Undetected target leads to patrol")
	check(brain.decide(8.0, true, false) == "CHASE", "Detection enters chase")
	check(brain.decide(1.0, true, false) == "ATTACK", "Close target enters attack")
	check(brain.decide(3.0, true, false) == "CHASE", "Leaving attack range resumes chase")
	check(brain.decide(25.0, true, false) == "PATROL", "Losing target resumes patrol")
	check(brain.decide(20.0, true, true) == "CHASE", "Gunshot can alert a distant agent")
	check(brain.decide(1.0, false, true) == "DEAD", "Death overrides attack and perception")
	check(brain.decide(1.0, true, true) == "DEAD", "Dead state is terminal")

func test_waves() -> void:
	var director = load("res://src/systems/wave_director.gd").new()
	director.start_next()
	check(director.round_number == 1 and director.pending == 5, "First wave has five enemies")
	check(not director.is_clear(), "Pending spawns prevent wave completion")
	director.register_spawn()
	director.register_kill()
	check(not director.is_clear(), "Last live kill cannot discard unspawned enemies")
	for i in range(4):
		director.register_spawn()
		director.register_kill()
	check(director.is_clear(), "Wave ends after all emitted enemies die")
	director.register_kill()
	check(director.alive == 0, "Count does not become negative")
	director.start_next()
	check(director.round_number == 2 and director.pending == 8, "Next wave increases count")
	var near_only: Array[Vector3] = [Vector3.ZERO, Vector3(1, 0, 0)]
	check(director.choose_spawn(near_only, Vector3.ZERO) == null, "Unsafe spawn is deferred")
	var candidates: Array[Vector3] = [Vector3.ZERO, Vector3(15, 0, 0)]
	check(director.choose_spawn(candidates, Vector3.ZERO) == Vector3(15, 0, 0), "Spawn is far from player")
	for i in range(20):
		director.start_next()
	for i in range(30):
		check(director.register_spawn(), "Capacity accepts first thirty agents")
	check(not director.register_spawn() and director.alive == 30, "Active agents are capped")

func finish() -> void:
	print("Rules: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
