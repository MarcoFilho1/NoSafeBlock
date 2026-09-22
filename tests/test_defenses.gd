extends SceneTree
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	if not ResourceLoader.exists("res://src/world/barricade.gd"):
		check(false, "Barricade missing")
		quit(1)
		return
	var p = load("res://src/systems/progression.gd").new()
	p.award(500)
	var barrier = load("res://src/world/barricade.gd").new()
	root.add_child(barrier)
	check(barrier.repair(p), "Build barricade")
	var before: int = p.balance
	check(not barrier.repair(p) and p.balance == before, "No repair spam")
	barrier.take_damage(1000)
	await physics_frame
	await physics_frame
	check(barrier.integrity == 0 and barrier.collision_layer == 0, "Destroyed barrier releases passage")
	check(p.earned == 500, "Repairs cannot farm rewards")
	barrier.free()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(6): await physics_frame
	game.start_game()
	var occupied = load("res://src/world/barricade.gd").new()
	occupied.position = game.player.global_position
	game.world.add_child(occupied)
	p.award(100)
	await physics_frame
	check(not occupied.repair(p), "Cannot rebuild barricade around player")
	game.player.position += Vector3(5, 0, 0)
	await physics_frame
	check(occupied.repair(p), "Rebuild succeeds after passage is clear")
	game.free()
	await create_timer(0.2).timeout
	print("Defenses: %d failures" % failures)
	quit(1 if failures else 0)
