extends SceneTree

var failures: int = 0
var checks: int = 0
var game: Node

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame

func run() -> void:
	check(ResourceLoader.exists("res://scenes/main.tscn"), "Playable scene exists")
	if failures:
		quit(1)
		return
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(5)
	check(game.world.navigation_ready, "Navigation has synchronized before play")
	game.start_game()
	game.set_physics_process(false)
	await frames(3)
	check(game.state == "PLAYING" and game.player.health.current == 100, "Start creates a healthy player")
	check(game.score == 0 and game.waves.round_number == 1, "Start resets score and waves")
	# Exercise registered input actions through the actual movement controller.
	for action in ["move_up", "move_down", "move_left", "move_right"]:
		game.player.position = Vector3.ZERO
		Input.action_press(action)
		await frames(12)
		Input.action_release(action)
		var screen_start: Vector2 = game.world.camera.unproject_position(Vector3.ZERO)
		var screen_end: Vector2 = game.world.camera.unproject_position(game.player.position)
		var motion: Vector2 = screen_end - screen_start
		match action:
			"move_up": check(motion.y < -5 and absf(motion.x) < 3, "W moves up on screen")
			"move_down": check(motion.y > 5 and absf(motion.x) < 3, "S moves down on screen")
			"move_left": check(motion.x < -5 and absf(motion.y) < 3, "A moves left on screen")
			"move_right": check(motion.x > 5 and absf(motion.y) < 3, "D moves right on screen")
	game.player.set_physics_process(false)
	# A real physics ray to an unobstructed enemy, then a wall-occluded one.
	var enemy = game.spawn_enemy(Vector3(0, 0, -4))
	enemy.set_physics_process(false)
	game.player.position = Vector3.ZERO
	game.player.focused = true
	await frames(3)
	check(game.player.shoot_at(Vector3(0, 1, -4)), "Shot is accepted")
	var tracer: Node3D = game.actors.get_child(game.actors.get_child_count() - 1)
	check(tracer.global_position.distance_to(game.player.visual.muzzle.global_position) < 0.01, "Shot tracer starts at visible muzzle")
	check(enemy.health.current == 34, "Actual raycast damages enemy")
	check(not game.player.shoot_at(Vector3(0, 1, -4)), "Actual player cannot bypass cadence")
	game.player.weapon.tick(0.25)
	game.player.shoot_at(Vector3(0, 1, -4))
	check(not enemy.health.is_alive() and game.score == 10, "Death grants score exactly once")
	enemy.take_damage(100)
	check(game.score == 10, "Dead enemies do not grant duplicate score")
	var protected_enemy = game.spawn_enemy(Vector3(-11, 0, -15))
	protected_enemy.set_physics_process(false)
	game.player.position = Vector3(-11, 0, -4)
	game.player.weapon.tick(0.25)
	await frames(3)
	game.player.shoot_at(Vector3(-11, 1, -15))
	check(protected_enemy.health.current == 68, "Building blocks shots")
	game.player.position = Vector3(-11, 0, -6)
	game.player.weapon.tick(0.25)
	await frames(3)
	game.player.shoot_at(Vector3(-11, 1, -15))
	check(protected_enemy.health.current == 68, "Barrel extending into building cannot bypass wall")
	protected_enemy.take_damage(100)
	# Body collision against the same building; no input or navigation doubles.
	game.player.position = Vector3(-11, 0, -5)
	for i in range(60):
		game.player.velocity = Vector3(0, 0, -5)
		game.player.move_and_slide()
		await physics_frame
	check(game.player.position.z > -6.5, "Player cannot pass through a building")
	# Every spawn must have a route into the playable center.
	var nav_map = game.world.get_world_3d().navigation_map
	for point in game.world.spawn_points:
		var path = NavigationServer3D.map_get_path(nav_map, point, Vector3.ZERO, true)
		check(path.size() >= 2, "Spawn has path to player: " + str(point))
	# Follow an actual route around the north-west building.
	game.player.position = Vector3(-11, 0, -4)
	var hunter = game.spawn_enemy(Vector3(-11, 0, -15))
	hunter.alert_time = 30.0
	var start_distance: float = hunter.position.distance_to(game.player.position)
	for i in range(620):
		await physics_frame
		if hunter.position.distance_to(game.player.position) < 1.5:
			break
	check(hunter.position.distance_to(game.player.position) < 2.5, "Agent navigates around building to reach player (start %.1f, end %.1f)" % [start_distance, hunter.position.distance_to(game.player.position)])
	if hunter.position.distance_to(game.player.position) >= 2.5:
		print("Navigation diagnostic: state=", game.state, " agent=", hunter.brain.state, " active=", hunter.active, " pos=", hunter.position, " target=", game.player.position, " path=", hunter.navigation.get_current_navigation_path())
	# Cooldown is measured with the real enemy controller.
	hunter.position = game.player.position + Vector3(0, 0, -1)
	hunter.attack_left = 0.0
	await frames(3)
	var hp_after_hit: float = game.player.health.current
	await frames(20)
	check(game.player.health.current == hp_after_hit, "Enemy damage respects attack cooldown")
	game.set_paused(true)
	var frozen_pos: Vector3 = hunter.position
	var frozen_hp: float = game.player.health.current
	await frames(65)
	check(hunter.position == frozen_pos and game.player.health.current == frozen_hp, "Pause freezes movement and damage")
	check(not game.player.shoot_at(Vector3.ZERO), "Paused player cannot shoot")
	game.set_paused(false)
	# The controller is disabled in this fixture; expire its hit grace explicitly.
	game.player.invulnerability = 0.0
	game.player.take_damage(1000)
	check(game.state == "OVER", "Player death enters game over")
	check(not game.player.shoot_at(Vector3.ZERO), "Dead player cannot shoot")
	for i in range(3):
		game.start_game()
		game.set_physics_process(false)
		await frames(3)
		check(game.player.health.current == 100 and game.player.weapon.ammo == 12 and game.score == 0 and game.enemies.is_empty(), "Restart resets all state")
	game.intermission = 0
	for i in range(5):
		game.try_spawn()
	for agent in game.enemies.duplicate():
		agent.take_damage(100)
	game.set_physics_process(true)
	await frames(3)
	check(game.waves.round_number == 2 and game.waves.pending == 8 and game.intermission > 0, "Real last kill advances to second wave")
	check(game.score == 175, "Five kills plus first wave survival reward")
	# An in-range target behind a thin obstacle must not strand the agent in ATTACK.
	game.start_game()
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.player.position = Vector3(-16.6, 0, 5)
	var blocked_attacker = game.spawn_enemy(Vector3(-15.4, 0, 5))
	blocked_attacker.idle_left = 0.0
	await frames(4)
	check(not blocked_attacker.has_clear_attack(), "Thin-obstacle fixture blocks melee ray")
	check(blocked_attacker.brain.state == "CHASE", "Occluded melee target falls back to navigation")
	await frames(120)
	if blocked_attacker.position.distance_to(Vector3(-15.4, 0, 5)) <= 0.3:
		print("Blocked fixture pos=", blocked_attacker.position, " velocity=", blocked_attacker.velocity, " closest=", NavigationServer3D.map_get_closest_point(nav_map, blocked_attacker.position), " path=", blocked_attacker.navigation.get_current_navigation_path())
	check(blocked_attacker.position.distance_to(Vector3(-15.4, 0, 5)) > 0.3, "Occluded attacker moves around obstacle")
	game.start_game()
	game.set_physics_process(false)
	await frames(3)
	# Bounded spawn population and a short 30-agent integration load.
	game.waves.round_number = 12
	game.waves.start_next()
	game.player.set_physics_process(false)
	for i in range(30):
		game.try_spawn()
	check(game.enemies.size() == 30, "Thirty agents can run simultaneously")
	game.try_spawn()
	check(game.enemies.size() == 30, "Spawner enforces active limit")
	for agent in game.enemies:
		check(agent.position.distance_to(game.player.position) >= 10, "Spawn respects safe radius")
		for other in game.enemies:
			if agent != other:
				check(agent.position.distance_to(other.position) >= 0.8, "Spawn does not overlap another agent")
	await frames(120)
	game.show_menu()
	await frames(3)
	check(game.state == "MENU" and game.enemies.is_empty() and game.player == null, "Menu cleans match entities")
	game.queue_free()
	# Let the audio mixer release its last playback buffer before engine shutdown.
	await create_timer(0.15).timeout
	print("Integration: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
