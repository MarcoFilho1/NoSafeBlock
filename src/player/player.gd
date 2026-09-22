extends CharacterBody3D

const Health = preload("res://src/core/health.gd")
const Weapon = preload("res://src/player/weapon.gd")
const Visual = preload("res://src/visuals/actor_visual.gd")
const Props = preload("res://src/world/props.gd")
const Loadout = preload("res://src/player/loadout.gd")
const Progression = preload("res://src/systems/progression.gd")
const Combat = preload("res://src/combat/combat_resolver.gd")
const Hazard = preload("res://src/combat/hazard.gd")
var loadout = Loadout.new()
var progression = Progression.new()
var armor: float = 0
var grenades: int = 1
var effects: Node3D
var visual_weapon_id: String = ""

signal shot_fired(origin: Vector3)
signal cue_requested(kind: String)
signal died

var health = Health.new(100.0)
var weapon: RefCounted:
	get: return loadout.current()
var visual: Node3D
var camera: Camera3D
var active: bool = true
var focused: bool = false
var aim_point: Vector3 = Vector3(0, 1, -5)
var invulnerability: float = 0.0
var mouse_armed: bool = false

func _ready() -> void:
	add_to_group("players")
	collision_layer = 2
	collision_mask = 1 | 4 | 8
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.8
	collision.shape = shape
	collision.position.y = 0.9
	add_child(collision)
	visual = Visual.new()
	add_child(visual)
	visual.build(false)
	health.died.connect(func(): active = false; died.emit())

func _physics_process(delta: float) -> void:
	if not health.is_alive():
		visual.animate(delta, 0, false, false)
		return
	if not active:
		return
	loadout.tick(delta, progression.modifier("reload"))
	if visual_weapon_id != weapon.id:
		visual_weapon_id = weapon.id
		visual.set_weapon(weapon.definition)
	invulnerability = maxf(0, invulnerability - delta)
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		mouse_armed = true
	focused = mouse_armed and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := Vector3(input.x + input.y, 0, input.y - input.x).normalized()
	var speed := 3.0 if focused else 5.3
	speed *= progression.modifier("movement") * float(weapon.definition.move_multiplier)
	velocity = direction * speed
	velocity.y = -1.0
	move_and_slide()
	update_aim()
	if Input.is_action_just_pressed("reload") and weapon.reload():
		cue_requested.emit("reload")
	if mouse_armed and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		shoot_at(aim_point)
	visual.animate(delta, Vector2(velocity.x, velocity.z).length(), focused, true, false, weapon.reloading)

func update_aim() -> void:
	if not camera:
		return
	var mouse := get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse)
	var ray_direction := camera.project_ray_normal(mouse)
	# Ground-plane raycast: targets are lifted to weapon height after intersection.
	var ground_hit: Variant = Plane(Vector3.UP, 0).intersects_ray(ray_origin, ray_direction)
	if ground_hit != null:
		aim_point = ground_hit + Vector3(0, 1.0, 0)
		var direction: Vector3 = aim_point - global_position
		if Vector2(direction.x, direction.z).length() > 0.1:
			rotation.y = atan2(-direction.x, -direction.z)

func shoot_at(target: Vector3) -> bool:
	if not active or not health.is_alive() or not weapon.fire():
		return false
	var facing := target - global_position
	if Vector2(facing.x, facing.z).length() > 0.1:
		rotation.y = atan2(-facing.x, -facing.z)
	visual.animate(0.0, 0.0, focused, true)
	Combat.fire(self, target)
	visual.shot()
	shot_fired.emit(global_position)
	cue_requested.emit("shot")
	return true

func draw_tracer(origin: Vector3, end: Vector3) -> void:
	var tracer := MeshInstance3D.new()
	tracer.name = "ShotTracer"
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, Props.material(weapon.definition.color, true))
	mesh.surface_add_vertex(Vector3.ZERO)
	mesh.surface_add_vertex(end - origin)
	mesh.surface_end()
	tracer.mesh = mesh
	get_parent().add_child(tracer)
	tracer.global_position = origin
	get_tree().create_timer(0.07).timeout.connect(tracer.queue_free)

func take_damage(amount: float) -> void:
	if amount <= 0 or not active or invulnerability > 0 or not health.is_alive():
		return
	invulnerability = 0.35
	var reduced := amount * (1.0 - progression.modifier("resistance"))
	var absorbed := minf(armor, reduced)
	armor -= absorbed
	health.damage(reduced - absorbed)
	visual.hurt()
	cue_requested.emit("hurt")

func apply_upgrades() -> void:
	var previous: float = health.maximum
	health.maximum = progression.modifier("health")
	health.heal(maxf(0, health.maximum - previous))

func throw_grenade(target: Vector3) -> bool:
	if not active or not health.is_alive() or grenades <= 0 or not is_instance_valid(effects):
		return false
	grenades -= 1
	var direction := target - global_position
	direction.y = 0
	var end := global_position + direction.limit_length(12)
	var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(global_position + Vector3.UP, end + Vector3.UP, 1 | 8))
	if not hit.is_empty():
		end = hit.position - direction.normalized() * 0.3
	end.y = 0
	var blast := Hazard.new()
	blast.configure("grenade", end, 150, 4, 0.2)
	blast.warmup = 1.2
	blast.targets_player = false
	effects.add_child(blast)
	return true

func _unhandled_input(event: InputEvent) -> void:
	if not active or not health.is_alive():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_1: loadout.select_slot(0)
			KEY_2: loadout.select_slot(1)
			KEY_G: throw_grenade(aim_point)
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		loadout.select_slot(1 - loadout.active_slot)
