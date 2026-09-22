extends RefCounted
## Perception -> decision. Enemy executes this state; no scene access here.

const DETECTION_RANGE: float = 12.0
const ATTACK_RANGE: float = 1.35
const LOSE_RANGE: float = 18.0
## Below this distance the flanker stops circling and commits to the target.
const FLANK_COMMIT_RANGE: float = 3.2
## Widest lateral offset applied to the approach point.
const FLANK_REACH: float = 6.0
var state: String = "IDLE"
## 0 approaches head-on; -1 and 1 approach from the left or the right.
var flank_side: float = 0.0

func decide(distance: float, alive: bool, alerted: bool, attack_visible: bool = true) -> String:
	if not alive or state == "DEAD":
		state = "DEAD"
	elif distance <= ATTACK_RANGE and attack_visible:
		state = "ATTACK"
	elif distance <= DETECTION_RANGE or alerted or (state in ["CHASE", "ATTACK"] and distance <= LOSE_RANGE):
		state = "CHASE"
	else:
		state = "PATROL"
	return state

func approach_target(origin: Vector3, target: Vector3) -> Vector3:
	## Where to walk to reach the target. Head-on agents keep flank_side at 0 and
	## get the target itself; a flanker aims beside it and closes the gap as it arrives.
	var to_target := target - origin
	to_target.y = 0.0
	var distance := to_target.length()
	if is_zero_approx(flank_side) or distance <= FLANK_COMMIT_RANGE:
		return target
	var lateral := Vector3(to_target.z, 0.0, -to_target.x).normalized()
	var reach := minf(FLANK_REACH, distance - FLANK_COMMIT_RANGE)
	return target + lateral * flank_side * reach
