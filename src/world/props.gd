extends RefCounted
## Small, original primitive kit. Visual meshes never participate in navigation baking.

static func material(color: Color, emission: bool = false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	if emission:
		mat.emission_enabled = true
		mat.emission = color
	return mat

static func box(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = material(color)
	mesh.position = pos
	parent.add_child(mesh)
	return mesh

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

static func cylinder(parent: Node3D, radius: float, height: float, pos: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = height
	shape.radial_segments = 8
	mesh.mesh = shape
	mesh.material_override = material(color)
	mesh.position = pos
	parent.add_child(mesh)
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

static func building(parent: Node3D, pos: Vector3, size: Vector3, color: Color, title: String) -> void:
	var body := solid(parent, size, pos + Vector3(0, size.y / 2.0, 0), color)
	box(body, Vector3(size.x + 0.5, 0.3, size.z + 0.5), Vector3(0, size.y / 2.0, 0), color.darkened(0.4))
	box(body, Vector3(size.x + 0.2, 0.35, 0.3), Vector3(0, 0.5, size.z / 2.0 + 0.15), Color("b5a780"))
	for x in [-size.x * 0.3, size.x * 0.3]:
		box(body, Vector3(1.4, 1.25, 0.08), Vector3(x, -0.15, size.z / 2.0 + 0.05), Color("273d40"))
		box(body, Vector3(1.6, 0.15, 0.16), Vector3(x, -0.6, size.z / 2.0 + 0.1), Color("756e59"))
	box(body, Vector3(1.2, 2.2, 0.12), Vector3(0, -size.y / 2.0 + 1.1, size.z / 2.0 + 0.1), Color("344544"))
	box(body, Vector3(size.x * 0.75, 0.85, 0.2), Vector3(0, size.y / 2.0 - 0.65, size.z / 2.0 + 0.1), Color("283a39"))
	sign_text(body, title, Vector3(0, size.y / 2.0 - 0.65, size.z / 2.0 + 0.22), 42)
	box(body, Vector3(1.5, 0.65, 1.5), Vector3(-1.4, size.y / 2.0 + 0.5, 0), Color("778078"))
	box(body, Vector3(0.25, 1.8, 0.25), Vector3(1.7, size.y / 2.0 + 0.7, -1), Color("444d49"))

static func car(parent: Node3D, pos: Vector3, color: Color) -> void:
	var body := solid(parent, Vector3(1.8, 1.1, 3.5), pos + Vector3(0, 0.65, 0), color)
	box(body, Vector3(1.55, 0.65, 1.6), Vector3(0, 0.75, -0.1), color.darkened(0.15))
	box(body, Vector3(1.4, 0.5, 0.05), Vector3(0, 0.72, 0.74), Color("263d43"))
	for x in [-0.95, 0.95]:
		for z in [-1.15, 1.15]:
			box(body, Vector3(0.28, 0.55, 0.6), Vector3(x, -0.35, z), Color("202b2e"))
	for x in [-0.6, 0.6]:
		box(body, Vector3(0.4, 0.22, 0.06), Vector3(x, 0.04, -1.78), Color("c4b58c"))

static func tree(parent: Node3D, pos: Vector3) -> void:
	solid(parent, Vector3(0.5, 2.1, 0.5), pos + Vector3(0, 1.05, 0), Color("625a48"))
	var crown := cylinder(parent, 1.4, 2.3, pos + Vector3(0, 3, 0), Color("536650"))
	crown.mesh.top_radius = 0.15
