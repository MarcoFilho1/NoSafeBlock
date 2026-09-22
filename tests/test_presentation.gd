extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var actor = load("res://src/visuals/actor_visual.gd").new()
	root.add_child(actor)
	actor.build(false)
	actor.animate(0.016, 0, true, true)
	var failures: int = 0
	var muzzle: Vector3 = actor.muzzle.global_position
	if muzzle.z >= -0.4:
		failures += 1
		push_error("Focused gun must point forward (-Z), muzzle: " + str(muzzle))
	actor.rotation.y = PI / 2
	if actor.muzzle.global_position.x >= -0.4:
		failures += 1
		push_error("Gun follows actor aim rotation")
	actor.free()
	print("Presentation: 2 checks, %d failures" % failures)
	quit(1 if failures else 0)
