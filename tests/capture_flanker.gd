extends SceneTree
## Run graphically: godot --path . --script tests/capture_flanker.gd
## Evidence for the flanker: silhouette next to a walker, and the flanking approach paths.
## The flanker is a lean humanoid, so the comparison shot is what shows the build apart.

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame

func capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://builds/screenshots/" + filename + ".png")

func aim(game: Node, focus: Vector3, size: float, offset: Vector3) -> void:
	var camera: Camera3D = game.world.camera
	camera.size = size
	camera.position = focus + offset
	camera.look_at(focus)

func restart(game: Node) -> void:
	## start_game clears the previous match through the normal path, so no freed
	## enemy is ever left behind in the lists the HUD reads.
	game.start_game()
	game.set_physics_process(false)
	game.intermission = 0
	game.player.active = false
	# The world lerps the camera onto the player every frame; freeze it to frame the shot.
	game.world.set_process(false)

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://builds/screenshots")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(15)
	restart(game)
	game.player.position = Vector3(0, 0, -1)
	var flanker = game.spawn_enemy(Vector3(-1.6, 0, -8), "flanker")
	var walker = game.spawn_enemy(Vector3(1.6, 0, -8), "walker")
	flanker.set_physics_process(false)
	walker.set_physics_process(false)
	aim(game, Vector3(0, 0.8, -8), 6.0, Vector3(4.5, 3.0, 4.5))
	await frames(20)
	await capture("flanker-silhouette")
	# Park the walker out of frame so the profile shows the quadruped alone.
	walker.position = Vector3(30, 0, 30)
	aim(game, Vector3(-1.6, 0.6, -8), 3.4, Vector3(-4.2, 1.1, 0))
	await frames(10)
	await capture("flanker-profile")
	restart(game)
	# Four flankers released at the same distance should fan out instead of forming a queue.
	for point in [Vector3(0, 0, -11), Vector3(0, 0, 11), Vector3(-11, 0, 0), Vector3(11, 0, 0)]:
		var agent = game.spawn_enemy(point, "flanker")
		agent.idle_left = 0
		agent.set_debug(true)
	aim(game, Vector3.ZERO, 30.0, Vector3(0.1, 40, 0.1))
	await frames(90)
	await capture("flanker-paths")
	game.free()
	await create_timer(0.2).timeout
	quit()
