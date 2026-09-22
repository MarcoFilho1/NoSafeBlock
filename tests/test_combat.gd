extends SceneTree
## Roughly where the muzzle sits when the player is aiming.
const SHOT_HEIGHT: float = 1.25
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
	# Shots leave the muzzle flat at SHOT_HEIGHT and there is no vertical aim, so every
	# kind has to keep a body standing in that line. Focus zeroes the weapon spread, so a
	# miss here means a hitbox problem and not bad luck.
	game.player.focused = true
	var angle := 0.0
	for kind in ["walker", "runner", "flanker", "spitter", "demolisher", "screamer", "volatile", "executioner", "matriarch", "aberration"]:
		var found = clear_spot(game, combat, angle)
		check(found != null, "%s has somewhere to stand in the open" % kind)
		if found == null:
			continue
		angle = found.angle + 0.45
		var spot: Vector3 = found.spot
		var target = game.spawn_enemy(spot, kind)
		target.set_physics_process(false)
		await frames(3)
		var before: float = target.health.current
		game.player.weapon.cooldown = 0.0
		game.player.weapon.ammo = game.player.weapon.definition.capacity
		game.player.shoot_at(spot + Vector3(0, 1, 0))
		await frames(2)
		check(target.health.current < before, "%s can be hit by direct fire" % kind)
	game.free()
	await create_timer(0.2).timeout
	print("Combat: %d failures" % failures)
	quit(1 if failures else 0)

func clear_spot(game: Node, combat, from_angle: float) -> Variant:
	## Parked cars, stations and walls block shots, so find an open line before firing.
	for step in range(90):
		var angle: float = from_angle + step * 0.07
		var spot := Vector3(cos(angle) * 6.0, 0, sin(angle) * 6.0)
		if not game.spawn_position_clear(spot):
			continue
		var eye: Vector3 = game.player.global_position + Vector3(0, SHOT_HEIGHT, 0)
		if combat.clear_line(game.world.get_world_3d(), eye, spot + Vector3(0, SHOT_HEIGHT, 0)):
			return {"spot": spot, "angle": angle}
	return null
