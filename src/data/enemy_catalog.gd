extends RefCounted
const IDS := ["walker", "runner", "flanker", "spitter", "demolisher", "screamer", "volatile", "executioner", "matriarch", "aberration"]
const BOSS_IDS := ["executioner", "matriarch", "aberration"]
const ROWS := [
	["ERRANTE", 68.0, 1.8, 10.0, 10, "728260", Vector3.ONE],
	["CORREDOR", 48.0, 3.7, 8.0, 15, "ac8757", Vector3(0.8, 0.9, 0.8)],
	["FLANQUEADOR", 50.0, 3.7, 9.0, 20, "77a8a0", Vector3(0.95, 0.95, 0.95)],
	["CUSPIDOR", 110.0, 1.6, 12.0, 25, "a1bb60", Vector3(1.0, 1.15, 1.0)],
	["DEMOLIDOR", 260.0, 1.5, 22.0, 40, "986d54", Vector3(1.35, 1.25, 1.35)],
	["GRITADOR", 130.0, 2.0, 12.0, 35, "b28bb0", Vector3(0.85, 1.4, 0.85)],
	["VOLATIL", 95.0, 2.8, 14.0, 30, "cb7950", Vector3(1.25, 0.95, 1.25)],
	["CARRASCO", 2400.0, 1.9, 32.0, 1500, "a96048", Vector3(1.8, 1.65, 1.8)],
	["MATRIARCA", 3400.0, 1.5, 28.0, 2000, "91a353", Vector3(1.9, 1.55, 1.9)],
	["ABERRACAO", 4200.0, 2.0, 30.0, 2500, "799acb", Vector3(1.65, 1.9, 1.65)]]
static func get_definition(id: String) -> Dictionary:
	var index := IDS.find(id)
	if index < 0:
		index = 0
	var r: Array = ROWS[index]
	# Boss identity follows the id, not the row order, so new types can be inserted anywhere.
	return {"name": r[0], "health": r[1], "speed": r[2], "damage": r[3], "points": r[4], "color": Color(r[5]), "scale": r[6], "boss": IDS[index] in BOSS_IDS}
