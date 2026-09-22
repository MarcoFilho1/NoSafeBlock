extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame

func mouse(pressed: bool, button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	Input.parse_input_event(event)

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(5)
	game.start_game()
	game.set_physics_process(false)
	await frames(3)
	mouse(true)
	await frames(3)
	var before: int = game.player.weapon.ammo
	var failures: int = 0
	game.set_paused(true)
	await frames(20)
	game.set_paused(false)
	await frames(20)
	if game.player.weapon.ammo != before:
		failures += 1
		push_error("Resuming with held fire must wait for button release")
	mouse(false)
	await frames(3)
	mouse(true)
	await frames(3)
	if game.player.weapon.ammo != before - 1:
		failures += 1
		push_error("Fresh click after resume must fire exactly once")
	mouse(false)
	game._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	if game.state != "PAUSED":
		failures += 1
		push_error("Focus loss pauses the match")
	mouse(true, MOUSE_BUTTON_RIGHT)
	game.set_paused(false)
	await frames(3)
	if game.player.focused:
		failures += 1
		push_error("Held right mouse after focus loss must wait for release")
	mouse(false, MOUSE_BUTTON_RIGHT)
	await frames(3)
	mouse(true, MOUSE_BUTTON_RIGHT)
	await frames(3)
	if not game.player.focused or game.player.visual.ring.scale.x >= 1.0:
		failures += 1
		push_error("Fresh focus input changes gameplay and visual stance")
	mouse(false, MOUSE_BUTTON_RIGHT)
	game.queue_free()
	await create_timer(0.15).timeout
	print("Controls: 5 checks, %d failures" % failures)
	quit(1 if failures else 0)
