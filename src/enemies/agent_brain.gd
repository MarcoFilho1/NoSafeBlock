extends RefCounted
## Perception -> decision. Enemy executes this state; no scene access here.

const DETECTION_RANGE: float = 12.0
const ATTACK_RANGE: float = 1.35
const LOSE_RANGE: float = 18.0
var state: String = "IDLE"

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
