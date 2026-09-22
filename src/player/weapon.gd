extends RefCounted
const Catalog = preload("res://src/data/weapon_catalog.gd")
const CAPACITY: int = 12
const DAMAGE: float = 34.0
const CADENCE: float = 0.24
const RELOAD_TIME: float = 1.4
var id: String
var definition: Dictionary
var ammo: int
var reserve: int
var cooldown: float = 0.0
var reload_left: float = 0.0
var reloading: bool = false
var reload_multiplier: float = 1.0
func _init(weapon_id: String = "service_pistol") -> void:
	id = weapon_id
	definition = Catalog.get_definition(id)
	if definition.is_empty():
		id = "service_pistol"
		definition = Catalog.get_definition(id)
	ammo = definition.capacity
	reserve = definition.reserve
func tick(delta: float) -> void:
	cooldown = maxf(0, cooldown - delta)
	if reloading:
		reload_left = maxf(0, reload_left - delta)
		if reload_left == 0:
			var amount: int = definition.capacity - ammo
			if reserve >= 0:
				amount = mini(amount, reserve)
				reserve -= amount
			ammo += amount
			reloading = false
func fire() -> bool:
	if reloading or cooldown > 0 or ammo <= 0:
		return false
	ammo -= 1
	cooldown = definition.cadence
	return true
func reload() -> bool:
	if reloading or ammo >= int(definition.capacity) or reserve == 0:
		return false
	reloading = true
	reload_left = float(definition.reload_time) * reload_multiplier
	return true
func refill() -> bool:
	if reserve < 0 or reserve >= int(definition.reserve):
		return false
	reserve = definition.reserve
	return true
