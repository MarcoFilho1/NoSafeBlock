extends RefCounted
## Pending and alive are separate: the last live kill need not end the wave.

const MAX_ACTIVE: int = 30
const MIN_SPAWN_DISTANCE: float = 10.0
var round_number: int = 0
var pending: int = 0
var alive: int = 0
var boss_pending: bool = false

func start_next() -> void:
	round_number += 1
	pending = 5 + (round_number - 1) * 3
	alive = 0
	boss_pending = round_number % 10 == 0

func register_spawn() -> bool:
	if pending <= 0 or alive >= MAX_ACTIVE:
		return false
	pending -= 1
	alive += 1
	return true

func register_kill() -> void:
	alive = maxi(0, alive - 1)

func is_clear() -> bool:
	return round_number > 0 and pending == 0 and alive == 0 and not boss_pending

func choose_spawn(points: Array[Vector3], player_position: Vector3) -> Variant:
	var safe: Array[Vector3] = []
	for point in points:
		if point.distance_to(player_position) >= MIN_SPAWN_DISTANCE:
			safe.append(point)
	return null if safe.is_empty() else safe.pick_random()

func enemy_kind(roll: float) -> String:
	var available: Array[String] = []
	var ids := ["runner", "spitter", "demolisher", "screamer", "volatile"]
	var rounds := [3, 5, 7, 9, 12]
	for i in range(ids.size()):
		if round_number >= rounds[i]:
			available.append(ids[i])
	var weight := minf(0.65, 0.16 + round_number * 0.02)
	if available.is_empty() or roll >= weight:
		return "walker"
	return available[mini(available.size() - 1, int(maxf(0, roll) / weight * available.size()))]
func spawn_interval() -> float:
	return maxf(0.25, 0.65 - 0.012 * (round_number - 1))
func boss_kind() -> String:
	if round_number <= 0 or round_number % 10 != 0:
		return ""
	return ["executioner", "matriarch", "aberration"][(int(round_number / 10.0) - 1) % 3]
func register_boss_spawn() -> bool:
	if not boss_pending or alive >= MAX_ACTIVE:
		return false
	boss_pending = false
	alive += 1
	return true
func register_summon() -> bool:
	if alive >= MAX_ACTIVE:
		return false
	alive += 1
	return true
