extends SceneTree
## Run graphically: godot --path . --script tests/capture_visuals.gd
## Produces reproducible screenshots and rendered performance evidence in builds/.

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame

func capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://builds/screenshots/" + filename + ".png")

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://builds/screenshots")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(30)
	await capture("menu")
	game.start_game()
	game.set_physics_process(false)
	game.intermission = 0
	game.player.active = false
	game.waves.round_number = 12
	game.waves.start_next()
	for i in range(30):
		game.try_spawn()
	await frames(180)
	await capture("gameplay-30-agents")
	var samples: Array[float] = []
	for i in range(180):
		await process_frame
		samples.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
	samples.sort()
	print("Rendered 30-agent frame time: median=%.2f ms p95=%.2f ms; FPS=%d" % [samples[90], samples[171], Engine.get_frames_per_second()])
	## What the camera actually pays for, after visibility ranges and culling.
	print("Rendered scene: %d objects, %d primitives, %d draw calls" % [
		Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)])
	game.debug_enabled = true
	for enemy in game.enemies:
		enemy.set_debug(true)
	await frames(10)
	await capture("agents-debug")
	game.player.health.damage(1000)
	await frames(50)
	await capture("game-over")
	game.queue_free()
	await create_timer(0.15).timeout
	quit()
