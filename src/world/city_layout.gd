extends RefCounted
## Stable city geometry and points of interest, independent of the scene tree.
static func definition() -> Dictionary:
	var districts: Array = [
		{"name": "CENTRO / LAST STOP", "position": Vector3.ZERO, "color": Color("d6a562")},
		{"name": "PALM HEIGHTS", "position": Vector3(-52, 0, -52), "color": Color("80968a")},
		{"name": "IRON YARD", "position": Vector3(-52, 0, 52), "color": Color("bd8561")},
		{"name": "SUNSET AVENUE", "position": Vector3(52, 0, 52), "color": Color("cbaa78")},
		{"name": "ZONA ZERO", "position": Vector3(52, 0, -52), "color": Color("73bdc2")}
	]
	var buildings: Array = []
	var kinds := ["APARTAMENTOS", "MOTEL", "CLINICA", "DELEGACIA", "DINER", "ARMAZEM", "LABORATORIO", "MERCADO"]
	for x in [-75, -45, -15, 15, 45, 75]:
		for z in [-75, -45, -15, 15, 45, 75]:
			if absi(x) < 20 and absi(z) < 20:
				continue
			var n: int = buildings.size()
			var pos := Vector3(x, 0, z)
			var accessible: bool = n % 3 == 0
			buildings.append({"id": "block_%d" % n, "position": pos,
				"size": Vector3(17, 4.5 if accessible else 6 + n % 5 * 2, 17),
				"kind": kinds[n % kinds.size()], "enterable": accessible,
				"entrances": [pos + Vector3(0, 0, 8.5), pos - Vector3(0, 0, 8.5)] if accessible else [],
				"color": districts[1 + n % 4].color.darkened(0.3)})
	var spawns: Array[Vector3] = []
	for x in range(-80, 81, 10):
		for z in range(-80, 81, 10):
			if x % 30 == 0 or z % 30 == 0:
				spawns.append(Vector3(x, 0, z))
	return {"bounds": Rect2(-90, -90, 180, 180), "districts": districts,
		"buildings": buildings, "stations": [], "defenses": [], "spawn_points": spawns}
