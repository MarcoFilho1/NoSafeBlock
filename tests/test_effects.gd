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
	if not ResourceLoader.exists("res://src/combat/hazard.gd"):
		check(false, "Hazard missing")
		quit(1)
		return
	var hazard = load("res://src/combat/hazard.gd").new()
	hazard.configure("acid", Vector3.ZERO, 10, 3, 4)
	root.add_child(hazard)
	hazard.active = false
	var before: float = hazard.remaining
	for i in range(5):
		await physics_frame
	check(hazard.remaining == before, "Paused hazard cannot expire or damage")
	hazard.free()
	var health = load("res://src/core/health.gd").new(100)
	health.damage(30)
	health.heal(200)
	check(health.current == 100, "Healing capped")
	health.damage(500)
	health.heal(200)
	check(health.current == 0, "Cannot resurrect with healing")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(6)
	game.start_game()
	game.player.health.current = 1
	var projectile = load("res://src/combat/projectile.gd").new()
	var projectile_origin: Vector3 = game.player.global_position + Vector3(0, 3, 0)
	projectile.launch(projectile_origin, Vector3.DOWN, 240, 10, 1)
	game.effects.add_child(projectile)
	await frames(4)
	check(game.state == "OVER", "Lethal projectile ends the match")
	for effect in game.effects.get_children():
		check(not effect.active, "Effects created by lethal projectile are frozen")
	game.free()
	await create_timer(0.2).timeout
	print("Effects: %d failures" % failures)
	quit(1 if failures else 0)
