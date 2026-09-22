extends SceneTree

var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if not ResourceLoader.exists("res://src/world/city_layout.gd"):
		check(false, "City layout is missing")
		quit(1)
		return
	var layout = load("res://src/world/city_layout.gd").definition()
	check(layout.bounds.size == Vector2(180, 180), "Expanded map bounds")
	check(layout.districts.size() == 5, "Five distinct districts")
	var interiors: Array = layout.buildings.filter(func(b): return b.enterable)
	check(interiors.size() >= 6, "Accessible interiors")
	var world = load("res://src/world/world.gd").new()
	root.add_child(world)
	for i in range(120):
		await physics_frame
		if world.navigation_ready:
			break
	check(world.navigation_ready, "Navigation ready")
	await physics_frame
	await physics_frame
	var map: RID = world.get_world_3d().navigation_map
	for b in interiors:
		check(b.entrances.size() >= 2, "Alternate escape route")
		var path = NavigationServer3D.map_get_path(map, Vector3.ZERO, b.position, true)
		if path.is_empty() or path[-1].distance_to(b.position) >= 1.0:
			print(b.id, " target=", b.position, " path=", path)
		check(path.size() > 1 and path[-1].distance_to(b.position) < 1.0, "Interior reachable: " + b.id)
	world.free()
	print("City: %d failures" % failures)
	quit(1 if failures else 0)
