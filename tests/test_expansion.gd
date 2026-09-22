extends SceneTree
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(6)
	game.start_game()
	game.set_physics_process(false)
	await frames(3)
	check(game.hud.get("minimap") != null, "Minimap available")
	game.progression.award(20000)
	var station = load("res://src/world/interaction_station.gd").new()
	station.offer = {"kind": "weapon", "id": "shotgun", "title": "Calibre 12"}
	root.add_child(station)
	check(station.interact(game.player, game.progression), "World weapon purchase")
	var balance: int = game.progression.balance
	check(not station.interact(game.player, game.progression) and game.progression.balance == balance, "Duplicate purchase atomic")
	game.progression.buy_upgrade("health")
	game.player.apply_upgrades()
	check(game.player.health.maximum == 125, "Upgrade applied to player")
	check(game.player.throw_grenade(Vector3(0, 0, -5)), "Grenade accepted")
	var hazard = game.effects.get_child(game.effects.get_child_count() - 1)
	game.set_paused(true)
	var remaining: float = hazard.warmup
	await frames(8)
	check(hazard.warmup == remaining, "Paused grenade cannot detonate")
	game.start_game()
	game.set_physics_process(false)
	await frames(3)
	check(not is_instance_valid(hazard), "Restart removes effects")
	check(game.progression.balance == 0 and game.player.health.maximum == 100, "Restart resets progression")
	check(game.player.weapon.id == "service_pistol", "Restart resets equipment")
	game.waves.alive = 0
	var matriarch = game.spawn_enemy(Vector3(0, 0, -7), "matriarch")
	matriarch.set_physics_process(false)
	matriarch.abilities.locked_target = game.player.global_position
	matriarch.abilities.execute()
	await frames(3)
	check(game.enemies.size() >= 2 and game.waves.alive >= 1, "Matriarch summons count as live enemies")
	game.waves.alive = 30
	var before_summons: int = game.enemies.size()
	matriarch.abilities.summon_cooldown = 0
	matriarch.abilities.execute()
	await frames(2)
	check(game.enemies.size() == before_summons, "Matriarch cannot exceed active limit")
	for kind in ["spitter", "demolisher", "screamer", "volatile", "executioner", "matriarch", "aberration"]:
		var enemy = game.spawn_enemy(Vector3(0, 0, -6), kind)
		enemy.set_physics_process(false)
		enemy.abilities.telegraph(0.01)
		enemy.abilities.tick(0.02)
		check(enemy.health.is_alive() or kind == "volatile", "Ability executes: " + kind)
		enemy.take_damage(100000)
	await frames(4)
	station.free()
	game.free()
	await create_timer(0.2).timeout
	print("Expansion: %d failures" % failures)
	quit(1 if failures else 0)
