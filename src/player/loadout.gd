extends RefCounted
const Weapon = preload("res://src/player/weapon.gd")
const Catalog = preload("res://src/data/weapon_catalog.gd")
var slots: Array = [Weapon.new(), null]
var active_slot: int = 0
func owns(id: String) -> bool:
	return slots.any(func(w): return w != null and w.id == id)
func equip(id: String) -> bool:
	if owns(id) or Catalog.get_definition(id).is_empty():
		return false
	if slots[1] == null:
		active_slot = 1
	slots[active_slot] = Weapon.new(id)
	return true
func select_slot(index: int) -> bool:
	if index < 0 or index >= 2 or slots[index] == null:
		return false
	active_slot = index
	return true
func current() -> RefCounted:
	return slots[active_slot]
func tick(delta: float, reload_modifier: float) -> void:
	for gun in slots:
		if gun:
			gun.reload_multiplier = reload_modifier
			gun.tick(delta)
