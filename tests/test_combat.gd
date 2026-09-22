extends SceneTree
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void: call_deferred("run")
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(6)
	game.start_game()
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.player.armor = 20
	game.player.take_damage(-5)
	check(game.player.armor == 20, "Negative damage cannot create armor")
	game.player.invulnerability = 0
	var props = load("res://src/world/props.gd")
	var wall = props.solid(game.world.region, Vector3(6, 3, 0.4), Vector3(0, 1.5, -3), Color.GRAY)
	var enemy = game.spawn_enemy(Vector3(0, 0, -6))
	enemy.set_physics_process(false)
	await frames(3)
	var combat = load("res://src/combat/combat_resolver.gd")
	combat.blast(game.world.get_world_3d(), Vector3(0, 1, -1), 10, 40, [enemy])
	check(enemy.health.current == 68, "Area damage blocked by wall")
	wall.queue_free()
	await frames(3)
	combat.blast(game.world.get_world_3d(), Vector3(0, 1, -1), 10, 40, [enemy])
	check(enemy.health.current == 28, "Area damage reaches exposed target")
	check(game.has_method("spawn_position_clear"), "Spawner validates physical space")
	if game.has_method("spawn_position_clear"):
		check(not game.spawn_position_clear(Vector3(-11, 0, -10)), "Reject spawn inside building")
		check(not game.spawn_position_clear(enemy.position), "Reject overlapping actor")
		check(game.spawn_position_clear(Vector3(0, 0, 20)), "Accept clear road")
	game.free()
	await create_timer(0.2).timeout
	print("Combat: %d failures" % failures)
	quit(1 if failures else 0)
