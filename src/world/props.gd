extends RefCounted
## Small, original primitive kit. Visual meshes never participate in navigation baking.
##
## Geometry comes in two tiers. Structure carries the silhouette and the shadows;
## decoration only adds polygons to what the structure already put on screen, so
## it is culled sooner and never pays for a second pass in the shadow map. Extra
## detail then costs fill rate near the camera instead of frame time city-wide.

## Culling distances. The orthographic camera sits ~42 units from the player and
## its far screen corner lands ~63 units out, so decoration still has headroom.
const STRUCTURE_RANGE: float = 90.0
const DETAIL_RANGE: float = 75.0

static func material(color: Color, emission: bool = false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	if emission:
		mat.emission_enabled = true
		mat.emission = color
	return mat

static func attach(parent: Node3D, shape: Mesh, pos: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.mesh = shape
	mesh.material_override = material(color)
	mesh.position = pos
	mesh.visibility_range_end = STRUCTURE_RANGE
	parent.add_child(mesh)
	return mesh

static func detail(mesh: MeshInstance3D) -> MeshInstance3D:
	## Marks decoration: it fades out earlier and never casts a shadow.
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.visibility_range_end = DETAIL_RANGE
	return mesh

static func box(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = size
	return attach(parent, shape, pos, color)

static func solid(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)
	box(body, size, Vector3.ZERO, color)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	return body

static func cylinder(parent: Node3D, radius: float, height: float, pos: Vector3, color: Color, segments: int = 12) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = height
	shape.radial_segments = segments
	return attach(parent, shape, pos, color)

static func cone(parent: Node3D, radius: float, height: float, pos: Vector3, color: Color, segments: int = 10) -> MeshInstance3D:
	## Apex at +Y: lamp shades, roof caps and traffic cones all point up.
	var shape := CylinderMesh.new()
	shape.top_radius = 0.0
	shape.bottom_radius = radius
	shape.height = height
	shape.radial_segments = segments
	return attach(parent, shape, pos, color)

static func sphere(parent: Node3D, radius: float, pos: Vector3, color: Color, rings: int = 4, segments: int = 10) -> MeshInstance3D:
	var shape := SphereMesh.new()
	shape.radius = radius
	shape.height = radius * 2.0
	shape.radial_segments = segments
	shape.rings = rings
	return attach(parent, shape, pos, color)

static func wedge(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	## Triangular prism with the ridge running along Z: gable roofs and ramps,
	## the one silhouette a kit of boxes cannot produce.
	var shape := PrismMesh.new()
	shape.size = size
	return attach(parent, shape, pos, color)

static func ring(parent: Node3D, inner: float, outer: float, pos: Vector3, color: Color, segments: int = 12) -> MeshInstance3D:
	var shape := TorusMesh.new()
	shape.inner_radius = inner
	shape.outer_radius = outer
	shape.rings = segments
	shape.ring_segments = 4
	return attach(parent, shape, pos, color)

static func beam(parent: Node3D, from: Vector3, to: Vector3, thickness: float, color: Color) -> MeshInstance3D:
	## A box stretched between two points, so railings, masts, stairs and branches
	## stop needing hand-solved rotations.
	var span: Vector3 = to - from
	var length: float = span.length()
	var mesh := box(parent, Vector3(thickness, maxf(length, 0.001), thickness), (from + to) / 2.0, color)
	if length > 0.001:
		var up: Vector3 = span / length
		var side: Vector3 = (Vector3.FORWARD if absf(up.z) < 0.95 else Vector3.RIGHT).cross(up).normalized()
		mesh.basis = Basis(side, up, side.cross(up).normalized())
	return mesh

static func sign_text(parent: Node3D, text: String, pos: Vector3, size: int = 64) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = size
	label.pixel_size = 0.012
	label.position = pos
	label.modulate = Color("eee3c4")
	label.outline_size = 6
	parent.add_child(label)
	return label

static func window_unit(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> void:
	## Pane plus frame, mullion and sill, so a facade reads as openings in a wall
	## rather than dark rectangles painted onto it.
	var frame := color.lightened(0.28)
	var face := Vector3(0, 0, 0.02)
	detail(box(parent, size, pos, color))
	for y in [-1.0, 1.0]:
		detail(box(parent, Vector3(size.x + 0.14, 0.08, size.z + 0.04), pos + face + Vector3(0, y * size.y / 2.0, 0), frame))
	for x in [-1.0, 1.0]:
		detail(box(parent, Vector3(0.07, size.y + 0.14, size.z + 0.04), pos + face + Vector3(x * size.x / 2.0, 0, 0), frame))
	detail(box(parent, Vector3(0.06, size.y, size.z + 0.03), pos + face, frame))
	detail(box(parent, Vector3(size.x + 0.26, 0.09, size.z + 0.14), pos + Vector3(0, -size.y / 2.0 - 0.09, 0.06), frame.darkened(0.2)))

static func parapet(parent: Node3D, size: Vector3, pos: Vector3, thickness: float, color: Color) -> void:
	## A low wall around a roof: the skyline gains a lip instead of ending on a slab.
	for x in [-1.0, 1.0]:
		detail(box(parent, Vector3(thickness, size.y, size.z), pos + Vector3(x * (size.x - thickness) / 2.0, 0, 0), color))
	for z in [-1.0, 1.0]:
		detail(box(parent, Vector3(size.x - thickness * 2.0, size.y, thickness), pos + Vector3(0, 0, z * (size.z - thickness) / 2.0), color))
	detail(box(parent, Vector3(size.x + 0.12, 0.08, size.z + 0.12), pos + Vector3(0, size.y / 2.0, 0), color.darkened(0.3)))

static func water_tank(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color) -> void:
	var legs: float = 0.9
	for i in range(4):
		var angle: float = i * TAU / 4.0 + PI / 4.0
		var offset := Vector3(cos(angle) * radius * 0.72, 0, sin(angle) * radius * 0.72)
		detail(beam(parent, pos + offset, pos + offset + Vector3(0, legs, 0), 0.11, color.darkened(0.4)))
	detail(cylinder(parent, radius, height, pos + Vector3(0, legs + height / 2.0, 0), color, 12))
	for band in [0.3, 0.72]:
		detail(ring(parent, radius - 0.02, radius + 0.07, pos + Vector3(0, legs + height * band, 0), color.darkened(0.35)))
	detail(cone(parent, radius * 1.06, radius * 0.6, pos + Vector3(0, legs + height + radius * 0.29, 0), color.darkened(0.2), 12))
	for step in range(4):
		var rung: float = legs * 0.3 + step * 0.45
		detail(beam(parent, pos + Vector3(-radius - 0.12, rung, -0.18), pos + Vector3(-radius - 0.12, rung, 0.18), 0.05, color.darkened(0.45)))

static func roof_vent(parent: Node3D, pos: Vector3, color: Color) -> void:
	detail(box(parent, Vector3(1.6, 0.7, 1.2), pos + Vector3(0, 0.35, 0), color))
	detail(box(parent, Vector3(1.7, 0.08, 1.3), pos + Vector3(0, 0.72, 0), color.darkened(0.3)))
	for x in [-0.38, 0.38]:
		detail(cylinder(parent, 0.25, 0.14, pos + Vector3(x, 0.8, 0), color.darkened(0.35), 10))
	detail(box(parent, Vector3(0.45, 0.95, 0.45), pos + Vector3(0, 0.48, -1.0), color.darkened(0.15)))
	detail(cone(parent, 0.33, 0.3, pos + Vector3(0, 1.08, -1.0), color.darkened(0.4), 8))

static func antenna(parent: Node3D, pos: Vector3, height: float, color: Color) -> void:
	detail(beam(parent, pos, pos + Vector3(0, height, 0), 0.1, color))
	for i in range(3):
		var y: float = pos.y + height * (0.46 + i * 0.19)
		var arm: float = 0.6 - i * 0.14
		detail(beam(parent, Vector3(pos.x - arm, y, pos.z), Vector3(pos.x + arm, y, pos.z), 0.05, color))
	for i in range(3):
		var angle: float = i * TAU / 3.0
		detail(beam(parent, pos + Vector3(cos(angle) * 1.25, 0, sin(angle) * 1.25), pos + Vector3(0, height * 0.78, 0), 0.035, color.darkened(0.25)))
	var lamp := detail(sphere(parent, 0.11, pos + Vector3(0, height + 0.1, 0), Color("e2664f"), 4, 8))
	lamp.material_override = material(Color("e86a52"), true)

static func fire_escape(parent: Node3D, pos: Vector3, levels: int, color: Color) -> Node3D:
	## Platforms hang off -X; the caller rotates the returned rig onto a facade.
	var rig := Node3D.new()
	rig.position = pos
	parent.add_child(rig)
	for i in range(levels):
		var y: float = 2.8 + i * 3.0
		detail(box(rig, Vector3(1.5, 0.09, 3.2), Vector3(-0.75, y, 0), color))
		for z in [-1.55, 1.55]:
			detail(beam(rig, Vector3(-1.45, y, z), Vector3(-1.45, y + 1.0, z), 0.07, color))
		for rail in [0.55, 1.0]:
			detail(beam(rig, Vector3(-1.45, y + rail, -1.55), Vector3(-1.45, y + rail, 1.55), 0.05, color))
		if i + 1 >= levels:
			continue
		var flight := Node3D.new()
		flight.position = Vector3(-1.05, y + 1.5, 0)
		flight.rotation.x = 0.7
		rig.add_child(flight)
		for side in [-0.42, 0.42]:
			detail(box(flight, Vector3(0.08, 0.12, 3.5), Vector3(side, 0, 0), color.darkened(0.25)))
		for step in range(6):
			detail(box(flight, Vector3(0.84, 0.07, 0.24), Vector3(0, 0.08, -1.45 + step * 0.58), color.darkened(0.1)))
	return rig

static func drainpipe(parent: Node3D, base: Vector3, height: float, color: Color) -> void:
	detail(cylinder(parent, 0.11, height, base + Vector3(0, height / 2.0, 0), color, 8))
	for i in range(int(height / 2.2) + 1):
		detail(box(parent, Vector3(0.3, 0.09, 0.16), base + Vector3(0, 0.8 + i * 2.2, -0.1), color.darkened(0.3)))
	var elbow := detail(cylinder(parent, 0.11, 0.55, base + Vector3(0, 0.12, 0.2), color, 8))
	elbow.rotation.x = PI / 2.0

static func lamp_post(parent: Node3D, pos: Vector3, color: Color) -> void:
	detail(cylinder(parent, 0.24, 0.14, pos + Vector3(0, 0.07, 0), color.darkened(0.35), 8))
	detail(cylinder(parent, 0.11, 4.2, pos + Vector3(0, 2.2, 0), color, 8))
	detail(beam(parent, pos + Vector3(0, 4.24, 0), pos + Vector3(0.95, 4.5, 0), 0.08, color))
	detail(cone(parent, 0.3, 0.34, pos + Vector3(1.05, 4.36, 0), color.darkened(0.2), 8))
	var bulb := detail(sphere(parent, 0.15, pos + Vector3(1.05, 4.2, 0), Color("f0d08a"), 4, 8))
	bulb.material_override = material(Color("f4d79a"), true)

static func hydrant(parent: Node3D, pos: Vector3) -> void:
	var color := Color("a85a4b")
	detail(cylinder(parent, 0.27, 0.1, pos + Vector3(0, 0.05, 0), color.darkened(0.45), 8))
	detail(cylinder(parent, 0.17, 0.62, pos + Vector3(0, 0.4, 0), color, 10))
	detail(cylinder(parent, 0.22, 0.06, pos + Vector3(0, 0.62, 0), color.darkened(0.25), 10))
	detail(sphere(parent, 0.17, pos + Vector3(0, 0.72, 0), color.lightened(0.12), 4, 10))
	for x in [-0.19, 0.19]:
		var cap := detail(cylinder(parent, 0.09, 0.16, pos + Vector3(x, 0.44, 0), color.darkened(0.2), 8))
		cap.rotation.z = PI / 2.0

static func bin(parent: Node3D, pos: Vector3, color: Color) -> void:
	detail(cylinder(parent, 0.34, 0.95, pos + Vector3(0, 0.48, 0), color, 10))
	for y in [0.2, 0.76]:
		detail(ring(parent, 0.33, 0.39, pos + Vector3(0, y, 0), color.darkened(0.35), 10))
	detail(cylinder(parent, 0.37, 0.07, pos + Vector3(0, 0.98, 0), color.darkened(0.2), 10))
	detail(cone(parent, 0.26, 0.16, pos + Vector3(0, 1.08, 0), color.darkened(0.3), 8))

static func barrel(parent: Node3D, pos: Vector3, color: Color) -> void:
	detail(cylinder(parent, 0.35, 1.1, pos + Vector3(0, 0.55, 0), color, 10))
	for y in [0.3, 0.55, 0.8]:
		detail(ring(parent, 0.34, 0.4, pos + Vector3(0, y, 0), color.darkened(0.4), 10))
	detail(cylinder(parent, 0.36, 0.06, pos + Vector3(0, 1.1, 0), color.darkened(0.25), 10))
	detail(cylinder(parent, 0.09, 0.05, pos + Vector3(0.18, 1.14, 0), color.darkened(0.5), 6))

static func traffic_cone(parent: Node3D, pos: Vector3) -> void:
	detail(box(parent, Vector3(0.46, 0.06, 0.46), pos + Vector3(0, 0.03, 0), Color("2b3436")))
	detail(cone(parent, 0.2, 0.72, pos + Vector3(0, 0.4, 0), Color("c4713f"), 8))
	detail(ring(parent, 0.11, 0.16, pos + Vector3(0, 0.46, 0), Color("d9cfae"), 8))

static func bench(parent: Node3D, pos: Vector3, color: Color) -> void:
	for x in [-0.7, 0.7]:
		detail(box(parent, Vector3(0.12, 0.45, 0.5), pos + Vector3(x, 0.23, 0), color.darkened(0.45)))
		detail(beam(parent, pos + Vector3(x, 0.45, -0.2), pos + Vector3(x, 0.95, -0.34), 0.1, color.darkened(0.45)))
	for z in [-0.16, 0.06, 0.24]:
		detail(box(parent, Vector3(1.7, 0.08, 0.17), pos + Vector3(0, 0.48, z), color))
	for y in [0.66, 0.88]:
		detail(box(parent, Vector3(1.7, 0.16, 0.08), pos + Vector3(0, y, -0.27), color))

static func fence(parent: Node3D, from: Vector3, to: Vector3, color: Color, height: float = 1.5) -> void:
	var span: Vector3 = to - from
	var posts: int = maxi(2, int(span.length() / 1.6))
	for i in range(posts + 1):
		var at: Vector3 = from + span * (float(i) / posts)
		detail(beam(parent, at, at + Vector3(0, height, 0), 0.1, color))
		detail(cone(parent, 0.1, 0.16, at + Vector3(0, height + 0.08, 0), color.darkened(0.3), 6))
	for y in [height * 0.34, height * 0.8]:
		detail(beam(parent, from + Vector3(0, y, 0), to + Vector3(0, y, 0), 0.06, color.darkened(0.15)))

static func building(parent: Node3D, pos: Vector3, size: Vector3, color: Color, title: String, storefront: bool = true) -> void:
	## `storefront` draws the ground-level shop and its porch. City towers turn it
	## off and compose their own facade over the same shell.
	var body := solid(parent, size, pos + Vector3(0, size.y / 2.0, 0), color)
	var top: float = size.y / 2.0
	var front: float = size.z / 2.0
	box(body, Vector3(size.x + 0.5, 0.3, size.z + 0.5), Vector3(0, top, 0), color.darkened(0.4))
	parapet(body, Vector3(size.x + 0.5, 0.6, size.z + 0.5), Vector3(0, top + 0.45, 0), 0.2, color.darkened(0.25))
	if storefront:
		box(body, Vector3(size.x + 0.2, 0.35, 0.3), Vector3(0, 0.5, front + 0.15), Color("b5a780"))
		for x in [-size.x * 0.3, size.x * 0.3]:
			window_unit(body, Vector3(x, -0.15, front + 0.05), Vector3(1.4, 1.25, 0.08), Color("273d40"))
		box(body, Vector3(1.2, 2.2, 0.12), Vector3(0, -top + 1.1, front + 0.1), Color("344544"))
		# A slanted awning on two posts turns the doorway into a porch.
		var awning := detail(box(body, Vector3(2.1, 0.12, 1.3), Vector3(0, -top + 2.55, front + 0.68), Color("8c5b4c")))
		awning.rotation.x = 0.3
		for x in [-0.95, 0.95]:
			detail(beam(body, Vector3(x, -top + 2.4, front + 1.2), Vector3(x, -top, front + 1.2), 0.08, Color("6d5346")))
		detail(box(body, Vector3(2.4, 0.16, 1.5), Vector3(0, -top + 0.08, front + 0.7), color.darkened(0.15)))
	box(body, Vector3(size.x * 0.75, 0.85, 0.2), Vector3(0, top - 0.65, front + 0.1), Color("283a39"))
	sign_text(body, title, Vector3(0, top - 0.65, front + 0.22), 42)
	roofscape(body, size, Vector3(0, top, 0), color)

static func roofscape(body: Node3D, size: Vector3, roof: Vector3, color: Color) -> void:
	## Tank, a stair bulkhead under a gable, and — where the roof is wide enough
	## to hold them apart — a vent block and a mast.
	water_tank(body, roof + Vector3(-size.x * 0.22, 0.15, -size.z * 0.15), minf(0.85, size.x * 0.16), 1.25, Color("7c8073"))
	detail(box(body, Vector3(1.5, 1.1, 1.4), roof + Vector3(size.x * 0.24, 0.7, size.z * 0.18), Color("778078")))
	detail(wedge(body, Vector3(1.75, 0.5, 1.6), roof + Vector3(size.x * 0.24, 1.5, size.z * 0.18), Color("5f6a63")))
	detail(box(body, Vector3(0.6, 0.85, 0.06), roof + Vector3(size.x * 0.24, 0.58, size.z * 0.18 + 0.72), Color("38453f")))
	if size.x >= 6.0:
		roof_vent(body, roof + Vector3(-size.x * 0.05, 0.15, size.z * 0.3), Color("6b7370"))
		antenna(body, roof + Vector3(size.x * 0.33, 0.2, -size.z * 0.3), 2.1, Color("444d49"))
	drainpipe(body, roof + Vector3(-size.x / 2.0 - 0.12, -size.y, size.z / 2.0 + 0.1), size.y, color.darkened(0.3))

static func car(parent: Node3D, pos: Vector3, color: Color) -> void:
	var body := solid(parent, Vector3(1.8, 1.1, 3.5), pos + Vector3(0, 0.65, 0), color)
	box(body, Vector3(1.55, 0.65, 1.6), Vector3(0, 0.75, -0.1), color.darkened(0.15))
	# Raked glass front and back, so the shape stops reading as stacked crates.
	var windshield := detail(box(body, Vector3(1.45, 0.78, 0.07), Vector3(0, 0.74, 0.72), Color("263d43")))
	windshield.rotation.x = 0.62
	var rear := detail(box(body, Vector3(1.42, 0.68, 0.07), Vector3(0, 0.76, -0.9), Color("22363c")))
	rear.rotation.x = -0.55
	for x in [-0.95, 0.95]:
		for z in [-1.15, 1.15]:
			var tyre := detail(cylinder(body, 0.31, 0.24, Vector3(x, -0.34, z), Color("202b2e"), 10))
			tyre.rotation.z = PI / 2.0
			var hub := detail(cylinder(body, 0.15, 0.26, Vector3(x * 1.01, -0.34, z), Color("79817d"), 8))
			hub.rotation.z = PI / 2.0
		detail(box(body, Vector3(0.1, 0.5, 2.3), Vector3(x * 1.02, -0.05, 0), color.darkened(0.3)))
		var mirror := detail(box(body, Vector3(0.26, 0.14, 0.1), Vector3(x * 1.12, 0.62, 0.55), color.darkened(0.25)))
		mirror.rotation.y = -x * 0.35
	for x in [-0.6, 0.6]:
		detail(box(body, Vector3(0.4, 0.22, 0.06), Vector3(x, 0.04, -1.78), Color("c4b58c")))
		detail(box(body, Vector3(0.36, 0.16, 0.06), Vector3(x, 0.04, 1.78), Color("8e5a4c")))
	for z in [-1.78, 1.78]:
		detail(box(body, Vector3(1.75, 0.2, 0.22), Vector3(0, -0.2, z), color.darkened(0.4)))
	var pipe := detail(cylinder(body, 0.07, 0.3, Vector3(-0.55, -0.42, -1.85), Color("545c59"), 6))
	pipe.rotation.x = PI / 2.0

static func tree(parent: Node3D, pos: Vector3) -> void:
	solid(parent, Vector3(0.5, 2.1, 0.5), pos + Vector3(0, 1.05, 0), Color("625a48"))
	## A forked dead canopy: each limb splits once instead of three flat planks.
	var crown := pos + Vector3(0, 2.05, 0)
	for i in range(5):
		var angle: float = i * TAU / 5.0 + 0.4
		var reach := Vector3(cos(angle), 0, sin(angle))
		var fork: Vector3 = crown + reach * 0.95 + Vector3(0, 1.3 + (i % 2) * 0.4, 0)
		detail(beam(parent, crown, fork, 0.17, Color("595647")))
		detail(beam(parent, fork, fork + reach * 0.55 + Vector3(0, 0.85, 0), 0.09, Color("4f4c40")))
		detail(beam(parent, fork, fork + reach.rotated(Vector3.UP, 0.9) * 0.7 + Vector3(0, 0.45, 0), 0.08, Color("4f4c40")))
