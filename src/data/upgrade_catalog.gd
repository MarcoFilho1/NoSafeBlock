extends RefCounted
static func get_definition(id: String) -> Dictionary:
	var data := {
		"health": {"name": "Vitalidade", "values": [100.0, 125.0, 150.0, 175.0]},
		"resistance": {"name": "Pele de ferro", "values": [0.0, 0.08, 0.16, 0.24]},
		"reload": {"name": "Maos ligeiras", "values": [1.0, 0.9, 0.8, 0.7]},
		"movement": {"name": "Folego", "values": [1.0, 1.05, 1.1, 1.15]}}
	return data.get(id, {}).duplicate(true)
