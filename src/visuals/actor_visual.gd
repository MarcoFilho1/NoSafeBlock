extends Node3D
## Procedural animation keeps assets editable and dependency-free.

const Props = preload("res://src/world/props.gd")
## Crawler limbs bend in the sagittal plane like human ones: elbows fold back,
## knees fold forward. Splay only clears the limb from the body.
const UPPER_ARM: float = 0.52
const FOREARM: float = 0.50
const ARM_ANGLE: float = 0.05
const ARM_BEND: float = 0.62
const ARM_SPLAY: float = 0.14
const THIGH: float = 0.44
const SHIN: float = 0.50
const LEG_ANGLE: float = 0.95
const LEG_BEND: float = -1.65
const LEG_SPLAY: float = 0.55
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
var weapon_mesh: MeshInstance3D
var body_mesh: MeshInstance3D
var head_mesh: MeshInstance3D
var crown_mesh: MeshInstance3D
var shadow_mesh: MeshInstance3D
var eye_meshes: Array[MeshInstance3D] = []
var shoulder_pads: Array[MeshInstance3D] = []
var belt_mesh: MeshInstance3D
## Limb cycle multiplier: a leaner frame moves its limbs faster at the same speed.
var gait: float = 1.0
var crawler: bool = false
## Resting fore/aft angle of each crawler limb; the gait swings around these.
var arm_base: float = 0.0
var leg_base: float = 0.0

func build(is_zombie: bool) -> void:
	zombie = is_zombie
	var coat := Color("728260") if zombie else Color("d7934d")
	var skin := Color("a0ab84") if zombie else Color("d8b48e")
	shadow_mesh = Props.cylinder(self, 0.52, 0.015, Vector3(0, 0.015, 0), Color("233c39"))
	shadow_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	torso = Node3D.new()
	add_child(torso)
	body_mesh = Props.box(torso, Vector3(0.65, 0.65, 0.38), Vector3(0, 1.02, 0), coat)
	body_material = body_mesh.material_override
	head_mesh = Props.box(torso, Vector3(0.42, 0.44, 0.42), Vector3(0, 1.58, -0.015), skin)
	crown_mesh = Props.box(torso, Vector3(0.46, 0.15, 0.45), Vector3(0, 1.84, 0), Color("374846"))
	for x in [-0.12, 0.12]:
		eye_meshes.append(Props.box(torso, Vector3(0.07, 0.045, 0.025), Vector3(x, 1.64, -0.237), Color("e8bd6c") if zombie else Color("293c42")))
	left_leg = limb(Vector3(-0.19, 0.65, 0), Vector3(0.23, 0.58, 0.26), Color("364d50"))
	right_leg = limb(Vector3(0.19, 0.65, 0), Vector3(0.23, 0.58, 0.26), Color("364d50"))
	left_arm = limb(Vector3(-0.43, 1.25, 0), Vector3(0.19, 0.55, 0.24), coat)
	right_arm = limb(Vector3(0.43, 1.25, 0), Vector3(0.19, 0.55, 0.24), coat)
	# Boots and hands hang off the limb tips, so the gait carries them for free.
	for leg in [left_leg, right_leg]:
		extremity(leg, Vector3(0.26, 0.16, 0.42), Vector3(0, 0.01, -0.07), Color("222d31"))
	for arm in [left_arm, right_arm]:
		extremity(arm, Vector3(0.2, 0.19, 0.22), Vector3(0, -0.05, 0), skin.darkened(0.3) if zombie else Color("3c4740"))
	for x in [-0.42, 0.42]:
		var pad := Props.detail(Props.wedge(torso, Vector3(0.36, 0.22, 0.44), Vector3(x, 1.28, 0), coat.darkened(0.22)))
		pad.rotation.z = -signf(x) * 0.55
		shoulder_pads.append(pad)
	belt_mesh = Props.detail(Props.box(torso, Vector3(0.69, 0.14, 0.42), Vector3(0, 0.75, 0), coat.darkened(0.45)))
	if zombie:
		Props.detail(Props.box(torso, Vector3(0.3, 0.13, 0.26), Vector3(0, 1.41, -0.16), skin.darkened(0.3)))
	else:
		Props.box(torso, Vector3(0.4, 0.5, 0.19), Vector3(0, 1, 0.28), Color("5c6752"))
		Props.detail(Props.box(torso, Vector3(0.5, 0.07, 0.22), Vector3(0, 1.79, -0.26), Color("2c3a38")))
		for x in [-0.17, 0.17]:
			Props.detail(Props.box(torso, Vector3(0.09, 0.62, 0.06), Vector3(x, 1.05, -0.2), Color("4a5545")))
		Props.box(right_arm, Vector3(0.13, 0.32, 0.2), Vector3(0, -0.62, 0.02), Color("27383d"))
		muzzle = Node3D.new()
		muzzle.position = Vector3(0, -0.81, 0.02)
		right_arm.add_child(muzzle)
		flash = Props.box(muzzle, Vector3(0.2, 0.25, 0.2), Vector3.ZERO, Color("ffe5a1"))
		flash.material_override = Props.material(Color("ffe5a1"), true)
		flash.visible = false
		ring = Props.ring(self, 0.52, 0.60, Vector3(0, 0.08, 0), Color("edba68"), 24)
		ring.material_override = Props.material(Color("edba68"), true)
		ring.material_override.no_depth_test = true

func limb(pos: Vector3, size: Vector3, color: Color) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = pos
	torso.add_child(pivot)
	Props.box(pivot, size, Vector3(0, -size.y / 2.0, 0), color)
	var tip := Node3D.new()
	tip.name = "Tip"
	tip.position.y = -size.y
	pivot.add_child(tip)
	return pivot

func extremity(pivot: Node3D, size: Vector3, offset: Vector3, color: Color) -> MeshInstance3D:
	return Props.detail(Props.box(pivot.get_node("Tip"), size, offset, color))

func animate(delta: float, speed: float, focus: bool, alive: bool, attacking: bool = false, reloading: bool = false) -> void:
	if not alive:
		death_time = minf(death_time + delta * 3, 1.0)
		rotation.z = lerpf(0.0, -PI / 2, death_time)
		position.y = -0.05
		if ring:
			ring.visible = false
		return
	phase += delta * (8.0 * gait if zombie else 12.0)
	recoil = maxf(0, recoil - delta * 7)
	hit_time = maxf(0, hit_time - delta)
	var stride := minf(speed / 3.0, 1.0)
	if crawler:
		animate_crawler(stride, attacking)
		return
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

func animate_crawler(stride: float, attacking: bool) -> void:
	## Limbs swing around their resting pose, diagonal pairs together.
	var swing := sin(phase) * 0.30 * stride
	left_arm.rotation.x = arm_base - swing
	right_arm.rotation.x = arm_base + swing
	left_leg.rotation.x = leg_base + swing
	right_leg.rotation.x = leg_base - swing
	if attacking:
		# Pushes off the back legs and strikes with both arms.
		var lunge: float = arm_base - 0.85 + sin(phase * 2.0) * 0.3
		left_arm.rotation.x = lunge
		right_arm.rotation.x = lunge
	torso.position.y = absf(sin(phase * 2.0)) * 0.04 * stride
	torso.rotation.z = sin(phase * 23) * 0.10 if hit_time > 0 else 0.0

func shot() -> void:
	recoil = 1.0

func hurt() -> void:
	hit_time = 0.22

func set_weapon(data: Dictionary) -> void:
	if weapon_mesh:
		weapon_mesh.queue_free()
	var long_gun: bool = data.id not in ["service_pistol", "heavy_pistol"]
	weapon_mesh = Props.box(right_arm, Vector3(0.18, 0.62 if long_gun else 0.26, 0.18), Vector3(0, -0.65, 0.02), data.color.darkened(0.35))
	flash.material_override = Props.material(data.color, true)

func set_enemy_kind(kind: String, color: Color) -> void:
	match kind:
		"flanker":
			build_crawler()
		"spitter", "matriarch":
			for x in [-0.35, 0.35]:
				Props.cylinder(torso, 0.3, 0.65, Vector3(x, 1.15, 0.35), color.lightened(0.2))
		"demolisher", "executioner":
			for x in [-0.5, 0.5]:
				Props.box(torso, Vector3(0.4, 0.35, 0.55), Vector3(x, 1.3, 0), Color("424848"))
			Props.box(torso, Vector3(0.7, 0.6, 0.2), Vector3(0, 1, -0.25), color.darkened(0.3))
		"screamer":
			Props.cylinder(torso, 0.28, 0.25, Vector3(0, 1.6, -0.2), Color("462b3e"))
		"volatile":
			Props.cylinder(torso, 0.45, 0.75, Vector3(0, 0.9, 0), Color("c58848"))
		"aberration":
			for x in [-0.45, 0.45]:
				var spike := Props.box(torso, Vector3(0.18, 1.0, 0.18), Vector3(x, 1.7, 0.2), color.lightened(0.3))
				spike.rotation.z = x

func build_crawler() -> void:
	## A thin human body on all fours: shoulders ride higher than the hips, so the
	## spine runs on a diagonal, and the joints fold the way human ones do.
	crawler = true
	gait = 1.45
	arm_base = ARM_ANGLE
	leg_base = LEG_ANGLE
	var shoulder := Vector3(0, limb_drop(ARM_SPLAY, ARM_ANGLE, ARM_BEND, UPPER_ARM, FOREARM), -0.35)
	var hip := Vector3(0, limb_drop(LEG_SPLAY, LEG_ANGLE, LEG_BEND, THIGH, SHIN), 0.42)
	var spine := shoulder - hip
	body_mesh.position = hip + spine * 0.5
	body_mesh.rotation.x = atan2(spine.y, -spine.z)
	body_mesh.scale = Vector3(0.70, 0.62, spine.length() / 0.38)
	head_mesh.scale = Vector3(0.80, 0.88, 0.80)
	head_mesh.position = shoulder + Vector3(0, 0.30, -0.17)
	# The head cranes up to keep the player in sight while the body stays low.
	head_mesh.rotation.x = 0.30
	crown_mesh.scale = Vector3(0.40, 1.9, 0.5)
	crown_mesh.position = shoulder + Vector3(0, 0.15, -0.10)
	# The neck rises from the shoulders and leans forward, instead of jutting straight out.
	crown_mesh.rotation.x = -0.45
	for i in range(eye_meshes.size()):
		eye_meshes[i].position = head_mesh.position + Vector3(-0.08 if i == 0 else 0.08, 0.06, -0.17)
	# Shoulder pads ride the lowered shoulders; a belt makes no sense on all fours.
	for i in range(shoulder_pads.size()):
		shoulder_pads[i].position = shoulder + Vector3(-0.26 if i == 0 else 0.26, 0.05, 0.04)
		shoulder_pads[i].scale = Vector3(0.75, 0.75, 0.75)
	belt_mesh.visible = false
	human_limb(left_arm, Vector3(-0.22, shoulder.y, shoulder.z), -ARM_SPLAY, ARM_ANGLE, ARM_BEND, UPPER_ARM, FOREARM, 0.105)
	human_limb(right_arm, Vector3(0.22, shoulder.y, shoulder.z), ARM_SPLAY, ARM_ANGLE, ARM_BEND, UPPER_ARM, FOREARM, 0.105)
	human_limb(left_leg, Vector3(-0.21, hip.y, hip.z), -LEG_SPLAY, LEG_ANGLE, LEG_BEND, THIGH, SHIN, 0.135)
	human_limb(right_leg, Vector3(0.21, hip.y, hip.z), LEG_SPLAY, LEG_ANGLE, LEG_BEND, THIGH, SHIN, 0.135)
	shadow_mesh.scale = Vector3(1.5, 1, 1.9)

func limb_drop(splay: float, angle: float, bend: float, upper: float, lower: float) -> float:
	## How far the folded limb reaches below its anchor, so hands and feet land on
	## the floor whatever pose the constants describe.
	var upper_basis := Basis.from_euler(Vector3(angle, 0, splay))
	var lower_basis := upper_basis * Basis.from_euler(Vector3(bend, 0, 0))
	return -(upper_basis * Vector3(0, -upper, 0)).y - (lower_basis * Vector3(0, -lower, 0)).y

func human_limb(pivot: Node3D, anchor: Vector3, splay: float, angle: float, bend: float, upper: float, lower: float, thickness: float) -> void:
	var color := Color("364d50")
	pivot.position = anchor
	pivot.rotation = Vector3(angle, 0, splay)
	var bone: MeshInstance3D = pivot.get_child(0)
	var size: Vector3 = bone.mesh.size
	bone.scale = Vector3(thickness / size.x, upper / size.y, thickness / size.z)
	bone.position.y = -upper / 2.0
	bone.material_override = Props.material(color)
	var joint := Node3D.new()
	joint.position.y = -upper
	joint.rotation.x = bend
	pivot.add_child(joint)
	Props.box(joint, Vector3(thickness * 0.85, lower, thickness * 0.85), Vector3(0, -lower / 2.0, 0), color)
	## The hand or foot follows the elbow down to the end of the lower bone and
	## shrinks with the limb, so a crawler plants four thin extremities.
	var tip: Node3D = pivot.get_node("Tip")
	pivot.remove_child(tip)
	joint.add_child(tip)
	tip.position = Vector3(0, -lower, 0)
	tip.scale = Vector3.ONE * (thickness / 0.22)
