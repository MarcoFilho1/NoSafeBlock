extends RefCounted
const Props = preload("res://src/world/props.gd")

static func build(parent: Node3D, data: Dictionary) -> Node3D:
	var building := Node3D.new()
	building.position = data.position
	building.name = data.id
	parent.add_child(building)
	var size: Vector3 = data.size
	var color: Color = data.color
	if not data.enterable:
		Props.building(building, Vector3.ZERO, size, color, data.kind)
		for y in range(3, int(size.y), 3):
			for x in [-6, -3, 0, 3, 6]:
				Props.box(building, Vector3(1.4, 1.4, 0.06), Vector3(x, y, 8.54), Color("263738"))
				if (x + y) % 3 == 0:
					var board := Props.box(building, Vector3(1.6, 0.16, 0.1), Vector3(x, y, 8.6), Color("655a46"))
					board.rotation.z = 0.5
	else:
		Props.box(building, Vector3(17, 0.04, 17), Vector3(0, 0.04, 0), color.lightened(0.14))
		for x in [-8.5, 8.5]:
			Props.solid(building, Vector3(0.45, 4.5, 17), Vector3(x, 2.25, 0), color)
		for z in [-8.5, 8.5]:
			for x in [-5.0, 5.0]:
				Props.solid(building, Vector3(7, 4.5, 0.45), Vector3(x, 2.25, z), color)
			Props.box(building, Vector3(3, 0.45, 0.5), Vector3(0, 4.3, z), color)
		var roof := Props.box(building, Vector3(17.8, 0.3, 17.8), Vector3(0, 4.6, 0), color.darkened(0.5))
		roof.set_meta("roof", true)
		for x in [-5, 5]:
			Props.solid(building, Vector3(2, 0.8, 3), Vector3(x, 0.4, 2), Color("514b41"))
			Props.box(building, Vector3(2.1, 0.12, 3.1), Vector3(x, 0.85, 2), color.lightened(0.15))
		Props.sign_text(building, data.kind, Vector3(0, 3.5, 8.8), 48)
		Props.box(building, Vector3(2.8, 0.12, 0.12), Vector3(0, 2.7, -8.1), Color("edba68"))
	for i in range(4):
		var debris := Props.box(building, Vector3(0.6 + i * 0.13, 0.3, 0.8), Vector3(-7 + i * 2, 0.15, 10), color.darkened(0.2))
		debris.rotation.y = i * 0.7
	if data.kind == "ARMAZEM":
		for x in [-4, 0, 4]:
			Props.box(building, Vector3(2.8, 2.8, 2.2), Vector3(x, 1.4, -10), color.darkened(0.1))
	elif data.kind == "MOTEL":
		Props.box(building, Vector3(18, 0.3, 3), Vector3(0, 3, 10), color.darkened(0.3))
	elif data.kind == "LABORATORIO":
		Props.cylinder(building, 1.2, 4, Vector3(-5, 2, -10), Color("556a6b"))
		Props.cylinder(building, 1.2, 4, Vector3(5, 2, -10), Color("556a6b"))
	elif data.kind == "DELEGACIA":
		Props.box(building, Vector3(3, 0.3, 0.35), Vector3(0, 3, 9), Color("af695b"))
	return building

static func set_occluded(building: Node3D, value: bool) -> void:
	for node in building.find_children("*", "MeshInstance3D", true, false):
		var mat: StandardMaterial3D = node.material_override
		if mat:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if value else BaseMaterial3D.TRANSPARENCY_DISABLED
			mat.albedo_color.a = 0.14 if value else 1.0
