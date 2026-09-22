extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(5):
		await physics_frame
	game.start_game()
	await process_frame
	await process_frame
	var failures: int = 0
	var viewport := Rect2(Vector2.ZERO, Vector2(1280, 800))
	for label in [game.hud.hp_label, game.hud.ammo_label, game.hud.mode_label, game.hud.audio_label]:
		if not viewport.encloses(label.get_global_rect()):
			failures += 1
			push_error("HUD element outside viewport: %s %s" % [label.text, label.get_global_rect()])
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("UI: 4 checks, %d failures" % failures)
	quit(1 if failures else 0)
