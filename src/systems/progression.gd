extends RefCounted
const Upgrades = preload("res://src/data/upgrade_catalog.gd")
const Weapons = preload("res://src/data/weapon_catalog.gd")
const COSTS := [750, 1500, 3000]
var balance: int = 0
var earned: int = 0
var levels: Dictionary = {}
var weapon_levels: Dictionary = {}
func award(amount: int) -> void:
	if amount > 0:
		balance += amount
		earned += amount
func spend(amount: int) -> bool:
	if amount < 0 or amount > balance:
		return false
	balance -= amount
	return true
func upgrade_cost(id: String) -> int:
	var level: int = levels.get(id, 0)
	return COSTS[level] if not Upgrades.get_definition(id).is_empty() and level < 3 else -1
func buy_upgrade(id: String) -> bool:
	var cost := upgrade_cost(id)
	if cost < 0 or not spend(cost):
		return false
	levels[id] = int(levels.get(id, 0)) + 1
	return true
func buy_weapon_upgrade(id: String) -> bool:
	var level: int = weapon_levels.get(id, 0)
	if Weapons.get_definition(id).is_empty() or level >= 2 or not spend(1500 * (level + 1)):
		return false
	weapon_levels[id] = level + 1
	return true
func modifier(id: String) -> float:
	var data := Upgrades.get_definition(id)
	return data["values"][int(levels.get(id, 0))] if not data.is_empty() else 1.0
