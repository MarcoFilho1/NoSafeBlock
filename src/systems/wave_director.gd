extends RefCounted
## Pending and alive are separate: the last live kill need not end the wave.

const MAX_ACTIVE: int = 30
const MIN_SPAWN_DISTANCE: float = 10.0
var round_number: int = 0
var pending: int = 0
var alive: int = 0

func start_next() -> void:
	round_number += 1
	pending = 5 + (round_number - 1) * 3
	alive = 0

func register_spawn() -> bool:
	if pending <= 0 or alive >= MAX_ACTIVE:
		return false
	pending -= 1
	alive += 1
	return true

func register_kill() -> void:
	alive = maxi(0, alive - 1)

func is_clear() -> bool:
	return round_number > 0 and pending == 0 and alive == 0

func choose_spawn(points: Array[Vector3], player_position: Vector3) -> Variant:
	var safe: Array[Vector3] = []
	for point in points:
		if point.distance_to(player_position) >= MIN_SPAWN_DISTANCE:
			safe.append(point)
	return null if safe.is_empty() else safe.pick_random()
