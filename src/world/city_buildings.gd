extends RefCounted
const Props = preload("res://src/world/props.gd")

static func build(parent: Node3D, data: Dictionary) -> Node3D:
	var building := Node3D.new()
	building.position = data.position
	building.name = data.id
	parent.add_child(building)
	var size: Vector3 = data.size
	var color: Color = data.color
	# Deterministic per-block variation, so the skyline repeats less than the grid.
	var variant: int = int(data.id.get_slice("_", 1))
	if data.enterable:
		interior(building, color, data.kind)
	else:
		tower(building, size, color, data.kind, variant)
	for i in range(4):
		var debris := Props.detail(Props.box(building, Vector3(0.6 + i * 0.13, 0.3, 0.8), Vector3(-7 + i * 2, 0.15, 10), color.darkened(0.2)))
		debris.rotation.y = i * 0.7
	if data.kind == "ARMAZEM":
		for x in [-4, 0, 4]:
			Props.box(building, Vector3(2.8, 2.8, 2.2), Vector3(x, 1.4, -10), color.darkened(0.1))
			Props.detail(Props.wedge(building, Vector3(3.0, 0.7, 2.4), Vector3(x, 3.15, -10), color.darkened(0.35)))
	elif data.kind == "MOTEL":
		Props.box(building, Vector3(18, 0.3, 3), Vector3(0, 3, 10), color.darkened(0.3))
		for x in [-7.0, -2.5, 2.5, 7.0]:
			Props.detail(Props.beam(building, Vector3(x, 0, 11.3), Vector3(x, 3, 11.3), 0.16, color.darkened(0.45)))
	elif data.kind == "LABORATORIO":
		for x in [-5, 5]:
			Props.cylinder(building, 1.2, 4, Vector3(x, 2, -10), Color("556a6b"))
			Props.detail(Props.cone(building, 1.3, 0.9, Vector3(x, 4.4, -10), Color("47595b"), 12))
			for band in [1.0, 3.0]:
				Props.detail(Props.ring(building, 1.18, 1.32, Vector3(x, band, -10), Color("3e4f51")))
		Props.detail(Props.beam(building, Vector3(-5, 3.4, -10), Vector3(5, 3.4, -10), 0.18, Color("46585a")))
	elif data.kind == "DELEGACIA":
		Props.box(building, Vector3(3, 0.3, 0.35), Vector3(0, 3, 9), Color("af695b"))
		for x in [-1.1, 1.1]:
			var beacon := Props.detail(Props.cylinder(building, 0.22, 0.3, Vector3(x, 3.35, 9), Color("d4604f"), 8))
			beacon.material_override = Props.material(Color("d4604f"), true)
	return building

static func tower(building: Node3D, size: Vector3, color: Color, kind: String, variant: int) -> void:
	## Windowless slabs became a banded facade: pilasters split the front into
	## bays, a cornice closes every floor, and the street level is a real shopfront.
	Props.building(building, Vector3.ZERO, size, color, kind, false)
	var face: float = 8.54
	for x in [-7.5, -4.5, -1.5, 1.5, 4.5, 7.5]:
		Props.detail(Props.box(building, Vector3(0.55, size.y - 0.7, 0.35), Vector3(x, size.y / 2.0, 8.4), color.lightened(0.08)))
	for y in range(3, int(size.y), 3):
		Props.detail(Props.box(building, Vector3(size.x + 0.7, 0.24, size.z + 0.7), Vector3(0, y - 1.35, 0), color.darkened(0.35)))
		for x in [-6, -3, 0, 3, 6]:
			Props.detail(Props.box(building, Vector3(1.4, 1.4, 0.06), Vector3(x, y, face), Color("263738")))
			Props.detail(Props.box(building, Vector3(1.7, 0.12, 0.3), Vector3(x, y - 0.78, face + 0.08), color.lightened(0.2)))
			if (x + y) % 3 == 0:
				var board := Props.detail(Props.box(building, Vector3(1.6, 0.16, 0.1), Vector3(x, y, face + 0.06), Color("655a46")))
				board.rotation.z = 0.5
	Props.detail(Props.box(building, Vector3(13.0, 2.2, 0.3), Vector3(0, 1.5, 8.42), Color("22302f")))
	for x in [-4.4, 0.0, 4.4]:
		Props.detail(Props.box(building, Vector3(0.45, 2.4, 0.5), Vector3(x, 1.45, 8.5), color.darkened(0.2)))
	var awning := Props.detail(Props.box(building, Vector3(13.4, 0.16, 1.9), Vector3(0, 3.05, 9.35), color.darkened(0.45)))
	awning.rotation.x = 0.26
	Props.detail(Props.box(building, Vector3(14.0, 0.18, 1.6), Vector3(0, 0.09, 9.2), color.darkened(0.1)))
	roof_extras(building, size, color, variant)

static func roof_extras(building: Node3D, size: Vector3, color: Color, variant: int) -> void:
	## The free corners of the roof, dressed differently per block.
	if variant % 2 == 0:
		for i in range(3):
			Props.detail(Props.box(building, Vector3(1.1, 0.9, 1.1), Vector3(-6.2 + i * 1.3, size.y + 0.9, -6.4 + i * 0.7), color.darkened(0.1)))
	if variant % 4 == 0:
		var mount := Vector3(-6.0, size.y + 0.15, 6.0)
		Props.detail(Props.beam(building, mount, mount + Vector3(0, 0.9, 0), 0.12, Color("4a5450")))
		var dish := Props.detail(Props.cone(building, 0.85, 0.55, mount + Vector3(0, 1.2, 0), Color("8a918a"), 12))
		dish.rotation.x = 2.3
		Props.detail(Props.box(building, Vector3(0.18, 0.18, 0.5), mount + Vector3(0, 1.05, 0.55), Color("3f4844")))
	if variant % 3 == 1:
		Props.fire_escape(building, Vector3(-8.4, 0, 0), maxi(2, mini(4, int(size.y / 3.0))), Color("4a5450"))

static func interior(building: Node3D, color: Color, kind: String) -> void:
	Props.box(building, Vector3(17, 0.04, 17), Vector3(0, 0.04, 0), color.lightened(0.14))
	# Joint lines break up a 17 m slab without adding anything to walk around.
	for i in [-6.0, -2.0, 2.0, 6.0]:
		Props.detail(Props.box(building, Vector3(16.6, 0.03, 0.08), Vector3(0, 0.07, i), color.darkened(0.18)))
		Props.detail(Props.box(building, Vector3(0.08, 0.03, 16.6), Vector3(i, 0.07, 0), color.darkened(0.18)))
	for x in [-8.5, 8.5]:
		Props.solid(building, Vector3(0.45, 4.5, 17), Vector3(x, 2.25, 0), color)
	for z in [-8.5, 8.5]:
		for x in [-5.0, 5.0]:
			Props.solid(building, Vector3(7, 4.5, 0.45), Vector3(x, 2.25, z), color)
		Props.box(building, Vector3(3, 0.45, 0.5), Vector3(0, 4.3, z), color)
	# Pilasters and a cornice give the walls depth; both sit flush, so the
	# navigation bake and the routes through the doors are unchanged.
	for x in [-8.15, 8.15]:
		for z in [-6.0, 0.0, 6.0]:
			Props.detail(Props.box(building, Vector3(0.35, 4.3, 0.9), Vector3(x, 2.15, z), color.lightened(0.1)))
	for x in [-8.45, 8.45]:
		Props.detail(Props.box(building, Vector3(0.5, 0.3, 17.4), Vector3(x, 4.2, 0), color.darkened(0.3)))
	for z in [-8.45, 8.45]:
		Props.detail(Props.box(building, Vector3(17.4, 0.3, 0.5), Vector3(0, 4.2, z), color.darkened(0.3)))
	var roof := Props.box(building, Vector3(17.8, 0.3, 17.8), Vector3(0, 4.6, 0), color.darkened(0.5))
	roof.set_meta("roof", true)
	Props.parapet(building, Vector3(17.8, 0.7, 17.8), Vector3(0, 5.05, 0), 0.3, color.darkened(0.35))
	Props.detail(Props.box(building, Vector3(3.4, 0.16, 3.4), Vector3(-3.5, 4.82, -3.5), Color("3c4f52")))
	for i in [-0.9, 0.0, 0.9]:
		Props.detail(Props.box(building, Vector3(3.5, 0.2, 0.14), Vector3(-3.5, 4.88, -3.5 + i), color.darkened(0.2)))
	# A guardrail around the skylight: visible from the camera, out of play.
	Props.fence(building, Vector3(-5.6, 4.75, -1.4), Vector3(-1.4, 4.75, -1.4), color.darkened(0.45), 1.05)
	Props.fence(building, Vector3(-1.4, 4.75, -1.4), Vector3(-1.4, 4.75, -5.6), color.darkened(0.45), 1.05)
	Props.roof_vent(building, Vector3(4.2, 4.75, 2.6), color.darkened(0.25))
	Props.water_tank(building, Vector3(4.6, 4.75, -4.6), 0.8, 1.2, Color("7c8073"))
	Props.detail(Props.box(building, Vector3(1.8, 1.2, 1.6), Vector3(-1.5, 5.35, 5.2), color.darkened(0.15)))
	Props.detail(Props.wedge(building, Vector3(2.1, 0.55, 1.8), Vector3(-1.5, 6.22, 5.2), color.darkened(0.4)))
	for x in [-5, 5]:
		Props.solid(building, Vector3(2, 0.8, 3), Vector3(x, 0.4, 2), Color("514b41"))
		Props.box(building, Vector3(2.1, 0.12, 3.1), Vector3(x, 0.85, 2), color.lightened(0.15))
	Props.sign_text(building, kind, Vector3(0, 3.5, 8.8), 48)
	Props.box(building, Vector3(2.8, 0.12, 0.12), Vector3(0, 2.7, -8.1), Color("edba68"))
	# A canopy marks the street entrance from across the block.
	var canopy := Props.detail(Props.box(building, Vector3(4.4, 0.14, 1.7), Vector3(0, 3.3, 9.4), Color("8c5b4c")))
	canopy.rotation.x = -0.26
	for x in [-2.0, 2.0]:
		Props.detail(Props.box(building, Vector3(0.22, 3.2, 0.22), Vector3(x, 1.6, 8.75), Color("6d5346")))

static func set_occluded(building: Node3D, value: bool) -> void:
	for node in building.find_children("*", "MeshInstance3D", true, false):
		var mat: StandardMaterial3D = node.material_override
		if mat:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if value else BaseMaterial3D.TRANSPARENCY_DISABLED
			mat.albedo_color.a = 0.14 if value else 1.0
