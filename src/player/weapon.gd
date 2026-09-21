extends RefCounted
## Ammunition is a magazine plus unlimited reserve, suitable for endless waves.

const CAPACITY: int = 12
const DAMAGE: float = 34.0
const CADENCE: float = 0.24
const RELOAD_TIME: float = 1.4

var ammo: int = CAPACITY
var cooldown: float = 0.0
var reload_left: float = 0.0
var reloading: bool = false

func tick(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)
	if reloading:
		reload_left = maxf(0.0, reload_left - delta)
		if reload_left == 0.0:
			ammo = CAPACITY
			reloading = false

func fire() -> bool:
	if reloading or cooldown > 0.0 or ammo <= 0:
		return false
	ammo -= 1
	cooldown = CADENCE
	return true

func reload() -> bool:
	if reloading or ammo == CAPACITY:
		return false
	reloading = true
	reload_left = RELOAD_TIME
	return true
