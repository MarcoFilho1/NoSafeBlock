extends RefCounted
const IDS := ["service_pistol", "heavy_pistol", "smg", "shotgun", "rifle", "sniper", "lmg", "plasma", "arc"]
const ROWS := [
	["Pistola de servico", 0, 12, -1, 34.0, 0.24, 1.4, 1, 0.065, "bullet", "edba68"],
	["Pistola pesada", 450, 8, 48, 75.0, 0.5, 1.8, 1, 0.055, "bullet", "edba68"],
	["Vespa / SMG", 900, 30, 180, 22.0, 0.09, 1.8, 1, 0.09, "bullet", "e2d59c"],
	["Calibre 12", 1200, 8, 48, 18.0, 0.85, 2.6, 8, 0.18, "bullet", "ffb36b"],
	["Fuzil Sentinela", 1800, 30, 150, 42.0, 0.14, 2.1, 1, 0.06, "bullet", "efdb9c"],
	["Olho Longo", 2400, 5, 35, 210.0, 1.1, 2.8, 1, 0.08, "bullet", "fff2ce"],
	["Bastiao / LMG", 3000, 75, 225, 36.0, 0.11, 4.0, 1, 0.1, "bullet", "e8a66a"],
	["Helios / Plasma", 4500, 12, 48, 120.0, 0.65, 2.8, 1, 0.03, "plasma", "62e8d0"],
	["Arco Zero", 5500, 20, 80, 85.0, 0.35, 2.5, 1, 0.025, "arc", "9fa3ff"]]
static func get_definition(id: String) -> Dictionary:
	var index := IDS.find(id)
	if index < 0:
		return {}
	var r: Array = ROWS[index]
	return {"id": id, "name": r[0], "price": r[1], "capacity": r[2], "reserve": r[3], "damage": r[4], "cadence": r[5], "reload_time": r[6], "pellets": r[7], "spread": r[8], "mode": r[9], "color": Color(r[10]), "range": 60.0 if id == "sniper" else 40.0, "move_multiplier": 0.85 if id == "lmg" else 1.0}
