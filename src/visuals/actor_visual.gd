extends Node3D
## Procedural animation keeps assets editable and dependency-free.

const Props = preload("res://src/world/props.gd")
var torso: Node3D
var left_leg: Node3D
var right_leg: Node3D
var left_arm: Node3D
var right_arm: Node3D
var muzzle: Node3D
var flash: MeshInstance3D
var ring: MeshInstance3D
var phase: float = 0.0
var recoil: float = 0.0
var hit_time: float = 0.0
var death_time: float = 0.0
var zombie: bool = false
var body_material: StandardMaterial3D

func build(is_zombie: bool) -> void:
	zombie = is_zombie
	var coat := Color("728260") if zombie else Color("d7934d")
	var skin := Color("a0ab84") if zombie else Color("d8b48e")
	var shadow := Props.cylinder(self, 0.52, 0.015, Vector3(0, 0.015, 0), Color("233c39"))
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	torso = Node3D.new()
	add_child(torso)
	var body := Props.box(torso, Vector3(0.65, 0.65, 0.38), Vector3(0, 1.02, 0), coat)
	body_material = body.material_override
	Props.box(torso, Vector3(0.42, 0.44, 0.42), Vector3(0, 1.58, -0.015), skin)
	Props.box(torso, Vector3(0.46, 0.15, 0.45), Vector3(0, 1.84, 0), Color("374846"))
	for x in [-0.12, 0.12]:
		Props.box(torso, Vector3(0.07, 0.045, 0.025), Vector3(x, 1.64, -0.237), Color("e8bd6c") if zombie else Color("293c42"))
	left_leg = limb(Vector3(-0.19, 0.65, 0), Vector3(0.23, 0.58, 0.26), Color("364d50"))
	right_leg = limb(Vector3(0.19, 0.65, 0), Vector3(0.23, 0.58, 0.26), Color("364d50"))
	left_arm = limb(Vector3(-0.43, 1.25, 0), Vector3(0.19, 0.55, 0.24), coat)
	right_arm = limb(Vector3(0.43, 1.25, 0), Vector3(0.19, 0.55, 0.24), coat)
	if not zombie:
		Props.box(torso, Vector3(0.4, 0.5, 0.19), Vector3(0, 1, 0.28), Color("5c6752"))
		Props.box(right_arm, Vector3(0.13, 0.32, 0.2), Vector3(0, -0.62, 0.02), Color("27383d"))
		muzzle = Node3D.new()
		muzzle.position = Vector3(0, -0.81, 0.02)
		right_arm.add_child(muzzle)
		flash = Props.box(muzzle, Vector3(0.2, 0.25, 0.2), Vector3.ZERO, Color("ffe5a1"))
		flash.material_override = Props.material(Color("ffe5a1"), true)
		flash.visible = false
		var mesh := TorusMesh.new()
		mesh.inner_radius = 0.52
		mesh.outer_radius = 0.60
		ring = MeshInstance3D.new()
		ring.mesh = mesh
		ring.material_override = Props.material(Color("edba68"), true)
		ring.material_override.no_depth_test = true
		ring.position.y = 0.08
		add_child(ring)

func limb(pos: Vector3, size: Vector3, color: Color) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = pos
	torso.add_child(pivot)
	Props.box(pivot, size, Vector3(0, -size.y / 2.0, 0), color)
	return pivot

func animate(delta: float, speed: float, focus: bool, alive: bool, attacking: bool = false, reloading: bool = false) -> void:
	if not alive:
		death_time = minf(death_time + delta * 3, 1.0)
		rotation.z = lerpf(0.0, -PI / 2, death_time)
		position.y = -0.05
		if ring:
			ring.visible = false
		return
	phase += delta * (8.0 if zombie else 12.0)
	recoil = maxf(0, recoil - delta * 7)
	hit_time = maxf(0, hit_time - delta)
	var stride := minf(speed / 3.0, 1.0)
	left_leg.rotation.x = sin(phase) * 0.55 * stride
	right_leg.rotation.x = -sin(phase) * 0.55 * stride
	torso.position.y = absf(sin(phase)) * 0.06 * stride - (0.08 if focus else 0.0)
	torso.rotation.z = sin(phase * 23) * 0.10 if hit_time > 0 else 0.0
	if zombie:
		right_arm.rotation.x = 1.1 + (sin(phase * 2) * 0.5 if attacking else 0.0)
		left_arm.rotation.x = 1.0
	else:
		right_arm.rotation.x = (0.6 if reloading else PI / 2) + recoil * 0.4
		left_arm.rotation.x = (1.4 if focus else 0.3) if not reloading else 0.9
		right_arm.rotation.z = -0.2 if focus else 0.0
		flash.visible = recoil > 0.6
		ring.scale = Vector3.ONE * (0.82 if focus else 1.0)
		ring.visible = true

func shot() -> void:
	recoil = 1.0

func hurt() -> void:
	hit_time = 0.22
