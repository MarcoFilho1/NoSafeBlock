extends SceneTree
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	if not ResourceLoader.exists("res://src/systems/progression.gd"):
		check(false, "Progression missing")
		quit(1)
		return
	var p = load("res://src/systems/progression.gd").new()
	p.award(450)
	check(not p.spend(451) and p.balance == 450, "Insufficient balance atomic")
	check(p.spend(450) and p.balance == 0 and p.earned == 450, "Exact balance purchase")
	check(not p.spend(-10), "Reject negative costs")
	check(not p.buy_upgrade("invalid"), "Reject invalid upgrade")
	p.award(100000)
	for id in ["health", "resistance", "reload", "movement"]:
		for i in range(3):
			check(p.buy_upgrade(id), "Buy allowed level")
		var before: int = p.balance
		check(not p.buy_upgrade(id) and p.balance == before, "Cap purchase never charges")
	check(p.modifier("health") == 175, "Health cap")
	check(is_equal_approx(p.modifier("resistance"), 0.24), "Resistance cap")
	check(is_equal_approx(p.modifier("reload"), 0.7), "Reload cap")
	check(is_equal_approx(p.modifier("movement"), 1.15), "Movement cap")
	check(p.buy_weapon_upgrade("shotgun"), "Weapon level one")
	check(p.buy_weapon_upgrade("shotgun"), "Weapon level two")
	check(not p.buy_weapon_upgrade("shotgun"), "Weapon level capped")
	var before: int = p.balance
	p.award(-500)
	check(p.balance == before, "Negative reward ignored")
	print("Progression: %d failures" % failures)
	quit(1 if failures else 0)
