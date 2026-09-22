extends SceneTree
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	if not ResourceLoader.exists("res://src/player/loadout.gd"):
		check(false, "Loadout missing")
		quit(1)
		return
	var kit = load("res://src/player/loadout.gd").new()
	check(kit.equip("shotgun"), "Equip second weapon")
	check(kit.slots.size() == 2, "Two slots")
	check(not kit.equip("shotgun"), "Duplicate cannot refill")
	var gun = kit.current()
	gun.fire()
	gun.reload()
	kit.select_slot(0)
	kit.select_slot(1)
	check(gun.ammo == 7 and gun.reloading, "Switch preserves reload")
	gun.tick(5)
	check(gun.ammo == 8 and gun.reserve == 47, "Reload consumes finite reserve")
	gun.ammo = 0
	gun.reserve = 2
	gun.reload()
	gun.tick(5)
	check(gun.ammo == 2 and gun.reserve == 0, "Partial reserve only")
	gun.fire()
	check(not gun.reload(), "No free ammunition")
	check(not kit.equip("invalid"), "Unknown weapon rejected")
	check(kit.equip("rifle") and kit.slots.size() == 2, "Third weapon replaces slot")
	check(kit.slots[0].id == "service_pistol", "Inactive slot preserved")
	print("Arsenal: %d failures" % failures)
	quit(1 if failures else 0)
