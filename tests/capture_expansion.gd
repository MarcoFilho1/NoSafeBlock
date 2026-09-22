extends SceneTree
var capture_game: Node
func _initialize() -> void: call_deferred("run")
func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		if is_instance_valid(capture_game) and capture_game.state == "PAUSED":
			capture_game.set_paused(false)
			capture_game.player.active = false
func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://builds/screenshots/" + name + ".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://builds/screenshots")
	var started := Time.get_ticks_msec()
	var game = load("res://scenes/main.tscn").instantiate()
	capture_game = game
	root.add_child(game)
	await frames(15)
	print("City ready after %d ms" % (Time.get_ticks_msec() - started))
	await capture("city-menu")
	game.start_game()
	game.set_physics_process(false)
	game.intermission = 0
	game.player.active = false
	game.progression.award(8500)
	for i in range(game.world.layout.districts.size()):
		var district: Dictionary = game.world.layout.districts[i]
		game.player.position = Vector3.ZERO if i == 0 else district.position + Vector3(8, 0, 8)
		await frames(45)
		await capture("district-%d" % i)
	game.player.position = Vector3(-75, 0, -75)
	for barrier in game.world.interactables:
		if barrier is StaticBody3D and barrier.position.distance_to(game.player.position) < 12:
			barrier.repair(game.progression)
	await frames(45)
	await capture("defended-interior")
	game.player.position = Vector3.ZERO
	game.waves.round_number = 12
	game.waves.start_next()
	for i in range(30): game.try_spawn()
	await frames(150)
	await capture("city-30-enemies")
	var samples: Array[float] = []
	for i in range(180):
		await process_frame
		if game.state == "PAUSED":
			game.set_paused(false)
			game.player.active = false
		samples.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000)
	samples.sort()
	print("Rendered 30 enemies: median %.2f ms / p95 %.2f ms / FPS %d" % [samples[90], samples[171], Engine.get_frames_per_second()])
	for id in ["executioner", "matriarch", "aberration"]:
		game.start_game()
		game.set_physics_process(false)
		game.player.active = false
		game.intermission = 0
		var boss = game.spawn_enemy(Vector3(0, 0, -7), id)
		boss.set_physics_process(false)
		boss.abilities.telegraph(1.2)
		await frames(40)
		await capture(id)
	game.free()
	await create_timer(0.2).timeout
	quit()
