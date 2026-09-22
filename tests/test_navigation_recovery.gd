extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(6): await physics_frame
	game.start_game()
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.player.position = Vector3(-16.6, 0, 5)
	var enemy = game.spawn_enemy(Vector3(-15.4, 0, 5))
	enemy.idle_left = 0
	for i in range(30):
		await physics_frame
	var ok: bool = enemy.position.distance_to(Vector3(-15.4, 0, 5)) > 0.3
	game.free()
	await create_timer(0.2).timeout
	print("Navigation recovery: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
